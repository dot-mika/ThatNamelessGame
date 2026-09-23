
import 'package:flutter_test/flutter_test.dart';
import 'package:that_nameless_game/config/assets.dart';
import 'package:that_nameless_game/config/config.dart';
import 'package:that_nameless_game/settings/settings_state.dart';

void main() {
  test('rule-page manifest has nine ordered pages and preserves GIF pages', () {
    expect(Assets.rulePageNumbers, [1, 2, 3, 4, 5, 6, 7, 8, 9]);
    for (final page in Assets.rulePageNumbers) {
      final asset = Assets.rulesPage(page, AppLanguage.en);
      expect(asset, contains('rules_${page}_en'));
      expect(asset.endsWith('.gif'), page >= 3 && page <= 6);
    }
  });

  test('rule navigation has localized semantic labels', () {
    expect(AppStrings.previousPage(AppLanguage.en), 'Previous page');
    expect(AppStrings.nextPage(AppLanguage.en), 'Next page');
    expect(AppStrings.previousPage(AppLanguage.jp), isNot('Previous page'));
    expect(AppStrings.nextPage(AppLanguage.jp), isNot('Next page'));
  });
}
