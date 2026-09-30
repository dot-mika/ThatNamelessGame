import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/audio_controller.dart';
import '../config/config.dart';
import '../diagnostics/app_error_handler.dart';
import '../game/game_engine.dart';
import '../settings/settings_notifier.dart';
import 'cpu_scheduler.dart';
import 'cpu_strategy.dart';
import 'play_mode.dart';

/// 実時間の取得を抽象化する。テストではFakeClockへ差し替える。
abstract interface class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  @override
  DateTime now() => DateTime.now();
}

/// 対局演出の時間。進行判定と表示計算で同じ値を使う。
abstract final class PlayTiming {
  /// カウントダウンの最初の数字。
  static const countdownFrom = 3;

  /// 「3・2・1・スタート」それぞれの表示とSE開始の間隔。
  static const countdownStep = Duration(seconds: 1);

  /// 「3・2・1・スタート」を同じ間隔ずつ表示する合計時間。
  static final countdown = countdownStep * (countdownFrom + 1);

  /// 攻撃手が相手の手に届き、値が変わる時点。
  static const attackHit = Duration(milliseconds: 600);

  /// 攻撃手が元の位置へ戻り終わるまでの時間。
  static const attack = Duration(milliseconds: 800);

  /// 進行を確認する間隔。経過時間は実時計で測る。
  static const tickInterval = Duration(milliseconds: 16);
}

/// 対局画面が描画・操作判断に使う進行フェーズ。
enum PlayPhase { countdown, selecting, attacking, confirmingExit, finished }

