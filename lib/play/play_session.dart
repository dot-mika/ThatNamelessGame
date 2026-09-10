import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/audio_controller.dart';
import '../config/config.dart';
import '../game/game_engine.dart';
import '../settings/update_settings.dart';
import 'play_mode.dart';

abstract interface class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  @override
  DateTime now() => DateTime.now();
}

final playClockProvider = Provider<Clock>((ref) => SystemClock());
final playModeProvider = Provider<PlayMode>((ref) => PlayMode.twoPlayer);
final initialGameProvider = Provider<GameSession Function()>(
  (ref) => InitialPositionGenerator(Random()).generate,
);
final playSessionProvider =
    NotifierProvider.autoDispose<PlaySessionNotifier, PlayState>(
      PlaySessionNotifier.new,
    );

enum PlayPhase { countdown, selecting, attacking, confirmingExit, finished }

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
  bool get canConfirm =>
      phase == PlayPhase.selecting && attacker != null && target != null;
}

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
  bool _foreground = true, _hit = false;
  bool _countdownStarted = false;
  int _operationId = 0;

  @override
  PlayState build() {
    _clock = ref.read(playClockProvider);
    _audio = ref.read(audioControllerProvider);
    _mode = ref.read(playModeProvider);
    _reset();
    final timer = Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => tick(),
    );
    ref.onDispose(() {
      timer.cancel();
      _operationId++;
      unawaited(_audio.setPlaySuspended(false));
    });
    return _snapshot();
  }

  void _reset() {
    _operationId++;
    _session = ref.read(initialGameProvider)();
    _limit = _mode.timeLimit(ref.read(appSettingsProvider));
    _remaining = _limit;
    _deadline = null;
    _phase = PlayPhase.countdown;
    _suspendedPhase = null;
    _attacker = _target = null;
    _pending = null;
    _result = null;
    _motion = Duration.zero;
    _countdownStarted = false;
    _hit = false;
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
    unawaited(_audio.play(SoundEffect.countdown));
    _publish();
  }

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
    if (!_foreground ||
        (_phase == PlayPhase.countdown && !_countdownStarted) ||
        _phase == PlayPhase.confirmingExit ||
        _phase == PlayPhase.finished) {
      return;
    }
    if (_phase == PlayPhase.selecting) {
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
        unawaited(
          _audio.play(
            _motion.inSeconds == 3 ? SoundEffect.start : SoundEffect.countdown,
          ),
        );
      }
    } else if (_phase == PlayPhase.attacking) {
      if (!_hit && _motion >= const Duration(milliseconds: 600)) {
        _hit = true;
        // Keep the attacker's turn visible until the hand has returned.
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
  }

  bool _checkDeadline() {
    if (_deadline == null) return false;
    final left = _deadline!.difference(_clock.now());
    _remaining = left.isNegative ? Duration.zero : left;
    if (left <= Duration.zero) {
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
    if (!_foreground || _phase != PlayPhase.selecting) return;
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
    if (!_foreground || _phase != PlayPhase.selecting) return;
    if (_checkDeadline()) {
      _publish();
      return;
    }
    if (_attacker == null || _target == null) return;
    final move = GameMove(_attacker!, _target!);
    if (!_engine.isLegalMove(_session, move)) return;
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
    if (_phase == PlayPhase.finished && _mode.earnsStar(_result!)) {
      await ref.read(appSettingsProvider.notifier).awardStar(_mode.starMode);
    }
  }

  void replay(int operationId) {
    if (_phase != PlayPhase.finished || operationId != _operationId) return;
    _reset();
    _publish();
  }
}
