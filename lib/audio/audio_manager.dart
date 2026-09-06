import 'dart:async';
import 'dart:developer' as developer;

import 'package:audioplayers/audioplayers.dart';

import '../config/config.dart';
import '../settings/app_settings.dart';
import '../config/assets.dart';

enum SoundEffect {
  tapButton(Assets.seTapButton),
  tapHand(Assets.seTapHand),
  win(Assets.seWin),
  tapOk(Assets.seTapOk),
  countdown(Assets.seCountdown),
  start(Assets.seStart),
  draw(Assets.seDraw),
  lose(Assets.seLose);

  const SoundEffect(this.asset);
  final String asset;
}

class AudioManager {
  AudioManager._(this._bgmPlayer, this._effectPlayers);

  /// Widgetテストや音声を利用できない環境向けに、音を再生しない管理クラスを作る。
  factory AudioManager.silent() => AudioManager._(null, const {});

  final AudioPlayer? _bgmPlayer;
  final Map<SoundEffect, AudioPlayer> _effectPlayers;
  bool _disposed = false;
  bool _bgmEnabled = true;
  bool _seEnabled = true;
  bool _foreground = true;
  bool _bgmPlaying = false;

  static Future<AudioManager> create() async {
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
      return AudioManager.silent();
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
    return AudioManager._(bgmPlayer, effectPlayers);
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
        '[audio manager] BGM preload failed; continuing without BGM.',
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
        '[audio manager] ${effect.name} preload failed; continuing without it.',
        error: error,
        stackTrace: stackTrace,
      );
      await player?.dispose();
      return null;
    }
  }

  Future<void> applySettings(AppSettings settings) async {
    _bgmEnabled = settings.bgmEnabled;
    _seEnabled = settings.seEnabled;
    await _syncBgm();
  }

  Future<void> setBgmEnabled(bool enabled) async {
    _bgmEnabled = enabled;
    await _syncBgm();
  }

  void setSeEnabled(bool enabled) => _seEnabled = enabled;

  Future<void> setForeground(bool foreground) async {
    _foreground = foreground;
    await _syncBgm();
  }

  Future<void> _syncBgm() async {
    final shouldPlay = _bgmEnabled && _foreground;
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
      _bgmPlaying = false;
      developer.log(
        '[audio manager] Could not update BGM state.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> play(SoundEffect effect) async {
    if (!_seEnabled || !_foreground || _disposed) return;
    final player = _effectPlayers[effect];
    if (player == null) return;
    try {
      await player.stop();
      await player.resume();
    } catch (error, stackTrace) {
      developer.log(
        '[audio manager] Could not play ${effect.name}.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> playResult(SoundEffect effect) async {
    if (_disposed) return;
    final shouldResume = _bgmEnabled && _foreground;
    if (_bgmPlaying) {
      await _bgmPlayer?.pause();
      _bgmPlaying = false;
    }
    final player = _effectPlayers[effect];
    if (_seEnabled && _foreground && player != null) {
      try {
        await player.stop();
        await player.resume();
        await player.onPlayerComplete.first;
      } catch (error, stackTrace) {
        developer.log(
          '[audio manager] Could not play result sound.',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    if (shouldResume) await _syncBgm();
  }

  Future<void> dispose() async {
    _disposed = true;
    await _bgmPlayer?.dispose();
    for (final player in _effectPlayers.values) {
      await player.dispose();
    }
  }
}

class _PreparedEffect {
  const _PreparedEffect(this.effect, this.player);

  final SoundEffect effect;
  final AudioPlayer player;
}
