import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/assets.dart';
import '../config/config.dart';
import '../diagnostics/app_error_handler.dart';
import '../settings/settings_state.dart';

/// BGMと効果音を事前ロードし、設定・前景状態に合わせて再生を同期する。
class AudioController {
  AudioController._(this._bgmPlayer, this._effectPlayers);

  // テスト用
  @visibleForTesting
  AudioController.withPlayers({
    AudioPlayer? bgmPlayer,
    Map<SoundEffect, AudioPlayer> effectPlayers = const {},
  }) : this._(bgmPlayer, effectPlayers);

  /// Widgetテストや音声を利用できない環境向けの音を再生しない管理クラス
  factory AudioController.silent() => AudioController._(null, const {});

  final AudioPlayer? _bgmPlayer;
  final Map<SoundEffect, AudioPlayer> _effectPlayers;
  bool _disposed = false;
  bool _bgmEnabled = true;
  bool _seEnabled = true;
  bool _foreground = true;
  bool? _bgmPlaying = false;
  bool _resultPlaying = false;
  Completer<void>? _resultStopped;
  final _playSuspensionOwners = <Object>{};
  final _commands = _AudioCommandQueue();
  // カウントダウンは同じSEプレイヤーを連続で使うため、通常SEとは
  // 別に到着順で直列化する。
  final _countdownCommands = _AudioCommandQueue();
  int _countdownGeneration = 0;
  Future<void>? _disposal;
  final _disposeRequested = Completer<void>();

