import 'package:audioplayers/audioplayers.dart';
import '../config/assets.dart';
import '../config/config.dart';

enum Se {
  tapButton(Assets.seTapButton),
  tapHand(Assets.seTapHand),
  win(Assets.seWin),
  tapOk(Assets.seTapOk),
  countdown(Assets.seCountdown),
  start(Assets.seStart),
  draw(Assets.seDraw),
  lose(Assets.seLose);

  const Se(this.asset);

  final String asset;
}

/// BGM/SE の再生を司る仕組みのみを提供する。
/// 「いつ何を鳴らすか」の判断は各画面/notifier 側の責務。
class AudioManager {
  AudioManager._(this._bgmPlayer, this._sePlayers);

  final AudioPlayer _bgmPlayer;

  // SE は種類ごとに専用プレイヤーを持つ(design_jp.md「BGM 用と SE 用でプレイヤーを
  // 分ける」)。1つのプレイヤーを使い回して毎回 play(AssetSource(...)) すると、
  // タップの度に setSource からやり直しになり体感できる遅延が出るため、
  // プレイヤーごとに source を create() で1度だけ設定し、以降は stop→resume のみで鳴らす。
  final Map<Se, AudioPlayer> _sePlayers;

  bool bgmEnabled = true;
  bool seEnabled = true;

  /// 起動時に BGM + SE8種を全プリロードする(遅延ロードは初回タップの音遅れの原因になるため)。
  static Future<AudioManager> create() async {
    // デフォルトだと Android は各プレイヤーが個別に AudioFocus を排他取得するため、
    // SE を鳴らす度に BGM プレイヤーが AUDIOFOCUS_LOSS を受けて一時停止してしまう
    // (例: ボタンSE→画面遷移のたびにBGMが消える)。同一アプリ内でBGMとSEを同時に
    // 鳴らしたいので、フォーカスを取り合わずミックスする設定を全プレイヤー共通にする。
    // audioplayers はプレイヤー作成時(AudioPlayer(...) 呼び出し時点)のデフォルト
    // AudioContext を1回だけコピーして持つ実装のため、必ずプレイヤーを1つも
    // 作る前に呼ぶこと(実際に BGM が SE 再生の度に pause される不具合として発現した)。
    await AudioPlayer.global.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {AVAudioSessionOptions.mixWithOthers},
        ),
      ),
    );

    final bgmPlayer = AudioPlayer(playerId: 'bgm');
    final sePlayers = {
      for (final se in Se.values) se: AudioPlayer(playerId: 'se_${se.name}'),
    };

    await bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await bgmPlayer.setSource(AssetSource(Assets.bgm));
    // SE は常に音量1.0(これ以上は上げられない)なので、BGMを下げて相対的に
    // SEが大きく聞こえるようにする。
    await bgmPlayer.setVolume(AppConfig.bgmVolume);

    for (final se in Se.values) {
      final player = sePlayers[se]!;
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setSource(AssetSource(se.asset));
    }

    return AudioManager._(bgmPlayer, sePlayers);
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
