import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'config/config.dart';
import 'diagnostics/app_error_handler.dart';
import 'diagnostics/test_error_logger.dart';
import 'initialization/bootstrap.dart';
import 'screens/home/home_screen.dart';

// Flutterとアプリの起動準備を行う
/// アプリの入口。Flutter初期化、例外ハンドラ登録、画面向き固定、起動前準備Widgetの表示を行う。
Future<void> main() async {
  // Flutterの機能をrunAppより前に使えるようにする
  WidgetsFlutterBinding.ensureInitialized();

  await TestErrorLogger.initialize(enabled: enableTestErrorLog);

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

// アプリ全体のテーマ、表示領域、最初の画面を定義する
/// アプリ共通テーマと1280×720の論理キャンバスを提供するルートWidget。
class ThatNamelessGame extends StatelessWidget {
  const ThatNamelessGame({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'That Nameless Game',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      fontFamily: 'Rwi',
      scaffoldBackgroundColor: Colors.transparent,
    ),

    // 画面を1280×720（16:9）に固定し、余った領域を黒くする
    builder: (context, child) => ColoredBox(
      color: Colors.black,
      child: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: AppConfig.canvasWidth,
            height: AppConfig.canvasHeight,
            child: child,
          ),
        ),
      ),
    ),
    home: const HomeScreen(),
  );
}