  /// 音声プレイヤーを事前準備してコントローラーを作る。
  static Future<AudioController> create() async {
    try {
      /// ゲームのBGM・効果音を再生するが、ユーザーが別アプリで流している音楽は邪魔しない
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            audioFocus: AndroidAudioFocus.none,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {AVAudioSessionOptions.mixWithOthers},
          ),
        ),
      );
    } catch (error, stackTrace) {
      AppErrorHandler.recordHandled(
        error,
        stackTrace,
        source: ErrorSource.audio,
        message: 'Audio context setup failed; continuing without audio.',
      );
      return AudioController.silent();
    }

    // ホーム画面を表示する前に、BGMとすべての効果音を並行して準備する。
    final (bgmPlayer, preparedEffects) = await (
      _prepareBgm(),
      Future.wait([
        for (final effect in SoundEffect.values) _prepareEffect(effect),
      ]),
    ).wait;
    final effectPlayers = <SoundEffect, AudioPlayer>{};
    for (final entry in preparedEffects.whereType<_PreparedEffect>()) {
      effectPlayers[entry.effect] = entry.player;
    }
    return AudioController._(bgmPlayer, effectPlayers);
  }

  /// BGMプレイヤーを準備し、失敗時はnullを返す。
  static Future<AudioPlayer?> _prepareBgm() async {
    AudioPlayer? player;
    try {
      player = AudioPlayer(playerId: 'bgm');
      await Future.wait([
        player.setReleaseMode(ReleaseMode.loop),
        player.setVolume(AppConfig.bgmVolume),
      ]);
      await player.setSource(AssetSource(Assets.bgm));
      return player;
    } catch (error, stackTrace) {
      AppErrorHandler.recordHandled(
        error,
        stackTrace,
        source: ErrorSource.audio,
        message: 'BGM preload failed; continuing without BGM.',
      );
      await player?.dispose();
      return null;
    }
  }

  /// 指定した効果音プレイヤーを準備する。
  static Future<_PreparedEffect?> _prepareEffect(SoundEffect effect) async {
    AudioPlayer? player;
    try {
      player = AudioPlayer(playerId: 'se_${effect.name}');
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setSource(AssetSource(effect.asset));
      return _PreparedEffect(effect, player);
    } catch (error, stackTrace) {
      AppErrorHandler.recordHandled(
        error,
        stackTrace,
        source: ErrorSource.audio,
        message: '${effect.name} preload failed; continuing without it.',
      );
      await player?.dispose();
      return null;
    }
  }

  /// 初期設定と前景状態をまとめて音声状態へ反映する。
  Future<void> applySettings(
    AppSettings settings, {
    required bool foreground,
  }) async {
    if (_disposed) return;
    _bgmEnabled = settings.bgmEnabled;
    _seEnabled = settings.seEnabled;
    _foreground = foreground;
    await _syncBgm();
  }

  /// BGMの有効状態を更新する。
  Future<void> setBgmEnabled(bool enabled) async {
    if (_disposed) return;
    _bgmEnabled = enabled;
    await _syncBgm();
  }

  /// 効果音の有効状態を更新する。
  void setSeEnabled(bool enabled) {
    if (!_disposed) _seEnabled = enabled;
  }

  /// アプリの前景・背景状態を音声再生へ反映する。
  Future<void> setForeground(bool foreground) async {
    if (_disposed) return;
    _foreground = foreground;
    await _syncBgm();
  }

  /// BGMと通常SEの操作を直列化し、一時停止・再開の競合を防ぐ。
  /// 破棄要求後の未実行操作は捨てる。
  Future<void> _enqueue(Future<void> Function() operation) {
    if (_disposed) return Future<void>.value();
    return _commands.enqueue(() async {
      if (!_disposed) await operation();
    });
  }

  /// 現在の各種フラグからBGMの再生・停止を同期する。
  Future<void> _syncBgm() => _enqueue(() async {
    final shouldPlay =
        _bgmEnabled &&
        _foreground &&
        !_resultPlaying &&
        _playSuspensionOwners.isEmpty;
    if (shouldPlay == _bgmPlaying) return;
    final player = _bgmPlayer;
    if (player == null) return;
    try {
      if (shouldPlay) {
        await player.resume();
      } else {
        await player.pause();
      }
      _bgmPlaying = shouldPlay;
    } catch (error, stackTrace) {
      _bgmPlaying = null;
      AppErrorHandler.recordHandled(
        error,
        stackTrace,
        source: ErrorSource.audio,
        message: 'Could not update BGM state.',
      );
    }
  });

  bool get _canPlayEffects => _seEnabled && _foreground && !_disposed;

  /// 対局中の一時停止状態を更新する。
  Future<void> setPlaySuspended(Object owner, bool suspended) async {
    if (_disposed) return;
    if (suspended) {
      _playSuspensionOwners.add(owner);
    } else {
      _playSuspensionOwners.remove(owner);
    }
    await _syncBgm();
  }

  /// 指定した通常の効果音を再生する。
  Future<void> play(SoundEffect effect) =>
      _enqueue(() => _restartEffect(effect));

  /// 事前ロード済みのSEを先頭から再生する共通処理。
  Future<void> _restartEffect(SoundEffect effect) async {
    if (!_canPlayEffects) return;
    final player = _effectPlayers[effect];
    if (player == null) return;
    try {
      await player.stop();
      if (!_canPlayEffects) return;
      await player.resume();
    } catch (error, stackTrace) {
      AppErrorHandler.recordHandled(
        error,
        stackTrace,
        source: ErrorSource.audio,
        message: 'Could not play ${effect.name}.',
      );
    }
  }

  /// 表示の秒境界とSEの開始時刻を揃えるため、BGMや他のSE操作とは別に実行する。
  ///
  /// カウントダウン用プレイヤーへの stop → resume が重ならないようにし、
  /// 終了・画面遷移後にキューへ残った古いSEは鳴らさない。
  Future<void> playCountdownCue(SoundEffect effect) {
    if (_disposed) return Future<void>.value();
    final generation = _countdownGeneration;
    return _countdownCommands.enqueue(
      () => _restartCountdownCue(effect, generation),
    );
  }

  Future<void> _restartCountdownCue(
    SoundEffect effect,
    int generation,
  ) async {
    if (!_canPlayEffects || generation != _countdownGeneration) return;
    final player = _effectPlayers[effect];
    if (player == null) return;
    try {
      await player.stop();
      if (!_canPlayEffects || generation != _countdownGeneration) return;
      await player.resume();
    } catch (error, stackTrace) {
      AppErrorHandler.recordHandled(
        error,
        stackTrace,
        source: ErrorSource.audio,
        message: 'Could not play ${effect.name}.',
      );
    }
  }

  /// 結果SEの間だけBGMを止め、完了後に最新設定でBGMを戻す。
  Future<void> playResult(SoundEffect effect) async {
    if (_disposed || _resultPlaying) return;
    _resultPlaying = true;
    final stopped = Completer<void>();
    _resultStopped = stopped;
    StreamSubscription<void>? subscription;
    final completed = Completer<void>();
    try {
      await _syncBgm();
      final player = _effectPlayers[effect];
      var started = false;
      if (player != null) {
        await _enqueue(() async {
          if (!_canPlayEffects) return;
          await player.stop();
          if (!_canPlayEffects) return;
          // 短い音でも完了を取り逃がさないよう、再生前に購読する。
          subscription = player.onPlayerComplete.listen(
            (_) {
              if (!completed.isCompleted) completed.complete();
            },
            onDone: () {
              if (!completed.isCompleted) completed.complete();
            },
            onError: (Object error, StackTrace stackTrace) {
              AppErrorHandler.recordHandled(
                error,
                stackTrace,
                source: ErrorSource.audio,
                message: 'Result playback failed.',
              );
              if (!completed.isCompleted) completed.complete();
            },
          );
          if (stopped.isCompleted) return;
          await player.resume();
          started = true;
        });
      }
      if (started) {
        // 再生完了待ちは操作キューの外で行い、設定変更・破棄を妨げない。
        await Future.any([
          completed.future,
          stopped.future,
          _disposeRequested.future,
        ]);
      }
    } finally {
      await subscription?.cancel();
      if (identical(_resultStopped, stopped)) _resultStopped = null;
      _resultPlaying = false;
      await _syncBgm();
    }
  }

  /// 結果音を含め、再生中の効果音をすべて停止する。
  Future<void> stopEffects() async {
    if (_disposed) return;
    _countdownGeneration++;
    final stopped = _resultStopped;
    if (stopped != null && !stopped.isCompleted) stopped.complete();
    await _enqueue(() async {
      await Future.wait([
        for (final player in _effectPlayers.values) player.stop(),
      ]);
    });
  }

  /// 保持している音声リソースを一度だけ解放する。
  Future<void> dispose() {
    if (_disposal != null) return _disposal!;
    _disposed = true;
    _countdownGeneration++;
    _disposeRequested.complete();
    return _disposal = Future.wait([
      _commands.completed,
      _countdownCommands.completed,
    ]).then((_) async {
      await Future.wait([
        if (_bgmPlayer != null) _bgmPlayer.dispose(),
        for (final player in _effectPlayers.values) player.dispose(),
      ]);
    });
  }
}

final audioControllerProvider = Provider<AudioController>((ref) {
  throw StateError('AudioController must be supplied at bootstrap.');
});

/// 画面のボタン操作音を鳴らす短縮形。再生完了は待たない。
extension TapSound on WidgetRef {
  void playTapSound() =>
      unawaited(read(audioControllerProvider).play(SoundEffect.tapButton));
}

class _PreparedEffect {
  const _PreparedEffect(this.effect, this.player);

  final SoundEffect effect;
  final AudioPlayer player;
}

/// 音声プレイヤーへの非同期操作を到着順に実行する内部キュー。
class _AudioCommandQueue {
  Future<void> _tail = Future<void>.value();

  /// 操作を追加し、完了を待つFutureを返す。
  Future<void> enqueue(Future<void> Function() operation) {
    _tail = _tail.then((_) async {
      try {
        await operation();
      } catch (error, stackTrace) {
        AppErrorHandler.recordHandled(
          error,
          stackTrace,
          source: ErrorSource.audio,
          message: 'Audio operation failed.',
        );
      }
    });
    return _tail;
  }

  /// 追加済みのすべての操作が完了するFutureを返す。
  Future<void> get completed => _tail;
}
