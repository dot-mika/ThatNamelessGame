import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'config/config.dart';
import 'infrastructure/audio_manager.dart';
import 'infrastructure/settings_repository.dart';
import 'presentation/home/home_screen.dart';
import 'state/settings_notifier.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 画面は常に横向き固定で、端末の向きによる回転は一切行えない
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  await initServices();

  runApp(const MyApp());
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
      home: const HomeScreen(),
    );
  }
}

late final SettingsRepository settingsRepository;
late final AudioManager audioManager;
late final SettingsNotifier settingsNotifier;

/// main() から runApp 前に呼ぶ。設定の読み込みと音声のプリロードをここで行う
Future<void> initServices() async {
  settingsRepository = SettingsRepository();
  await settingsRepository.init();
  
  audioManager = AudioManager();
  await audioManager.preload();

  settingsNotifier = SettingsNotifier(settingsRepository, audioManager);
}
