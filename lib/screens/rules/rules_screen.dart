import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../audio/audio_controller.dart';
import '../../config/assets.dart';
import '../../config/config.dart';
import '../../settings/update_settings.dart';
import '../widgets/tappable_image.dart';

/// Hosts the nine rule pages and their shared navigation controls.
class RulesScreen extends ConsumerStatefulWidget {
  const RulesScreen({super.key});

  @override
  ConsumerState<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends ConsumerState<RulesScreen> {
  static const _pages = Assets.rulePageNumbers;

  var _page = 0;
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

  void _goHome() {
    unawaited(ref.read(audioControllerProvider).play(SoundEffect.tapButton));
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
              onPageChanged: (page) => setState(() => _page = page),
              itemBuilder: (_, index) => Image.asset(
                Assets.rulesPage(_pages[index], language),
                fit: BoxFit.cover,
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
                asset: 'assets/rules/buttons/rules_back_page.png',
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
                asset: 'assets/rules/buttons/rules_next_page.png',
                semanticLabel: AppStrings.nextPage(language),
                onTap: () => _setPage(_page + 1),
              ),
            ),
        ],
      ),
    );
  }
}
