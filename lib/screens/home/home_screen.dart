import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/app_settings_notifier.dart';
import '../../config/config.dart';
import '../../settings/app_settings.dart';
import '../../config/assets.dart';
import '../../audio/audio_manager.dart';
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
            child: Image.asset(
              Assets.backgroundRainbow,
              fit: BoxFit.cover,
              cacheWidth: AppConfig.canvasWidth.toInt(),
              cacheHeight: AppConfig.canvasHeight.toInt(),
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
              semanticLabel: language == AppLanguage.jp ? 'ルール' : 'Rules',
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
            semanticLabel: language == AppLanguage.jp ? '2人対戦' : '2 players',
            onTap: () => debugPrint('2人対戦は未実装です'),
          ),
          _ModeButton(
            left: 346,
            asset: Assets.playEasy(language),
            showStar: settings.starEasy,
            semanticLabel: language == AppLanguage.jp ? 'かんたん' : 'Easy',
            onTap: () => debugPrint('かんたんモードは未実装です'),
          ),
          _ModeButton(
            left: 656,
            asset: Assets.playNormal(language),
            showStar: settings.starNormal,
            semanticLabel: language == AppLanguage.jp ? 'ふつう' : 'Normal',
            onTap: () => debugPrint('ふつうモードは未実装です'),
          ),
          _ModeButton(
            left: 966,
            asset: Assets.playHard(language),
            showStar: settings.starHard,
            semanticLabel: language == AppLanguage.jp ? 'むずかしい' : 'Hard',
            onTap: () => debugPrint('むずかしいモードは未実装です'),
          ),
        ],
      ),
    );
  }

  Future<void> _openSettings(BuildContext context, WidgetRef ref) async {
    unawaited(ref.read(audioManagerProvider).play(SoundEffect.tapButton));
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
