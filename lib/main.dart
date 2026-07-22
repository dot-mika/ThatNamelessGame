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
  WidgetsFlutterBinding.ensureInitialized();

  // 画面は常に横向き固定で、端末の向きによる回転は一切行えない
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // ステータスバー/ナビゲーションバーを隠し、全画面表示にする
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // 設定の読み込みと音声のプリロードは、UI表示前に完了させたいので
  // runApp 前に済ませ、出来上がった実体を Provider に差し込む。
  final settingsRepository = SettingsRepository();
  await settingsRepository.init();

  final audioManager = AudioManager();
  await audioManager.preload();

  final container = ProviderContainer(
    overrides: [
      settingsRepositoryProvider.overrideWithValue(settingsRepository),
      audioManagerProvider.overrideWithValue(audioManager),
    ],
  );
  // SettingsNotifier は Provider が最初に watch/read された時点で作られる(遅延生成)。
  // ここで先に読んでおかないと、HomeScreen.initState() の playBgm() が
  // 保存済みの bgmOn/seOn より先に走り、AudioManager のデフォルト値(true)で
  // 再生されてしまう(= 前回OFFにしていてもBGMが鳴る不具合の原因)。
  container.read(settingsNotifierProvider);

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
