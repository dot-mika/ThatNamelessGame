import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

import '../settings/settings_state.dart';
import 'config.dart';

/// アセットパスを1か所に集約し、画面側へ文字列を散らさないための定義。
class Assets {
  Assets._();

  static const backgroundRainbow = 'assets/home/home_background.png';
  static const settingsIcon = 'assets/home/home_settings.png';
  static const starClear = 'assets/home/home_star_clear.png';
  static const starBlue = 'assets/home/home_star_blue.png';
  static const starYellow = 'assets/home/home_star_yellow.png';
  static const settingsBackground = 'assets/settings/background_settings.png';
  static const settingsHome = 'assets/settings/settings_home.png';
  static const rulesHome = 'assets/rules/buttons/rules_home.png';
  static const rulePageNumbers = [1, 2, 3, 4, 5, 6, 7, 8, 9];

  static String rulesPage(int page, AppLanguage language) {
    assert(rulePageNumbers.contains(page));
    final extension = page >= 3 && page <= 6 ? '.gif' : '.png';
    return 'assets/rules/${language.name}/rules_${page}_${language.name}$extension';
  }
  static String playBackground(
    bool near, {
    bool easy = false,
    String soloColor = 'F2D087',
  }) =>
      'assets/play/backgrounds/play_background_${easy ? (near ? soloColor : 'CCCCCC') : (near ? 'F59DBC' : 'C297C8')}.png';
  static String hand(int value, bool selected) =>
      'assets/play/hands/hand_$value${selected && value != 0 ? '_selected' : ''}.png';
  static String countdown(int value) =>
      'assets/play/start/start_${value == 0 ? 'start' : value}.png';
  static String playLabel(String name, AppLanguage language) =>
      'assets/play/labels/${language.name}/${name}_${language.name}.png';
  static String judge(String name, AppLanguage language) =>
      'assets/play/judge/${language.name}/${name}_${language.name}.png';

  /// 事前読み込みと画面表示で同じ解像度・キャッシュキーを使う。
  static ImageProvider image(String asset, {AssetBundle? bundle}) {
    final provider = AssetImage(asset, bundle: bundle);
    if (asset == backgroundRainbow ||
        asset == settingsBackground ||
        asset.startsWith('assets/play/backgrounds/')) {
      return ResizeImage.resizeIfNeeded(
        AppConfig.canvasWidth.toInt(),
        AppConfig.canvasHeight.toInt(),
        provider,
      );
    }
    return provider;
  }

  static String _languageCode(AppLanguage language) => language.name;
  static String titleLogo(AppLanguage language) {
    final code = _languageCode(language);
    return 'assets/home/$code/home_logo_$code.png';
  }

  static String rules(AppLanguage language) {
    final code = _languageCode(language);
    return 'assets/home/$code/home_rules_$code.png';
  }

  static String playTwo(AppLanguage language) {
    final code = _languageCode(language);
    return 'assets/home/$code/home_play2_$code.png';
  }

  static String playEasy(AppLanguage language) {
    final code = _languageCode(language);
    return 'assets/home/$code/home_play1easy_$code.png';
  }

  static String playNormal(AppLanguage language) {
    final code = _languageCode(language);
    return 'assets/home/$code/home_play1normal_$code.png';
  }

  static String playHard(AppLanguage language) {
    final code = _languageCode(language);
    return 'assets/home/$code/home_play1hard_$code.png';
  }

  // AssetSource uses paths relative to the Flutter assets directory.
  static const bgm = 'audio/bgm/bgm.mp3';
  static const seTapButton = 'audio/se/tap_button.mp3';
  static const seTapHand = 'audio/se/tap_hand.mp3';
  static const seWin = 'audio/se/win.mp3';
  static const seTapOk = 'audio/se/tap_ok.mp3';
  static const seCountdown = 'audio/se/countdown.mp3';
  static const seStart = 'audio/se/start.mp3';
  static const seDraw = 'audio/se/draw.mp3';
  static const seLose = 'audio/se/lose.mp3';
}
