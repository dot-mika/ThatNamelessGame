import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../audio/audio_controller.dart';
import '../../config/assets.dart';
import '../../config/config.dart';
import '../../game/game_engine.dart';
import '../../play/play_session.dart';
import '../../settings/settings_notifier.dart';
import '../../settings/settings_state.dart';
import '../widgets/hand_artwork.dart';
import '../widgets/play_buttons.dart';
import '../widgets/tappable_image.dart';

/// 対局状態を描画し、画面遷移完了後にカウントダウンを始める画面
class PlayScreen extends ConsumerStatefulWidget {
  const PlayScreen({super.key});
  @override
  ConsumerState<PlayScreen> createState() => _PlayScreenState();
}

/// 対局そのものはNotifierへ任せ、画面固有の予約・二重操作だけを保持する
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
      if (animation?.status == AnimationStatus.completed) {
        _queueCountdownStart();
      }
    }
  }

  void _onRouteStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _queueCountdownStart();
  }

  /// 遷移完了後の次フレームで開始し、見えない間にカウントを消費しない
  void _queueCountdownStart() {
    if (_countdownStartQueued || !mounted) return;
    final state = ref.read(playSessionProvider);
    if (state.phase != PlayPhase.countdown || state.countdownStarted) return;
    if (!_routeSettled()) return;
    _countdownStartQueued = true;
    final operationId = state.operationId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _countdownStartQueued = false;
      if (!mounted || !_routeSettled()) return;
      ref.read(playSessionProvider.notifier).startCountdown(operationId);
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  /// この画面が最前面にあり、遷移アニメーションが完了しているか
  bool _routeSettled() {
    final route = ModalRoute.of(context);
    if (route == null) return true;
    final animation = route.animation;
    return route.isCurrent &&
        (animation == null || animation.status == AnimationStatus.completed);
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

  /// 終局済みなら結果を保存し、未完了なら連勝中断としてホームへ戻る
  Future<void> _home({bool completed = false}) async {
    if (_committing || _leaving) return;
    _committing = true;
    try {
      final session = ref.read(playSessionProvider.notifier);
      if (completed) {
        await session.commitResult();
      } else {
        await session.abandonGame();
      }
      if (!mounted) return;
      await ref.read(audioControllerProvider).stopEffects();
      if (!mounted) return;
      ref.playTapSound();
      setState(() => _leaving = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    } finally {
      if (mounted && !_leaving) _committing = false;
    }
  }

  /// 結果を一度だけ保存してから、同じモードで新しい対局を開始する
  Future<void> _replay() async {
    if (_committing || _leaving) return;
    _committing = true;
    try {
      final controller = ref.read(playSessionProvider.notifier);
      final id = ref.read(playSessionProvider).operationId;
      await controller.commitResult();
      if (!mounted) return;
      await ref.read(audioControllerProvider).stopEffects();
      if (!mounted) return;
      controller.replay(id);
    } finally {
      if (mounted) _committing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playSessionProvider);
    final controller = ref.read(playSessionProvider.notifier);
    final language = ref.watch(appSettingsProvider.select((s) => s.language));
    final turn = state.session.position.turn;
    final nearTurn = turn == PlayerSide.near;
    final twoPlayer = state.mode.isTwoPlayer;
    final lowerControls = nearTurn || !twoPlayer;
    final color = state.mode.colorFor(turn);
    final remaining = state.remaining;
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
                image: Assets.image(Assets.playBackground(color)),
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
            ),
            for (final side in PlayerSide.values)
              for (final hand in HandPosition.values)
                if (!(state.attacking &&
                    side == turn &&
                    hand == state.attacker))
                  _GameHand(
                    state: state,
                    side: side,
                    hand: hand,
                    language: language,
                    onSelected: controller.select,
                  ),
            // 移動する手を最前面に描画し、ほかの手の上を通過させる
            if (state.attacking && state.attacker != null)
              _AnimatedAttackHand(
                key: ValueKey(
                  'attack-${state.operationId}-${state.attacker}-${state.target}',
                ),
                state: state,
                side: turn,
                hand: state.attacker!,
                language: language,
                onSelected: controller.select,
              ),
            _TurnLabel(
              lowerControls: lowerControls,
              twoPlayer: twoPlayer,
              nearTurn: nearTurn,
              language: language,
            ),
            if (remaining != null)
              _TurnTimerDisplay(
                remainingSeconds: (remaining.inMilliseconds / 1000).ceil(),
                lowerControls: lowerControls,
              ),
            if (!state.attacking && (twoPlayer || nearTurn))
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
                    color: AppColors.cpuTurnOverlay,
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
            ?switch (state.phase) {
              PlayPhase.countdown => _CountdownOverlay(
                countdown: state.countdown,
                started: state.countdownStarted,
                twoPlayer: twoPlayer,
              ),
              PlayPhase.confirmingExit => _ExitOverlay(
                language: language,
                onYes: () => _home(),
                onNo: controller.cancelExit,
              ),
              PlayPhase.finished => _ResultOverlay(
                result: state.result!,
                twoPlayer: twoPlayer,
                language: language,
                onHome: () => _home(completed: true),
                onReplay: _replay,
              ),
              PlayPhase.selecting || PlayPhase.attacking => null,
            },
          ],
        ),
      ),
    );
  }
}

