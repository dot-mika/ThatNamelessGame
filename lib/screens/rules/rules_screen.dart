import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../audio/audio_controller.dart';
import '../../config/assets.dart';
import '../../config/config.dart';
import '../../settings/settings_notifier.dart';
import '../widgets/tappable_image.dart';
import 'rule_animations.dart';

/// 9ページのルール画像と共通ナビゲーションを表示する画面
class RulesScreen extends ConsumerStatefulWidget {
  const RulesScreen({super.key});

  @override
  ConsumerState<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends ConsumerState<RulesScreen> {
  static const _pages = Assets.rulePageNumbers;

  var _page = 0;

  /// スクロールが止まり、画面がぴったり表示しているページ
  var _settledPage = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
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

  void _onPageChanged(int index) {
    setState(() => _page = index);
  }

  /// スワイプやボタン操作のスクロールが止まった時だけ、表示ページを確定する
  bool _onScroll(ScrollNotification notification) {
    if (notification is! ScrollEndNotification || notification.depth != 0) {
      return false;
    }
    final page = _pageController.page;
    if (page == null || (page - page.round()).abs() > 0.01) return false;
    if (page.round() != _settledPage) {
      setState(() => _settledPage = page.round());
    }
    return false;
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
      // アプリ全体のScaffoldは透過設定のため、ページ画像の描画待ちでも
      // 背面のホーム画面が見えないようルール画面は不透明にする。
      backgroundColor: Colors.white,
      body: Listener(
        child: Stack(
          children: [
            Positioned.fill(
              child: NotificationListener<ScrollNotification>(
                onNotification: _onScroll,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  // 隣のページも先にレイアウトし、スワイプ開始時の描画待ちを減らす。
                  allowImplicitScrolling: true,
                  onPageChanged: (index) {
                    _onPageChanged(index);
                  },
                  itemBuilder: (_, index) {
                    final page = _pages[index];
                    if (RuleAnimationPage.supports(page)) {
                      // 隣のページも先に構築されるため、画面が止まったページだけ再生する
                      return RuleAnimationPage(
                        key: ValueKey(page),
                        page: page,
                        language: language,
                        isActive: index == _settledPage,
                      );
                    }
                    if (RuleStillPage.supports(page)) {
                      return RuleStillPage(
                        key: ValueKey(page),
                        page: page,
                        language: language,
                      );
                    }
                    return Image.asset(
                      Assets.rulesPage(page, language),
                      fit: BoxFit.cover,
                    );
                  },
                ),
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
      ),
    );
  }
}
