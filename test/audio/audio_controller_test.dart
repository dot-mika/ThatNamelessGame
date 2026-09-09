import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:that_nameless_game/audio/audio_controller.dart';
import 'package:that_nameless_game/config/config.dart';

import 'fake_audio_player.dart';

void main() {
  test(
    'OFF during an in-flight resume stops BGM after resume completes',
    () async {
      final player = FakeAudioPlayer();
      final audio = AudioController.withPlayers(bgmPlayer: player);
      addTearDown(audio.dispose);
      final started = Completer<void>();
      final release = Completer<void>();
      player.onResume = () {
        started.complete();
        return release.future;
      };

      final enable = audio.setBgmEnabled(true);
      await started.future;
      final disable = audio.setBgmEnabled(false);
      release.complete();
      await Future.wait([enable, disable]);

      expect(player.calls, ['resume', 'pause']);
      expect(player.playing, isFalse);
    },
  );

  test(
    'foreground return during pause restores the latest BGM state',
    () async {
      final player = FakeAudioPlayer();
      final audio = AudioController.withPlayers(bgmPlayer: player);
      addTearDown(audio.dispose);
      await audio.setBgmEnabled(true);
      final started = Completer<void>();
      final release = Completer<void>();
      player.onPause = () {
        started.complete();
        return release.future;
      };

      final background = audio.setForeground(false);
      await started.future;
      final foreground = audio.setForeground(true);
      release.complete();
      await Future.wait([background, foreground]);

      expect(player.calls, ['resume', 'pause', 'resume']);
      expect(player.playing, isTrue);
    },
  );

  test(
    'disposal drains in-flight commands and rejects subsequent commands',
    () async {
      final player = FakeAudioPlayer();
      final audio = AudioController.withPlayers(bgmPlayer: player);
      final started = Completer<void>();
      final release = Completer<void>();
      player.onResume = () {
        started.complete();
        return release.future;
      };

      final enable = audio.setBgmEnabled(true);
      await started.future;
      final disable = audio.setBgmEnabled(false);
      final dispose = audio.dispose();
      expect(player.disposed, isFalse);
      release.complete();
      await Future.wait([enable, disable, dispose, audio.dispose()]);
      await audio.setForeground(true);
      await audio.setBgmEnabled(true);
      await audio.play(SoundEffect.tapButton);

      expect(player.calls, ['resume', 'dispose']);
    },
  );

  test('a failed BGM command does not block the next update', () async {
    final player = FakeAudioPlayer();
    final audio = AudioController.withPlayers(bgmPlayer: player);
    addTearDown(audio.dispose);
    await audio.setBgmEnabled(true);
    player.onPause = () async {
      throw StateError('pause failed');
    };
    await audio.setBgmEnabled(false);
    player.onPause = null;
    await audio.setBgmEnabled(false);
    expect(player.calls, ['resume', 'pause', 'pause']);
    expect(player.playing, isFalse);
  });

  test('an effect does not resume if disposed while stop is pending', () async {
    final player = FakeAudioPlayer();
    final audio = AudioController.withPlayers(
      effectPlayers: {SoundEffect.tapButton: player},
    );
    final started = Completer<void>();
    final release = Completer<void>();
    player.onStop = () {
      started.complete();
      return release.future;
    };
    final play = audio.play(SoundEffect.tapButton);
    await started.future;
    final dispose = audio.dispose();
    release.complete();
    await Future.wait([play, dispose]);
    expect(player.calls, ['stop', 'dispose']);
  });

  test(
    'result sound suppresses BGM until completion and uses latest settings',
    () async {
      final bgm = FakeAudioPlayer();
      final effect = FakeAudioPlayer();
      final audio = AudioController.withPlayers(
        bgmPlayer: bgm,
        effectPlayers: {SoundEffect.win: effect},
      );
      addTearDown(audio.dispose);
      await audio.setBgmEnabled(true);
      final started = Completer<void>();
      effect.onResume = () async {
        started.complete();
      };
      final result = audio.playResult(SoundEffect.win);
      await started.future;
      await audio.setBgmEnabled(false);
      await audio.setBgmEnabled(true);
      expect(bgm.playing, isFalse);
      effect.completion.add(null);
      await result;
      expect(bgm.calls, ['resume', 'pause', 'resume']);
    },
  );

  test(
    'disposal cancels result completion wait without restarting BGM',
    () async {
      final bgm = FakeAudioPlayer();
      final effect = FakeAudioPlayer();
      final audio = AudioController.withPlayers(
        bgmPlayer: bgm,
        effectPlayers: {SoundEffect.win: effect},
      );
      await audio.setBgmEnabled(true);
      final started = Completer<void>();
      effect.onResume = () async {
        started.complete();
      };
      final result = audio.playResult(SoundEffect.win);
      await started.future;
      await audio.dispose();
      await result;
      expect(bgm.calls, ['resume', 'pause', 'dispose']);
    },
  );
}
