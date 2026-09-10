import 'package:flutter_test/flutter_test.dart';
import 'package:that_nameless_game/config/config.dart';
import 'package:that_nameless_game/game/game_engine.dart';
import 'package:that_nameless_game/play/play_mode.dart';
import 'package:that_nameless_game/settings/settings_state.dart';

void main() {
  test('only two-player mode uses the configurable time limit', () {
    final settings = AppSettings.defaults(
      AppLanguage.jp,
    ).copyWith(timeLimit: TimeLimit.unlimited);
    expect(PlayMode.twoPlayer.timeLimit(settings), isNull);
    expect(PlayMode.easy.timeLimit(settings), const Duration(seconds: 30));
    expect(PlayMode.normal.timeLimit(settings), const Duration(seconds: 15));
    expect(PlayMode.hard.timeLimit(settings), const Duration(seconds: 5));
  });

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
