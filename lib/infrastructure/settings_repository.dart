import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/config.dart';

/// SharedPreferences のラッパー。永続化するキーは8個(仕様書「ゲーム全体を通して」)。
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

  String get language {
    final saved = _prefs.getString(_keyLanguage);
    if (saved != null) return saved;
    // 初回起動: 端末の設定言語が日本語ならjp、それ以外はen
    return PlatformDispatcher.instance.locale.languageCode == 'ja'
        ? 'jp'
        : 'en';
  }

  Future<void> setLanguage(String lang) => _prefs.setString(_keyLanguage, lang);

  bool get bgmOn => _prefs.getBool(_keyBgmOn) ?? true;

  Future<void> setBgmOn(bool value) => _prefs.setBool(_keyBgmOn, value);

  bool get seOn => _prefs.getBool(_keySeOn) ?? true;

  Future<void> setSeOn(bool value) => _prefs.setBool(_keySeOn, value);

  TwoPlayerTimeLimit get twoPlayerTimeLimit {
    final saved = _prefs.getString(_keyTwoPlayerTimeLimit);
    if (saved == null) return TwoPlayerTimeLimit.defaultValue;
    return TwoPlayerTimeLimit.values.byName(saved);
  }

  Future<void> setTwoPlayerTimeLimit(TwoPlayerTimeLimit value) =>
      _prefs.setString(_keyTwoPlayerTimeLimit, value.name);

  bool get starTwoPlayer => _prefs.getBool(_keyStarTwoPlayer) ?? false;

  Future<void> setStarTwoPlayer(bool value) =>
      _prefs.setBool(_keyStarTwoPlayer, value);

  bool get starEasy => _prefs.getBool(_keyStarEasy) ?? false;

  Future<void> setStarEasy(bool value) => _prefs.setBool(_keyStarEasy, value);

  bool get starNormal => _prefs.getBool(_keyStarNormal) ?? false;

  Future<void> setStarNormal(bool value) =>
      _prefs.setBool(_keyStarNormal, value);

  bool get starHard => _prefs.getBool(_keyStarHard) ?? false;

  Future<void> setStarHard(bool value) => _prefs.setBool(_keyStarHard, value);
}
