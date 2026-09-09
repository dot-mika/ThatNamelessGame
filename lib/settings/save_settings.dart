import 'dart:ui';
import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

import 'settings_state.dart';

class SettingsRepository {
  SettingsRepository._(this._preferences);

  static const _initializedKey = 'settingsInitialized';
  static const _languageKey = 'language';
  static const _bgmKey = 'bgmEnabled';
  static const _seKey = 'seEnabled';
  static const _timeLimitKey = 'twoPlayerTimeLimitSeconds';
  static const _starTwoPlayerKey = 'starTwoPlayer';
  static const _starEasyKey = 'starEasy';
  static const _starNormalKey = 'starNormal';
  static const _starHardKey = 'starHard';

  final SharedPreferences _preferences;

  static Future<SettingsRepository> create() async =>
      SettingsRepository._(await SharedPreferences.getInstance());

  /// 保存済み設定を読み込み、初回起動時だけ既定値を保存する。
  Future<AppSettings> loadOrCreate({Locale? deviceLocale}) async {
    final settings = load(deviceLocale: deviceLocale);
    if (_preferences.get(_initializedKey) != true) {
      await save(settings);
    }
    return settings;
  }

  AppSettings load({Locale? deviceLocale}) {
    final locale = deviceLocale ?? PlatformDispatcher.instance.locale;
    final defaults = AppSettings.defaults(
      locale.languageCode == 'ja' ? AppLanguage.jp : AppLanguage.en,
    );
    return AppSettings(
      language: _readLanguage(defaults.language),
      bgmEnabled: _readBool(_bgmKey, defaults.bgmEnabled),
      seEnabled: _readBool(_seKey, defaults.seEnabled),
      timeLimit: _readTimeLimit(defaults.timeLimit),
      star2p: _readBool(_starTwoPlayerKey, defaults.star2p),
      starEasy: _readBool(_starEasyKey, defaults.starEasy),
      starNormal: _readBool(_starNormalKey, defaults.starNormal),
      starHard: _readBool(_starHardKey, defaults.starHard),
    );
  }

  AppLanguage _readLanguage(AppLanguage defaultValue) {
    final value = _preferences.get(_languageKey);
    if (value is String) {
      for (final language in AppLanguage.values) {
        if (language.name == value) return language;
      }
    }
    _logInvalidSetting(_languageKey, value);
    return defaultValue;
  }

  bool _readBool(String key, bool defaultValue) {
    final value = _preferences.get(key);
    if (value is bool) return value;
    _logInvalidSetting(key, value);
    return defaultValue;
  }

  TimeLimit _readTimeLimit(TimeLimit defaultValue) {
    final value = _preferences.get(_timeLimitKey);
    if (value is int) {
      final timeLimit = TimeLimit.fromSeconds(value);
      if (timeLimit != null) return timeLimit;
    }
    _logInvalidSetting(_timeLimitKey, value);
    return defaultValue;
  }

  void _logInvalidSetting(String key, Object? value) {
    if (_preferences.get(_initializedKey) != true) return;
    developer.log('Stored setting "$key" is missing or invalid: $value');
  }

  Future<void> save(AppSettings settings) async {
    await Future.wait([
      _requireSaved(
        _preferences.setString(_languageKey, settings.language.name),
        _languageKey,
      ),
      _requireSaved(
        _preferences.setBool(_bgmKey, settings.bgmEnabled),
        _bgmKey,
      ),
      _requireSaved(_preferences.setBool(_seKey, settings.seEnabled), _seKey),
      _requireSaved(
        _preferences.setInt(_timeLimitKey, settings.timeLimit.seconds),
        _timeLimitKey,
      ),
      _requireSaved(
        _preferences.setBool(_starTwoPlayerKey, settings.star2p),
        _starTwoPlayerKey,
      ),
      _requireSaved(
        _preferences.setBool(_starEasyKey, settings.starEasy),
        _starEasyKey,
      ),
      _requireSaved(
        _preferences.setBool(_starNormalKey, settings.starNormal),
        _starNormalKey,
      ),
      _requireSaved(
        _preferences.setBool(_starHardKey, settings.starHard),
        _starHardKey,
      ),
    ]);
    // 全項目の保存完了後に、設定の初期化済みフラグを保存する。
    await _requireSaved(
      _preferences.setBool(_initializedKey, true),
      _initializedKey,
    );
  }

  Future<void> _requireSaved(Future<bool> operation, String key) async {
    if (!await operation) throw StateError('Could not persist "$key".');
  }
}
