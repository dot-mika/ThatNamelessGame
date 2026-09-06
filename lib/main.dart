import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings/app_settings_notifier.dart';
import 'config/config.dart';
import 'audio/audio_manager.dart';
import 'initialization/image_preloader.dart';
import 'settings/save_settings.dart';
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
  runApp(const AppBootstrap());
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

// 設定や音声など、ホーム画面を表示する前の準備を行う
class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap>
    with WidgetsBindingObserver {
  ProviderContainer? _container;
  AudioManager? _audio;
  Object? _error;

  @override
  void initState() {
    super.initState();

    // バックグラウンド移行と復帰を監視する
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initialize());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // バックグラウンド中は音声を止め、復帰時に設定に従って再開する
    unawaited(_audio?.setForeground(state == AppLifecycleState.resumed));
  }

  Future<void> _initialize() async {
    setState(() => _error = null);
    AudioManager? pendingAudio;
    try {
      // 端末に保存されている設定を読み込む
      final repository = await SettingsRepository.create();
      final settings = await repository.loadOrCreate();

      if (!mounted) return;

      // 全画面の画像と全音声を並行して準備し、両方の完了を待つ。
      final (audio, _) = await (
        AudioManager.create().then((audio) {
          pendingAudio = audio;
          return audio;
        }),
        preloadAllImages(context),
      ).wait;

      // 準備中に画面が破棄された場合は、音声も破棄して終了する
      if (!mounted) {
        return;
      }
      await audio.applySettings(settings);
      if (!mounted) return;

      // 読み込んだ実体をRiverpodへ渡す
      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(repository),
          audioManagerProvider.overrideWithValue(audio),
          initialSettingsProvider.overrideWithValue(settings),
        ],
      );
      container.read(appSettingsProvider);

      // 起動準備が完了したらホーム画面へ切り替える
      setState(() {
        _audio = audio;
        _container = container;
      });
      pendingAudio = null;
    } catch (error) {
      // 起動に失敗した場合は、再試行ボタンを表示する
      if (mounted) setState(() => _error = error);
    } finally {
      // 起動失敗や画面破棄で引き渡せなかった音声を片付ける。
      await pendingAudio?.dispose();
    }
  }

  @override
  void dispose() {
    // アプリ終了時に監視と外部リソースを破棄する
    WidgetsBinding.instance.removeObserver(this);
    _container?.dispose();
    unawaited(_audio?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final container = _container;
    if (container != null) {
      return UncontrolledProviderScope(
        container: container,
        child: const ThatNamelessGame(),
      );
    }

    // 設定や画像の読み込み中は専用の起動画面を表示する
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ColoredBox(
        key: const Key('startupScreen'),
        color: Colors.black,
        child: Center(
          child: _error == null
              ? const SizedBox.shrink()
              : TextButton(onPressed: _initialize, child: const Text('Retry')),
        ),
      ),
    );
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
