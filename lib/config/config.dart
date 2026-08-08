import 'package:flutter/widgets.dart';

class AppConfig {
  AppConfig._();

  /// 固定キャンバスのサイズ(16:9)。これを拡大縮小して画面に適用
  static const double canvasWidth = 1280;
  static const double canvasHeight = 720;

  /// 連打対策のクールダウンタイム
  static const Duration tapCooldown = Duration(milliseconds: 500);

  /// BGM の再生音量(0.0〜1.0)。SE(常に1.0)より相対的に控えめにする
  static const double bgmVolume = 0.5;
}

class AppColors {
  AppColors._();

  // 各モードのカラーコード
  static const Color twoPlayerFront = Color(0xFFF59DBC); // ピンク
  static const Color twoPlayerBack = Color(0xFFC297C8); // パープル
  static const Color easyPlayer = Color(0xFFF2D087); // イエロー
  static const Color normalPlayer = Color(0xFF8BCD7D); // グリーン
  static const Color hardPlayer = Color(0xFF81BFE0); // ブルー
  static const Color cpu = Color(0xFFCCCCCC); // グレー(CPU共通)

  static const Color disabledButton = Color(0xFFCCCCCC);

  /// 黒のカラーコード
  static const Color blackHomeSettings = Color(0xFF7F7F7F);
  static const Color blackPlayRules = Color(0xFF666666);

  /// 白のカラーコード
  static const Color white = Color(0xFFFFFFFF);
}

enum PlayMode { twoPlayer, easy, normal, hard }

enum Language { jp, en }

enum TwoPlayerTimeLimit {
  seconds5(5),
  seconds10(10),
  seconds15(15),
  seconds20(20),
  seconds30(30),
  seconds45(45),
  seconds60(60),
  unlimited(-1);

  const TwoPlayerTimeLimit(this.seconds);

  final int seconds;
}

/// SettingsRepository の初期値をまとめて持つクラス。
class SettingsDefaults {
  SettingsDefaults._();

  static const bool bgmOn = true;
  static const bool seOn = true;
  static const TwoPlayerTimeLimit twoPlayerTimeLimit = TwoPlayerTimeLimit.seconds15;
  static const bool starTwoPlayer = false;
  static const bool starEasy = false;
  static const bool starNormal = false;
  static const bool starHard = false;

  // 1人プレイの制限時間(秒)
  static const int oneEasySeconds = 30;
  static const int oneNormalSeconds = 15;
  static const int oneHardSeconds = 5;
}
