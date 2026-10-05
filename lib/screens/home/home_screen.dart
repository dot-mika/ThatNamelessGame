import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../audio/audio_controller.dart';
import '../../config/assets.dart';
import '../../config/config.dart';
import '../../diagnostics/app_error_handler.dart';
import '../../initialization/image_preloader.dart';
import '../../play/play_mode.dart';
import '../../play/play_session.dart';
import '../../settings/settings_notifier.dart';
import '../../settings/settings_state.dart';
import '../play/play_screen.dart';
import '../rules/rules_screen.dart';
import '../settings/settings_screen.dart';
import '../widgets/tappable_image.dart';

/// モード選択、星の進捗、設定画面への入口を表示するホーム画面
class HomeScreen extends ConsumerWidget {
  // StatelessWidget + Riverpod の ref が使えるWidget
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
              onTap: () => _openInstant(context, ref, const SettingsScreen()),
            ),
          ),
          for (final definition in _HomeModeDefinition.values)
            _ModeButton(
              left: definition.left,
              asset: definition.asset(language),
              star: settings.starAppearance(definition.mode.starMode),
              semanticLabel: definition.label(language),
              onTap: () => _openPlay(context, ref, definition.mode),
            ),
        ],
      ),
    );
  }

  /// 選択モードをその対局専用Providerへ渡して、スライド遷移で開始する
  Future<void> _openPlay(
    BuildContext context,
    WidgetRef ref,
    PlayMode mode,
  ) async {
    ref.playTapSound();
    await Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => ProviderScope(
          overrides: [playModeProvider.overrideWithValue(mode)],
          child: const PlayScreen(),
        ),
        // スライド中もホーム画面を背面に描画し、透明なScaffold越しに
        // アプリの黒い土台が一瞬見えるのを防ぐ
        opaque: false,
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

  /// ルール画面は画像の準備を終えてから開き、ホーム画面の透過を防ぐ。
  Future<void> _openRules(BuildContext context, WidgetRef ref) async {
    debugPrint('RULES: open start');
    ref.playTapSound();
    try {
      debugPrint('RULES: preload start');
      await preloadRuleImages(context, ref.read(appSettingsProvider).language);
      debugPrint('RULES: preload finished');
    } catch (error, stackTrace) {
      debugPrint('RULES: preload error: $error');
      AppErrorHandler.recordHandled(
        error,
        stackTrace,
        source: ErrorSource.assets,
        message: 'Could not preload rule screen images before navigation.',
      );
    }
    debugPrint('RULES: before navigation');
    if (!context.mounted) return;
    await _openInstant(context, ref, const RulesScreen(), playSound: false);
    debugPrint('RULES: returned from rules screen');
  }

  /// ルール・設定画面は対局状態を持たないため、Providerの上書きなしで即時に開く
  Future<void> _openInstant(
    BuildContext context,
    WidgetRef ref,
    Widget page, {
    bool playSound = true,
  }) async {
    if (playSound) ref.playTapSound();
    await Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => page,
        // 即時遷移でも、最初の描画フレームが来るまではホームを残す
        opaque: false,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }
}

/// ホーム画面にある4つのモード選択ボタンの定義
enum _HomeModeDefinition {
  twoPlayer(PlayMode.twoPlayer, 40),
  easy(PlayMode.easy, 349),
  normal(PlayMode.normal, 658),
  hard(PlayMode.hard, 967);

  const _HomeModeDefinition(this.mode, this.left);

  final PlayMode mode;
  final double left;

  String asset(AppLanguage language) => switch (this) {
    twoPlayer => Assets.playTwo(language),
    easy => Assets.playEasy(language),
    normal => Assets.playNormal(language),
    hard => Assets.playHard(language),
  };

  String label(AppLanguage language) => switch (this) {
    twoPlayer => AppStrings.playTwo(language),
    easy => AppStrings.playEasy(language),
    normal => AppStrings.playNormal(language),
    hard => AppStrings.playHard(language),
  };
}

/// モード選択画像の上に、進捗に応じた星を重ねる部品
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
