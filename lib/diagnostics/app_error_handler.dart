import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import 'app_runtime_policy.dart';
import 'release_recovery_overlay.dart';
import 'test_error_logger.dart';

/// 例外の発生元。送信先で絞り込めるよう、記録時に必ず付ける。
enum ErrorSource {
  /// build・layout・paintなど、Flutterフレームワーク内の未処理例外
  flutter,

  /// 非同期処理など、ルートIsolateで未処理になった例外
  platform,

  /// ホーム画面表示前の起動準備
  startup,

  /// BGM・効果音
  audio,

  /// 設定の読込・保存
  settings,

  /// CPU思考・対局進行
  gameplay,

  /// 画面素材の読込・デコード
  assets,
}

// インスタンス化も継承もさせず、staticな機能をまとめる
/// アプリ内の例外の共通窓口。
///
/// - 未処理例外（想定外のバグ）は `fatal` として扱い、開発時はデバッガを止める。
/// - catch済みで回復できた例外は [recordHandled] で記録し、処理は止めない。
abstract final class AppErrorHandler {
  /// `FlutterError.onError` に渡すハンドラ。
  static void onFlutterError(FlutterErrorDetails details) {
    if (AppRuntimePolicy.showDeveloperErrorDetails) {
      FlutterError.presentError(details);
    }
    _report(
      details.exception,
      details.stack ?? StackTrace.current,
      source: ErrorSource.flutter,
      // 画像の読込失敗など、Flutterが軽微と判断したものは止めない
      fatal: !details.silent,
    );
  }

  /// `PlatformDispatcher.instance.onError` に渡すハンドラ。
  static bool onPlatformError(Object error, StackTrace stackTrace) {
    // trueを返すとエンジンは何も表示しないため、ここで出力する
    if (AppRuntimePolicy.showDeveloperErrorDetails) {
      debugPrint('Uncaught error: $error\n$stackTrace');
    }
    _report(error, stackTrace, source: ErrorSource.platform, fatal: true);
    return true;
  }

  /// catch済みで、アプリが処理を続けられる例外を記録する。
  static void recordHandled(
    Object error,
    StackTrace stackTrace, {
    required ErrorSource source,
    required String message,
  }) {
    if (AppRuntimePolicy.showDeveloperErrorDetails) {
      developer.log(
        message,
        name: source.name,
        error: error,
        stackTrace: stackTrace,
      );
    }
    _report(error, stackTrace, source: source, fatal: false);
  }

  static void _report(
    Object error,
    StackTrace stackTrace, {
    required ErrorSource source,
    required bool fatal,
  }) {
    if (AppRuntimePolicy.enableTestDiagnostics) {
      TestErrorLogger.writeSync(
        error,
        stackTrace,
        source: source.name,
        fatal: fatal,
      );
    }
    if (fatal) ReleaseRecovery.show();
    if (AppRuntimePolicy.pauseDebuggerOnError) {
      // デバッガ接続時だけ一時停止する。投げ直さないため処理の流れは変わらない。
      // debugでは復旧可能なエラーも、原因確認のためここで止める。
      developer.debugger(message: '[${source.name}] $error');
    }
  }
}
