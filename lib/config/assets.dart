class Assets {
  Assets._();

  // ── home ──────────────────────────────────────────
  static const String backgroundRainbow = 'assets/home/background_rainbow.png';
  static const String settingsIcon = 'assets/home/settings.png';
  static const String star = 'assets/home/star.png';

  static String rules(String lang) => 'assets/home/$lang/rules_$lang.png';
  static String titleLogo(String lang) =>
      'assets/home/$lang/title_logo_$lang.png';
  static String play2(String lang) => 'assets/home/$lang/play_2_$lang.png';
  static String play1Easy(String lang) =>
      'assets/home/$lang/play_1_easy_$lang.png';
  static String play1Normal(String lang) =>
      'assets/home/$lang/play_1_normal_$lang.png';
  static String play1Hard(String lang) =>
      'assets/home/$lang/play_1_hard_$lang.png';

  // ── settings ──────────────────────────────────────
  static const String settingsBackground =
      'assets/settings/background_settings.png';
  static const String settingsHome = 'assets/settings/settings_home.png';

  // ── audio ─────────────────────────────────────────
  static const String bgm = 'audio/bgm/bgm.mp3';

  static const String _sePrefix = 'audio/se/';

  static const String seTapButton = '${_sePrefix}tap_button.mp3';
  static const String seTapHand = '${_sePrefix}tap_hand.mp3';
  static const String seWin = '${_sePrefix}win.mp3';
  static const String seTapOk = '${_sePrefix}tap_ok.mp3';
  static const String seCountdown = '${_sePrefix}countdown.mp3';
  static const String seStart = '${_sePrefix}start.mp3';
  static const String seDraw = '${_sePrefix}draw.mp3';
  static const String seLose = '${_sePrefix}lose.mp3';
}
