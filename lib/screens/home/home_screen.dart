import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/update_settings.dart';
import '../../settings/settings_state.dart';
import '../../config/config.dart';
import '../../config/assets.dart';
import '../../audio/audio_controller.dart';
import '../settings/settings_screen.dart';
import '../rules/rules_screen.dart';
import '../play/play_screen.dart';
import '../../play/play_mode.dart';
import '../../play/play_session.dart';
import '../widgets/tappable_image.dart';

/// モード選択、星の進捗、設定画面への入口を表示するホーム画面。
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
            left: 219,
            top: 84,
            width: 826,
            height: 360,
            child: Image.asset(Assets.titleLogo(language)),
          ),
          Positioned(
            right: 140,
            top: 20,
            width: 100,
            height: 100,
            child: TappableImage(
              key: const Key('rulesButton'),
              asset: Assets.rules(language),
              semanticLabel: AppStrings.rules(language),
              onTap: () => _openRules(context, ref),
            ),
          ),
          Positioned(
            right: 20,
            top: 20,
            width: 100,
            height: 100,
            child: TappableImage(
              key: const Key('settingsButton'),
              asset: Assets.settingsIcon,
              semanticLabel: AppStrings.settingsTitle(language),
              onTap: () => _openSettings(context, ref),
            ),
          ),
          _ModeButton(
            left: 40,
            asset: Assets.playTwo(language),
            star: settings.starAppearance(StarMode.twoPlayer),
            semanticLabel: AppStrings.playTwo(language),
            onTap: () => _openPlay(context, ref, PlayMode.twoPlayer),
          ),
          _ModeButton(
            left: 349,
            asset: Assets.playEasy(language),
            star: settings.starAppearance(StarMode.easy),
            semanticLabel: AppStrings.playEasy(language),
            onTap: () => _openPlay(context, ref, PlayMode.easy),
          ),
          _ModeButton(
            left: 658,
            asset: Assets.playNormal(language),
            star: settings.starAppearance(StarMode.normal),
            semanticLabel: AppStrings.playNormal(language),
            onTap: () => _openPlay(context, ref, PlayMode.normal),
          ),
          _ModeButton(
            left: 967,
            asset: Assets.playHard(language),
            star: settings.starAppearance(StarMode.hard),
            semanticLabel: AppStrings.playHard(language),
            onTap: () => _openPlay(context, ref, PlayMode.hard),
          ),
        ],
      ),
    );
  }

  /// 選択モードをその対局専用Providerへ渡して、スライド遷移で開始する。
  Future<void> _openPlay(
    BuildContext context,
    WidgetRef ref,
    PlayMode mode,
  ) async {
    unawaited(ref.read(audioControllerProvider).play(SoundEffect.tapButton));
    await Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => ProviderScope(
          overrides: [playModeProvider.overrideWithValue(mode)],
          child: const PlayScreen(),
        ),
        transitionsBuilder: (_, animation, _, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(
                CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              ),
          child: child,
        ),
        transitionDuration: const Duration(seconds: 1),
        reverseTransitionDuration: const Duration(seconds: 1),
      ),
    );
  }

  /// 設定画面は対局状態を持たないため、Providerの上書きなしで開く。
  Future<void> _openRules(BuildContext context, WidgetRef ref) async {
    unawaited(ref.read(audioControllerProvider).play(SoundEffect.tapButton));
    await Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => const RulesScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
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

/// モード選択画像の上に、進捗に応じた星を重ねる部品。
class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.left,
    required this.asset,
    required this.star,
    required this.semanticLabel,
    required this.onTap,
  });

  final double left;
  final String asset;
  final StarAppearance star;
  final String semanticLabel;
  final FutureOr<void> Function() onTap;

  @override
  Widget build(BuildContext context) => Positioned(
    left: left,
    top: 516,
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
        Positioned(
          right: 21,
          bottom: 17,
          width: 60,
          height: 60,
          child: IgnorePointer(
            child: Image.asset(switch (star) {
              StarAppearance.clear => Assets.starClear,
              StarAppearance.blue => Assets.starBlue,
              StarAppearance.yellow => Assets.starYellow,
            }),
          ),
        ),
      ],
    ),
  );
}
