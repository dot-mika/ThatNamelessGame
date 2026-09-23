import 'package:flutter_test/flutter_test.dart';
import 'package:that_nameless_game/config/config.dart';
import 'package:that_nameless_game/game/game_engine.dart';
import 'package:that_nameless_game/play/play_mode.dart';

void main() {
  test(
    'solo modes award stars only for the human winner and use loss audio',
    () {
      for (final mode in PlayMode.values) {
        expect(mode.isHuman(PlayerSide.near), isTrue);
        expect(mode.isHuman(PlayerSide.far), mode == PlayMode.twoPlayer);
        for (final outcome in GameOutcome.values) {
          final result = GameResult(GameEndReason.loop, outcome);
          expect(
            mode.earnsStar(result),
            mode == PlayMode.twoPlayer || outcome == GameOutcome.nearWin,
          );
          expect(
            mode.resultSound(result),
            outcome == GameOutcome.draw
                ? SoundEffect.draw
                : outcome == GameOutcome.nearWin || mode == PlayMode.twoPlayer
                ? SoundEffect.win
                : SoundEffect.lose,
          );
        }
      }
    },
  );
}
