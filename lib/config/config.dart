import 'dart:ui';

import '../settings/settings_state.dart';
import 'assets.dart';

/// アプリ共通の色。配色の変更はここで行う。
/// Figmaと対応するアプリ共通色。
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
class AppConfig {
  AppConfig._();

  static const canvasWidth = 1280.0;
  static const canvasHeight = 720.0;
  static const bgmVolume = 0.5;
  static const tapCooldown = Duration(milliseconds: 500);
}

/// 言語に応じて画面文言を返す簡易ローカライズ窓口。
class AppStrings {
  AppStrings._();
  static String confirm(AppLanguage language) =>
      language == AppLanguage.jp ? 'けってい' : 'OK';
  static String exitQuestion(AppLanguage language) => language == AppLanguage.jp
      ? '本当にゲームを終わりますか？'
      : 'Are you sure you want to quit the game?';
  static String yes(AppLanguage language) =>
      language == AppLanguage.jp ? 'はい' : 'Yes';
  static String no(AppLanguage language) =>
      language == AppLanguage.jp ? 'いいえ' : 'No';
  static String playAgain(AppLanguage language) =>
      language == AppLanguage.jp ? 'もう一度プレイ' : 'Play again';

  static String settingsTitle(AppLanguage language) =>
      language == AppLanguage.jp ? '設定' : 'Settings';
  static String timeLimit(AppLanguage language) => language == AppLanguage.jp
      ? '☆ 2人プレイの時間制限'
      : '☆ Time limit for 2 player mode';
  static String soundEffects(AppLanguage language) =>
      language == AppLanguage.jp ? '☆ 効果音のON/OFF' : '☆ Sound Effects ON/OFF';
  static String bgm(AppLanguage language) =>
      language == AppLanguage.jp ? '☆ BGMのON/OFF' : '☆ BGM ON/OFF';
  static String language(AppLanguage language) =>
      language == AppLanguage.jp ? '☆ 言語' : '☆ Language';
  static String unlimited(AppLanguage language) =>
      language == AppLanguage.jp ? '無制限' : 'Unlimited';
  static String home(AppLanguage language) =>
      language == AppLanguage.jp ? 'ホーム' : 'Home';
  static String rules(AppLanguage language) =>
      language == AppLanguage.jp ? 'ルール' : 'Rules';
  static String playTwo(AppLanguage language) =>
      language == AppLanguage.jp ? '2人対戦' : '2 players';
  static String playEasy(AppLanguage language) =>
      language == AppLanguage.jp ? 'かんたん' : 'Easy';
  static String playNormal(AppLanguage language) =>
      language == AppLanguage.jp ? 'ふつう' : 'Normal';
  static String playHard(AppLanguage language) =>
      language == AppLanguage.jp ? 'むずかしい' : 'Hard';
  static String retry(AppLanguage language) =>
      language == AppLanguage.jp ? '再試行' : 'Retry';
  static String previousPage(AppLanguage language) =>
      language == AppLanguage.jp ? '前のページ' : 'Previous page';
  static String nextPage(AppLanguage language) =>
      language == AppLanguage.jp ? '次のページ' : 'Next page';
}

enum SoundEffect {
  tapButton(Assets.seTapButton),
  tapHand(Assets.seTapHand),
  win(Assets.seWin),
  tapOk(Assets.seTapOk),
  countdown(Assets.seCountdown),
  start(Assets.seStart),
  draw(Assets.seDraw),
  lose(Assets.seLose);

  const SoundEffect(this.asset);
  final String asset;
}
