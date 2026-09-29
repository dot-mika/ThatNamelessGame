import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import 'test_error_logger.dart';

/// テスト配布ビルドで、例外を端末内のファイルへ記録するかどうか。
/// 開発中に限り、`--dart-define=TEST_ERROR_LOG=true` で端末内ログを有効にする。
///
/// リリースビルドではフラグの指定有無にかかわらず常に無効。
const enableTestErrorLog =
    kDebugMode && bool.fromEnvironment('TEST_ERROR_LOG');

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
}

// インスタンス化も継承もさせず、staticな機能をまとめる
/// アプリ内の例外の共通窓口。
///
/// - 未処理例外（想定外のバグ）は `fatal` として扱い、開発時はデバッガを止める。
/// - catch済みで回復できた例外は [recordHandled] で記録し、処理は止めない。
abstract final class AppErrorHandler {
  /// `FlutterError.onError` に渡すハンドラ。
  static void onFlutterError(FlutterErrorDetails details) {
    FlutterError.presentError(details);
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
    debugPrint('Uncaught error: $error\n$stackTrace');
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
    developer.log(
      message,
      name: source.name,
      error: error,
      stackTrace: stackTrace,
    );
    _report(error, stackTrace, source: source, fatal: false);
  }

  static void _report(
    Object error,
    StackTrace stackTrace, {
    required ErrorSource source,
    required bool fatal,
  }) {
    if (enableTestErrorLog) {
      TestErrorLogger.writeSync(
        error,
        stackTrace,
        source: source.name,
        fatal: fatal,
      );
    }

    // TODO: リリース後の追跡ツールが決まったら、kReleaseModeでここから送信する

    if (kDebugMode && fatal) {
      // デバッガ接続時だけ一時停止する。投げ直さないため処理の流れは変わらない
      developer.debugger(message: '[${source.name}] $error');
    }
  }
}
