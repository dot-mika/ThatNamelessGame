import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../audio/audio_controller.dart';
import '../../config/assets.dart';
import '../../config/config.dart';
import '../../game/game_engine.dart';
import '../../play/play_session.dart';
import '../../settings/settings_state.dart';
import '../../settings/update_settings.dart';
import '../widgets/tappable_image.dart';
import '../widgets/play_buttons.dart';
import '../widgets/hand_artwork.dart';
import 'widgets/exit_confirmation.dart';

/// 対局状態を描画し、画面遷移完了後にカウントダウンを始める画面。
class PlayScreen extends ConsumerStatefulWidget {
  const PlayScreen({super.key});
  @override
  ConsumerState<PlayScreen> createState() => _PlayScreenState();
}

/// 対局そのものはNotifierへ任せ、画面固有の予約・二重操作だけを保持する。
class _PlayScreenState extends ConsumerState<PlayScreen>
    with WidgetsBindingObserver {
  bool _leaving = false, _committing = false;
  Animation<double>? _routeAnimation;
  bool _countdownStartQueued = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(playSessionProvider.notifier)
            .setForeground(
              WidgetsBinding.instance.lifecycleState == null ||
                  WidgetsBinding.instance.lifecycleState ==
                      AppLifecycleState.resumed,
            );
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animation = ModalRoute.of(context)?.animation;
    if (_routeAnimation != animation) {
      _routeAnimation?.removeStatusListener(_onRouteStatus);
      _routeAnimation = animation;
      _routeAnimation?.addStatusListener(_onRouteStatus);
    }
  }

  void _onRouteStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _queueCountdownStart();
  }

  /// 遷移完了後の次フレームで開始し、見えない間にカウントを消費しない。
  void _queueCountdownStart() {
    if (_countdownStartQueued || !mounted) return;
    final state = ref.read(playSessionProvider);
    if (state.phase != PlayPhase.countdown || state.countdownStarted) return;
    final route = ModalRoute.of(context);
    if (route != null &&
        (!route.isCurrent ||
            (route.animation != null &&
                route.animation!.status != AnimationStatus.completed))) {
      return;
    }
    _countdownStartQueued = true;
    final operationId = state.operationId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _countdownStartQueued = false;
      if (!mounted) return;
      final route = ModalRoute.of(context);
      if (route != null &&
          (!route.isCurrent ||
              (route.animation != null &&
                  route.animation!.status != AnimationStatus.completed))) {
        return;
      }
      ref.read(playSessionProvider.notifier).startCountdown(operationId);
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_onRouteStatus);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref
        .read(playSessionProvider.notifier)
        .setForeground(state == AppLifecycleState.resumed);
    if (state == AppLifecycleState.resumed) _queueCountdownStart();
  }

  /// 終局済みなら結果を保存し、未完了なら連勝中断としてホームへ戻る。
  Future<void> _home({bool completed = false}) async {
    if (_committing || _leaving) return;
    _committing = true;
    final session = ref.read(playSessionProvider.notifier);
    if (completed) {
      await session.commitResult();
    } else {
      await session.abandonGame();
    }
    if (!mounted) return;
    unawaited(ref.read(audioControllerProvider).play(SoundEffect.tapButton));
    setState(() => _leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  /// 結果を一度だけ保存してから、同じモードで新しい対局を開始する。
  Future<void> _replay() async {
    if (_committing || _leaving) return;
    _committing = true;
    final controller = ref.read(playSessionProvider.notifier);
    final id = ref.read(playSessionProvider).operationId;
    await controller.commitResult();
    if (!mounted) return;
    await ref.read(audioControllerProvider).stopEffects();
    if (!mounted) return;
    controller.replay(id);
    _committing = false;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playSessionProvider);
    if (state.phase == PlayPhase.countdown && !state.countdownStarted) {
      _queueCountdownStart();
    }
    final controller = ref.read(playSessionProvider.notifier);
    final language = ref.watch(appSettingsProvider.select((s) => s.language));
    final nearTurn = state.session.position.turn == PlayerSide.near;
    final twoPlayer = state.mode.isTwoPlayer;
    final lowerControls = nearTurn || !twoPlayer;
    final nearColor = state.mode.playerColor;
    final farColor = twoPlayer ? AppColors.farPlayer : AppColors.disabled;
    final color = nearTurn ? nearColor : farColor;
    final countdownLayout = _CountdownLayout.forValue(state.countdown);
    final remainingSeconds = state.remaining == null
        ? null
        : (state.remaining!.inMilliseconds / 1000).ceil();
    final attacking =
        state.phase == PlayPhase.attacking ||
        (state.phase == PlayPhase.confirmingExit && state.attackProgress > 0);
    return PopScope(
      canPop: _leaving,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (state.phase == PlayPhase.finished) {
          unawaited(_home(completed: true));
        } else if (state.phase == PlayPhase.confirmingExit) {
          controller.cancelExit();
        } else {
          controller.requestExit();
        }
      },
      child: Scaffold(
        key: const Key('playScreen'),
        body: Stack(
          children: [
            Positioned.fill(
              child: Image(
                image: Assets.image(
                  Assets.playBackground(
                    nearTurn,
                    easy: !twoPlayer,
                    soloColor: nearColor
                        .toARGB32()
                        .toRadixString(16)
                        .substring(2)
                        .toUpperCase(),
                  ),
                ),
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
            ),
            for (final side in PlayerSide.values)
              for (final hand in HandPosition.values)
                if (!(attacking &&
                    side == state.session.position.turn &&
                    hand == state.attacker))
                  _hand(state, side, hand, controller, language, attacking),
            // Paint the moving hand last so it passes over every other hand.
            if (attacking && state.attacker != null)
              _hand(
                state,
                state.session.position.turn,
                state.attacker!,
                controller,
                language,
                attacking,
              ),
            Positioned(
              left: lowerControls ? 50 : 1012.5,
              top: lowerControls ? 534 : 56,
              width: 217.5,
              height: 130,
              child: RotatedBox(
                quarterTurns: lowerControls ? 0 : 2,
                child: Image.asset(
                  Assets.playLabel(
                    !twoPlayer && !nearTurn ? 'cpu_turn' : 'your_turn',
                    language,
                  ),
                ),
              ),
            ),
            if (state.remaining != null)
              Positioned(
                // The bundled font has a left/up overhang relative to
                // Figma's text bounds, so its paint origin is compensated.
                left: lowerControls ? 1073 : 103,
                top: lowerControls ? 521 : 99,
                width: 104,
                // The bundled font paints below Figma's nominal 82px text
                // bounds; leave vertical room so the descenders are not cut.
                height: 120,
                child: RotatedBox(
                  quarterTurns: lowerControls ? 0 : 2,
                  child: Text(
                    '$remainingSeconds',
                    key: const Key('turnTimer'),
                    // Keep every remaining-time value centered in the same
                    // timer frame, regardless of its digit count.
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 84,
                      color: AppColors.settingsBlack,
                    ),
                  ),
                ),
              ),
            if (!attacking && (twoPlayer || nearTurn))
              Positioned(
                left: lowerControls ? 1005 : 35,
                top: lowerControls ? 300 : 280,
                child: RotatedBox(
                  quarterTurns: lowerControls ? 0 : 2,
                  child: PlayConfirmButton(
                    key: const Key('confirmMove'),
                    text: AppStrings.confirm(language),
                    color: color,
                    onTap: state.canConfirm ? controller.confirm : null,
                  ),
                ),
              ),
            if (!twoPlayer &&
                !nearTurn &&
                state.phase != PlayPhase.countdown &&
                state.phase != PlayPhase.finished)
              const Positioned.fill(
                child: IgnorePointer(
                  child: ColoredBox(
                    key: Key('cpuTurnOverlay'),
                    color: Color(0x66000000),
                  ),
                ),
              ),
            Positioned(
              left: 20,
              top: 20,
              child: PlayHomeButton(
                key: const Key('playHome'),
                color: color,
                semanticLabel: AppStrings.home(language),
                onTap: controller.requestExit,
              ),
            ),
            if (state.phase == PlayPhase.countdown) ...[
              const Positioned.fill(
                child: ModalBarrier(
                  color: Color(0xB3000000),
                  dismissible: false,
                ),
              ),
              if (state.countdownStarted)
                for (final near in [if (twoPlayer) false, true])
                  Positioned(
                    left: countdownLayout.left,
                    top: near ? 510 : 50,
                    width: countdownLayout.width,
                    height: _CountdownLayout.height,
                    child: RotatedBox(
                      quarterTurns: near ? 0 : 2,
                      child: Image.asset(
                        Assets.countdown(state.countdown),
                        key: ValueKey('countdown-$near-${state.countdown}'),
                      ),
                    ),
                  ),
            ],
            if (state.phase == PlayPhase.confirmingExit) ...[
              const Positioned.fill(child: ModalBarrier(dismissible: false)),
              Positioned(
                left: 235,
                top: 110,
                width: 810,
                height: 500,
                  child: ExitConfirmation(
                  language: language,
                  onYes: () => _home(),
                  onNo: controller.cancelExit,
                ),
              ),
            ],
            if (state.phase == PlayPhase.finished) ...[
              const Positioned.fill(
                child: ModalBarrier(
                  color: Color(0xB3000000),
                  dismissible: false,
                ),
              ),
              for (final side in [
                if (twoPlayer) PlayerSide.far,
                PlayerSide.near,
              ])
                Positioned(
                  left: 288,
                  top: side == PlayerSide.near ? 472 : 24,
                  width: 704,
                  height: 224,
                  child: RotatedBox(
                    quarterTurns: side == PlayerSide.near ? 0 : 2,
                    child: Image.asset(
                      _resultAsset(state.result!, side, language),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              Positioned(
                left: 344,
                top: 283,
                width: 256,
                height: 154,
                child: TappableImage(
                  key: const Key('resultHome'),
                  fit: BoxFit.contain,
                  asset: Assets.judge('return_to_home', language),
                  semanticLabel: AppStrings.home(language),
                  onTap: () => _home(completed: true),
                ),
              ),
              Positioned(
                left: 680,
                top: 283,
                width: 256,
                height: 154,
                child: TappableImage(
                  key: const Key('playAgain'),
                  fit: BoxFit.contain,
                  asset: Assets.judge('play_again', language),
                  semanticLabel: AppStrings.playAgain(language),
                  onTap: _replay,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 1本の手を、選択状態・攻撃アニメーション・回転を含めて描画する。
  Widget _hand(
    PlayState state,
    PlayerSide side,
    HandPosition hand,
    PlaySessionNotifier controller,
    AppLanguage language,
    bool attacking,
  ) {
    final own = side == state.session.position.turn;
    final selected = (own ? state.attacker : state.target) == hand;
    final value = state.session.position.hands(side)[hand.index];
    final near = side == PlayerSide.near;
    const handLefts = [295.0, 530.0, 765.0];
    final height = HandArtwork.frameHeight(selected);
    // The selected artwork is taller, but its wrist stays on the shared
    // lower baseline from the Figma frame.
    final origin = Offset(handLefts[hand.index], near ? 700 - height : 20);
    var position = origin;
    if (attacking && own && selected && state.target != null) {
      final destination = Offset(
        handLefts[state.target!.index],
        near ? 170 : 286,
      );
      final p = state.attackProgress;
      final travel = p <= .75
          ? Curves.easeInOut.transform(p / .75)
          : (1 - p) / .25;
      position = Offset.lerp(origin, destination, travel)!;
    }
    return Positioned(
      key: ValueKey('handLayer-${side.name}-${hand.name}'),
      left: position.dx,
      top: position.dy,
      width: HandArtwork.frameWidth,
      height: height,
      child: Semantics(
        button: value != 0,
        selected: selected,
        label:
            '${near ? (language == AppLanguage.jp ? '手前' : 'Near') : (language == AppLanguage.jp ? '奥' : 'Far')} ${hand.index + 1}: $value',
        child: GestureDetector(
          key: ValueKey('hand-${side.name}-${hand.name}'),
          behavior: HitTestBehavior.opaque,
          onTap: state.canSelect && value != 0
              ? () => controller.select(side, hand)
              : null,
          child: RotatedBox(
            quarterTurns: near ? 0 : 2,
            child: HandArtwork(
              key: ValueKey('handArt-${side.name}-${hand.name}'),
              asset: Assets.hand(value, selected),
              selected: selected,
              color: state.mode.isTwoPlayer
                  ? (near ? AppColors.nearPlayer : AppColors.farPlayer)
                  : (near ? state.mode.playerColor : AppColors.disabled),
            ),
          ),
        ),
      ),
    );
  }

  String _resultAsset(
    GameResult result,
    PlayerSide side,
    AppLanguage language,
  ) {
    final win = result.outcome == GameResult.winner(side);
    final label = result.outcome == GameOutcome.draw
        ? 'draw_loop'
        : '${win ? 'win' : 'lose'}${result.reason == GameEndReason.loop ? '_loop' : ''}';
    return Assets.judge(label, language);
  }
}

/// Figma fixes every countdown image to the same height and center while
/// preserving each exported PNG's distinct aspect ratio.
class _CountdownLayout {
  const _CountdownLayout(this.width);

  static const height = 160.0;
  final double width;

  double get left => (AppConfig.canvasWidth - width) / 2;

  static _CountdownLayout forValue(int value) => switch (value) {
    3 => const _CountdownLayout(108),
    2 => const _CountdownLayout(128.6),
    1 => const _CountdownLayout(85),
    _ => const _CountdownLayout(532.6),
  };
}

