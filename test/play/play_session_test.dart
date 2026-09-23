import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:that_nameless_game/play/cpu_strategy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:that_nameless_game/audio/audio_controller.dart';
import 'package:that_nameless_game/config/config.dart';
import 'package:that_nameless_game/game/game_engine.dart';
import 'package:that_nameless_game/play/play_session.dart';
import 'package:that_nameless_game/play/play_mode.dart';
import 'package:that_nameless_game/settings/save_settings.dart';
import 'package:that_nameless_game/settings/settings_state.dart';
import 'package:that_nameless_game/settings/update_settings.dart';
import '../audio/fake_audio_player.dart';

class FakeClock implements Clock {
  DateTime value = DateTime(2026);
  @override
  DateTime now() => value;
  void advance(int milliseconds) =>
      value = value.add(Duration(milliseconds: milliseconds));
}

class PendingCpu implements CpuStrategy {
  final result = Completer<GameMove>();
  @override
  Future<GameMove> chooseMove(GameSession session, Random random) =>
      result.future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ProviderContainer container;
  late FakeClock clock;
  late PlaySessionNotifier controller;
  late SettingsRepository repository;
  Future<void> setup({
    TimeLimit limit = TimeLimit.seconds5,
    GameSession? game,
    AudioController? audio,
    bool startCountdown = true,
    PlayMode mode = PlayMode.twoPlayer,
    CpuStrategy? strategy,
  }) async {
    SharedPreferences.setMockInitialValues({});
    repository = await SettingsRepository.create();
    clock = FakeClock();
    container = ProviderContainer(
      overrides: [
        playClockProvider.overrideWithValue(clock),
        playModeProvider.overrideWithValue(mode),
        if (strategy != null) cpuStrategyProvider.overrideWithValue(strategy),
        initialGameProvider.overrideWithValue(
          () =>
              game ??
              GameSession(
                GamePosition(
                  nearHands: [1, 1, 1],
                  farHands: [1, 1, 1],
                  turn: PlayerSide.near,
                ),
              ),
        ),
        audioControllerProvider.overrideWithValue(
          audio ?? AudioController.silent(),
        ),
        settingsRepositoryProvider.overrideWithValue(repository),
        initialSettingsProvider.overrideWithValue(
          AppSettings.defaults(AppLanguage.jp).copyWith(timeLimit: limit),
        ),
      ],
    );
    container.listen(playSessionProvider, (_, _) {});
    controller = container.read(playSessionProvider.notifier);
    if (startCountdown) {
      controller.startCountdown(
        container.read(playSessionProvider).operationId,
      );
    }
    addTearDown(container.dispose);
  }

  PlayState state() => container.read(playSessionProvider);
  void advance(int ms) {
    clock.advance(ms);
    controller.tick();
  }

  void select() {
    controller.select(PlayerSide.near, HandPosition.left);
    controller.select(PlayerSide.far, HandPosition.left);
  }

  for (final mode in [PlayMode.normal, PlayMode.hard]) {
    test(
      '${mode.name}: async result waits through exit and background pause',
      () async {
        final cpu = PendingCpu();
        await setup(
          mode: mode,
          strategy: cpu,
          game: GameSession(
            GamePosition(
              nearHands: [3, 0, 0],
              farHands: [2, 0, 0],
              turn: PlayerSide.far,
            ),
          ),
        );
        advance(4000);
        controller.requestExit();
        cpu.result.complete(
          const GameMove(HandPosition.left, HandPosition.left),
        );
        await Future<void>.delayed(Duration.zero);
        advance(5000);
        expect(state().attacker, isNull);
        controller.cancelExit();
        controller.setForeground(false);
        advance(5000);
        controller.setForeground(true);
        expect(state().attacker, isNull);
        for (var i = 0; i < 3; i++) {
          advance(cpuSettingsFor(mode).stepInterval.inMilliseconds);
        }
        expect(state().phase, PlayPhase.attacking);
        advance(800);
        expect(state().result!.outcome, GameOutcome.farWin);
        await controller.commitResult();
        expect(
          container.read(appSettingsProvider).hasStar(mode.starMode),
          false,
        );
      },
    );
  }
  test('late CPU result is ignored after provider disposal', () async {
    final cpu = PendingCpu();
    await setup(
      mode: PlayMode.hard,
      strategy: cpu,
      game: GameSession(
        GamePosition(
          nearHands: [3, 0, 0],
          farHands: [2, 0, 0],
          turn: PlayerSide.far,
        ),
      ),
    );
    advance(4000);
    container.invalidate(playSessionProvider);
    cpu.result.complete(const GameMove(HandPosition.left, HandPosition.left));
    await Future<void>.delayed(Duration.zero);
    expect(state().phase, PlayPhase.countdown);
    expect(state().attacker, isNull);
  });

