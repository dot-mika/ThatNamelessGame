import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../audio/audio_controller.dart';
import '../../config/assets.dart';
import '../../config/config.dart';
import '../../settings/settings_notifier.dart';
import '../widgets/tappable_image.dart';

/// 9ページのルール画像と共通ナビゲーションを表示する画面。
class RulesScreen extends ConsumerStatefulWidget {
  const RulesScreen({super.key});

  @override
  ConsumerState<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends ConsumerState<RulesScreen> {
  static const _pages = Assets.rulePageNumbers;

  var _page = 0;
  final _gifRevisions = <int, int>{};
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // GIFページへ移動する頃にはバイト列を用意済みにし、初回表示でも
    // デコード待ちの黒い一瞬を出さない。
    unawaited(_preloadRuleGifs());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _setPage(int page) {
    if (page < 0 || page >= _pages.length || page == _page) return;
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  bool _isGifPage(int page) => page >= 3 && page <= 6;

  Future<void> _preloadRuleGifs() async {
    final language = ref.read(appSettingsProvider).language;
    await Future.wait([
      for (final page in [3, 4, 5, 6])
        rootBundle.load(Assets.rulesPage(page, language)),
    ]);
  }

  void _onPageChanged(int index) {
    final page = _pages[index];
    setState(() {
      _page = index;
      if (_isGifPage(page)) {
        _gifRevisions[page] = (_gifRevisions[page] ?? 0) + 1;
      }
    });
  }

  void _goHome() {
    ref.playTapSound();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(appSettingsProvider).language;

    return Scaffold(
      key: const Key('rulesScreen'),
      body: Stack(
        children: [
          Positioned.fill(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (_, index) {
                final page = _pages[index];
                final asset = Assets.rulesPage(page, language);
                return _isGifPage(page)
                    ? _RestartingGif(
                        asset: asset,
                        revision: _gifRevisions[page] ?? 0,
                      )
                    : Image.asset(asset, fit: BoxFit.cover);
              },
            ),
          ),
          Positioned(
            top: 20,
            right: 20,
            width: 100,
            height: 100,
            child: TappableImage(
              key: const Key('rulesHomeButton'),
              asset: Assets.rulesHome,
              semanticLabel: AppStrings.home(language),
              onTap: _goHome,
            ),
          ),
          if (_page > 0)
            Positioned(
              left: 20,
              bottom: 20,
              width: 100,
              height: 100,
              child: TappableImage(
                key: const Key('rulesBackButton'),
                asset: Assets.rulesBackPage,
                semanticLabel: AppStrings.previousPage(language),
                onTap: () => _setPage(_page - 1),
              ),
            ),
          if (_page < _pages.length - 1)
            Positioned(
              right: 20,
              bottom: 20,
              width: 100,
              height: 100,
              child: TappableImage(
                key: const Key('rulesNextButton'),
                asset: Assets.rulesNextPage,
                semanticLabel: AppStrings.nextPage(language),
                onTap: () => _setPage(_page + 1),
              ),
            ),
        ],
      ),
    );
  }
}

/// 毎回新しいGIFデコーダーを使い、先頭フレームから再生する画像。
/// 新しい先頭フレームが描画されるまでは直前フレームを残すため、
/// ページ送りの黒いちらつきが起きない。
class _RestartingGif extends StatefulWidget {
  const _RestartingGif({required this.asset, required this.revision});

  final String asset;
  final int revision;

  @override
  State<_RestartingGif> createState() => _RestartingGifState();
}

class _RestartingGifState extends State<_RestartingGif> {
  Uint8List? _sourceBytes;
  Uint8List? _currentBytes;
  Uint8List? _previousBytes;
  var _request = 0;
  var _previousRemovalQueued = false;

  @override
  void initState() {
    super.initState();
    _loadGif();
  }

  @override
  void didUpdateWidget(covariant _RestartingGif oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset != widget.asset ||
        oldWidget.revision != widget.revision) {
      if (oldWidget.asset != widget.asset) _sourceBytes = null;
      _loadGif();
    }
  }

  Future<void> _loadGif() async {
    if (_sourceBytes case final sourceBytes?) {
      _showFreshGif(sourceBytes);
      return;
    }
    final request = ++_request;
    final data = await rootBundle.load(widget.asset);
    final sourceBytes = Uint8List.fromList(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    if (!mounted || request != _request) return;
    _sourceBytes = sourceBytes;
    _showFreshGif(sourceBytes);
  }

  void _showFreshGif(Uint8List sourceBytes) {
    final bytes = Uint8List.fromList(sourceBytes);
    setState(() {
      _previousBytes = _currentBytes;
      _currentBytes = bytes;
      _previousRemovalQueued = false;
    });
  }

  void _removePreviousWhenReady(Uint8List bytes) {
    if (_previousBytes == null || _previousRemovalQueued) return;
    _previousRemovalQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && identical(_currentBytes, bytes)) {
        setState(() => _previousBytes = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentBytes = _currentBytes;
    if (currentBytes == null) {
      // 初回デコードが済むまでPageViewの背面（黒）を見せない。
      return const ColoredBox(color: Colors.white);
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_previousBytes case final previousBytes?)
          Image.memory(previousBytes, fit: BoxFit.cover),
        Image.memory(
          currentBytes,
          fit: BoxFit.cover,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || frame != null) {
              _removePreviousWhenReady(currentBytes);
            }
            return child;
          },
        ),
      ],
    );
  }
}
