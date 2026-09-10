import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  }) async {
    SharedPreferences.setMockInitialValues({});
    repository = await SettingsRepository.create();
    clock = FakeClock();
    container = ProviderContainer(
      overrides: [
        playClockProvider.overrideWithValue(clock),
        playModeProvider.overrideWithValue(mode),
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
}
