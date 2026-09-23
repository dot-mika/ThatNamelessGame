import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_state.dart';
import '../audio/audio_controller.dart';
import 'save_settings.dart';

/// 設定変更、星進捗更新、端末保存を1か所で扱うNotifier。
class AppSettingsNotifier extends Notifier<AppSettings> {
  late SettingsStore _repository;
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
    final next = state.withStar(mode, false);
    if (next != state) _update(next);
  }

  Future<void> awardStar(StarMode mode) {
    state = state.markStar(mode);
    return _enqueueSave(state);
  }

  /// Records a completed game for the three-state home-screen star.
  /// 結果画面から呼ばれ、星の進捗を更新して保存する。
  Future<void> recordResult(
    StarMode mode, {
    required bool won,
    required bool draw,
  }) {
    state = state.recordCompletedGame(mode, won: won, draw: draw);
    return _enqueueSave(state);
  }

  Future<void> abandonGame(StarMode mode) {
    if (mode != StarMode.twoPlayer) _resetWinStreak(mode);
    return _enqueueSave(state);
  }

  void _resetWinStreak(StarMode mode) {
    state = state.withWinStreak(mode, 0);
  }

  void _update(AppSettings next) {
    state = next;
    unawaited(_enqueueSave(next));
  }

  /// 連続操作でも保存順が逆転しないよう、保存要求を直列化する。
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

final settingsRepositoryProvider = Provider<SettingsStore>((ref) {
  throw StateError('SettingsStore must be supplied at bootstrap.');
});

final initialSettingsProvider = Provider<AppSettings>((ref) {
  throw StateError('Initial AppSettings must be supplied at bootstrap.');
});

final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);
