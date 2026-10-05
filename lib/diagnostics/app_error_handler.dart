import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import 'app_runtime_policy.dart';
import 'release_recovery_overlay.dart';
import 'test_error_logger.dart';

/// 例外の発生元送信先で絞り込めるよう、記録時に必ず付ける
enum ErrorSource {
  flutter,  // build・layout・paintなど、Flutterフレームワーク内の未処理例外
  platform, // 非同期処理など、ルートIsolateで未処理になった例外
  startup,  // ホーム画面表示前の起動準備
  audio,    // BGM・効果音
  settings, // 設定の読込・保存
  gameplay, // CPU思考・対局進行
  assets,   // 画面素材の読込・デコード
}

/// アプリ内の例外の共通窓口
abstract final class AppErrorHandler {
  /// `FlutterError.onError` に渡すハンドラ
  static void onFlutterError(FlutterErrorDetails details) {
  
    /// degugでのビルドのみ、FlutterErrorDetails の内容を開発者向けに表示する
    if (AppRuntimePolicy.showDeveloperErrorDetails) {
      FlutterError.presentError(details);
    }
    
    /// 例外を記録し、debugでのビルドの際はそこで実行を一時停止する
    _report(
      details.exception,
      details.stack ?? StackTrace.current,
      source: ErrorSource.flutter,
      fatal: !details.silent,
    );
  }

  /// `PlatformDispatcher.instance.onError` に渡すハンドラ
  static bool onPlatformError(Object error, StackTrace stackTrace) {
    // trueを返すとエンジンは何も表示しないため、ここで出力する
    if (AppRuntimePolicy.showDeveloperErrorDetails) {
      debugPrint('Uncaught error: $error\n$stackTrace');
    }
    _report(error, stackTrace, source: ErrorSource.platform, fatal: true);
    return true;
  }

  /// catch済みで、アプリが処理を続けられる例外を記録する
  static void recordHandled(
    Object error,
    StackTrace stackTrace, {
    required ErrorSource source,
    required String message,
  }) {
  
    // エラー詳細を表示する
    if (AppRuntimePolicy.showDeveloperErrorDetails) {
      developer.log(
        message,
        name: source.name,
        error: error,
        stackTrace: stackTrace,
      );
    }
    
    /// 例外を記録し、debugでのビルドの際はそこで実行を一時停止する
    _report(error, stackTrace, source: source, fatal: false);
  }

  /// catch済みで、アプリが処理を続けられる例外を記録する
  /// debugでのビルドの際はそこで実行を一時停止する
  static void _report(
    Object error, // 何のエラーか
    StackTrace stackTrace, { // どこを通ってエラーが起きたか
    required ErrorSource source, // どこ経由のエラーか
    required bool fatal, // 致命的なエラーか否か
  }) {
    // `--dart-define=TEST_ERROR_LOG=true` 指定時だけエラーをファイルに書き込む
    if (AppRuntimePolicy.enableTestDiagnostics) {
      TestErrorLogger.writeSync(
        error,
        stackTrace,
        source: source.name,
        fatal: fatal,
      );
    }
    
    // リリースで復旧不能な例外が起きたことをアプリ全体へ通知する
    if (fatal) ReleaseRecovery.show();
    
    // デバッガーが接続されている場合、そこで実行を一時停止する
    if (AppRuntimePolicy.pauseDebuggerOnError) {
      developer.debugger(message: '[${source.name}] $error');
    }
  }
}
