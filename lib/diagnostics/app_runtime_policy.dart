import 'package:flutter/foundation.dart';

/// アプリを動かしているビルド種別
enum AppBuildMode { debug, profile, release }

/// ビルド種別とテスト診断の方針を一箇所に集約する
/// 個別機能の復旧処理はこの値を参照しないここで扱うのは、
/// 開発者向けの観測とリリース時の表示方針だけ
abstract final class AppRuntimePolicy {
  static const buildMode = kReleaseMode
      ? AppBuildMode.release
      : kProfileMode
      ? AppBuildMode.profile
      : AppBuildMode.debug;

  static const isRelease = buildMode == AppBuildMode.release;

  /// `--dart-define=TEST_ERROR_LOG=true` 指定時だけ、debugでログ収集を有効にする
  static const enableTestDiagnostics =
      buildMode == AppBuildMode.debug &&
      bool.fromEnvironment('TEST_ERROR_LOG');

  /// テスト実行時にログへ付ける項目名指定しない場合は全項目を対象とする
  static const testItem = String.fromEnvironment(
    'TEST_ITEM',
    defaultValue: 'all',
  );

  /// エラー詳細を表示するかどうか
  static const showDeveloperErrorDetails = buildMode == AppBuildMode.debug;
  
  /// エラー時にデバッガを停止するかどうか
  static const pauseDebuggerOnError = buildMode == AppBuildMode.debug;

  /// リリースでは詳細を出さず、安全な復帰UIだけを出すための方針
  static const showReleaseRecoveryUi = isRelease;
}