/// 画面全体を暗くし、下の操作を受け付けないようにする背景
const _dimBarrier = ModalBarrier(color: Color(0xB3000000), dismissible: false);

/// 開始前のカウントダウン2人プレイでは奥側にも反転して表示する
class _CountdownOverlay extends StatelessWidget {
  const _CountdownOverlay({
    required this.countdown,
    required this.started,
    required this.twoPlayer,
  });

  final int countdown;
  final bool started;
  final bool twoPlayer;

  @override
  Widget build(BuildContext context) {
    final layout = _CountdownLayout.forValue(countdown);
    return Positioned.fill(
      child: Stack(
        children: [
          const Positioned.fill(child: _dimBarrier),
          if (started)
            for (final near in [if (twoPlayer) false, true])
              Positioned(
                left: layout.left,
                top: near ? 510 : 50,
                width: layout.width,
                height: _CountdownLayout.height,
                child: RotatedBox(
                  quarterTurns: near ? 0 : 2,
                  child: Image.asset(
                    Assets.countdown(countdown),
                    key: ValueKey('countdown-$near-$countdown'),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

/// ホームへ戻るか確認するモーダル
class _ExitOverlay extends StatelessWidget {
  const _ExitOverlay({
    required this.language,
    required this.onYes,
    required this.onNo,
  });

  final AppLanguage language;
  final VoidCallback onYes;
  final VoidCallback onNo;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: Stack(
      children: [
        const Positioned.fill(child: ModalBarrier(dismissible: false)),
        Positioned(
          left: 235,
          top: 110,
          width: 810,
          height: 500,
          child: _ExitConfirmation(
            language: language,
            onYes: onYes,
            onNo: onNo,
          ),
        ),
      ],
    ),
  );
}

/// 勝敗画像と、ホーム・もう一度プレイのボタンを表示する結果画面
class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay({
    required this.result,
    required this.twoPlayer,
    required this.language,
    required this.onHome,
    required this.onReplay,
  });

  final GameResult result;
  final bool twoPlayer;
  final AppLanguage language;
  final FutureOr<void> Function() onHome;
  final FutureOr<void> Function() onReplay;

  /// 指定側から見た勝敗・終局理由に対応する結果画像を返す
  String _resultAsset(PlayerSide side) {
    final win = result.outcome == GameResult.winner(side);
    final label = result.outcome == GameOutcome.draw
        ? 'draw_loop'
        : '${win ? 'win' : 'lose'}${result.reason == GameEndReason.loop ? '_loop' : ''}';
    return Assets.judge(label, language);
  }

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: Stack(
      children: [
        const Positioned.fill(child: _dimBarrier),
        for (final side in [if (twoPlayer) PlayerSide.far, PlayerSide.near])
          Positioned(
            left: 288,
            top: side == PlayerSide.near ? 472 : 24,
            width: 704,
            height: 224,
            child: RotatedBox(
              quarterTurns: side == PlayerSide.near ? 0 : 2,
              child: Image.asset(_resultAsset(side), fit: BoxFit.contain),
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
            onTap: onHome,
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
            onTap: onReplay,
          ),
        ),
      ],
    ),
  );
}

/// カウントダウン画像を、縦幅と中央位置を揃えて表示するレイアウト
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

/// 盤面上の1本の手を、選択・攻撃アニメーションを含めて表示する部品
class _GameHand extends StatelessWidget {
  const _GameHand({
    required this.state,
    required this.side,
    required this.hand,
    required this.language,
    required this.onSelected,
    this.visualAttackProgress,
  });

  final PlayState state;
  final PlayerSide side;
  final HandPosition hand;
  final AppLanguage language;
  final void Function(PlayerSide side, HandPosition hand) onSelected;
  final double? visualAttackProgress;

  @override
  Widget build(BuildContext context) {
    final own = side == state.session.position.turn;
    final selected = (own ? state.attacker : state.target) == hand;
    final value = state.session.position.hands(side)[hand.index];
    final near = side == PlayerSide.near;
    const handLefts = [295.0, 530.0, 765.0];
    final height = HandArtwork.frameHeight(selected);
    final origin = Offset(handLefts[hand.index], near ? 700 - height : 20);
    var position = origin;
    if (visualAttackProgress case final progress?
        when own && selected && state.target != null) {
      final destination = Offset(
        handLefts[state.target!.index],
        near ? 170 : 286,
      );
      final travel = progress <= .75
          ? Curves.easeInOut.transform(progress / .75)
          : (1 - progress) / .25;
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
            '${near ? AppStrings.nearSide(language) : AppStrings.farSide(language)} '
            '${hand.index + 1}: $value',
        child: GestureDetector(
          key: ValueKey('hand-${side.name}-${hand.name}'),
          behavior: HitTestBehavior.opaque,
          onTap: state.canSelect && value != 0
              ? () => onSelected(side, hand)
              : null,
          child: RotatedBox(
            quarterTurns: near ? 0 : 2,
            child: HandArtwork(
              key: ValueKey('handArt-${side.name}-${hand.name}'),
              asset: Assets.hand(value, selected),
              selected: selected,
              color: state.mode.colorFor(side),
            ),
          ),
        ),
      ),
    );
  }
}

/// 攻撃の描画だけを Flutter のフレーム駆動で進める
/// 着弾・完了は PlaySessionNotifier がそれぞれ 600ms / 800ms で扱う
class _AnimatedAttackHand extends StatefulWidget {
  const _AnimatedAttackHand({
    super.key,
    required this.state,
    required this.side,
    required this.hand,
    required this.language,
    required this.onSelected,
  });

  final PlayState state;
  final PlayerSide side;
  final HandPosition hand;
  final AppLanguage language;
  final void Function(PlayerSide side, HandPosition hand) onSelected;

  @override
  State<_AnimatedAttackHand> createState() => _AnimatedAttackHandState();
}

class _AnimatedAttackHandState extends State<_AnimatedAttackHand>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: PlayTiming.attack, vsync: this);
    if (!widget.state.attackPaused) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _AnimatedAttackHand oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.attackPaused) {
      _controller.stop();
    } else if (!_controller.isAnimating && _controller.value < 1) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) => _GameHand(
      state: widget.state,
      side: widget.side,
      hand: widget.hand,
      language: widget.language,
      onSelected: widget.onSelected,
      visualAttackProgress: _controller.value,
    ),
  );
}

