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

  /// ボタンを押した瞬間を表す集中線（rules_3、rules_9）
  static const rulesSyuchusen = 'assets/rules/syuchusenn.png';
  static const rulePageNumbers = [1, 2, 3, 4, 5, 6, 7, 8, 9];

  /// 画像ではなくコードで描くルールページ（3〜6はアニメーション）
  static const codeRulePageNumbers = [2, 3, 4, 5, 6, 7, 8, 9];

  /// 起動時に先読みする画面画像のディレクトリ
  static const screenImageDirectories = [
    'assets/home/',
    'assets/settings/',
    'assets/play/',
    'assets/rules/',
  ];

  static String rulesPage(int page, AppLanguage language) {
    assert(
      rulePageNumbers.contains(page) && !codeRulePageNumbers.contains(page),
    );
    return 'assets/rules/rules_${page}_${language.name}.png';
  }

  /// 対局背景はファイル名に手番側の色名（green、blueなど）を持つ
  static String playBackground(Color color) =>
      'assets/play/backgrounds/play_background_${_colorName(color)}.png';

  /// ルール画面の背景　対局背景にない赤だけルール画面用の画像を使う
  static String ruleBackground(Color color) => color == AppColors.red
      ? 'assets/rules/background_red.png'
      : playBackground(color);

  /// AppColorsの基本の色を、背景画像のファイル名に使う色名へ変換する
  static String _colorName(Color color) {
    const names = {
      'green': AppColors.green,
      'blue': AppColors.blue,
      'purple': AppColors.purple,
      'pink': AppColors.pink,
      'yellow': AppColors.yellow,
      'gray': AppColors.gray,
    };
    for (final MapEntry(:key, :value) in names.entries) {
      if (value == color) return key;
    }
    throw ArgumentError.value(color, 'color', 'No background image for color');
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
        asset.startsWith('assets/play/backgrounds/') ||
        asset.startsWith('assets/rules/background_')) {
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
  static const seCountdown = 'audio/se/countdown_start.mp3';
  static const seDraw = 'audio/se/draw.mp3';
  static const seLose = 'audio/se/lose.mp3';

  /// 指定した効果音の、Flutter assets ディレクトリからの相対パス
  static String soundEffect(SoundEffect effect) => switch (effect) {
    SoundEffect.tapButton => seTapButton,
    SoundEffect.tapHand => seTapHand,
    SoundEffect.win => seWin,
    SoundEffect.tapOk => seTapOk,
    SoundEffect.countdown => seCountdown,
    SoundEffect.draw => seDraw,
    SoundEffect.lose => seLose,
  };
}
