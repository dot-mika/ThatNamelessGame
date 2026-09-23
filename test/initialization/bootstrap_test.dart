import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:that_nameless_game/audio/audio_controller.dart';
import 'package:that_nameless_game/initialization/bootstrap.dart';

import '../audio/fake_audio_player.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'settingsInitialized': true,
      'language': 'jp',
    });
  });

  testWidgets(
    'startup waits for both resources and remembers background state',
    (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      final player = FakeAudioPlayer();
      final audio = AudioController.withPlayers(bgmPlayer: player);
      final audioReady = Completer<AudioController>();
      final imagesReady = Completer<void>();
      await tester.pumpWidget(
        Bootstrap(
          createAudio: () => audioReady.future,
          preloadImages: (_) => imagesReady.future,
          child: const SizedBox(key: Key('ready')),
        ),
      );
      await tester.pump();
      audioReady.complete(audio);
      await tester.pump();
      expect(find.byKey(const Key('ready')), findsNothing);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      imagesReady.complete();
      await tester.pump();
      expect(player.calls, isEmpty);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ready')), findsOneWidget);
      expect(player.calls, ['resume']);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(player.disposed, isTrue);
    },
  );

  testWidgets('audio completing after unmount is disposed without playback', (
    tester,
  ) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final player = FakeAudioPlayer();
    final audio = AudioController.withPlayers(bgmPlayer: player);
    final audioReady = Completer<AudioController>();
    await tester.pumpWidget(
      Bootstrap(
        createAudio: () => audioReady.future,
        preloadImages: (_) async {},
        child: const SizedBox(),
      ),
    );
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    audioReady.complete(audio);
    await tester.pump();
    expect(player.calls, ['dispose']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed startup disposes audio and retry starts only once', (
    tester,
  ) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final players = <FakeAudioPlayer>[];
    var attempts = 0;
    await tester.pumpWidget(
      Bootstrap(
        createAudio: () async {
          final player = FakeAudioPlayer();
          players.add(player);
          return AudioController.withPlayers(bgmPlayer: player);
        },
        preloadImages: (_) async {
          if (++attempts == 1) throw StateError('image load failed');
        },
        child: const SizedBox(key: Key('ready')),
      ),
    );
    await tester.pumpAndSettle();
    expect(players.single.calls, ['dispose']);
    expect(find.text('再試行'), findsOneWidget);
    final retry = tester.widget<TextButton>(find.byType(TextButton)).onPressed!;
    retry();
    retry();
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(players, hasLength(2));
    expect(find.byKey(const Key('ready')), findsOneWidget);
    expect(players.last.playing, isTrue);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(players.last.disposed, isTrue);
  });
}
