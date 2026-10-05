import 'dart:ui';
import '../config/config.dart';
import '../game/game_engine.dart';
import '../settings/settings_state.dart';


/// 対局モード画面色、時間、CPU、星の扱いをまとめて切り替える
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

  /// 指定側の手の縁取り、手番中のボタン、背景に使う色
  /// 1人プレイのCPU側は無効色で表示する
  Color colorFor(PlayerSide side) => side == PlayerSide.near
      ? playerColor
      : isTwoPlayer
      ? AppColors.farPlayer
      : AppColors.disabled;

  /// 1人プレイでは手前だけが人間、2人プレイでは両側が人間となる
  bool isHuman(PlayerSide side) => isTwoPlayer || side == PlayerSide.near;
  bool pausesTimerForExit(PlayerSide side) => isTwoPlayer || !isHuman(side);

  SoundEffect resultSound(GameResult result) => switch (result.outcome) {
    GameOutcome.draw => SoundEffect.draw,
    GameOutcome.nearWin => SoundEffect.win,
    GameOutcome.farWin => isTwoPlayer ? SoundEffect.win : SoundEffect.lose,
  };
}
