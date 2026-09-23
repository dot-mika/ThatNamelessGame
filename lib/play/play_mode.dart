import 'dart:ui';
import '../config/config.dart';
import '../game/game_engine.dart';
import '../settings/settings_state.dart';

/// 難易度ごとに異なるCPUの時間・思考・演出パラメータ。
/// 対局モード。画面色、時間、CPU、星の扱いをまとめて切り替える。
enum PlayMode {
  twoPlayer(StarMode.twoPlayer),
  easy(StarMode.easy),
  normal(StarMode.normal),
  hard(StarMode.hard);

  const PlayMode(this.starMode);
  final StarMode starMode;

  bool get isTwoPlayer => this == twoPlayer;
  Color get playerColor => switch (this) {
    twoPlayer => AppColors.nearPlayer,
    easy => AppColors.easyPlayer,
    normal => AppColors.normalPlayer,
    hard => AppColors.hardPlayer,
  };

  /// 1人プレイでは手前だけが人間、2人プレイでは両側が人間となる。
  bool isHuman(PlayerSide side) => isTwoPlayer || side == PlayerSide.near;
  bool pausesTimerForExit(PlayerSide side) => isTwoPlayer || !isHuman(side);

  /// 2人プレイだけ設定画面の時間を使い、1人プレイは難易度固定とする。
  bool earnsStar(GameResult result) =>
      isTwoPlayer || result.outcome == GameOutcome.nearWin;

  SoundEffect resultSound(GameResult result) => switch (result.outcome) {
    GameOutcome.draw => SoundEffect.draw,
    GameOutcome.nearWin => SoundEffect.win,
    GameOutcome.farWin => isTwoPlayer ? SoundEffect.win : SoundEffect.lose,
  };
}
