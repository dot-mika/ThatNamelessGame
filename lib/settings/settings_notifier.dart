import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/audio_controller.dart';
import '../diagnostics/app_error_handler.dart';
import 'settings_repository.dart';
import 'settings_state.dart';

/// 設定変更、星進捗更新、端末保存を1か所で扱うNotifier
class AppSettingsNotifier extends Notifier<AppSettings> {
  late _SettingsSaveQueue _saveQueue;
  late AudioController _audio;

  @override
  /// 初期設定と依存サービスを読み込んで状態を作る
  AppSettings build() {
    _saveQueue = _SettingsSaveQueue(ref.read(settingsRepositoryProvider));
    _audio = ref.read(audioControllerProvider);
    return ref.read(initialSettingsProvider);
  }

  /// 表示言語を更新して保存予約する
  void setLanguage(AppLanguage language) {
    if (state.language == language) return;
    _update(state.copyWith(language: language));
  }

  /// BGMの有効状態を更新し、再生状態へ反映する
  void setBgmEnabled(bool enabled) {
    if (state.bgmEnabled == enabled) return;
    _update(state.copyWith(bgmEnabled: enabled));
    unawaited(_audio.setBgmEnabled(enabled));
  }

  /// 効果音の有効状態を更新する
  void setSeEnabled(bool enabled) {
    if (state.seEnabled == enabled) return;
    _update(state.copyWith(seEnabled: enabled));
    _audio.setSeEnabled(enabled);
  }

  /// 2人対戦の制限時間を更新する
  void setTimeLimit(TimeLimit timeLimit) {
    if (state.timeLimit == timeLimit) return;
    _update(state.copyWith(timeLimit: timeLimit));
  }

  /// 結果画面から呼ばれ、星の進捗を更新して保存する
  Future<void> recordResult(
    StarMode mode, {
    required bool won,
    required bool draw,
  }) {
    state = state.recordCompletedGame(mode, won: won, draw: draw);
    return _saveQueue.save(state);
  }

  /// 対局放棄時に必要な連勝進捗をリセットして保存する
  Future<void> abandonGame(StarMode mode) {
    // 2人対戦の完了数は放棄では変えず、CPU対戦の連勝数だけをゼロに戻す
    if (mode != StarMode.twoPlayer) state = state.withProgressCount(mode, 0);
    return _saveQueue.save(state);
  }

  /// 状態を即時反映し、保存はUIを待たせずに予約する
  void _update(AppSettings next) {
    state = next;
    unawaited(_saveQueue.save(next));
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

/// 設定保存の順序を保証する内部キュー
class _SettingsSaveQueue {
  _SettingsSaveQueue(this._store);

  final SettingsStore _store;
  Future<void> _pending = Future<void>.value();

  /// 保存を予約し、先行する保存後に実行する
  Future<void> save(AppSettings snapshot) {
    _pending = _pending.then((_) async {
      try {
        await _store.save(snapshot);
      } catch (error, stackTrace) {
        AppErrorHandler.recordHandled(
          error,
          stackTrace,
          source: ErrorSource.settings,
          message: 'Could not save app settings. The in-memory value is retained.',
        );
      }
    });
    return _pending;
  }
}
