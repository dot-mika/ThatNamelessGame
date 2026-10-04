import 'dart:developer' as developer;
import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';

import 'settings_state.dart';

/// 状態管理から永続化を切り離すための保存境界
/// NotifierをSharedPreferencesに依存させず、テスト時の差し替えを容易にする
abstract interface class SettingsStore {
  Future<void> save(AppSettings settings);
}

/// SharedPreferencesへ設定を読み書きする永続化層
class SettingsRepository implements SettingsStore {
  SettingsRepository._(this._preferences);

  static const _initializedKey = 'settingsInitialized';
  static const _languageKey = 'language';
  static const _bgmKey = 'bgmEnabled';
  static const _seKey = 'seEnabled';
  static const _timeLimitKey = 'twoPlayerTimeLimitSeconds';

  /// 保存済みデータとの互換のため、キー名は変更しない
  static const _starKeys = {
    StarMode.twoPlayer: 'starTwoPlayer',
    StarMode.easy: 'starEasy',
    StarMode.normal: 'starNormal',
    StarMode.hard: 'starHard',
  };
  static const _progressKeys = {
    StarMode.twoPlayer: 'twoPlayerCompleted',
    StarMode.easy: 'easyWinStreak',
    StarMode.normal: 'normalWinStreak',
    StarMode.hard: 'hardWinStreak',
  };

  final SharedPreferences _preferences;

  static Future<SettingsRepository> create() async =>
      SettingsRepository._(await SharedPreferences.getInstance());

  /// 保存済み設定を読み込み、初回起動時だけ既定値を保存する
  Future<AppSettings> loadOrCreate({Locale? deviceLocale}) async {
    final settings = load(deviceLocale: deviceLocale);
    if (_preferences.get(_initializedKey) != true) {
      await save(settings);
    }
    return settings;
  }

  /// 壊れた保存値は初期値へフォールバックして設定を復元する
  AppSettings load({Locale? deviceLocale}) {
    final locale = deviceLocale ?? PlatformDispatcher.instance.locale;
    final defaults = AppSettings.defaults(
      locale.languageCode == 'ja' ? AppLanguage.jp : AppLanguage.en,
    );
    var settings = defaults.copyWith(
      language: _readLanguage(defaults.language),
      bgmEnabled: _readBool(_bgmKey, defaults.bgmEnabled),
      seEnabled: _readBool(_seKey, defaults.seEnabled),
      timeLimit: _readTimeLimit(defaults.timeLimit),
    );
    for (final mode in StarMode.values) {
      settings = settings
          .withStar(mode, _readBool(_starKeys[mode]!, defaults.hasStar(mode)))
          .withProgressCount(mode, _readNonNegativeInt(_progressKeys[mode]!));
    }
    return settings;
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

  int _readNonNegativeInt(String key) {
    final value = _preferences.get(key);
    if (value is int && value >= 0) return value;
    _logInvalidSetting(key, value);
    return 0;
  }

  void _logInvalidSetting(String key, Object? value) {
    if (_preferences.get(_initializedKey) != true) return;
    developer.log('Stored setting "$key" is missing or invalid: $value');
  }

  /// 設定値をすべて保存してから、初期化済みフラグを立てる
  @override
  Future<void> save(AppSettings settings) async {
    await Future.wait([
      _writeString(_languageKey, settings.language.name),
      _writeBool(_bgmKey, settings.bgmEnabled),
      _writeBool(_seKey, settings.seEnabled),
      _writeInt(_timeLimitKey, settings.timeLimit.seconds),
      for (final mode in StarMode.values) ...[
        _writeBool(_starKeys[mode]!, settings.hasStar(mode)),
        _writeInt(_progressKeys[mode]!, settings.progressCount(mode)),
      ],
    ]);
    // 全項目の保存完了後に、設定の初期化済みフラグを保存する
    await _writeBool(_initializedKey, true);
  }

  Future<void> _writeString(String key, String value) =>
      _requireSaved(_preferences.setString(key, value), key);

  Future<void> _writeBool(String key, bool value) =>
      _requireSaved(_preferences.setBool(key, value), key);

  Future<void> _writeInt(String key, int value) =>
      _requireSaved(_preferences.setInt(key, value), key);

  Future<void> _requireSaved(Future<bool> operation, String key) async {
    if (!await operation) throw StateError('Could not persist "$key".');
  }
}
