import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/update_settings.dart';
import '../../config/config.dart';
import '../../config/assets.dart';
import '../../audio/audio_controller.dart';
import '../settings/settings_screen.dart';
import '../widgets/tappable_image.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final language = settings.language;

    return Scaffold(
      key: const Key('homeScreen'),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image(
              image: Assets.image(
                Assets.backgroundRainbow,
                bundle: DefaultAssetBundle.of(context),
              ),
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            left: 225,
            top: 88,
            width: 808,
            height: 352,
            child: Image.asset(Assets.titleLogo(language)),
          ),
          Positioned(
            left: 1050,
            top: 20,
            width: 96,
            height: 96,
            child: TappableImage(
              key: const Key('rulesButton'),
              asset: Assets.rules(language),
              semanticLabel: AppStrings.rules(language),
              onTap: () => debugPrint('ルール画面は未実装です'),
            ),
          ),
          Positioned(
            left: 1162,
            top: 20,
            width: 96,
            height: 96,
            child: TappableImage(
              key: const Key('settingsButton'),
              asset: Assets.settingsIcon,
              semanticLabel: AppStrings.settingsTitle(language),
              onTap: () => _openSettings(context, ref),
            ),
          ),
          _ModeButton(
            left: 36,
            asset: Assets.playTwo(language),
            showStar: settings.star2p,
            semanticLabel: AppStrings.playTwo(language),
            onTap: () => debugPrint('2人対戦は未実装です'),
          ),
          _ModeButton(
            left: 346,
            asset: Assets.playEasy(language),
            showStar: settings.starEasy,
            semanticLabel: AppStrings.playEasy(language),
            onTap: () => debugPrint('かんたんモードは未実装です'),
          ),
          _ModeButton(
            left: 656,
            asset: Assets.playNormal(language),
            showStar: settings.starNormal,
            semanticLabel: AppStrings.playNormal(language),
            onTap: () => debugPrint('ふつうモードは未実装です'),
          ),
          _ModeButton(
            left: 966,
            asset: Assets.playHard(language),
            showStar: settings.starHard,
            semanticLabel: AppStrings.playHard(language),
            onTap: () => debugPrint('むずかしいモードは未実装です'),
          ),
        ],
      ),
    );
  }

  Future<void> _openSettings(BuildContext context, WidgetRef ref) async {
    unawaited(ref.read(audioControllerProvider).play(SoundEffect.tapButton));
    await Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => const SettingsScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.left,
    required this.asset,
    required this.showStar,
    required this.semanticLabel,
    required this.onTap,
  });

  final double left;
  final String asset;
  final bool showStar;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Positioned(
    left: left,
    top: 518,
    width: 278,
    height: 175,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: TappableImage(
            asset: asset,
            semanticLabel: semanticLabel,
            onTap: onTap,
          ),
        ),
        if (showStar)
          Positioned(
            right: -8,
            bottom: -8,
            width: 58,
            height: 58,
            child: Image.asset(Assets.star),
          ),
      ],
    ),
  );
}
