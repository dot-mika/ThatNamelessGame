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

/// 実時間の取得を抽象化するテストではFakeClockへ差し替える
abstract interface class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  @override
  DateTime now() => DateTime.now();
}

/// 対局演出の時間進行判定と表示計算で同じ値を使う
abstract final class PlayTiming {
  /// カウントダウンの最初の数字
  static const countdownFrom = 3;

  /// 「3・2・1・スタート」それぞれの表示とSE開始の間隔
  static const countdownStep = Duration(seconds: 1);

  /// 「3・2・1・スタート」を同じ間隔ずつ表示する合計時間
  static final countdown = countdownStep * (countdownFrom + 1);

  /// 攻撃手が相手の手に届き、値が変わる時点
  static const attackHit = Duration(milliseconds: 600);

  /// 攻撃手が元の位置へ戻り終わるまでの時間
  static const attack = Duration(milliseconds: 800);

  /// 進行を確認する間隔経過時間は実時計で測る
}

/// 対局画面が描画・操作判断に使う進行フェーズ
enum PlayPhase { countdown, selecting, attacking, confirmingExit, finished }

/// 対局進行をUIへ渡す不変のスナップショット
class PlayState {
  const PlayState({
    required this.mode,
    required this.session,
    required this.phase,
    required this.remaining,
    required this.countdown,
    required this.countdownStarted,
    required this.attacking,
    required this.attackPaused,
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

  /// 攻撃アニメーション中か終了確認で一時停止している間もtrue
  final bool attacking;
  final bool attackPaused;
  final int operationId;
  final HandPosition? attacker;
  final HandPosition? target;
  final GameResult? result;

  /// 攻撃側と対象側の手が両方選ばれているか判定する
  bool get canConfirm => canSelect && attacker != null && target != null;

  /// 現在の手番を人間が選択操作できるか判定する
  bool get canSelect =>
      phase == PlayPhase.selecting && mode.isHuman(session.position.turn);
}

/// 対局に必要な依存をProviderとして切り出し、画面ごとのモードと
/// テスト用の偽物を安全に差し替えられるようにする
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

/// モードに応じた初期局面の作り方ふつう・むずかしいだけ28局面プールを使う
final initialGameProvider = Provider<GameSession Function()>((ref) {
  final mode = ref.watch(playModeProvider);
  final random = ref.watch(cpuRandomProvider);
  return switch (mode) {
    PlayMode.normal ||
    PlayMode.hard => SoloInitialPositionGenerator(random).generate,
    _ => InitialPositionGenerator(random).generate,
  };
}, dependencies: [playModeProvider, cpuRandomProvider]);
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

/// カウントダウンから結果画面まで、対局の時間軸を管理する司令塔
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
  HandPosition? _attacker, _target;
  GameResult? _result;

  /// カウントダウンと攻撃アニメーションの経過時間
  Duration _motion = Duration.zero;
  bool _foreground = true, _resultCommitted = false;
  bool _countdownStarted = false;
  bool _exitConfirming = false;
  int _operationId = 0;

  /// 攻撃アニメーション中の適用後局面攻撃中以外はnull
  _Attack? _attack;

  /// CPUの手が決まった後の演出予定決まるまではnull
  _CpuPlan? _cpuPlan;
  int _cpuRequest = 0;
  Timer? _scheduledTick;
  bool get _cpuTurn => !_mode.isHuman(_session.position.turn);
  bool get _isHalted =>
      !_foreground ||
      (_phase == PlayPhase.countdown && !_countdownStarted) ||
      _exitConfirming ||
      _phase == PlayPhase.finished;

  void _resetTickClock() => _lastTick = _clock.now();

  @override
  PlayState build() {
    _clock = ref.read(playClockProvider);
    _audio = ref.read(audioControllerProvider);
    _mode = ref.read(playModeProvider);
    _reset();
    // tick自体は実経過時間を使うTimerは進行を確認する契機にすぎない
    ref.onDispose(() {
      _scheduledTick?.cancel();
      _operationId++;
      _cpuRequest++;
      unawaited(_audio.setPlaySuspended(_audioSuspensionOwner, false));
    });
    return _snapshot();
  }

  void _reset() {
    _scheduledTick?.cancel();
    // 古い非同期CPU計算と画面コールバックを、新しい対局へ反映させない
    _cpuRequest++;
    _operationId++;
    _session = ref.read(initialGameProvider)();
    _timer.reset(
      _mode.isTwoPlayer
          ? ref.read(appSettingsProvider).timeLimit.duration
          : cpuSettingsFor(_mode).timeLimit,
    );
    _phase = PlayPhase.countdown;
    _exitConfirming = false;
    _attacker = _target = null;
    _attack = null;
    _cpuPlan = null;
    _result = null;
    _motion = Duration.zero;
    _countdownStarted = false;
    _resultCommitted = false;
    _resetTickClock();
    unawaited(_audio.setPlaySuspended(_audioSuspensionOwner, true));
  }

  /// 画面遷移後の最初の描画完了を受け取り、カウントダウンを開始する
  void startCountdown(int operationId) {
    if (operationId != _operationId ||
        _phase != PlayPhase.countdown ||
        _countdownStarted ||
        !_foreground) {
      return;
    }
    _countdownStarted = true;
    _resetTickClock();
    // 最初の「3」の表示開始とSE発火を同じ境界に揃える
    unawaited(_audio.playCountdownCue(SoundEffect.countdown));
    _publish();
  }

  /// 現在表示すべきカウントダウンの数字0は「スタート」
  int get _countdownValue =>
      (PlayTiming.countdownFrom -
              (_motion.inMicroseconds ~/
                  PlayTiming.countdownStep.inMicroseconds))
          .clamp(0, PlayTiming.countdownFrom);

  /// 内部の可変フィールドを、画面へ公開する不変のPlayStateへ変換する
  PlayState _snapshot() => PlayState(
    mode: _mode,
    session: _session,
    phase: _exitConfirming ? PlayPhase.confirmingExit : _phase,
    remaining: _timer.displayedRemaining,
    countdown: _countdownValue,
    countdownStarted: _countdownStarted,
    attacking: _attack != null,
    attackPaused: _attack != null && (!_foreground || _exitConfirming),
    operationId: _operationId,
    attacker: _attacker,
    target: _target,
    result: _result,
  );
  void _publish() {
    state = _snapshot();
    _scheduleTick();
  }

  /// 次にゲーム状態が変わる時刻だけを一度予約する描画フレームは
  /// PlayScreen の AnimationController が担当する
  void _scheduleTick() {
    _scheduledTick?.cancel();
    if (_isHalted) {
      return;
    }
    final now = _clock.now();
    Duration? delay;
    if (_phase == PlayPhase.countdown) {
      delay = _until(_motion, PlayTiming.countdownStep);
    } else if (_phase == PlayPhase.attacking) {
      delay = _motion < PlayTiming.attackHit
          ? PlayTiming.attackHit - _motion
          : PlayTiming.attack - _motion;
    } else if (_cpuTurn) {
      delay = _cpuPlan?.schedule.untilNext;
    } else {
      delay = _timer.untilNextDisplayUpdate(now);
    }
    if (delay == null) return;
    _scheduledTick = Timer(delay.isNegative ? Duration.zero : delay, tick);
  }

  Duration _until(Duration elapsed, Duration interval) {
    final remainder = elapsed.inMicroseconds % interval.inMicroseconds;
    return remainder == 0 ? interval : interval - Duration(microseconds: remainder);
  }

  void tick() {
    final now = _clock.now();
    final elapsed = now.difference(_lastTick);
    _lastTick = now;
    // 背景中、カウントダウン開始前、モーダル中、終局後は進行を止める
    if (_isHalted) {
      return;
    }
    if (_phase == PlayPhase.selecting) {
      if (_cpuTurn) {
        // CPU手番は人間用の制限時間ではなく、演出用スケジュールを進める
        if (_tickCpu(elapsed)) {
          _publish();
        } else {
          _scheduleTick();
        }
        return;
      }
      final previous = _timer.displayedRemaining;
      _checkDeadline();
      if (previous != _timer.displayedRemaining || _result != null) {
        _publish();
      } else {
        _scheduleTick();
      }
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
      // 数字が変わった瞬間だけ、表示と同期した即時SEを鳴らす
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
      // 攻撃手が戻るまでは、画面上の手番を維持したまま着弾結果だけ反映する
      _session = attack.intermediateSession(_session);
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

  /// CPU戦略へ手を問い合わせる非同期の結果は、同じ手番の要求にだけ反映する
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
      _resetTickClock();
    }

    unawaited(
      move.then(
        (selected) => accept(() => selected),
        // 探索に失敗しても対局を止めず、最初の合法手で進める
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
      // 攻撃手、対象手、選び直しの表示、決定の順に1操作ずつ進める
      CpuScheduler(interval: cpu.stepInterval, operations: 2 + previews.length),
    );
    _resetTickClock();
    _scheduleTick();
  }

  bool _tickCpu(Duration elapsed) {
    final plan = _cpuPlan;
    if (plan == null) return false;
    final schedule = plan.schedule;
    final ready = schedule.advance(elapsed);
    _timer.setElapsed(schedule.elapsed);
    if (!ready) return false;
    if (schedule.step == schedule.operations) {
      _confirmMove();
    } else if (plan.selectionAt(schedule.step) case final selection?) {
      _attacker = selection.attacker;
      _target = selection.target;
      unawaited(_audio.play(SoundEffect.tapHand));
    }
    return true;
  }

  bool _checkDeadline() {
    if (_timer.refresh(_clock.now())) {
      // 決定操作直前にもここを呼ぶため、遅延フレームでも時間切れを優先できる
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

  /// 人間の操作を受け付けられるか確認する時間切れならここで終局させる
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
    // 結果はすぐ確定せず、攻撃アニメーション終了時まで保持する
    _attack = _Attack(_engine.applyMove(_session, move));
    _phase = PlayPhase.attacking;
    _motion = Duration.zero;
    _timer.pause();
    _resetTickClock();
    _publish();
  }

  void requestExit() {
    if (!_foreground ||
        (_phase != PlayPhase.selecting && _phase != PlayPhase.attacking)) {
      return;
    }
    tick();
    if (_phase == PlayPhase.finished) return;
    // 2人対戦では終了確認中に時間を止める1人プレイ人間手番は止めない
    if (_phase == PlayPhase.selecting &&
        _mode.pausesTimerForExit(_session.position.turn)) {
      _timer.pause();
    }
    _exitConfirming = true;
    unawaited(_audio.setPlaySuspended(_audioSuspensionOwner, true));
    unawaited(_audio.play(SoundEffect.tapButton));
    _publish();
  }

  void cancelExit() {
    if (!_exitConfirming) return;
    _exitConfirming = false;
    _resetTickClock();
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
    _resetTickClock();
    if (foreground && _phase == PlayPhase.selecting) {
      _checkDeadline();
    }
    _publish();
  }

  void _finish(GameResult result) {
    _phase = PlayPhase.finished;
    _result = result;
    _timer.pause();
    unawaited(_audio.playResult(_mode.resultSound(result)));
  }

  Future<void> commitResult() async {
    if (_phase == PlayPhase.finished && !_resultCommitted) {
      // ホームとリトライの連打で、星の進捗を二重保存しない
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

/// 攻撃アニメーション1回分の状態
class _Attack {
  _Attack(this.next);

  /// 手を適用した後の対局アニメーション終了時に確定する
  final GameSession next;

  /// 着弾（相手の手の値の更新）を反映済みか
  bool hit = false;

  GameSession intermediateSession(GameSession current) {
    final nextPosition = next.position;
    return GameSession(
      GamePosition(
        nearHands: nextPosition.nearHands,
        farHands: nextPosition.farHands,
        turn: current.position.turn,
        rules: nextPosition.rules,
      ),
      visitedPositions: current.visitedPositions,
    );
  }
}

/// CPU手番1回分の演出予定
class _CpuPlan {
  const _CpuPlan(this.previews, this.schedule);

  /// 表示する手の順番末尾が実際に指す手
  final List<GameMove> previews;
  final CpuScheduler schedule;

  _CpuSelection? selectionAt(int step) {
    if (step == 1) {
      final first = previews.first;
      return _CpuSelection(first.attackerPosition, null);
    }
    if (step == 2) {
      final first = previews.first;
      return _CpuSelection(first.attackerPosition, first.targetPosition);
    }
    final previewIndex = step - 2;
    return previewIndex < previews.length
        ? _CpuSelection.fromMove(previews[previewIndex])
        : null;
  }
}

class _CpuSelection {
  const _CpuSelection(this.attacker, this.target);
  _CpuSelection.fromMove(GameMove move)
      : attacker = move.attackerPosition,
        target = move.targetPosition;

  final HandPosition attacker;
  final HandPosition? target;
}

/// 1手番の制限時間を管理する内部状態
class _MatchTimer {
  Duration? _limit;
  Duration? _remaining;
  DateTime? _deadline;

  Duration? get remaining => _remaining;

  /// UI に公開する値は表示が変わる秒単位に丸める
  Duration? get displayedRemaining {
    final remaining = _remaining;
    if (remaining == null) return null;
    return Duration(seconds: (remaining.inMilliseconds / 1000).ceil());
  }

  /// 表示秒が変わる境界、または期限そのものまでの待ち時間
  Duration? untilNextDisplayUpdate(DateTime now) {
    final deadline = _deadline;
    if (deadline == null) return null;
    final remaining = deadline.difference(now);
    if (remaining <= Duration.zero) return Duration.zero;
    final seconds = (remaining.inMilliseconds / 1000).ceil();
    return remaining - Duration(seconds: seconds - 1);
  }

  void reset(Duration? limit) {
    _limit = limit;
    _remaining = limit;
    _deadline = null;
  }

  void begin(DateTime now) {
    _remaining = _limit;
    _deadline = _limit == null ? null : now.add(_limit!);
  }

  /// 残り時間を保ったまま、時計の進行を止める
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
