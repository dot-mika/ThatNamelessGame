class Assets {
  Assets._();

  // home
  static const String _homePrefix = 'assets/home/';

  static const String backgroundRainbow = '${_homePrefix}background_rainbow.png';
  static const String settingsIcon = '${_homePrefix}settings.png';
  static const String star = '${_homePrefix}star.png';

  static String rules(String lang) => '$_homePrefix$lang/rules_$lang.png';
  static String titleLogo(String lang) => '$_homePrefix$lang/title_logo_$lang.png';
  static String play2(String lang) => '$_homePrefix$lang/play_2_$lang.png';
  static String play1Easy(String lang) => '$_homePrefix$lang/play_1_easy_$lang.png';
  static String play1Normal(String lang) => '$_homePrefix$lang/play_1_normal_$lang.png';
  static String play1Hard(String lang) => '$_homePrefix$lang/play_1_hard_$lang.png';

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
