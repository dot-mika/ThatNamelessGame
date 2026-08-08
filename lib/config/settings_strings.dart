import 'config.dart';

/// 設定画面で描画するテキストの JP/EN 辞書(素材が png ではない文言のみ)。
class SettingsStrings {
  SettingsStrings._();

  static const Map<String, Map<Language, String>> _dict = {
    'settingsTitle': {Language.jp: '設定', Language.en: 'Settings'},
    'twoPlayerTimeLimit': {
      Language.jp: '☆ 2人プレイの時間制限',
      Language.en: '☆ Time limit for 2 player mode',
    },
    'seOnOff': {Language.jp: '☆ 効果音のON/OFF', Language.en: '☆ Sound Effects ON/OFF'},
    'bgmOnOff': {Language.jp: '☆ BGMのON/OFF', Language.en: '☆ BGM ON/OFF'},
    'language': {Language.jp: '☆ 言語', Language.en: '☆ Language'},
    'unlimited': {Language.jp: '無制限', Language.en: 'Unlimited'},
  };

  static const Map<String, String> _common = {
    'on': 'ON',
    'off': 'OFF',
    'japanese': '日本語',
    'english': 'English',
  };

  static String of(String key, Language lang) =>
      _dict[key]?[lang] ?? _common[key]!;
}
