import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:that_nameless_game/settings/settings_state.dart';
import 'package:that_nameless_game/settings/save_settings.dart';

void main() {
  test('4つの星を個別のboolとして保存・復元できる', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = await SettingsRepository.create();
    const settings = AppSettings(
      language: AppLanguage.jp,
      bgmEnabled: true,
      seEnabled: true,
      timeLimit: TimeLimit.seconds15,
      star2p: true,
      starEasy: false,
      starNormal: true,
      starHard: false,
    );

    await repository.save(settings);
    final loaded = repository.load();

    expect(loaded.star2p, isTrue);
    expect(loaded.starEasy, isFalse);
    expect(loaded.starNormal, isTrue);
    expect(loaded.starHard, isFalse);
  });

  test('未使用の旧キーは設定として読み込まない', () async {
    SharedPreferences.setMockInitialValues({
      'achievement_twoPlayer': true,
      'achievement_easy': true,
      'achievement_normal': false,
      'achievement_hard': true,
    });
    final repository = await SettingsRepository.create();

    final loaded = repository.load();

    expect(loaded.star2p, isFalse);
    expect(loaded.starEasy, isFalse);
    expect(loaded.starNormal, isFalse);
    expect(loaded.starHard, isFalse);
  });
}
