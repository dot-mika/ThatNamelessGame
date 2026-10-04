import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

import 'app_language.dart';
import 'config.dart';

/// アセットパスを1か所に集約し、画面側へ文字列を散らさないための定義
abstract final class Assets {
  static const backgroundRainbow = 'assets/home/home_background.png';
  static const settingsIcon = 'assets/home/home_settings.png';
  static const starClear = 'assets/home/home_star_clear.png';
  static const starBlue = 'assets/home/home_star_blue.png';
  static const starYellow = 'assets/home/home_star_yellow.png';
  static const settingsBackground = 'assets/settings/background_settings.png';
  static const settingsHome = 'assets/settings/settings_home.png';
  static const rulesHome = 'assets/rules/buttons/rules_home.png';
  static const rulesBackPage = 'assets/rules/buttons/rules_back_page.png';
  static const rulesNextPage = 'assets/rules/buttons/rules_next_page.png';
  static const rulePageNumbers = [1, 2, 3, 4, 5, 6, 7, 8, 9];

  /// 起動時に先読みする画面画像のディレクトリ
  static const screenImageDirectories = [
    'assets/home/',
    'assets/settings/',
    'assets/play/',
    'assets/rules/',
  ];

  static String rulesPage(int page, AppLanguage language) {
    assert(rulePageNumbers.contains(page));
    final extension = page >= 3 && page <= 6 ? '.gif' : '.png';
    return 'assets/rules/${language.name}/rules_${page}_${language.name}$extension';
  }

  /// 対局背景はファイル名に手番側の色コード（RRGGBB）を持つ
  static String playBackground(Color color) {
    final rgb = (color.toARGB32() & 0xFFFFFF)
        .toRadixString(16)
        .padLeft(6, '0')
        .toUpperCase();
    return 'assets/play/backgrounds/play_background_$rgb.png';
  }

  static String hand(int value, bool selected) =>
      'assets/play/hands/hand_$value${selected && value != 0 ? '_selected' : ''}.png';
  static String countdown(int value) =>
      'assets/play/start/start_${value == 0 ? 'start' : value}.png';
  static String playLabel(String name, AppLanguage language) =>
      'assets/play/labels/${language.name}/${name}_${language.name}.png';
  static String judge(String name, AppLanguage language) =>
      'assets/play/judge/${language.name}/${name}_${language.name}.png';

  /// 事前読み込みと画面表示で同じ解像度・キャッシュキーを使う
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

  /// ホーム画面の言語別画像
  static String _home(String name, AppLanguage language) =>
      'assets/home/${language.name}/home_${name}_${language.name}.png';
  static String titleLogo(AppLanguage language) => _home('logo', language);
  static String rules(AppLanguage language) => _home('rules', language);
  static String playTwo(AppLanguage language) => _home('play2', language);
  static String playEasy(AppLanguage language) => _home('play1easy', language);
  static String playNormal(AppLanguage language) =>
      _home('play1normal', language);
  static String playHard(AppLanguage language) => _home('play1hard', language);

  // AssetSourceにはFlutterのassetsディレクトリからの相対パスを渡す
  // 効果音のパスもこのクラスに集約する
  static const bgm = 'audio/bgm/bgm.mp3';
  static const seTapButton = 'audio/se/tap_button.mp3';
  static const seTapHand = 'audio/se/tap_hand.mp3';
  static const seWin = 'audio/se/win.mp3';
  static const seTapOk = 'audio/se/tap_ok.mp3';
  static const seCountdown = 'audio/se/countdown.mp3';
  static const seStart = 'audio/se/start.mp3';
  static const seDraw = 'audio/se/draw.mp3';
  static const seLose = 'audio/se/lose.mp3';

  /// 指定した効果音の、Flutter assets ディレクトリからの相対パス
  static String soundEffect(SoundEffect effect) => switch (effect) {
    SoundEffect.tapButton => seTapButton,
    SoundEffect.tapHand => seTapHand,
    SoundEffect.win => seWin,
    SoundEffect.tapOk => seTapOk,
    SoundEffect.countdown => seCountdown,
    SoundEffect.start => seStart,
    SoundEffect.draw => seDraw,
    SoundEffect.lose => seLose,
  };
}
