import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'config/config.dart';
import 'initialization/bootstrap.dart';
import 'screens/home/home_screen.dart';

void main() {
  // 起動前を含む、アプリのZone内で未処理になった例外を受け取る
  runZonedGuarded(startApplication, AppExit.onUncaughtError);
}

// Flutterとアプリの起動準備を行う
Future<void> startApplication() async {
  // Flutterの機能をrunAppより前に使えるようにする
  WidgetsFlutterBinding.ensureInitialized();

  // Flutterフレームワーク内で発生した例外を受け取る
  FlutterError.onError = (FlutterErrorDetails details) {
    AppExit.onUncaughtError(
      details.exception,
      details.stack ?? StackTrace.current,
    );
  };

  // 非同期処理など、ルートIsolateで未処理になった例外を受け取る
  PlatformDispatcher.instance.onError = (Object error, StackTrace stackTrace) {
    AppExit.onUncaughtError(error, stackTrace);
    return true;
  };

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

// 未処理例外が起きたら、不整合な状態で継続せず安全にアプリを閉じる
// インスタンス化も継承もさせず、staticな機能をまとめる
abstract final class AppExit {
  static bool _requested = false;

  static void onUncaughtError(Object error, StackTrace stackTrace) {
    if (_requested) return;
    _requested = true;

    // OS標準の終了処理
    unawaited(SystemNavigator.pop());
  }
}

// アプリ全体のテーマ、表示領域、最初の画面を定義する
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
