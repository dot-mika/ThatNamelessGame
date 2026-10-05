import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'config/config.dart';
import 'diagnostics/app_error_handler.dart';
import 'diagnostics/app_runtime_policy.dart';
import 'diagnostics/release_recovery_overlay.dart';
import 'diagnostics/test_error_logger.dart';
import 'initialization/bootstrap.dart';
import 'screens/home/home_screen.dart';


/// アプリの入口Flutter初期化、例外ハンドラ登録、画面向き固定、起動前準備Widgetの表示を行う
Future<void> main() async {
  // runAppより前に使えるようにする
  WidgetsFlutterBinding.ensureInitialized();

  // debugモードで、`--dart-define=TEST_ERROR_LOG=true` 指定時だけ、端末に例外ログを残す
  if (AppRuntimePolicy.enableTestDiagnostics) {
    await TestErrorLogger.initialize();
  }

  // Flutterフレームワーク内で発生した例外を受け取る
  FlutterError.onError = AppErrorHandler.onFlutterError;

  // 非同期処理など、ルートIsolateで未処理になった例外を受け取る
  PlatformDispatcher.instance.onError = AppErrorHandler.onPlatformError;

  // 画面を横向きに固定する
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // ステータスバーとナビゲーションバーを隠す
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // アプリを起動
  runApp(const Bootstrap(child: ThatNamelessGame()));
}


/// アプリ共通テーマと1280×720の論理キャンバスを提供するルートWidget
class ThatNamelessGame extends StatelessWidget {
  const ThatNamelessGame({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'That Nameless Game',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: false, // Material3を使わない
      fontFamily: 'Rwi', // フォントをRwiに固定する
      scaffoldBackgroundColor: Colors.transparent,
    ),

    // 画面を1280×720（16:9）に固定し、余った領域を黒くする
    builder: (context, child) {
      assert(child != null, 'MaterialApp.builder received a null child.');
      if (child == null) ReleaseRecovery.show();

      return ColoredBox(
        // child以外の部分を黒くする
        color: Colors.black,
        child: Center(
          child: FittedBox(
            /// 1280×720のキャンバスに合わせて広げる
            fit: BoxFit.contain,
            child: SizedBox(
              width: AppConfig.canvasWidth, // 1280
              height: AppConfig.canvasHeight, // 720
              child: ReleaseRecoveryOverlay( // 例外発生時に再起動を促す全画面表示を重ねる
                // release では復旧表示を重ねるための土台だけを残す
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      );
    },
    home: const HomeScreen(), // 最初に表示する画面はホーム画面
  );
}
