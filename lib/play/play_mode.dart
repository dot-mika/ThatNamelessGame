import '../config/config.dart';
import '../game/game_engine.dart';
import '../settings/settings_state.dart';

/// Mode-specific rules shared by session management and future CPU integration.
/// Declaring a mode here does not enable it on the home screen.
enum PlayMode {
  twoPlayer(StarMode.twoPlayer),
  easy(StarMode.easy),
  normal(StarMode.normal),
  hard(StarMode.hard);

  const PlayMode(this.starMode);
  final StarMode starMode;

  bool get isTwoPlayer => this == twoPlayer;
  bool isHuman(PlayerSide side) => isTwoPlayer || side == PlayerSide.near;
  bool pausesTimerForExit(PlayerSide side) => isTwoPlayer || !isHuman(side);

  Duration? timeLimit(AppSettings settings) => switch (this) {
    twoPlayer => settings.timeLimit.duration,
    easy => const Duration(seconds: 30),
    normal => const Duration(seconds: 15),
    hard => const Duration(seconds: 5),
  };

  bool earnsStar(GameResult result) =>
      isTwoPlayer || result.outcome == GameOutcome.nearWin;

  SoundEffect resultSound(GameResult result) => switch (result.outcome) {
    GameOutcome.draw => SoundEffect.draw,
    GameOutcome.nearWin => SoundEffect.win,
    GameOutcome.farWin => isTwoPlayer ? SoundEffect.win : SoundEffect.lose,
  };
}
