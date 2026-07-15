import 'package:audioplayers/audioplayers.dart';
import '../config/assets.dart';
import '../config/config.dart';

enum Se { tapButton, tapHand, win, tapOk, countdown, start, draw, lose }

extension on Se {
  String get asset => switch (this) {
        Se.tapButton => Assets.seTapButton,
        Se.tapHand => Assets.seTapHand,
        Se.win => Assets.seWin,
        Se.tapOk => Assets.seTapOk,
        Se.countdown => Assets.seCountdown,
        Se.start => Assets.seStart,
        Se.draw => Assets.seDraw,
        Se.lose => Assets.seLose,
      };
}

/// BGM/SE の再生を司る仕組みのみを提供する。
/// 「いつ何を鳴らすか」の判断は各画面/notifier 側の責務。
class AudioManager {
  // bgm/SE プレイヤーは preload() 内で、AudioContext 設定の後に作る(late)。
  // audioplayers はプレイヤー作成時(AudioPlayer(...) 呼び出し時点)の
  // デフォルト AudioContext を1回だけコピーして持つ実装のため、フィールド
  // 初期化子でここに書いて先に作ってしまうと、後から
  // AudioPlayer.global.setAudioContext() を呼んでも反映されない
  // (実際に BGM が SE 再生の度に pause される不具合として発現した)。
  late final AudioPlayer _bgmPlayer;

  // SE は種類ごとに専用プレイヤーを持つ(design_jp.md「BGM 用と SE 用でプレイヤーを
  // 分ける」)。1つのプレイヤーを使い回して毎回 play(AssetSource(...)) すると、
  // タップの度に setSource からやり直しになり体感できる遅延が出るため、
  // プレイヤーごとに source を preload() で1度だけ設定し、以降は stop→resume のみで鳴らす。
  late final Map<Se, AudioPlayer> _sePlayers;

  bool bgmEnabled = true;
  bool seEnabled = true;

  /// 起動時に BGM + SE8種を全プリロードする(遅延ロードは初回タップの音遅れの原因になるため)。
  Future<void> preload() async {
    // デフォルトだと Android は各プレイヤーが個別に AudioFocus を排他取得するため、
    // SE を鳴らす度に BGM プレイヤーが AUDIOFOCUS_LOSS を受けて一時停止してしまう
    // (例: ボタンSE→画面遷移のたびにBGMが消える)。同一アプリ内でBGMとSEを同時に
    // 鳴らしたいので、フォーカスを取り合わずミックスする設定を全プレイヤー共通にする。
    // 必ずプレイヤーを1つも作る前に呼ぶこと。
    await AudioPlayer.global.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {AVAudioSessionOptions.mixWithOthers},
        ),
      ),
    );

    _bgmPlayer = AudioPlayer(playerId: 'bgm');
    _sePlayers = {
      for (final se in Se.values) se: AudioPlayer(playerId: 'se_${se.name}'),
    };

    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgmPlayer.setSource(AssetSource(Assets.bgm));
    // SE は常に音量1.0(これ以上は上げられない)なので、BGMを下げて相対的に
    // SEが大きく聞こえるようにする。
    await _bgmPlayer.setVolume(AppConfig.bgmVolume);

    for (final se in Se.values) {
      final player = _sePlayers[se]!;
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setSource(AssetSource(se.asset));
    }
  }

  Future<void> playBgm() async {
    if (!bgmEnabled) return;
    await _bgmPlayer.resume();
  }

  Future<void> pauseBgm() async {
    await _bgmPlayer.pause();
  }

  Future<void> resumeBgm() async {
    if (!bgmEnabled) return;
    await _bgmPlayer.resume();
  }

  Future<void> playSe(Se se) async {
    if (!seEnabled) return;
    final player = _sePlayers[se]!;
    await player.stop();
    await player.resume();
  }

  /// SE 再生中は BGM を停止し、SE 終了後に再開する。
  Future<void> playSeInterruptingBgm(Se se) async {
    final wasPlayingBgm = bgmEnabled;
    if (wasPlayingBgm) await pauseBgm();
    if (seEnabled) {
      final player = _sePlayers[se]!;
      await player.stop();
      await player.resume();
      await player.onPlayerComplete.first;
    }
    if (wasPlayingBgm) await resumeBgm();
  }

  Future<void> dispose() async {
    await _bgmPlayer.dispose();
    for (final player in _sePlayers.values) {
      await player.dispose();
    }
  }
}
