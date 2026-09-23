import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:that_nameless_game/config/config.dart';
import 'package:that_nameless_game/config/assets.dart';
import 'package:that_nameless_game/screens/widgets/tappable_image.dart';

void main() {
  testWidgets('ignores rapid taps and accepts taps after cooldown', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: TappableImage(
          asset: Assets.settingsIcon,
          onTap: () {
            calls++;
          },
        ),
      ),
    );
    final button = find.byType(TappableImage);
    await tester.tap(button);
    await tester.tap(button);
    expect(calls, 1);
    await tester.pump(AppConfig.tapCooldown);
    await tester.tap(button);
    expect(calls, 2);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('blocks taps until async action completes, even after rebuild', (
    tester,
  ) async {
    var calls = 0;
    final pending = Completer<void>();
    Widget buildButton(double opacity) => MaterialApp(
      home: TappableImage(
        asset: Assets.settingsIcon,
        opacity: opacity,
        onTap: () async {
          calls++;
          await pending.future;
        },
      ),
    );
    await tester.pumpWidget(buildButton(1));
    final button = find.byType(TappableImage);
    await tester.tap(button);
    await tester.pump(AppConfig.tapCooldown);
    await tester.pumpWidget(buildButton(0.5));
    await tester.tap(button);
    expect(calls, 1);
    pending.complete();
    await tester.pump();
    await tester.tap(button);
    expect(calls, 2);
    await tester.pumpWidget(const SizedBox());
  });
}
