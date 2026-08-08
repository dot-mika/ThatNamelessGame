import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/config.dart';
import 'app_logger.dart';

class SettingsRepository {
  static const _keyLanguage = 'language';
  static const _keyBgmOn = 'bgmOn';
  static const _keySeOn = 'seOn';
  static const _keyTwoPlayerTimeLimit = 'twoPlayerTimeLimit';
  static const _keyStarTwoPlayer = 'starTwoPlayer';
  static const _keyStarEasy = 'starEasy';
  static const _keyStarNormal = 'starNormal';
  static const _keyStarHard = 'starHard';

  final SharedPreferences _prefs;
  SettingsRepository._(this._prefs);
  // これが「_」コンストラクタの定義。展開すると
  // SettingsRepository._(SharedPreferences prefs) {
  // this._prefs = prefs;
  // }

  static Future<SettingsRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsRepository._(prefs);
    // ここで「_」コンストラクタを呼び出し
  }

  Language get language {
    final saved = _prefs.getString(_keyLanguage);
    if (saved != null) {
      try {
        return Language.values.byName(saved);
      } catch (e) {
        appLogger.e('[ERROR] Invalid saved language "$saved"', error: e);
      }
    }
    // 初回起動 or 不正値: 端末の設定言語が日本語ならjp、それ以外はen
    return PlatformDispatcher.instance.locale.languageCode == 'ja'
        ? Language.jp
        : Language.en;
  }

  Future<void> setLanguage(Language lang) => _prefs.setString(_keyLanguage, lang.name);

  bool get bgmOn => _prefs.getBool(_keyBgmOn) ?? SettingsDefaults.bgmOn;

  Future<void> setBgmOn(bool value) => _prefs.setBool(_keyBgmOn, value);

  bool get seOn => _prefs.getBool(_keySeOn) ?? SettingsDefaults.seOn;

  Future<void> setSeOn(bool value) => _prefs.setBool(_keySeOn, value);

  TwoPlayerTimeLimit get twoPlayerTimeLimit {
    final saved = _prefs.getString(_keyTwoPlayerTimeLimit);
    if (saved != null) {
      try {
        return TwoPlayerTimeLimit.values.byName(saved);
      } catch (e) {
        appLogger.w('Invalid saved twoPlayerTimeLimit "$saved", falling back to default', error: e);
      }
    }
    return SettingsDefaults.twoPlayerTimeLimit;
  }

  Future<void> setTwoPlayerTimeLimit(TwoPlayerTimeLimit value) => _prefs.setString(_keyTwoPlayerTimeLimit, value.name);

  bool get starTwoPlayer => _prefs.getBool(_keyStarTwoPlayer) ?? SettingsDefaults.starTwoPlayer;

  Future<void> setStarTwoPlayer(bool value) => _prefs.setBool(_keyStarTwoPlayer, value);

  bool get starEasy => _prefs.getBool(_keyStarEasy) ?? SettingsDefaults.starEasy;

  Future<void> setStarEasy(bool value) => _prefs.setBool(_keyStarEasy, value);

  bool get starNormal => _prefs.getBool(_keyStarNormal) ?? SettingsDefaults.starNormal;

  Future<void> setStarNormal(bool value) => _prefs.setBool(_keyStarNormal, value);

  bool get starHard => _prefs.getBool(_keyStarHard) ?? SettingsDefaults.starHard;

  Future<void> setStarHard(bool value) => _prefs.setBool(_keyStarHard, value);
}
