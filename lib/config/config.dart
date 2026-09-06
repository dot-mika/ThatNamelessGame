import 'dart:ui';

import '../settings/app_settings.dart';

/// アプリ共通の色。配色の変更はここで行う。
abstract final class AppColors {
  static const settingsBlack = Color(0xFF7F7F7F);
  static const white = Color(0xFFFFFFFF);
}

class AppConfig {
  AppConfig._();

  static const canvasWidth = 1280.0;
  static const canvasHeight = 720.0;
  static const bgmVolume = 0.5;
  static const tapCooldown = Duration(milliseconds: 500);
}

class AppStrings {
  AppStrings._();

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
}
