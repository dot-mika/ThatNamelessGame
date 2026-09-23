import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/audio_controller.dart';
import '../config/config.dart';
import '../game/game_engine.dart';
import '../settings/update_settings.dart';
import 'play_mode.dart';
import 'cpu_strategy.dart';
import 'cpu_scheduler.dart';

/// 実時間の取得を抽象化する。テストではFakeClockへ差し替える。
abstract interface class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  @override
  DateTime now() => DateTime.now();
}

/// 対局に必要な依存をProviderとして切り出し、画面ごとのモードと
/// テスト用の偽物を安全に差し替えられるようにする。
final playClockProvider = Provider<Clock>((ref) => SystemClock());
final playModeProvider = Provider<PlayMode>(
  (ref) => PlayMode.twoPlayer,
  dependencies: [],
);
final cpuRandomProvider = Provider<Random>((ref) => Random());
final cpuStrategyProvider = Provider<CpuStrategy>((ref) {
  final mode = ref.watch(playModeProvider);
  if (mode.isTwoPlayer) throw StateError('Two-player mode has no CPU strategy.');
  final cpu = cpuSettingsFor(mode);
  return cpu.searchDepth == 0
      ? EasyCpu(eliminationChance: cpu.eliminationChance)
      : mode == PlayMode.hard
      ? HardCpu(depth: cpu.searchDepth)
      : SearchCpu(cpu.searchDepth);
}, dependencies: [playModeProvider]);

/// モードに応じた初期局面の作り方。ふつう・むずかしいだけ28局面プールを使う。
final initialGameProvider = Provider<GameSession Function()>((ref) {
  final mode = ref.watch(playModeProvider);
  final random = Random();
  return switch (mode) {
    PlayMode.normal ||
    PlayMode.hard => SoloInitialPositionGenerator(random).generate,
    _ => InitialPositionGenerator(random).generate,
  };
}, dependencies: [playModeProvider]);
final playSessionProvider =
    NotifierProvider.autoDispose<PlaySessionNotifier, PlayState>(
      PlaySessionNotifier.new,
      dependencies: [
        playClockProvider,
        playModeProvider,
        cpuRandomProvider,
        cpuStrategyProvider,
        initialGameProvider,
        audioControllerProvider,
        appSettingsProvider,
      ],
    );

/// 対局画面が現在どの操作を受け付ける段階かを表す。
enum PlayPhase { countdown, selecting, attacking, confirmingExit, finished }

/// PlayScreenが描画に必要な値だけをまとめた読み取り専用の状態。
class PlayState {
  const PlayState({
    required this.mode,
    required this.session,
    required this.phase,
    required this.remaining,
    required this.countdown,
    required this.countdownStarted,
    required this.attackProgress,
    required this.operationId,
    this.attacker,
    this.target,
    this.result,
  });
  final GameSession session;
  final PlayMode mode;
  final PlayPhase phase;
  final Duration? remaining;
  final int countdown, operationId;
  final bool countdownStarted;
  final double attackProgress;
  final HandPosition? attacker, target;
  final GameResult? result;
  bool get canConfirm => canSelect && attacker != null && target != null;
  bool get canSelect =>
      phase == PlayPhase.selecting && mode.isHuman(session.position.turn);
}

/// カウントダウンから結果画面まで、対局の時間軸を管理する司令塔。
class PlaySessionNotifier extends Notifier<PlayState> {
  final _engine = const GameEngine();
  late Clock _clock;
  late AudioController _audio;
  late PlayMode _mode;
  late GameSession _session;
  late DateTime _lastTick;
  Duration? _limit, _remaining;
  DateTime? _deadline;
  PlayPhase _phase = PlayPhase.countdown;
  PlayPhase? _suspendedPhase;
  HandPosition? _attacker, _target;
  GameSession? _pending;
  GameResult? _result;
  Duration _motion = Duration.zero;
  bool _foreground = true, _hit = false, _resultCommitted = false;
  bool _countdownStarted = false;
  int _operationId = 0;
  CpuScheduler? _cpuSchedule;
  GameMove? _cpuMove;
  int _cpuRequest = 0;
  List<GameMove> _cpuPreviews = [];
  bool get _cpuTurn => !_mode.isHuman(_session.position.turn);

