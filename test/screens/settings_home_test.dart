import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:that_nameless_game/settings/update_settings.dart';
import 'package:that_nameless_game/config/config.dart';
import 'package:that_nameless_game/settings/settings_state.dart';
import 'package:that_nameless_game/audio/audio_controller.dart';
import 'package:that_nameless_game/settings/save_settings.dart';
import 'package:that_nameless_game/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('settings are applied immediately and back returns home', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final repository = await SettingsRepository.create();
    final initial = AppSettings.defaults(AppLanguage.jp);

    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(repository),
          audioControllerProvider.overrideWithValue(AudioController.silent()),
          initialSettingsProvider.overrideWithValue(initial),
        ],
        child: const ThatNamelessGame(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('homeScreen')), findsOneWidget);
    final openSettings = tester
        .widget<InkWell>(
          find.descendant(
            of: find.byKey(const Key('settingsButton')),
            matching: find.byType(InkWell),
          ),
        )
        .onTap!;
    // Deliver both callbacks before the next frame can hide the home button.
    openSettings();
    openSettings();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settingsScreen')), findsOneWidget);
    expect(
      find.byKey(const Key('settingsScreen'), skipOffstage: false),
      findsOneWidget,
    );

    await tester.tap(find.text('English'));
    await tester.pump();
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('☆ Language'), findsOneWidget);

    await tester.tap(find.byKey(const Key('settingsHomeButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('homeScreen')), findsOneWidget);

    await tester.pump(AppConfig.tapCooldown);
    await tester.tap(find.byKey(const Key('settingsButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settingsScreen')), findsOneWidget);
    await tester.tap(find.byKey(const Key('settingsHomeButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('homeScreen')), findsOneWidget);
  });

  testWidgets('a non-16:9 viewport is letterboxed in black', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final repository = await SettingsRepository.create();
    await tester.binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(repository),
          audioControllerProvider.overrideWithValue(AudioController.silent()),
          initialSettingsProvider.overrideWithValue(
            AppSettings.defaults(AppLanguage.en),
          ),
        ],
        child: const ThatNamelessGame(),
      ),
    );
    await tester.pumpAndSettle();

    final box = tester.widget<ColoredBox>(
      find
          .byWidgetPredicate(
            (widget) => widget is ColoredBox && widget.color == Colors.black,
          )
          .first,
    );
    expect(box.color, Colors.black);
    expect(
      tester.getSize(find.byKey(const Key('homeScreen'))).aspectRatio,
      16 / 9,
    );
  });
}