/// 対局進行をUIへ渡す不変のスナップショット。
class PlayState {
  const PlayState({
    required this.mode,
    required this.session,
    required this.phase,
    required this.remaining,
    required this.countdown,
    required this.countdownStarted,
    required this.attacking,
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
  final int countdown;
  final bool countdownStarted;

  /// 攻撃アニメーション中か。終了確認で一時停止している間もtrue。
  final bool attacking;
  final double attackProgress;
  final int operationId;
  final HandPosition? attacker;
  final HandPosition? target;
  final GameResult? result;

  /// 攻撃側と対象側の手が両方選ばれているか判定する。
  bool get canConfirm => canSelect && attacker != null && target != null;

  /// 現在の手番を人間が選択操作できるか判定する。
  bool get canSelect =>
      phase == PlayPhase.selecting && mode.isHuman(session.position.turn);
}

/// 対局に必要な依存をProviderとして切り出し、画面ごとのモードと
/// テスト用の偽物を安全に差し替えられるようにする。
final playClockProvider = Provider<Clock>((ref) => SystemClock());
final playModeProvider = Provider<PlayMode>(
  (ref) => PlayMode.twoPlayer,
  dependencies: [],
);
final cpuRandomProvider = Provider<Random>((ref) => Random());
final cpuStrategyProvider = Provider<CpuStrategy>(
  (ref) => cpuStrategyFor(ref.watch(playModeProvider)),
  dependencies: [playModeProvider],
);

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

/// カウントダウンから結果画面まで、対局の時間軸を管理する司令塔。
class PlaySessionNotifier extends Notifier<PlayState> {
  final _engine = const GameEngine();
  final _audioSuspensionOwner = Object();
  late Clock _clock;
  late AudioController _audio;
  late PlayMode _mode;
  late GameSession _session;
  late DateTime _lastTick;
  final _timer = _MatchTimer();
  PlayPhase _phase = PlayPhase.countdown;
  PlayPhase? _suspendedPhase;
  HandPosition? _attacker, _target;
  GameResult? _result;

  /// カウントダウンと攻撃アニメーションの経過時間。
  Duration _motion = Duration.zero;
  bool _foreground = true, _resultCommitted = false;
  bool _countdownStarted = false;
  int _operationId = 0;

  /// 攻撃アニメーション中の適用後局面。攻撃中以外はnull。
  _Attack? _attack;

  /// CPUの手が決まった後の演出予定。決まるまではnull。
  _CpuPlan? _cpuPlan;
  int _cpuRequest = 0;
  bool get _cpuTurn => !_mode.isHuman(_session.position.turn);

  @override
  PlayState build() {
    _clock = ref.read(playClockProvider);
    _audio = ref.read(audioControllerProvider);
    _mode = ref.read(playModeProvider);
    _reset();
    // tick自体は実経過時間を使う。Timerは進行を確認する契機にすぎない。
    final timer = Timer.periodic(PlayTiming.tickInterval, (_) => tick());
    ref.onDispose(() {
      timer.cancel();
      _operationId++;
      _cpuRequest++;
      unawaited(_audio.setPlaySuspended(_audioSuspensionOwner, false));
    });
    return _snapshot();
  }

  void _reset() {
    // 古い非同期CPU計算と画面コールバックを、新しい対局へ反映させない。
    _cpuRequest++;
    _operationId++;
    _session = ref.read(initialGameProvider)();
    _timer.reset(
      _mode.isTwoPlayer
          ? ref.read(appSettingsProvider).timeLimit.duration
          : cpuSettingsFor(_mode).timeLimit,
    );
    _phase = PlayPhase.countdown;
    _suspendedPhase = null;
    _attacker = _target = null;
    _attack = null;
    _cpuPlan = null;
    _result = null;
    _motion = Duration.zero;
    _countdownStarted = false;
    _resultCommitted = false;
    _lastTick = _clock.now();
    unawaited(_audio.setPlaySuspended(_audioSuspensionOwner, true));
  }

  /// 画面遷移後の最初の描画完了を受け取り、カウントダウンを開始する。
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

  /// 現在表示すべきカウントダウンの数字。0は「スタート」。
  int get _countdownValue =>
      (PlayTiming.countdownFrom -
              (_motion.inMicroseconds ~/
                  PlayTiming.countdownStep.inMicroseconds))
          .clamp(0, PlayTiming.countdownFrom);

  /// 内部の可変フィールドを、画面へ公開する不変のPlayStateへ変換する。
  PlayState _snapshot() => PlayState(
    mode: _mode,
    session: _session,
    phase: _phase,
    remaining: _timer.remaining,
    countdown: _countdownValue,
    countdownStarted: _countdownStarted,
    attacking: _attack != null,
    attackProgress: (_motion.inMicroseconds / PlayTiming.attack.inMicroseconds)
        .clamp(0, 1),
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
      final previous = _timer.remaining;
      _checkDeadline();
      if (previous != _timer.remaining || _result != null) _publish();
      return;
    }
    _motion += elapsed.isNegative ? Duration.zero : elapsed;
    if (_phase == PlayPhase.countdown) {
      _tickCountdown();
    } else if (_phase == PlayPhase.attacking) {
      _tickAttack();
    }
    _publish();
  }

  void _tickCountdown() {
    if (_motion >= PlayTiming.countdown) {
      _beginTurn();
      unawaited(_audio.setPlaySuspended(_audioSuspensionOwner, false));
    } else if (state.countdown != _countdownValue) {
      // 数字が変わった瞬間だけ、表示と同期した即時SEを鳴らす。
      unawaited(
        _audio.playCountdownCue(
          _countdownValue == 0 ? SoundEffect.start : SoundEffect.countdown,
        ),
      );
    }
  }

  void _tickAttack() {
    final attack = _attack!;
    if (!attack.hit && _motion >= PlayTiming.attackHit) {
      attack.hit = true;
      // 攻撃手が戻るまでは、画面上の手番を維持したまま着弾結果だけ反映する。
      final next = attack.next.position;
      _session = GameSession(
        GamePosition(
          nearHands: next.nearHands,
          farHands: next.farHands,
          turn: _session.position.turn,
          rules: next.rules,
        ),
        visitedPositions: _session.visitedPositions,
      );
      unawaited(_audio.play(SoundEffect.tapOk));
    }
    if (_motion >= PlayTiming.attack) {
      _session = attack.next;
      _attack = null;
      if (_session.result case final result?) {
        _finish(result);
      } else {
        _beginTurn();
      }
    }
  }

  void _beginTurn() {
    _phase = PlayPhase.selecting;
    _attacker = _target = null;
    _motion = Duration.zero;
    _timer.begin(_clock.now());
    _cpuPlan = null;
    if (_cpuTurn) {
      _timer.pause();
      _requestCpuMove();
    }
  }

  /// CPU戦略へ手を問い合わせる。非同期の結果は、同じ手番の要求にだけ反映する。
  void _requestCpuMove() {
    final random = ref.read(cpuRandomProvider);
    final request = ++_cpuRequest;
    final move = ref.read(cpuStrategyProvider).chooseMove(_session, random);
    if (move is GameMove) {
      _acceptCpuMove(move, random);
      return;
    }
    void accept(GameMove Function() pick) {
      if (!ref.mounted ||
          request != _cpuRequest ||
          _phase == PlayPhase.finished) {
        return;
      }
      _acceptCpuMove(pick(), random);
      _lastTick = _clock.now();
    }

    unawaited(
      move.then(
        (selected) => accept(() => selected),
        // 探索に失敗しても対局を止めず、最初の合法手で進める。
        onError: (Object error, StackTrace stackTrace) {
          AppErrorHandler.recordHandled(
            error,
            stackTrace,
            source: ErrorSource.gameplay,
            message: 'CPU strategy failed; using the first legal move.',
          );
          accept(() => _engine.legalMoves(_session).first);
        },
      ),
    );
  }

  void _acceptCpuMove(GameMove move, Random random) {
    final cpu = cpuSettingsFor(_mode);
    final previews = cpuPreviewMoves(_session, move, cpu, random);
    _cpuPlan = _CpuPlan(
      previews,
      // 攻撃手、対象手、選び直しの表示、決定の順に1操作ずつ進める。
      CpuScheduler(interval: cpu.stepInterval, operations: 2 + previews.length),
    );
  }

  void _tickCpu(Duration elapsed) {
    final plan = _cpuPlan;
    if (plan == null) return;
    final schedule = plan.schedule;
    final ready = schedule.advance(elapsed);
    _timer.setElapsed(schedule.elapsed);
    if (!ready) return;
    switch (schedule.step) {
      case 1:
        _attacker = plan.previews.first.attackerPosition;
        unawaited(_audio.play(SoundEffect.tapHand));
      case 2:
        _target = plan.previews.first.targetPosition;
        unawaited(_audio.play(SoundEffect.tapHand));
      default:
        if (schedule.step == schedule.operations) {
          _confirmMove();
        } else {
          final preview = plan.previews[schedule.step - 2];
          _attacker = preview.attackerPosition;
          _target = preview.targetPosition;
          unawaited(_audio.play(SoundEffect.tapHand));
        }
    }
  }

  bool _checkDeadline() {
    if (_timer.refresh(_clock.now())) {
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

  /// 人間の操作を受け付けられるか確認する。時間切れならここで終局させる。
  bool _acceptsHumanInput() {
    if (!_foreground || _phase != PlayPhase.selecting || _cpuTurn) return false;
    if (_checkDeadline()) {
      _publish();
      return false;
    }
    return true;
  }

  void select(PlayerSide side, HandPosition hand) {
    if (!_acceptsHumanInput()) return;
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
    if (_acceptsHumanInput()) _confirmMove();
  }

  void _confirmMove() {
    if (_attacker == null || _target == null) return;
    final move = GameMove(_attacker!, _target!);
    if (!_engine.isLegalMove(_session, move)) return;
    // 結果はすぐ確定せず、攻撃アニメーション終了時まで保持する。
    _attack = _Attack(_engine.applyMove(_session, move));
    _phase = PlayPhase.attacking;
    _motion = Duration.zero;
    _timer.pause();
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
      _timer.pause();
    }
    _phase = PlayPhase.confirmingExit;
    unawaited(_audio.setPlaySuspended(_audioSuspensionOwner, true));
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
        _timer.remaining != null) {
      _timer.resume(_lastTick);
    }
    unawaited(_audio.play(SoundEffect.tapButton));
    if (_phase == PlayPhase.selecting) _checkDeadline();
    unawaited(_audio.setPlaySuspended(_audioSuspensionOwner, false));
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
    _timer.pause();
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

/// 攻撃アニメーション1回分の状態。
class _Attack {
  _Attack(this.next);

  /// 手を適用した後の対局。アニメーション終了時に確定する。
  final GameSession next;

  /// 着弾（相手の手の値の更新）を反映済みか。
  bool hit = false;
}

/// CPU手番1回分の演出予定。
class _CpuPlan {
  const _CpuPlan(this.previews, this.schedule);

  /// 表示する手の順番。末尾が実際に指す手。
  final List<GameMove> previews;
  final CpuScheduler schedule;
}

/// 1手番の制限時間を管理する内部状態。
class _MatchTimer {
  Duration? _limit;
  Duration? _remaining;
  DateTime? _deadline;

  Duration? get remaining => _remaining;

  void reset(Duration? limit) {
    _limit = limit;
    _remaining = limit;
    _deadline = null;
  }

  void begin(DateTime now) {
    _remaining = _limit;
    _deadline = _limit == null ? null : now.add(_limit!);
  }

  /// 残り時間を保ったまま、時計の進行を止める。
  void pause() => _deadline = null;

  void resume(DateTime now) {
    if (_remaining != null) _deadline = now.add(_remaining!);
  }

  bool refresh(DateTime now) {
    final deadline = _deadline;
    if (deadline == null) return false;
    final left = deadline.difference(now);
    _remaining = left.isNegative ? Duration.zero : left;
    return left <= Duration.zero;
  }

  void setElapsed(Duration elapsed) {
    final limit = _limit;
    if (limit == null) return;
    final left = limit - elapsed;
    _remaining = left.isNegative ? Duration.zero : left;
  }
}
