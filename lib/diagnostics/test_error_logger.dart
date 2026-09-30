import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'app_runtime_policy.dart';

/// テスト実行中だけ、例外を端末のプライベート領域へ一時記録する。
///
/// テスト終了後は `tool/run_device_test.ps1` がPC側の `log/` へ回収する。
///
/// `writeSync` は直後にアプリが終了しても記録を残せるよう、意図的に同期書き込みする。
abstract final class TestErrorLogger {
  static File? _logFile;
  static Map<String, Object?> _device = const {};

  static Future<void> initialize({required bool enabled}) async {
    if (!enabled) return;

    try {
      final directory = await getApplicationSupportDirectory();
      await directory.create(recursive: true);
      _logFile = File(
        '${directory.path}${Platform.pathSeparator}test-errors.jsonl',
      );
      _device = await _loadDeviceInfo();
    } catch (error, stackTrace) {
      // ロガーの初期化失敗が、元の例外を隠したりアプリを停止させたりしないようにする。
      debugPrint('Could not initialize test error logger: $error\n$stackTrace');
    }
  }

  static void writeSync(
    Object error,
    StackTrace stackTrace, {
    required String source,
    required bool fatal,
  }) {
    final logFile = _logFile;
    if (logFile == null) return;

    try {
      final event = <String, Object?>{
        'timestampUtc': DateTime.now().toUtc().toIso8601String(),
        'buildMode': _buildMode,
        'source': source,
        'fatal': fatal,
        'platform': Platform.operatingSystem,
        'osVersion': Platform.operatingSystemVersion,
        'error': error.toString(),
        'stackTrace': stackTrace.toString(),
        ..._device,
      };
      logFile.writeAsStringSync(
        '${jsonEncode(event)}\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (loggingError, loggingStackTrace) {
      // 例外処理中の二次例外は標準出力だけに留める。
      debugPrint(
        'Could not write test error log: $loggingError\n$loggingStackTrace',
      );
    }
  }

  static String get _buildMode {
    return AppRuntimePolicy.buildMode.name;
  }

  static Future<Map<String, Object?>> _loadDeviceInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final result = <String, Object?>{
      'appVersion': '${packageInfo.version}+${packageInfo.buildNumber}',
    };
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      result.addAll({
        'deviceModel': info.model,
        'deviceName': info.device,
        'deviceManufacturer': info.manufacturer,
        'osName': 'Android',
        'osVersion': info.version.release,
        'androidApiLevel': info.version.sdkInt,
      });
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      result.addAll({
        'deviceModel': info.model,
        'deviceName': info.name,
        'osName': info.systemName,
        'osVersion': info.systemVersion,
      });
    }

    return result;
  }
}
