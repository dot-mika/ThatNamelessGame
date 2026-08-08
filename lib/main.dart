import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/assets.dart';
import 'config/config.dart';
import 'infrastructure/audio_manager.dart';
import 'infrastructure/settings_repository.dart';
import 'presentation/home/home_screen.dart';
import 'state/providers.dart';

Future<void> main() async {
  // runApp より前に OS 機能(画面向き・システムUI)を触るため、先に Flutter の土台を起動
  WidgetsFlutterBinding.ensureInitialized();

  // 画面は常に横向き固定で、端末の向きによる回転は一切行えない
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // ステータスバー/ナビゲーションバーを隠し、全画面表示にする
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // 設定の読み込みと音声のプリロードをUI表示前に完了させる
  final settingsRepository = await SettingsRepository.create();
  final audioManager = await AudioManager.create();

  final container = createAppProviderContainer(
    settingsRepository: settingsRepository,
    audioManager: audioManager,
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'That Nameless Game',
      debugShowCheckedModeBanner: false,
      // 画⾯は端末サイズ、縦横比にかかわらず16:9固定。余⽩は⿊⾊で埋める
      // 内側は1280×720の固定キャンバス方式。それを画面にあわせて拡大縮小する
      builder: (context, child) {
        return ColoredBox(
          color: Colors.black,
          child: Center(
            child: AspectRatio(
              aspectRatio: AppConfig.canvasWidth / AppConfig.canvasHeight,
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
        );
      },
      home: const _BackgroundPreloader(child: HomeScreen()),
    );
  }
}

/// 背景画像は非同期デコードのため、何もしないと初回描画後に一瞬遅れて
/// ポップインする(音声と同じ理由でここも先読みしたい)。
/// デコードが終わるまでは既存の黒レターボックスをそのまま見せておく。
class _BackgroundPreloader extends StatefulWidget {
  const _BackgroundPreloader({required this.child});

  final Widget child;

  @override
  State<_BackgroundPreloader> createState() => _BackgroundPreloaderState();
}

class _BackgroundPreloaderState extends State<_BackgroundPreloader> {
  bool _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_ready) _precache();
  }

  Future<void> _precache() async {
    await Future.wait([
      precacheImage(const AssetImage(Assets.backgroundRainbow), context),
      precacheImage(const AssetImage(Assets.settingsBackground), context),
    ]);
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    return _ready ? widget.child : const ColoredBox(color: Colors.black);
  }
}