  for (final mode in [PlayMode.twoPlayer, PlayMode.easy]) {
    test(
      '${mode.name}: one hand each continues after attack animation',
      () async {
        await setup(
          mode: mode,
          game: GameSession(
            GamePosition(
              nearHands: [2, 0, 0],
              farHands: [3, 0, 1],
              turn: PlayerSide.near,
            ),
          ),
        );
        advance(4000);
        select();
        controller.confirm();
        advance(600);
        expect(state().phase, PlayPhase.attacking);
        expect(state().result, isNull);
        advance(200);
        expect(state().phase, PlayPhase.selecting);
        expect(state().result, isNull);
        expect(state().session.position.nearHands, [2, 0, 0]);
        expect(state().session.position.farHands, [0, 0, 1]);
      },
    );
  }

  test(
    'four countdown screens block input and start full turn limit',
    () async {
      await setup();
      for (var count = 3; count >= 0; count--) {
        expect(state().countdown, count);
        select();
        controller.confirm();
        controller.requestExit();
        expect(state().phase, PlayPhase.countdown);
        expect(state().attacker, isNull);
        advance(1000);
      }
      expect(state().phase, PlayPhase.selecting);
      expect(state().remaining, const Duration(seconds: 5));
    },
  );
  test(
    'loading and route transition do not shorten the first countdown',
    () async {
      await setup(startCountdown: false);
      advance(5250);
      expect(state().countdown, 3);
      expect(state().countdownStarted, isFalse);
      final id = state().operationId;
      controller.startCountdown(id - 1);
      expect(state().countdownStarted, isFalse);
      controller.startCountdown(id);
      advance(999);
      expect(state().countdown, 3);
      controller.startCountdown(
        id,
      ); // Duplicate frame acknowledgements do not reset time.
      advance(1);
      expect(state().countdown, 2);
    },
  );
  test(
    'countdown plays three beeps then start, with BGM paused until play',
    () async {
      final events = <String>[];
      final bgm = FakeAudioPlayer()
        ..onResume = () async {
          events.add('bgm resume');
        }
        ..onPause = () async {
          events.add('bgm pause');
        };
      final countdown = FakeAudioPlayer()
        ..onResume = () async {
          events.add('countdown');
        };
      final start = FakeAudioPlayer()
        ..onResume = () async {
          events.add('start');
        };
      final audio = AudioController.withPlayers(
        bgmPlayer: bgm,
        effectPlayers: {
          SoundEffect.countdown: countdown,
          SoundEffect.start: start,
        },
      );
      addTearDown(audio.dispose);
      await audio.setBgmEnabled(true);
      events.clear();
      await setup(audio: audio);
      await audio.setForeground(true); // Drain queued audio commands.
      expect(events, ['bgm pause', 'countdown']);
      for (var second = 1; second <= 4; second++) {
        advance(1000);
        await audio.setForeground(true);
      }
      expect(events, [
        'bgm pause',
        'countdown',
        'countdown',
        'countdown',
        'start',
        'bgm resume',
      ]);
      expect(state().phase, PlayPhase.selecting);
    },
  );
  test('deadline wins over confirm even before a timer callback', () async {
    await setup();
    advance(4000);
    select();
    clock.advance(5000);
    controller.confirm();
    expect(state().result!.reason, GameEndReason.timeout);
    expect(state().result!.outcome, GameOutcome.farWin);
    expect(state().session.position.farHands, [1, 1, 1]);
    expect(container.read(appSettingsProvider).star2p, isFalse);
    await controller.commitResult();
    expect(
      (await SharedPreferences.getInstance()).getBool('starTwoPlayer'),
      isTrue,
    );
  });
  test(
    'attack hits once at 600ms, completes at 800ms, then resets timer',
    () async {
      await setup();
      advance(4000);
      select();
      controller.confirm();
      controller.confirm();
      advance(599);
      expect(state().session.position.farHands, [1, 1, 1]);
      advance(1);
      expect(state().session.position.farHands, [2, 1, 1]);
      expect(state().session.position.turn, PlayerSide.near);
      advance(200);
      expect(state().session.position.turn, PlayerSide.far);
      expect(state().remaining, const Duration(seconds: 5));
      expect(state().attacker, isNull);
      expect(state().session.visitedPositions, hasLength(2));
    },
  );
  test(
    'two-player exit pauses the timer including background time and gives no star',
    () async {
      await setup();
      advance(4000);
      advance(1000);
      controller.requestExit();
      controller.setForeground(false);
      advance(20000);
      controller.setForeground(true);
      expect(state().phase, PlayPhase.confirmingExit);
      expect(state().remaining, const Duration(seconds: 4));
      await controller.commitResult();
      expect(container.read(appSettingsProvider).star2p, isFalse);
      controller.cancelExit();
      expect(state().phase, PlayPhase.selecting);
      expect(state().remaining, const Duration(seconds: 4));
      advance(1000);
      controller.requestExit();
      advance(10000);
      controller.cancelExit();
      expect(state().remaining, const Duration(seconds: 3));
      advance(2999);
      expect(state().result, isNull);
      advance(1);
      expect(state().result!.reason, GameEndReason.timeout);
    },
  );
  test('solo human exit still includes elapsed time', () async {
    await setup(mode: PlayMode.easy);
    advance(4000);
    controller.requestExit();
    advance(30000);
    controller.cancelExit();
    expect(state().result!.reason, GameEndReason.timeout);
  });
  test(
    'background counts for selecting but pauses countdown and attack',
    () async {
      await setup();
      advance(500);
      controller.setForeground(false);
      advance(20000);
      controller.setForeground(true);
      advance(500);
      expect(state().countdown, 2);
      advance(3000);
      select();
      controller.confirm();
      advance(400);
      controller.setForeground(false);
      advance(20000);
      controller.setForeground(true);
      expect(state().attackProgress, .5);
      advance(400);
      expect(state().session.position.turn, PlayerSide.far);
      controller.setForeground(false);
      advance(5000);
      controller.setForeground(true);
      expect(state().result!.outcome, GameOutcome.nearWin);
    },
  );
  test(
    'exit during attack resumes remaining motion without consuming turn time',
    () async {
      await setup();
      advance(4000);
      select();
      controller.confirm();
      advance(300);
      controller.requestExit();
      advance(20000);
      controller.cancelExit();
      expect(state().attackProgress, .375);
      advance(500);
      expect(state().phase, PlayPhase.selecting);
      expect(state().remaining, const Duration(seconds: 5));
    },
  );
  test('unlimited has no deadline, selections can change', () async {
    await setup(limit: TimeLimit.unlimited);
    advance(4000);
    advance(999999);
    select();
    controller.select(PlayerSide.near, HandPosition.right);
    expect(state().attacker, HandPosition.right);
    expect(state().remaining, isNull);
    expect(state().phase, PlayPhase.selecting);
  });
  test(
    'elimination is deferred until attack ends; replay rejects stale operation',
    () async {
      await setup(
        game: GameSession(
          GamePosition(
            nearHands: [2, 0, 0],
            farHands: [3, 0, 0],
            turn: PlayerSide.near,
          ),
        ),
      );
      advance(4000);
      select();
      controller.confirm();
      advance(600);
      expect(state().phase, PlayPhase.attacking);
      expect(state().result, isNull);
      advance(200);
      expect(state().result!.reason, GameEndReason.eliminated);
      final id = state().operationId;
      await controller.commitResult();
      controller.replay(id);
      expect(state().phase, PlayPhase.countdown);
      controller.replay(id);
      expect(state().operationId, id + 1);
      expect(state().session.visitedPositions, hasLength(1));
      expect(container.read(appSettingsProvider).star2p, isTrue);
    },
  );
  test(
    'easy CPU ignores input, pauses in background and exit, then attacks',
    () async {
      await setup(
        mode: PlayMode.easy,
        game: GameSession(
          GamePosition(
            nearHands: [1, 1, 1],
            farHands: [1, 1, 1],
            turn: PlayerSide.far,
          ),
        ),
      );
      advance(4000);
      select();
      controller.confirm();
      expect(state().attacker, isNull);
      expect(state().canSelect, isFalse);
      advance(500);
      final remaining = state().remaining;
      controller.setForeground(false);
      advance(60000);
      controller.setForeground(true);
      expect(state().remaining, remaining);
      controller.requestExit();
      advance(60000);
      controller.cancelExit();
      expect(state().remaining, remaining);
      for (var i = 0; i < 1000 && state().phase == PlayPhase.selecting; i++) {
        advance(10);
      }
      expect(state().phase, PlayPhase.attacking);
      expect(state().attacker, isNotNull);
      expect(state().target, isNotNull);
      controller.setForeground(false);
      advance(60000);
      controller.setForeground(true);
      advance(800);
      expect(state().session.position.turn, PlayerSide.near);
      expect(state().remaining, const Duration(seconds: 30));
      expect(state().session.position.nearHands.reduce((a, b) => a + b), 4);
      controller.setForeground(false);
      advance(30000);
      controller.setForeground(true);
      expect(state().result!.outcome, GameOutcome.farWin);
      await controller.commitResult();
      expect(container.read(appSettingsProvider).starEasy, isFalse);
    },
  );

  for (final mode in [PlayMode.easy, PlayMode.normal, PlayMode.hard]) {
    test(
      '${mode.name}: human victory persists only own star and replay starts fresh',
      () async {
        await setup(
          mode: mode,
          game: GameSession(
            GamePosition(
              nearHands: [2, 0, 0],
              farHands: [3, 0, 0],
              turn: PlayerSide.near,
            ),
          ),
        );
        advance(4000);
        select();
        controller.confirm();
        advance(800);
        expect(state().result!.outcome, GameOutcome.nearWin);
        expect(
          container.read(appSettingsProvider).hasStar(mode.starMode),
          isFalse,
        );
        await controller.commitResult();
        expect(
          container.read(appSettingsProvider).hasStar(mode.starMode),
          isTrue,
        );
        expect(container.read(appSettingsProvider).star2p, isFalse);
        expect(
          (await repository.loadOrCreate()).hasStar(mode.starMode),
          isTrue,
        );
        controller.replay(state().operationId);
        expect(state().phase, PlayPhase.countdown);
        expect(
          state().remaining,
          mode.isTwoPlayer
              ? container.read(appSettingsProvider).timeLimit.duration
              : cpuSettingsFor(mode).timeLimit,
        );
      },
    );
  }
}