  @override
  PlayState build() {
    _clock = ref.read(playClockProvider);
    _audio = ref.read(audioControllerProvider);
    _mode = ref.read(playModeProvider);
    _reset();
    // tick自体は実経過時間を使う。Timerは進行を確認する契機にすぎない。
    final timer = Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => tick(),
    );
    ref.onDispose(() {
      timer.cancel();
      _operationId++;
      _cpuRequest++;
      unawaited(_audio.setPlaySuspended(false));
    });
    return _snapshot();
  }

  void _reset() {
    // 古い非同期CPU計算と画面コールバックを、新しい対局へ反映させない。
    _cpuRequest++;
    _operationId++;
    _session = ref.read(initialGameProvider)();
    _limit = _mode.isTwoPlayer
        ? ref.read(appSettingsProvider).timeLimit.duration
        : cpuSettingsFor(_mode).timeLimit;
    _remaining = _limit;
    _deadline = null;
    _phase = PlayPhase.countdown;
    _suspendedPhase = null;
    _attacker = _target = null;
    _pending = null;
    _cpuSchedule = null;
    _cpuMove = null;
    _result = null;
    _motion = Duration.zero;
    _countdownStarted = false;
    _hit = false;
    _resultCommitted = false;
    _lastTick = _clock.now();
    unawaited(_audio.setPlaySuspended(true));
  }

  /// The screen acknowledges its first frame after the route transition.
  void startCountdown(int operationId) {
    if (operationId != _operationId ||
        _phase != PlayPhase.countdown ||
        _countdownStarted ||
        !_foreground) {
      return;
    }
    _countdownStarted = true;
    _lastTick = _clock.now();
    // 最初の「3」の表示開始とSE発火を同じ境界に揃える。
    unawaited(_audio.playCountdownCue(SoundEffect.countdown));
    _publish();
  }

  /// 内部の可変フィールドを、画面へ公開する不変のPlayStateへ変換する。
  PlayState _snapshot() => PlayState(
    mode: _mode,
    session: _session,
    phase: _phase,
    remaining: _remaining,
    countdown: (3 - _motion.inSeconds).clamp(0, 3),
    countdownStarted: _countdownStarted,
    attackProgress: (_motion.inMicroseconds / 800000).clamp(0, 1),
    operationId: _operationId,
    attacker: _attacker,
    target: _target,
    result: _result,
  );
  void _publish() => state = _snapshot();

  void tick() {
    final now = _clock.now();
    final elapsed = now.difference(_lastTick);
    _lastTick = now;
    // 背景中、カウントダウン開始前、モーダル中、終局後は進行を止める。
    if (!_foreground ||
        (_phase == PlayPhase.countdown && !_countdownStarted) ||
        _phase == PlayPhase.confirmingExit ||
        _phase == PlayPhase.finished) {
      return;
    }
    if (_phase == PlayPhase.selecting) {
      if (_cpuTurn) {
        // CPU手番は人間用の制限時間ではなく、演出用スケジュールを進める。
        _tickCpu(elapsed);
        _publish();
        return;
      }
      final previous = _remaining;
      _checkDeadline();
      if (previous != _remaining || _result != null) _publish();
      return;
    }
    _motion += elapsed.isNegative ? Duration.zero : elapsed;
    if (_phase == PlayPhase.countdown) {
      if (_motion >= const Duration(seconds: 4)) {
        _beginTurn();
        unawaited(_audio.setPlaySuspended(false));
      } else if (state.countdown != (3 - _motion.inSeconds).clamp(0, 3)) {
        // 数字が変わった瞬間だけ、表示と同期した即時SEを鳴らす。
        unawaited(
          _audio.playCountdownCue(
            _motion.inSeconds == 3 ? SoundEffect.start : SoundEffect.countdown,
          ),
        );
      }
    } else if (_phase == PlayPhase.attacking) {
      if (!_hit && _motion >= const Duration(milliseconds: 600)) {
        _hit = true;
        // 攻撃手が戻るまでは、画面上の手番を維持したまま着弾結果だけ反映する。
        final next = _pending!.position;
        _session = GameSession(
          GamePosition(
            nearHands: next.nearHands,
            farHands: next.farHands,
            turn: _session.position.turn,
          ),
          visitedPositions: _session.visitedPositions,
        );
        unawaited(_audio.play(SoundEffect.tapOk));
      }
      if (_motion >= const Duration(milliseconds: 800)) {
        _session = _pending!;
        _pending = null;
        if (_session.result case final result?) {
          _finish(result);
        } else {
          _beginTurn();
        }
      }
    }
    _publish();
  }

  void _beginTurn() {
    _phase = PlayPhase.selecting;
    _attacker = _target = null;
    _motion = Duration.zero;
    _remaining = _limit;
    _deadline = _limit == null ? null : _clock.now().add(_limit!);
    _cpuSchedule = null;
    _cpuMove = null;
    if (_cpuTurn) {
      _deadline = null;
      final random = ref.read(cpuRandomProvider);
      // 非同期探索の完了時に、この対局の要求かどうかを照合する番号。
      final request = ++_cpuRequest;
      final move = ref.read(cpuStrategyProvider).chooseMove(_session, random);
      if (move is GameMove) {
        _acceptCpuMove(move, random);
      } else {
        unawaited(
          move.then(
            (selected) {
              if (ref.mounted &&
                  request == _cpuRequest &&
                  _phase != PlayPhase.finished) {
                _acceptCpuMove(selected, random);
                _lastTick = _clock.now();
              }
            },
            onError: (Object error, StackTrace stack) {
              if (ref.mounted &&
                  request == _cpuRequest &&
                  _phase != PlayPhase.finished) {
                _acceptCpuMove(_engine.legalMoves(_session).first, random);
                _lastTick = _clock.now();
              }
            },
          ),
        );
      }
    }
  }

  void _acceptCpuMove(GameMove move, Random random) {
    _cpuMove = move;
    final cpu = cpuSettingsFor(_mode);
    // 見た目だけの再選択。最終手は変えず、中間表示も必ず合法手にする。
    final alternatives = _engine
        .legalMoves(_session)
        .where(
          (m) =>
              (m.attackerPosition == move.attackerPosition) !=
              (m.targetPosition == move.targetPosition),
        )
        .toList();
    final previews = <GameMove>[move];
    for (var i = 0; alternatives.isNotEmpty && i < cpu.maxReselections; i++) {
      if (random.nextDouble() >= cpu.reselectionChance) break;
      final next = previews.first;
      final options = alternatives
          .where(
            (m) =>
                (m.attackerPosition == next.attackerPosition) !=
                (m.targetPosition == next.targetPosition),
          )
          .toList();
      if (options.isEmpty) break;
      previews.insert(0, options[random.nextInt(options.length)]);
    }
    _cpuPreviews = previews;
    _cpuSchedule = CpuScheduler(
      interval: cpu.stepInterval,
      operations: 2 + previews.length,
    );
  }

  void _tickCpu(Duration elapsed) {
    if (_cpuMove == null) return;
    final schedule = _cpuSchedule!;
    final ready = schedule.advance(elapsed);
    _remaining = _limit! - schedule.elapsed;
    if (!ready) return;
    // stepごとに攻撃手、対象手、決定を順に画面へ見せる。
    switch (schedule.step) {
      case 1:
        _attacker = _cpuPreviews.first.attackerPosition;
        unawaited(_audio.play(SoundEffect.tapHand));
      case 2:
        _target = _cpuPreviews.first.targetPosition;
        unawaited(_audio.play(SoundEffect.tapHand));
      default:
        if (schedule.step == schedule.operations) {
          _confirmMove();
        } else {
          final preview = _cpuPreviews[schedule.step - 2];
          _attacker = preview.attackerPosition;
          _target = preview.targetPosition;
          unawaited(_audio.play(SoundEffect.tapHand));
        }
    }
  }

  bool _checkDeadline() {
    if (_deadline == null) return false;
    final left = _deadline!.difference(_clock.now());
    _remaining = left.isNegative ? Duration.zero : left;
    if (left <= Duration.zero) {
      // 決定操作直前にもここを呼ぶため、遅延フレームでも時間切れを優先できる。
      _finish(
        GameResult(
          GameEndReason.timeout,
          GameResult.winner(_session.position.turn.opponent),
        ),
      );
      return true;
    }
    return false;
  }

  void select(PlayerSide side, HandPosition hand) {
    if (!_foreground || _phase != PlayPhase.selecting || _cpuTurn) return;
    if (_checkDeadline()) {
      _publish();
      return;
    }
    if (_session.position.hands(side)[hand.index] == 0) return;
    if (side == _session.position.turn) {
      _attacker = hand;
    } else {
      _target = hand;
    }
    unawaited(_audio.play(SoundEffect.tapHand));
    _publish();
  }

  void confirm() {
    if (!_foreground || _phase != PlayPhase.selecting || _cpuTurn) return;
    if (_checkDeadline()) {
      _publish();
      return;
    }
    _confirmMove();
  }

  void _confirmMove() {
    if (_attacker == null || _target == null) return;
    final move = GameMove(_attacker!, _target!);
    if (!_engine.isLegalMove(_session, move)) return;
    // 結果はすぐ確定せず、攻撃アニメーション終了時まで_pendingに保持する。
    _pending = _engine.applyMove(_session, move);
    _phase = PlayPhase.attacking;
    _motion = Duration.zero;
    _hit = false;
    _deadline = null;
    _lastTick = _clock.now();
    _publish();
  }

  void requestExit() {
    if (!_foreground ||
        (_phase != PlayPhase.selecting && _phase != PlayPhase.attacking)) {
      return;
    }
    tick();
    if (_phase == PlayPhase.finished) return;
    _suspendedPhase = _phase;
    // 2人対戦では終了確認中に時間を止める。1人プレイ人間手番は止めない。
    if (_phase == PlayPhase.selecting &&
        _mode.pausesTimerForExit(_session.position.turn)) {
      _deadline = null;
    }
    _phase = PlayPhase.confirmingExit;
    unawaited(_audio.setPlaySuspended(true));
    unawaited(_audio.play(SoundEffect.tapButton));
    _publish();
  }

  void cancelExit() {
    if (_phase != PlayPhase.confirmingExit) return;
    _phase = _suspendedPhase!;
    _lastTick = _clock.now();
    if (_phase == PlayPhase.selecting &&
        !_cpuTurn &&
        _mode.pausesTimerForExit(_session.position.turn) &&
        _remaining != null) {
      _deadline = _lastTick.add(_remaining!);
    }
    unawaited(_audio.play(SoundEffect.tapButton));
    if (_phase == PlayPhase.selecting) _checkDeadline();
    unawaited(_audio.setPlaySuspended(false));
    _publish();
  }

  void setForeground(bool foreground) {
    if (_foreground == foreground) return;
    if (!foreground) tick();
    _foreground = foreground;
    _lastTick = _clock.now();
    if (foreground && _phase == PlayPhase.selecting) {
      _checkDeadline();
      _publish();
    }
  }

  void _finish(GameResult result) {
    _phase = PlayPhase.finished;
    _result = result;
    _deadline = null;
    unawaited(_audio.playResult(_mode.resultSound(result)));
  }

  Future<void> commitResult() async {
    if (_phase == PlayPhase.finished && !_resultCommitted) {
      // ホームとリトライの連打で、星の進捗を二重保存しない。
      _resultCommitted = true;
      final outcome = _result!.outcome;
      await ref
          .read(appSettingsProvider.notifier)
          .recordResult(
            _mode.starMode,
            won: outcome == GameOutcome.nearWin,
            draw: outcome == GameOutcome.draw,
          );
    }
  }

  Future<void> abandonGame() =>
      ref.read(appSettingsProvider.notifier).abandonGame(_mode.starMode);

  void replay(int operationId) {
    if (_phase != PlayPhase.finished || operationId != _operationId) return;
    _reset();
    _publish();
  }
}
