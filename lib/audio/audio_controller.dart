import 'dart:async';
import 'dart:developer' as developer;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/config.dart';
import '../settings/settings_state.dart';
import '../config/assets.dart';

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
  bool _playSuspended = false;
  Future<void> _commands = Future<void>.value();
  Future<void>? _disposal;
  final _disposeRequested = Completer<void>();

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
      developer.log(
        'Audio context setup failed; continuing without audio.',
        error: error,
        stackTrace: stackTrace,
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
      developer.log(
        '[audio controller] BGM preload failed; continuing without BGM.',
        error: error,
        stackTrace: stackTrace,
      );
      await player?.dispose();
      return null;
    }
  }

  static Future<_PreparedEffect?> _prepareEffect(SoundEffect effect) async {
    AudioPlayer? player;
    try {
      player = AudioPlayer(playerId: 'se_${effect.name}');
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setSource(AssetSource(effect.asset));
      return _PreparedEffect(effect, player);
    } catch (error, stackTrace) {
      developer.log(
        '[audio controller] ${effect.name} preload failed; continuing without it.',
        error: error,
        stackTrace: stackTrace,
      );
      await player?.dispose();
      return null;
    }
  }

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

  Future<void> setBgmEnabled(bool enabled) async {
    if (_disposed) return;
    _bgmEnabled = enabled;
    await _syncBgm();
  }

  void setSeEnabled(bool enabled) {
    if (!_disposed) _seEnabled = enabled;
  }

  Future<void> setForeground(bool foreground) async {
    if (_disposed) return;
    _foreground = foreground;
    await _syncBgm();
  }

  // プレイヤーへの操作を直列化し、破棄要求後の未実行操作は捨てる。
  Future<void> _enqueue(Future<void> Function() operation) {
    if (_disposed) return Future<void>.value();
    _commands = _commands.then((_) async {
      if (_disposed) return;
      try {
        await operation();
      } catch (error, stackTrace) {
        developer.log(
          '[audio controller] Audio operation failed.',
          error: error,
          stackTrace: stackTrace,
        );
      }
    });
    return _commands;
  }

  Future<void> _syncBgm() => _enqueue(() async {
    final shouldPlay =
        _bgmEnabled && _foreground && !_resultPlaying && !_playSuspended;
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
      developer.log(
        '[audio controller] Could not update BGM state.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  });

  bool get _canPlayEffects => _seEnabled && _foreground && !_disposed;

  Future<void> setPlaySuspended(bool suspended) async {
    if (_disposed) return;
    _playSuspended = suspended;
    await _syncBgm();
  }

  Future<void> play(SoundEffect effect) => _enqueue(() async {
    if (!_canPlayEffects) return;
    final player = _effectPlayers[effect];
    if (player == null) return;
    try {
      await player.stop();
      if (!_canPlayEffects) return;
      await player.resume();
    } catch (error, stackTrace) {
      developer.log(
        '[audio controller] Could not play ${effect.name}.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  });

  Future<void> playResult(SoundEffect effect) async {
    if (_disposed || _resultPlaying) return;
    _resultPlaying = true;
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
              developer.log(
                '[audio controller] Result playback failed.',
                error: error,
                stackTrace: stackTrace,
              );
              if (!completed.isCompleted) completed.complete();
            },
          );
          await player.resume();
          started = true;
        });
      }
      if (started) {
        // 再生完了待ちは操作キューの外で行い、設定変更・破棄を妨げない。
        await Future.any([completed.future, _disposeRequested.future]);
      }
    } finally {
      await subscription?.cancel();
      _resultPlaying = false;
      await _syncBgm();
    }
  }

  Future<void> dispose() {
    if (_disposal != null) return _disposal!;
    _disposed = true;
    _disposeRequested.complete();
    return _disposal = _commands.then((_) async {
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

class _PreparedEffect {
  const _PreparedEffect(this.effect, this.player);

  final SoundEffect effect;
  final AudioPlayer player;
}
