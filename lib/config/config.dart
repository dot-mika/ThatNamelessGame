import 'dart:ui';

import 'app_language.dart';

/// アプリ共通の色。配色の変更はここで行う。
abstract final class AppColors {
  static const easyPlayer = Color(0xFFF2D087);
  static const normalPlayer = Color(0xFF8BCD7D);
  static const hardPlayer = Color(0xFF81BFE0);
  static const nearPlayer = Color(0xFFF59DBC);
  static const farPlayer = Color(0xFFC297C8);
  static const disabled = Color(0xFFCCCCCC);
  static const settingsBlack = Color(0xFF7F7F7F);
  static const white = Color(0xFFFFFFFF);
}

/// 画面サイズや音量など、アプリ全体で共有する数値設定。
abstract final class AppConfig {

  static const canvasWidth = 1280.0;
  static const canvasHeight = 720.0;
  static const bgmVolume = 0.5;
  static const tapCooldown = Duration(milliseconds: 500);
}

/// 言語に応じて画面文言を返す簡易ローカライズ窓口。
abstract final class AppStrings {
  /// 日本語と英語の文言から、指定言語の方を返す。
  static String _pick(AppLanguage language, String jp, String en) =>
      language == AppLanguage.jp ? jp : en;

  // 対局画面
  static String confirm(AppLanguage l) => _pick(l, 'けってい', 'OK');
  static String exitQuestion(AppLanguage l) =>
      _pick(l, '本当にゲームを終わりますか？', 'Are you sure you want to quit the game?');
  static String exitQuestionDisplay(AppLanguage l) =>
      _pick(l, '本当にゲームを\n終わりますか？', 'Are you sure you want\nto quit the game?');
  static String yes(AppLanguage l) => _pick(l, 'はい', 'Yes');
  static String no(AppLanguage l) => _pick(l, 'いいえ', 'No');
  static String playAgain(AppLanguage l) => _pick(l, 'もう一度プレイ', 'Play again');
  static String nearSide(AppLanguage l) => _pick(l, '手前', 'Near');
  static String farSide(AppLanguage l) => _pick(l, '奥', 'Far');

  // 設定画面
  static String settingsTitle(AppLanguage l) => _pick(l, '設定', 'Settings');
  static String timeLimit(AppLanguage l) =>
      _pick(l, '☆ 2人プレイの時間制限', '☆ Time limit for 2 player mode');
  static String soundEffects(AppLanguage l) =>
      _pick(l, '☆ 効果音のON/OFF', '☆ Sound Effects ON/OFF');
  static String bgm(AppLanguage l) => _pick(l, '☆ BGMのON/OFF', '☆ BGM ON/OFF');
  static String language(AppLanguage l) => _pick(l, '☆ 言語', '☆ Language');
  static String unlimited(AppLanguage l) => _pick(l, '無制限', 'Unlimited');

  // ホーム・ルール・起動画面
  static String home(AppLanguage l) => _pick(l, 'ホーム', 'Home');
  static String rules(AppLanguage l) => _pick(l, 'ルール', 'Rules');
  static String playTwo(AppLanguage l) => _pick(l, '2人対戦', '2 players');
  static String playEasy(AppLanguage l) => _pick(l, 'かんたん', 'Easy');
  static String playNormal(AppLanguage l) => _pick(l, 'ふつう', 'Normal');
  static String playHard(AppLanguage l) => _pick(l, 'むずかしい', 'Hard');
  static String retry(AppLanguage l) => _pick(l, '再試行', 'Retry');
  static String previousPage(AppLanguage l) =>
      _pick(l, '前のページ', 'Previous page');
  static String nextPage(AppLanguage l) => _pick(l, '次のページ', 'Next page');
}

/// 効果音と、そのアセットパス（assetsディレクトリからの相対パス）。
enum SoundEffect {
  tapButton('audio/se/tap_button.mp3'),
  tapHand('audio/se/tap_hand.mp3'),
  win('audio/se/win.mp3'),
  tapOk('audio/se/tap_ok.mp3'),
  countdown('audio/se/countdown.mp3'),
  start('audio/se/start.mp3'),
  draw('audio/se/draw.mp3'),
  lose('audio/se/lose.mp3');

  const SoundEffect(this.asset);
  final String asset;
}
