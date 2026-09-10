import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

import '../settings/settings_state.dart';
import 'config.dart';

class Assets {
  Assets._();

  static const backgroundRainbow = 'assets/home/background_rainbow.png';
  static const settingsIcon = 'assets/home/settings.png';
  static const star = 'assets/home/star.png';
  static const exitFrame = 'assets/play/pop/pop_frame.png';
  static String exitDialog(String name, AppLanguage language) =>
      'assets/play/pop/${language.name}/pop_${name}_${language.name}.png';
  static const settingsBackground = 'assets/settings/background_settings.png';
  static const settingsHome = 'assets/settings/settings_home.png';
  static String playBackground(bool near) =>
      'assets/play/backgrounds/background_${near ? 'F59DBC' : 'C297C8'}.png';
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
    return 'assets/home/$code/title_logo_$code.png';
  }

  static String rules(AppLanguage language) {
    final code = _languageCode(language);
    return 'assets/home/$code/rules_$code.png';
  }

  static String playTwo(AppLanguage language) {
    final code = _languageCode(language);
    return 'assets/home/$code/play_2_$code.png';
  }

  static String playEasy(AppLanguage language) {
    final code = _languageCode(language);
    return 'assets/home/$code/play_1_easy_$code.png';
  }

  static String playNormal(AppLanguage language) {
    final code = _languageCode(language);
    return 'assets/home/$code/play_1_normal_$code.png';
  }

  static String playHard(AppLanguage language) {
    final code = _languageCode(language);
    return 'assets/home/$code/play_1_hard_$code.png';
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
