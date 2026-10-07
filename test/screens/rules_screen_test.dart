import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:that_nameless_game/audio/audio_controller.dart';
import 'package:that_nameless_game/config/assets.dart';
import 'package:that_nameless_game/config/config.dart';
import 'package:that_nameless_game/screens/rules/rule_animations.dart';
import 'package:that_nameless_game/screens/rules/rules_screen.dart';
import 'package:that_nameless_game/settings/settings_notifier.dart';
import 'package:that_nameless_game/settings/settings_repository.dart';
import 'package:that_nameless_game/settings/settings_state.dart';

/// rules_3は再生開始から1秒で自分の手が選択状態になる
bool _showsSelectedHand(WidgetTester tester) => tester
    .widgetList<Image>(find.byType(Image))
    .map((image) => image.image)
    .whereType<AssetImage>()
    .any((image) => image.assetName.contains('selected'));

Widget _rules3({required bool isActive}) => MaterialApp(
  home: Material(
    child: RuleAnimationPage(
      page: 3,
      language: AppLanguage.jp,
      isActive: isActive,
    ),
  ),
);

void main() {
  test(
    'rule-page manifest has nine ordered pages and draws pages 2-9 in code',
    () {
      expect(Assets.rulePageNumbers, [1, 2, 3, 4, 5, 6, 7, 8, 9]);
      expect(Assets.codeRulePageNumbers, [2, 3, 4, 5, 6, 7, 8, 9]);
      for (final page in [1]) {
        final asset = Assets.rulesPage(page, AppLanguage.en);
        expect(asset, contains('rules_${page}_en'));
        expect(asset.endsWith('.png'), isTrue);
      }
    },
  );

  test('rule navigation has localized semantic labels', () {
    expect(AppStrings.previousPage(AppLanguage.en), 'Previous page');
    expect(AppStrings.nextPage(AppLanguage.en), 'Next page');
    expect(AppStrings.previousPage(AppLanguage.jp), isNot('Previous page'));
    expect(AppStrings.nextPage(AppLanguage.jp), isNot('Next page'));
  });

  test('every rule and play background color has an image file', () {
    for (final color in [
      AppColors.rules2Yellow,
      AppColors.rules3Green,
      AppColors.rules4Blue,
      AppColors.rules5Purple,
      AppColors.rules6Pink,
      AppColors.rules7Red,
      AppColors.rules8Yellow,
      AppColors.rules9Green,
      AppColors.disabled,
    ]) {
      final asset = Assets.ruleBackground(color);
      expect(File(asset).existsSync(), isTrue, reason: asset);
    }
  });

  test('pages 2-9 are drawn in code and 3-6 are animated', () {
    for (final page in Assets.rulePageNumbers) {
      expect(
        RuleAnimationPage.supports(page) || RuleStillPage.supports(page),
        Assets.codeRulePageNumbers.contains(page),
      );
      expect(RuleAnimationPage.supports(page), page >= 3 && page <= 6);
    }
  });

  testWidgets('rule animation plays only while its page is shown', (
    tester,
  ) async {
    await tester.pumpWidget(_rules3(isActive: false));
    await tester.pump(const Duration(seconds: 3));
    expect(_showsSelectedHand(tester), isFalse);

    await tester.pumpWidget(_rules3(isActive: true));
    await tester.pump(const Duration(milliseconds: 1200));
    expect(_showsSelectedHand(tester), isTrue);

    // 離れたページは先頭に戻り、再表示時は最初から再生する
    await tester.pumpWidget(_rules3(isActive: false));
    await tester.pump();
    expect(_showsSelectedHand(tester), isFalse);
    await tester.pumpWidget(_rules3(isActive: true));
    await tester.pump(const Duration(milliseconds: 800));
    expect(_showsSelectedHand(tester), isFalse);
    await tester.pump(const Duration(milliseconds: 400));
    expect(_showsSelectedHand(tester), isTrue);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('rule animation starts only after the page stops scrolling', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final repository = await SettingsRepository.create();
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(repository),
          audioControllerProvider.overrideWithValue(AudioController.silent()),
          initialSettingsProvider.overrideWithValue(
            AppSettings.defaults(AppLanguage.jp),
          ),
        ],
        child: const MaterialApp(home: RulesScreen()),
      ),
    );
    await tester.tap(find.byKey(const Key('rulesNextButton')));
    await tester.pumpAndSettle();

    bool rules3Active() => tester
        .widget<RuleAnimationPage>(
          find.byWidgetPredicate(
            (widget) => widget is RuleAnimationPage && widget.page == 3,
            skipOffstage: false,
          ),
        )
        .isActive;
    expect(rules3Active(), isFalse);

    // 半分以上めくっても、指を離してスクロールが止まるまでは再生しない
    final gesture = await tester.startGesture(const Offset(1000, 360));
    await gesture.moveBy(const Offset(-400, 0));
    await gesture.moveBy(const Offset(-400, 0));
    await tester.pump(const Duration(seconds: 2));
    expect(rules3Active(), isFalse);

    await gesture.up();
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(rules3Active(), isTrue);

    await tester.pumpWidget(const SizedBox());
  });
}
