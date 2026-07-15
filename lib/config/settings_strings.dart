/// 設定画面で描画するテキストの JP/EN 辞書(素材が png ではない文言のみ)。
class SettingsStrings {
  SettingsStrings._();

  static const String on = 'ON';
  static const String off = 'OFF';
  static const String japanese = '日本語';
  static const String english = 'English';

  static const Map<String, Map<String, String>> _dict = {
    'settingsTitle': {'jp': '設定', 'en': 'Settings'},
    'twoPlayerTimeLimit': {'jp': '2人プレイの時間制限', 'en': 'Time limit for 2 player mode'},
    'seOnOff': {'jp': '効果音のON/OFF', 'en': 'Sound Effects ON/OFF'},
    'bgmOnOff': {'jp': 'BGMのON/OFF', 'en': 'BGM ON/OFF'},
    'language': {'jp': '言語', 'en': 'Language'},
    'unlimited': {'jp': '無制限', 'en': 'Unlimited'},
  };

  static String of(String key, String lang) => _dict[key]![lang]!;
}
