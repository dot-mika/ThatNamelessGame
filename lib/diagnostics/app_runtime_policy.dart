import 'package:flutter/foundation.dart';

/// アプリを動かしているビルド種別。
enum AppBuildMode { debug, profile, release }

/// ビルド種別とテスト診断の方針を一箇所に集約する。
///
/// 個別機能の復旧処理はこの値を参照しない。ここで扱うのは、
/// 開発者向けの観測とリリース時の表示方針だけ。
abstract final class AppRuntimePolicy {
  static const buildMode = kReleaseMode
      ? AppBuildMode.release
      : kProfileMode
      ? AppBuildMode.profile
      : AppBuildMode.debug;

  static const isRelease = buildMode == AppBuildMode.release;

  /// `--dart-define=TEST_ERROR_LOG=true` 指定時だけ、debugで有効にする。
  /// release/profileでは指定されても必ず無効。
  static const enableTestDiagnostics =
      buildMode == AppBuildMode.debug &&
      bool.fromEnvironment('TEST_ERROR_LOG');

  static const showDeveloperErrorDetails = buildMode == AppBuildMode.debug;
  static const pauseDebuggerOnError = buildMode == AppBuildMode.debug;

  /// リリースでは詳細を出さず、安全な復帰UIだけを出すための方針。
  static const showReleaseRecoveryUi = isRelease;
}
