import 'config.dart';

class Assets {
  Assets._();

  // home
  static const String _homePrefix = 'assets/home/';

  static const String backgroundRainbow = '${_homePrefix}background_rainbow.png';
  static const String settingsIcon = '${_homePrefix}settings.png';
  static const String star = '${_homePrefix}star.png';

  static String rules(Language lang) => '$_homePrefix${lang.name}/rules_${lang.name}.png';
  static String titleLogo(Language lang) => '$_homePrefix${lang.name}/title_logo_${lang.name}.png';
  static String play2(Language lang) => '$_homePrefix${lang.name}/play_2_${lang.name}.png';
  static String play1Easy(Language lang) => '$_homePrefix${lang.name}/play_1_easy_${lang.name}.png';
  static String play1Normal(Language lang) => '$_homePrefix${lang.name}/play_1_normal_${lang.name}.png';
  static String play1Hard(Language lang) => '$_homePrefix${lang.name}/play_1_hard_${lang.name}.png';

  // settings
  static const String _settingsPrefix = 'assets/settings/';

  static const String settingsBackground = '${_settingsPrefix}background_settings.png';
  static const String settingsHome = '${_settingsPrefix}settings_home.png';

  // audio
  static const String _audioPrefix = 'audio/';

  static const String bgm = '${_audioPrefix}bgm/bgm.mp3';

  static const String _sePrefix = '${_audioPrefix}se/';

  static const String seTapButton = '${_sePrefix}tap_button.mp3';
  static const String seTapHand = '${_sePrefix}tap_hand.mp3';
  static const String seWin = '${_sePrefix}win.mp3';
  static const String seTapOk = '${_sePrefix}tap_ok.mp3';
  static const String seCountdown = '${_sePrefix}countdown.mp3';
  static const String seStart = '${_sePrefix}start.mp3';
  static const String seDraw = '${_sePrefix}draw.mp3';
  static const String seLose = '${_sePrefix}lose.mp3';
}
