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
import 'package:that_nameless_game/play/cpu_strategy.dart';
import 'package:that_nameless_game/settings/save_settings.dart';
import 'package:that_nameless_game/settings/settings_state.dart';
import 'package:that_nameless_game/settings/update_settings.dart';

import '../play/play_session_test.dart' show FakeClock;

import 'package:that_nameless_game/play/play_mode.dart';
import 'package:that_nameless_game/config/assets.dart';

void main() {
  for (final mode in [PlayMode.easy, PlayMode.normal, PlayMode.hard]) {
    for (final language in AppLanguage.values) {
      testWidgets(
        '${mode.name} navigation, CPU display and human result ${language.name}',
        (tester) async {
          SharedPreferences.setMockInitialValues({});
          final repository = await SettingsRepository.create();
          final clock = FakeClock();
          var initialTurn = PlayerSide.far;
          final boundaryKey = GlobalKey();
          await tester.binding.setSurfaceSize(const Size(1280, 720));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                settingsRepositoryProvider.overrideWithValue(repository),
                initialSettingsProvider.overrideWithValue(
                  AppSettings.defaults(language),
                ),
                audioControllerProvider.overrideWithValue(
                  AudioController.silent(),
                ),
                playClockProvider.overrideWithValue(clock),
                initialGameProvider.overrideWithValue(
                  () => GameSession(
                    GamePosition(
                      nearHands: [4, 0, 0],
                      farHands: [1, 0, 0],
                      turn: initialTurn,
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
          });
          final label = switch (mode) {
            PlayMode.normal => AppStrings.playNormal(language),
            PlayMode.hard => AppStrings.playHard(language),
            _ => AppStrings.playEasy(language),
          };
          await tester.tap(find.bySemanticsLabel(label));
          await tester.pumpAndSettle();
          final container = ProviderScope.containerOf(
            tester.element(find.byKey(const Key('playScreen'))),
          );
          expect(container.read(playSessionProvider).mode, mode);
          expect(find.byKey(const Key('countdown-true-3')), findsOneWidget);
          expect(find.byKey(const Key('countdown-false-3')), findsNothing);
          clock.advance(4000);
          await tester.pump(const Duration(seconds: 4));
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('confirmMove')), findsNothing);
          if (mode != PlayMode.easy) {
            await tester.runAsync(() async {
              // Exercise the real background isolate, outside FakeAsync.
              await Future<void>.delayed(const Duration(milliseconds: 300));
            });
          }
          expect(
            tester.widget<Text>(find.byKey(const Key('turnTimer'))).data,
            '${cpuSettingsFor(mode).timeLimit.inSeconds}',
          );
          expect(
            find.image(AssetImage(Assets.playLabel('cpu_turn', language))),
            findsOneWidget,
          );
          expect(
            tester
                .widget<GestureDetector>(
                  find.byKey(const Key('hand-near-left')),
                )
                .onTap,
            isNull,
          );
          if (Platform.environment['PLAY_SCREENSHOTS'] == '1') {
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
                'build/play_previews/${mode.name}_cpu_${language.name}.png',
              ).writeAsBytesSync(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
          // A cosmetic reselection adds one visible CPU operation per retry.
          for (var i = 0;
              i < 3 + cpuSettingsFor(mode).maxReselections;
              i++) {
            clock.advance(10000);
            await tester.pump(const Duration(milliseconds: 16));
          }
          clock.advance(800);
          await tester.pump(const Duration(milliseconds: 800));
          await tester.pumpAndSettle();
          expect(
            find.image(AssetImage(Assets.judge('lose', language))),
            findsOneWidget,
          );
          expect(
            find.image(AssetImage(Assets.judge('win', language))),
            findsNothing,
          );
          await tester.tap(find.byKey(const Key('resultHome')));
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('homeScreen')), findsOneWidget);
          initialTurn = PlayerSide.near;
          await tester.tap(find.bySemanticsLabel(label));
          await tester.pumpAndSettle();
          clock.advance(4000);
          await tester.pump(const Duration(seconds: 4));
          await tester.pumpAndSettle();
          final theme = mode.playerColor
              .toARGB32()
              .toRadixString(16)
              .substring(2)
              .toUpperCase();
          expect(
            find.image(
              Assets.image(
                Assets.playBackground(true, easy: true, soloColor: theme),
              ),
            ),
            findsOneWidget,
          );
          if (Platform.environment['PLAY_SCREENSHOTS'] == '1') {
            await tester.runAsync(() async {
              final boundary =
                  boundaryKey.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary;
              final image = await boundary.toImage();
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              File(
                'build/play_previews/${mode.name}_human_${language.name}.png',
              ).writeAsBytesSync(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
          await tester.tap(find.byKey(const Key('hand-near-left')));
          await tester.tap(find.byKey(const Key('hand-far-left')));
          await tester.pump();
          await tester.tap(find.byKey(const Key('confirmMove')));
          clock.advance(800);
          await tester.pump(const Duration(milliseconds: 800));
          await tester.pumpAndSettle();
          expect(
            find.image(AssetImage(Assets.judge('win', language))),
            findsOneWidget,
          );
          await tester.tap(find.byKey(const Key('resultHome')));
          await tester.pumpAndSettle();
          await tester.tap(find.bySemanticsLabel(AppStrings.playTwo(language)));
          await tester.pumpAndSettle();
          final twoContainer = ProviderScope.containerOf(
            tester.element(find.byKey(const Key('playScreen'))),
          );
          expect(
            twoContainer.read(playSessionProvider).mode,
            PlayMode.twoPlayer,
          );
          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
        },
      );
    }
  }
}
