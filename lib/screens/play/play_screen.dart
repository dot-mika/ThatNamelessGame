import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

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

class PlayScreen extends ConsumerStatefulWidget {
  const PlayScreen({super.key});
  @override
  ConsumerState<PlayScreen> createState() => _PlayScreenState();
}

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

  Future<void> _home({bool completed = false}) async {
    if (_committing || _leaving) return;
    _committing = true;
    if (completed) await ref.read(playSessionProvider.notifier).commitResult();
    if (!mounted) return;
    unawaited(ref.read(audioControllerProvider).play(SoundEffect.tapButton));
    setState(() => _leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  Future<void> _replay() async {
    if (_committing || _leaving) return;
    _committing = true;
    final controller = ref.read(playSessionProvider.notifier);
    final id = ref.read(playSessionProvider).operationId;
    await controller.commitResult();
    if (!mounted) return;
    unawaited(ref.read(audioControllerProvider).play(SoundEffect.tapButton));
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
    final color = nearTurn ? AppColors.nearPlayer : AppColors.farPlayer;
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
                image: Assets.image(Assets.playBackground(nearTurn)),
                fit: BoxFit.cover,
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
              left: 18,
              top: 18,
              child: PlayHomeButton(
                key: const Key('playHome'),
                color: color,
                semanticLabel: AppStrings.home(language),
                onTap: controller.requestExit,
              ),
            ),
            Positioned(
              left: nearTurn ? 37 : 1012,
              top: nearTurn ? 527 : 56,
              width: 230,
              height: 130,
              child: RotatedBox(
                quarterTurns: nearTurn ? 0 : 2,
                child: Image.asset(Assets.playLabel('your_turn', language)),
              ),
            ),
            if (state.remaining != null)
              Positioned(
                left: nearTurn ? 1039.5 : 65.5,
                top: nearTurn ? 534 : 110,
                width: 175,
                height: 105,
                child: RotatedBox(
                  quarterTurns: nearTurn ? 0 : 2,
                  child: Text(
                    '${(state.remaining!.inMilliseconds / 1000).ceil()}',
                    key: const Key('turnTimer'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 85,
                      color: AppColors.settingsBlack,
                    ),
                  ),
                ),
              ),
            if (!attacking)
              Positioned(
                left: nearTurn ? 1008 : 34,
                top: nearTurn ? 297 : 280,
                child: RotatedBox(
                  quarterTurns: nearTurn ? 0 : 2,
                  child: PlayConfirmButton(
                    key: const Key('confirmMove'),
                    text: AppStrings.confirm(language),
                    color: color,
                    onTap: state.canConfirm ? controller.confirm : null,
                  ),
                ),
              ),
            if (state.phase == PlayPhase.countdown) ...[
              const Positioned.fill(
                child: ModalBarrier(
                  color: Color(0xB3000000),
                  dismissible: false,
                ),
              ),
              for (final near in [false, true])
                Positioned(
                  left: 412,
                  top: near ? 473 : 68,
                  width: 456,
                  height: 180,
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
                left: 150,
                top: 90,
                width: 980,
                height: 588,
                child: _ExitConfirmation(
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
              for (final side in PlayerSide.values)
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
    // Fixed coordinates on the app's 1280 × 720 canvas, including PNG margins.
    // Both variants share the same image frame and bottom anchor.
    const handLefts = [302.0, 535.0, 768.0];
    final origin = Offset(handLefts[hand.index], near ? 440 : 28);
    var position = origin;
    if (attacking && own && selected && state.target != null) {
      final destination = Offset(
        handLefts[state.target!.index],
        near ? 270 : 186,
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
      width: 210,
      height: 252,
      child: Semantics(
        button: value != 0,
        selected: selected,
        label:
            '${near ? (language == AppLanguage.jp ? '手前' : 'Near') : (language == AppLanguage.jp ? '奥' : 'Far')} ${hand.index + 1}: $value',
        child: GestureDetector(
          key: ValueKey('hand-${side.name}-${hand.name}'),
          onTap: state.phase == PlayPhase.selecting && value != 0
              ? () => controller.select(side, hand)
              : null,
          child: RotatedBox(
            quarterTurns: near ? 0 : 2,
            child: _OutlinedHand(
              asset: Assets.hand(value, selected),
              color: near ? AppColors.nearPlayer : AppColors.farPlayer,
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

/// Dilate only the asset's alpha silhouette, leaving its skin and line colors intact.
class _OutlinedHand extends StatelessWidget {
  const _OutlinedHand({required this.asset, required this.color});
  final String asset;
  final Color color;
  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    fit: StackFit.expand,
    children: [
      for (var i = 0; i < 12; i++)
        Transform.translate(
          offset: Offset(
            math.cos(i * math.pi / 6) * 5,
            math.sin(i * math.pi / 6) * 5,
          ),
          child: Image.asset(
            asset,
            fit: BoxFit.fitWidth,
            alignment: Alignment.bottomCenter,
            color: color,
            colorBlendMode: ui.BlendMode.srcIn,
          ),
        ),
      Image.asset(
        asset,
        fit: BoxFit.fitWidth,
        alignment: Alignment.bottomCenter,
      ),
    ],
  );
}

/// Existing artwork supplies the frame, copy and neutral gray buttons.
class _ExitConfirmation extends StatelessWidget {
  const _ExitConfirmation({
    required this.language,
    required this.onYes,
    required this.onNo,
  });
  final AppLanguage language;
  final FutureOr<void> Function() onYes;
  final VoidCallback onNo;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(child: Image.asset(Assets.exitFrame, fit: BoxFit.fill)),
      Positioned(
        left: 260,
        top: 95,
        width: 460,
        height: 165,
        child: Image.asset(
          Assets.exitDialog('text', language),
          semanticLabel: AppStrings.exitQuestion(language),
        ),
      ),
      Positioned(
        left: 135,
        top: 325,
        width: 300,
        height: 150,
        child: TappableImage(
          key: const Key('exitYes'),
          fit: BoxFit.contain,
          asset: Assets.exitDialog('yes', language),
          semanticLabel: AppStrings.yes(language),
          onTap: onYes,
        ),
      ),
      Positioned(
        right: 135,
        top: 325,
        width: 300,
        height: 150,
        child: TappableImage(
          key: const Key('exitNo'),
          fit: BoxFit.contain,
          asset: Assets.exitDialog('no', language),
          semanticLabel: AppStrings.no(language),
          onTap: onNo,
        ),
      ),
    ],
  );
}
