import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_state.dart';
import '../audio/audio_controller.dart';
import 'save_settings.dart';

class AppSettingsNotifier extends Notifier<AppSettings> {
  late SettingsRepository _repository;
  late AudioController _audio;
  Future<void> _saveQueue = Future<void>.value();

  @override
  AppSettings build() {
    _repository = ref.read(settingsRepositoryProvider);
    _audio = ref.read(audioControllerProvider);
    return ref.read(initialSettingsProvider);
  }

  void setLanguage(AppLanguage language) {
    if (state.language == language) return;
    _update(state.copyWith(language: language));
  }

  void setBgmEnabled(bool enabled) {
    if (state.bgmEnabled == enabled) return;
    _update(state.copyWith(bgmEnabled: enabled));
    unawaited(_audio.setBgmEnabled(enabled));
  }

  void setSeEnabled(bool enabled) {
    if (state.seEnabled == enabled) return;
    _update(state.copyWith(seEnabled: enabled));
    _audio.setSeEnabled(enabled);
  }

  void setTimeLimit(TimeLimit timeLimit) {
    if (state.timeLimit == timeLimit) return;
    _update(state.copyWith(timeLimit: timeLimit));
  }

  void clearStar(StarMode mode) {
    final next = switch (mode) {
      StarMode.twoPlayer => state.copyWith(star2p: false),
      StarMode.easy => state.copyWith(starEasy: false),
      StarMode.normal => state.copyWith(starNormal: false),
      StarMode.hard => state.copyWith(starHard: false),
    };
    if (next != state) _update(next);
  }

  void _update(AppSettings next) {
    state = next;
    unawaited(_enqueueSave(next));
  }

  Future<void> _enqueueSave(AppSettings snapshot) {
    _saveQueue = _saveQueue.then((_) async {
      try {
        await _repository.save(snapshot);
      } catch (error, stackTrace) {
        developer.log(
          'Could not save app settings. The in-memory value is retained.',
          error: error,
          stackTrace: stackTrace,
        );
      }
    });
    return _saveQueue;
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  throw StateError('SettingsRepository must be supplied at bootstrap.');
});

final initialSettingsProvider = Provider<AppSettings>((ref) {
  throw StateError('Initial AppSettings must be supplied at bootstrap.');
});

final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);