/// 手番の残り秒数を、プレイヤー側に合わせて回転表示する部品
class _TurnTimerDisplay extends StatelessWidget {
  const _TurnTimerDisplay({
    required this.remainingSeconds,
    required this.lowerControls,
  });

  final int remainingSeconds;
  final bool lowerControls;

  @override
  Widget build(BuildContext context) => Positioned(
    left: lowerControls ? 1073 : 103,
    top: lowerControls ? 521 : 99,
    width: 104,
    height: 120,
    child: RotatedBox(
      quarterTurns: lowerControls ? 0 : 2,
      child: Text(
        '$remainingSeconds',
        key: const Key('turnTimer'),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 84, color: AppColors.settingsBlack),
      ),
    ),
  );
}

/// 現在の手番を示す画像ラベルを、担当プレイヤー側に表示する部品
class _TurnLabel extends StatelessWidget {
  const _TurnLabel({
    required this.lowerControls,
    required this.twoPlayer,
    required this.nearTurn,
    required this.language,
  });

  final bool lowerControls;
  final bool twoPlayer;
  final bool nearTurn;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) => Positioned(
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
  );
}

/// 終了確認ダイアログの枠・文字・ボタンに使う灰色
/// 対局状態に依存しない終了確認オーバーレイ
class _ExitConfirmation extends StatelessWidget {
  const _ExitConfirmation({
    required this.language,
    required this.onYes,
    required this.onNo,
  });

  final AppLanguage language;
  final VoidCallback onYes;
  final VoidCallback onNo;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: AppStrings.exitQuestion(language),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.dialogGray, width: 5),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 20,
            right: 20,
            top: 95,
          child: ExcludeSemantics(
            child: Text(
              AppStrings.exitQuestionDisplay(language),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 64,
                  height: 1,
                  color: AppColors.dialogGray,
                ),
              ),
            ),
          ),
          Positioned(
            left: 100,
            top: 275,
            child: _DialogButton(
              key: const Key('exitYes'),
              text: AppStrings.yes(language),
              onTap: onYes,
            ),
          ),
          Positioned(
            left: 450,
            top: 275,
            child: _DialogButton(
              key: const Key('exitNo'),
              text: AppStrings.no(language),
              onTap: onNo,
            ),
          ),
        ],
      ),
    ),
  );
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({super.key, required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: text,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        height: 130,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.dialogGray,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 64, color: Colors.white),
        ),
      ),
    ),
  );
}
