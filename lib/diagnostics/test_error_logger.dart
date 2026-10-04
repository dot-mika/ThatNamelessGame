import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'app_runtime_policy.dart';


/// テスト実行中だけ、例外を端末のプライベート領域へ一時記録する
/// テスト終了後は `tool/run_device_test.ps1` がPC側の `log/` へ回収する
/// `writeSync` は直後にアプリが終了しても記録を残せるよう、意図的に同期書き込みする
abstract final class TestErrorLogger {
  static File? _logFile;
  static Map<String, Object?> _device = const {};

  static Future<void> initialize() async {
    try {
      // アプリ専用の保存場所をOSから取得
      final directory = await getApplicationSupportDirectory();
      
      // フォルダが存在してなかったら再帰的に作る
      await directory.create(recursive: true);
      
      // logFile作成
      final logFile = File(
        '${directory.path}${Platform.pathSeparator}'
        'test-errors-${_fileTimestamp()}.jsonl',
      );
      await logFile.create(exclusive: true);
      _logFile = logFile;
      
      // 端末情報を取って保存
      _device = await _loadDeviceInfo();
      
    } catch (error, stackTrace) {
      // 診断ログは補助機能なので、初期化に失敗してもアプリは継続する
      debugPrint('Could not initialize test error logger: $error\n$stackTrace');
    }
  }


  /// 発生したエラー情報をJSON形式にして、ログファイルへ即座に追記する
  static void writeSync(
    Object error, // 何のエラーか
    StackTrace stackTrace, { // どこを通ってエラーが起きたか
    required String source, // どこ経由のエラーか
    required bool fatal, // 致命的なエラーか否か
  }) {
    final logFile = _logFile; // initializeで作ったログファイル
    
    if (logFile == null) {
      debugPrint(
        'Could not write test error log: logger has not been initialized.',
      );
      return;
    }

    try {
      final event = <String, Object?>{
        'timestampUtc': DateTime.now().toUtc().toIso8601String(), // 時刻
        'buildMode': _buildMode, // debugかprofileかrelease
        'testItem': AppRuntimePolicy.testItem, // ログに付ける項目名
        'source': source, // どこ経由のエラーか
        'fatal': fatal, // 重大なエラー（アプリが続行できないエラー）か否か
        'platform': Platform.operatingSystem, // OSの種類
        'platformVersion': Platform.operatingSystemVersion,
        'error': error.toString(), // 何のエラーか
        'stackTrace': stackTrace.toString(), // どこを通ってエラーが起きたか
        ..._device,
      };
      logFile.writeAsStringSync(
        '${jsonEncode(event)}\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (loggingError, loggingStackTrace) {
      // 例外処理中の二次例外
      debugPrint(
        'Could not write test error log: $loggingError\n$loggingStackTrace',
      );
    }
  }

  static String get _buildMode {
    return AppRuntimePolicy.buildMode.name;
  }

  /// ファイル名用の時刻文字列を作成
  /// 形式は「YYYYMMDD-HHmmss」
  static String _fileTimestamp() {
    final now = DateTime.now();
    String twoDigits(int value) => value.toString().padLeft(2, '0');

    return '${now.year}${twoDigits(now.month)}${twoDigits(now.day)}-'
        '${twoDigits(now.hour)}${twoDigits(now.minute)}${twoDigits(now.second)}';
  }

  /// アプリの「端末・OS・アプリ版」の情報を取得して、Map にまとめる
  static Future<Map<String, Object?>> _loadDeviceInfo() async {
    final packageInfo = await PackageInfo.fromPlatform(); // アプリのバージョンとビルド番号
    final result = <String, Object?>{ // 返す情報を入れる
      'appVersion': '${packageInfo.version}+${packageInfo.buildNumber}',
    };
    final deviceInfo = DeviceInfoPlugin(); // 端末情報をとるためのクラスのインスタンス

    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      result.addAll({
        'deviceModel': info.model, // 機種名
        'deviceName': info.device, //端末の内部識別名
        'deviceManufacturer': info.manufacturer, // メーカー名
        'osName': 'Android', // OS名
        'osVersion': info.version.release, // OSバージョン
        'androidApiLevel': info.version.sdkInt, // Android APIレベル
      });
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      result.addAll({
        'deviceModel': info.model, // 機種名
        'deviceName': info.name, //端末の内部識別名
        'osName': info.systemName, // OS名
        'osVersion': info.systemVersion, // OSバージョン
      });
    } else {
      result.addAll({
        'osName': Platform.operatingSystem, // OS名
        'osVersion': Platform.operatingSystemVersion, // OSバージョン
        'deviceModel': 'Unsupported platform', // 機種名
      });
      debugPrint('Unsupported platform detected. Device info: $result');
    }
    return result;
  }
}
