import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:that_nameless_game/settings/settings_state.dart';
import 'package:that_nameless_game/settings/save_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'uses the device language and specification defaults on first launch',
    () async {
      SharedPreferences.setMockInitialValues({});
      final repository = await SettingsRepository.create();

      final jp = repository.load(deviceLocale: const Locale('ja', 'JP'));
      final en = repository.load(deviceLocale: const Locale('fr', 'FR'));

      expect(jp.language, AppLanguage.jp);
      expect(en.language, AppLanguage.en);
      expect(jp.bgmEnabled, isTrue);
      expect(jp.seEnabled, isTrue);
      expect(jp.timeLimit, TimeLimit.seconds15);
      expect(jp.star2p, isFalse);
      expect(jp.starEasy, isFalse);
      expect(jp.starNormal, isFalse);
      expect(jp.starHard, isFalse);
    },
  );

  test('persists specification defaults when settings do not exist', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = await SettingsRepository.create();

    final settings = await repository.loadOrCreate(
      deviceLocale: const Locale('ja', 'JP'),
    );
    final preferences = await SharedPreferences.getInstance();

    expect(settings.language, AppLanguage.jp);
    expect(preferences.getBool('settingsInitialized'), isTrue);
    expect(preferences.getString('language'), 'jp');
    expect(preferences.getInt('twoPlayerTimeLimitSeconds'), 15);
  });

  test('falls back per field without discarding valid settings', () async {
    SharedPreferences.setMockInitialValues({
      'settingsInitialized': true,
      'language': 'unknown',
      'bgmEnabled': false,
      'seEnabled': 'wrong type',
      'twoPlayerTimeLimitSeconds': 12,
      'starTwoPlayer': true,
      'starEasy': 1,
      'starNormal': false,
      'starHard': true,
    });
    final repository = await SettingsRepository.create();

    final value = repository.load(deviceLocale: const Locale('ja'));

    expect(value.language, AppLanguage.jp);
    expect(value.bgmEnabled, isFalse);
    expect(value.seEnabled, isTrue);
    expect(value.timeLimit, TimeLimit.seconds15);
    expect(value.star2p, isTrue);
    expect(value.starEasy, isFalse);
    expect(value.starNormal, isFalse);
    expect(value.starHard, isTrue);
  });

  test('round-trips every persisted field with string enum values', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = await SettingsRepository.create();
    const expected = AppSettings(
      language: AppLanguage.en,
      bgmEnabled: false,
      seEnabled: false,
      timeLimit: TimeLimit.unlimited,
      star2p: true,
      starEasy: true,
      starNormal: true,
      starHard: true,
    );

    await repository.save(expected);

    expect(repository.load(), expected);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('language'), 'en');
    expect(preferences.getInt('twoPlayerTimeLimitSeconds'), -1);
    expect(preferences.getBool('settingsInitialized'), isTrue);
  });
}
