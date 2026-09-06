import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_settings.dart';
import '../audio/audio_manager.dart';
import 'save_settings.dart';

class AppSettingsNotifier extends Notifier<AppSettings> {
  late SettingsRepository _repository;
  late AudioManager _audio;
  Future<void> _saveQueue = Future<void>.value();
  Object? _lastSaveError;

  Object? get lastSaveError => _lastSaveError;

  @override
  AppSettings build() {
    _repository = ref.read(settingsRepositoryProvider);
    _audio = ref.read(audioManagerProvider);
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
    _enqueueSave(next);
  }

  Future<void> _enqueueSave(AppSettings snapshot) {
    _saveQueue = _saveQueue.then((_) async {
      try {
        await _repository.save(snapshot);
        _lastSaveError = null;
      } catch (error, stackTrace) {
        _lastSaveError = error;
        developer.log(
          'Could not save app settings. The in-memory value is retained.',
          error: error,
          stackTrace: stackTrace,
        );
      }
    });
    return _saveQueue;
  }

  Future<void> retrySave() => _enqueueSave(state);
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  throw StateError('SettingsRepository must be supplied at bootstrap.');
});

final audioManagerProvider = Provider<AudioManager>((ref) {
  throw StateError('AudioManager must be supplied at bootstrap.');
});

final initialSettingsProvider = Provider<AppSettings>((ref) {
  throw StateError('Initial AppSettings must be supplied at bootstrap.');
});

final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);
