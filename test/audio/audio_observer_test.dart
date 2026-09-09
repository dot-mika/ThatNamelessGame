import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:that_nameless_game/audio/audio_observer.dart';
import 'package:that_nameless_game/audio/audio_controller.dart';
import 'package:that_nameless_game/settings/settings_state.dart';

import 'fake_audio_player.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  test('remembers background transition before audio is ready', () async {
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final lifecycle = AudioObserver();
    final player = FakeAudioPlayer();
    final audio = AudioController.withPlayers(bgmPlayer: player);
    addTearDown(() async {
      lifecycle.dispose();
      await audio.dispose();
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    });

    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await lifecycle.attach(audio, AppSettings.defaults(AppLanguage.jp));
    expect(player.calls, isEmpty);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);
    expect(player.playing, isTrue);
  });

  test(
    'reads initial lifecycle and does not briefly play disabled BGM',
    () async {
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      final lifecycle = AudioObserver();
      final player = FakeAudioPlayer();
      final audio = AudioController.withPlayers(bgmPlayer: player);
      addTearDown(() async {
        lifecycle.dispose();
        await audio.dispose();
        binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      });
      await lifecycle.attach(
        audio,
        AppSettings.defaults(AppLanguage.jp).copyWith(bgmEnabled: false),
      );
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);
      expect(player.calls, isEmpty);
    },
  );

  test(
    'background transition during attach is applied before settling',
    () async {
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      final lifecycle = AudioObserver();
      final player = FakeAudioPlayer();
      final audio = AudioController.withPlayers(bgmPlayer: player);
      addTearDown(() async {
        lifecycle.dispose();
        await audio.dispose();
        binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      });
      final started = Completer<void>();
      final release = Completer<void>();
      player.onResume = () {
        started.complete();
        return release.future;
      };
      final attach = lifecycle.attach(
        audio,
        AppSettings.defaults(AppLanguage.jp),
      );
      await started.future;
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      release.complete();
      await attach;
      await Future<void>.delayed(Duration.zero);
      expect(player.calls, ['resume', 'pause']);
      expect(player.playing, isFalse);
    },
  );
}
