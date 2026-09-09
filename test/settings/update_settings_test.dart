import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:that_nameless_game/audio/audio_controller.dart';
import 'package:that_nameless_game/settings/settings_state.dart';
import 'package:that_nameless_game/settings/update_settings.dart';
import 'package:that_nameless_game/settings/save_settings.dart';

void main() {
  test(
    'save failure preserves state and does not block the next queued save',
    () async {
      final firstStarted = Completer<void>();
      final firstSave = Completer<void>();
      final secondSaved = Completer<void>();
      final snapshots = <AppSettings>[];
      final repository = _RecordingRepository((settings) async {
        snapshots.add(settings);
        if (snapshots.length == 1) {
          firstStarted.complete();
          await firstSave.future;
        } else {
          secondSaved.complete();
        }
      });
      final audio = AudioController.silent();
      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(repository),
          audioControllerProvider.overrideWithValue(audio),
          initialSettingsProvider.overrideWithValue(
            AppSettings.defaults(AppLanguage.jp),
          ),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await audio.dispose();
      });
      final notifier = container.read(appSettingsProvider.notifier);
      notifier.setLanguage(AppLanguage.en);
      await firstStarted.future;
      notifier.setTimeLimit(TimeLimit.seconds30);
      expect(
        container.read(appSettingsProvider).timeLimit,
        TimeLimit.seconds30,
      );
      expect(snapshots, hasLength(1));
      firstSave.completeError(StateError('disk unavailable'));
      await secondSaved.future;
      expect(snapshots[0].timeLimit, TimeLimit.seconds15);
      expect(snapshots[1].timeLimit, TimeLimit.seconds30);
      expect(snapshots[1].language, AppLanguage.en);
      expect(container.read(appSettingsProvider), snapshots[1]);
    },
  );
}

class _RecordingRepository implements SettingsRepository {
  _RecordingRepository(this.onSave);
  final Future<void> Function(AppSettings) onSave;

  @override
  Future<void> save(AppSettings settings) => onSave(settings);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
