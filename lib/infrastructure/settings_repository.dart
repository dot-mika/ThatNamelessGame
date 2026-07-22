import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/config.dart';

class SettingsRepository {
  static const _keyLanguage = 'language';
  static const _keyBgmOn = 'bgmOn';
  static const _keySeOn = 'seOn';
  static const _keyTwoPlayerTimeLimit = 'twoPlayerTimeLimit';
  static const _keyStarTwoPlayer = 'starTwoPlayer';
  static const _keyStarEasy = 'starEasy';
  static const _keyStarNormal = 'starNormal';
  static const _keyStarHard = 'starHard';

  late final SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // 端末に旧バージョン由来の型違いの値が残っている場合があるため、
  // getString()/getBool() の型キャスト例外を避けて安全に読む。
  String? _getString(String key) {
    final value = _prefs.get(key);
    return value is String ? value : null;
  }

  bool? _getBool(String key) {
    final value = _prefs.get(key);
    return value is bool ? value : null;
  }

  String get language {
    final saved = _getString(_keyLanguage);
    if (saved != null) return saved;
    // 初回起動: 端末の設定言語が日本語ならjp、それ以外はen
    return PlatformDispatcher.instance.locale.languageCode == 'ja'
        ? 'jp'
        : 'en';
  }

  Future<void> setLanguage(String lang) => _prefs.setString(_keyLanguage, lang);

  bool get bgmOn => _getBool(_keyBgmOn) ?? SettingsDefaults.bgmOn;

  Future<void> setBgmOn(bool value) => _prefs.setBool(_keyBgmOn, value);

  bool get seOn => _getBool(_keySeOn) ?? SettingsDefaults.seOn;

  Future<void> setSeOn(bool value) => _prefs.setBool(_keySeOn, value);

  TwoPlayerTimeLimit get twoPlayerTimeLimit {
    final saved = _getString(_keyTwoPlayerTimeLimit);
    if (saved == null) return SettingsDefaults.twoPlayerTimeLimit;
    return TwoPlayerTimeLimit.values.firstWhere(
      (e) => e.name == saved,
      orElse: () => SettingsDefaults.twoPlayerTimeLimit,
    );
  }

  Future<void> setTwoPlayerTimeLimit(TwoPlayerTimeLimit value) => _prefs.setString(_keyTwoPlayerTimeLimit, value.name);

  bool get starTwoPlayer => _getBool(_keyStarTwoPlayer) ?? SettingsDefaults.starTwoPlayer;

  Future<void> setStarTwoPlayer(bool value) => _prefs.setBool(_keyStarTwoPlayer, value);

  bool get starEasy => _getBool(_keyStarEasy) ?? SettingsDefaults.starEasy;

  Future<void> setStarEasy(bool value) => _prefs.setBool(_keyStarEasy, value);

  bool get starNormal => _getBool(_keyStarNormal) ?? SettingsDefaults.starNormal;

  Future<void> setStarNormal(bool value) => _prefs.setBool(_keyStarNormal, value);

  bool get starHard => _getBool(_keyStarHard) ?? SettingsDefaults.starHard;

  Future<void> setStarHard(bool value) => _prefs.setBool(_keyStarHard, value);
}
