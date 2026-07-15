import 'package:flutter/material.dart';
import '../../config/assets.dart';
import '../../infrastructure/audio_manager.dart';
import '../../main.dart';
import '../app_routes.dart';
import '../settings/settings_screen.dart';
import '../widgets/navigation_tap.dart';

/// ホーム画面
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // 起動後より、BGMはループ再生する(BGM設定がONの場合のみ)。
    audioManager.playBgm();
  }

  Future<void> _goTo(Widget page, {required bool slide}) async {
    await audioManager.playSe(Se.tapButton);
    if (mounted) {
      await Navigator.of(context).push(
        slide ? slideFromRightRoute(page) : noAnimationRoute(page),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: settingsNotifier,
        builder: (context, _) {
          final lang = settingsNotifier.language;
          return Stack(
            children: [
              Positioned.fill(
                child: Image.asset(Assets.backgroundRainbow, fit: BoxFit.cover),
              ),
              Positioned(
                left: 222.5,
                top: 100,
                width: 800,
                child: Image.asset(Assets.titleLogo(lang)),
              ),
              Positioned(
                left: 1030,
                top: 20,
                width: 110,
                child: NavigationTap(
                  onTap: () => debugPrint('[HomeScreen] rules button pushed'),
                  child: Image.asset(Assets.rules(lang)),
                ),
              ),
              Positioned(
                left: 1150,
                top: 20,
                width: 110,
                child: NavigationTap(
                  onTap: () => _goTo(const SettingsScreen(), slide: false),
                  child: Image.asset(Assets.settingsIcon),
                ),
              ),
              _ModeButton(
                left: 26,
                asset: Assets.play2(lang),
                showStar: settingsNotifier.starTwoPlayer,
                onTap: () => debugPrint('[HomeScreen] 2 plays mode button pushed'),
              ),
              _ModeButton(
                left: 337,
                asset: Assets.play1Easy(lang),
                showStar: settingsNotifier.starEasy,
                onTap: () => debugPrint('[HomeScreen] 1 play easy mode button pushed'),
              ),
              _ModeButton(
                left: 648,
                asset: Assets.play1Normal(lang),
                showStar: settingsNotifier.starNormal,
                onTap: () => debugPrint('[HomeScreen] 1 play normal mode button pushed'),
              ),
              _ModeButton(
                left: 959,
                asset: Assets.play1Hard(lang),
                showStar: settingsNotifier.starHard,
                onTap: () => debugPrint('[HomeScreen] 1 play hard mode button pushed'),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// ホーム下段のモードボタン(2人プレイ/やさしい/ふつう/むずかしい共通)。
class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.left,
    required this.asset,
    required this.showStar,
    required this.onTap,
  });

  final double left;
  final String asset;
  final bool showStar;
  final VoidCallback onTap;

  static const double _width = 295;
  static const double _top = 515;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: _top,
      width: _width,
      child: NavigationTap(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Image.asset(asset, width: _width),
            if (showStar)
              Positioned(
                right: -10,
                bottom: -10,
                width: 60,
                height: 60,
                child: Image.asset(Assets.star),
              ),
          ],
        ),
      ),
    );
  }
}
