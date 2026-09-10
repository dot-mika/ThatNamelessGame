import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:that_nameless_game/audio/audio_controller.dart';
import 'package:that_nameless_game/config/config.dart';
import 'package:that_nameless_game/game/game_engine.dart';
import 'package:that_nameless_game/main.dart';
import 'package:that_nameless_game/initialization/image_preloader.dart';
import 'package:that_nameless_game/play/play_session.dart';
import 'package:that_nameless_game/settings/save_settings.dart';
import 'package:that_nameless_game/settings/settings_state.dart';
import 'package:that_nameless_game/settings/update_settings.dart';

import '../play/play_session_test.dart' show FakeClock;

void main() {
  for (final language in AppLanguage.values) {
    testWidgets(
      '${language.name}: home, countdown, selection, exit, result, replay and star',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final repository = await SettingsRepository.create();
        final clock = FakeClock();
        final boundaryKey = GlobalKey();
        await tester.binding.setSurfaceSize(const Size(1280, 720));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              settingsRepositoryProvider.overrideWithValue(repository),
              initialSettingsProvider.overrideWithValue(
                AppSettings.defaults(
                  language,
                ).copyWith(timeLimit: TimeLimit.seconds5),
              ),
              audioControllerProvider.overrideWithValue(
                AudioController.silent(),
              ),
              playClockProvider.overrideWithValue(clock),
              initialGameProvider.overrideWithValue(
                () => GameSession(
                  GamePosition(
                    nearHands: [1, 2, 3],
                    farHands: [1, 2, 4],
                    turn: PlayerSide.near,
                  ),
                ),
              ),
            ],
            child: RepaintBoundary(
              key: boundaryKey,
              child: const ThatNamelessGame(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          await preloadAllImages(
            tester.element(find.byKey(const Key('homeScreen'))),
          );
          await (FontLoader(
            'Rwi',
          )..addFont(rootBundle.load('assets/font/font.ttf'))).load();
          await (FontLoader('MaterialIcons')
                ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
              .load();
        });
        Future<void> capture(String name) async {
          if (Platform.environment['PLAY_SCREENSHOTS'] != '1') return;
          await tester.runAsync(() async {
            final boundary =
                boundaryKey.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await boundary.toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            Directory('build/play_previews').createSync(recursive: true);
            File(
              'build/play_previews/${name}_${language.name}.png',
            ).writeAsBytesSync(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }

        await tester.pumpAndSettle();
        await tester.tap(find.bySemanticsLabel(AppStrings.playTwo(language)));
        await tester.pump();
        clock.advance(125);
        await tester.pump(const Duration(milliseconds: 125));
        final container = ProviderScope.containerOf(
          tester.element(find.byKey(const Key('playScreen'))),
        );
        expect(container.read(playSessionProvider).countdownStarted, isFalse);
        clock.advance(125);
        await tester.pump(const Duration(milliseconds: 125));
        await tester.pumpAndSettle();
        expect(container.read(playSessionProvider).countdownStarted, isTrue);
        expect(find.byKey(const Key('playScreen')), findsOneWidget);
        expect(find.byKey(const Key('countdown-true-3')), findsOneWidget);
        await capture('countdown');
        clock.advance(999);
        await tester.pump(const Duration(milliseconds: 999));
        expect(find.byKey(const Key('countdown-true-3')), findsOneWidget);
        clock.advance(1);
        // Deliver the next periodic tick after crossing the one-second boundary.
        await tester.pump(const Duration(milliseconds: 16));
        expect(container.read(playSessionProvider).countdown, 2);
        for (var i = 0; i < 3; i++) {
          clock.advance(1000);
          await tester.pump(const Duration(seconds: 1));
        }
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('hand-near-left')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('hand-far-center')));
        await tester.pumpAndSettle();
        expect(
          tester.widget<Text>(find.byKey(const Key('turnTimer'))).data,
          '5',
        );
        await capture('play');
        await tester.tap(find.byKey(const Key('confirmMove')));
        await tester.pump();
        expect(find.byKey(const Key('confirmMove')), findsNothing);
        clock.advance(800);
        await tester.pump(const Duration(milliseconds: 800));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('playHome')));
        await tester.pump();
        expect(
          find.bySemanticsLabel(AppStrings.exitQuestion(language)),
          findsOneWidget,
        );
        await tester.pumpAndSettle();
        await capture('exit');
        clock.advance(6000);
        await tester.pump(const Duration(seconds: 6));
        expect(find.byKey(const Key('resultHome')), findsNothing);
        await tester.tap(find.byKey(const Key('exitNo')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('resultHome')), findsNothing);
        expect(
          tester.widget<Text>(find.byKey(const Key('turnTimer'))).data,
          '5',
        );
        clock.advance(5000);
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('resultHome')), findsOneWidget);
        await capture('result');
        expect(
          (await SharedPreferences.getInstance()).getBool('starTwoPlayer'),
          isNull,
        );
        await tester.tap(find.byKey(const Key('playAgain')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('countdown-true-3')), findsOneWidget);
        expect(
          (await SharedPreferences.getInstance()).getBool('starTwoPlayer'),
          isTrue,
        );
        clock.advance(4000);
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await tester.pump();
        await tester.tap(find.byKey(const Key('exitYes')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('homeScreen')), findsOneWidget);
        await tester.tap(find.bySemanticsLabel(AppStrings.playTwo(language)));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('countdown-true-3')), findsOneWidget);
        clock.advance(4000);
        await tester.pump(const Duration(seconds: 4));
        clock.advance(5000);
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('resultHome')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('homeScreen')), findsOneWidget);
        await capture('home_star');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      },
    );
  }
}
