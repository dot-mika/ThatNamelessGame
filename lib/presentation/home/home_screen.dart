import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/assets.dart';
import '../../infrastructure/app_logger.dart';
import '../../infrastructure/audio_manager.dart';
import '../../state/providers.dart';
import '../app_routes.dart';
import '../settings/settings_screen.dart';
import '../widgets/navigation_tap.dart';

/// ホーム画面
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // 起動後より、BGMはループ再生する(BGM設定がONの場合のみ)。
    ref.read(audioManagerProvider).playBgm();
  }

  Future<void> _goTo(Widget page, {required bool slide}) async {
    await ref.read(audioManagerProvider).playSe(Se.tapButton);
    if (mounted) {
      await Navigator.of(context).push(
        slide ? slideFromRightRoute(page) : noAnimationRoute(page),
      );
    }
  }

  // ルール画面/プレイ画面は未実装のため、遷移先ができるまでのスタブ。
  // 効果音は仕様通りに鳴らす。
  void _tap(String debugMessage) {
    ref.read(audioManagerProvider).playSe(Se.tapButton);
    appLogger.d(debugMessage);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsNotifierProvider);
    final lang = settings.language;
    return Scaffold(
      body: Stack(
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
              onTap: () => _tap('[HomeScreen] rules button pushed'),
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
            showStar: settings.starTwoPlayer,
            onTap: () => _tap('[HomeScreen] 2 plays mode button pushed'),
          ),
          _ModeButton(
            left: 337,
            asset: Assets.play1Easy(lang),
            showStar: settings.starEasy,
            onTap: () => _tap('[HomeScreen] 1 play easy mode button pushed'),
          ),
          _ModeButton(
            left: 648,
            asset: Assets.play1Normal(lang),
            showStar: settings.starNormal,
            onTap: () => _tap('[HomeScreen] 1 play normal mode button pushed'),
          ),
          _ModeButton(
            left: 959,
            asset: Assets.play1Hard(lang),
            showStar: settings.starHard,
            onTap: () => _tap('[HomeScreen] 1 play hard mode button pushed'),
          ),
        ],
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
