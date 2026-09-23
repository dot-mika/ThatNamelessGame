import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:that_nameless_game/game/game_engine.dart';

void main() {
  const engine = GameEngine();
  const move = GameMove(HandPosition.left, HandPosition.center);
  GameSession session(
    List<int> near,
    List<int> far, {
    PlayerSide turn = PlayerSide.near,
  }) => GameSession(GamePosition(nearHands: near, farHands: far, turn: turn));

  test('modulo five, immutable input, turn and history', () {
    for (var a = 1; a < 5; a++) {
      for (var b = 1; b < 5; b++) {
        final before = session([a, 1, 1], [1, b, 1]);
        final after = engine.applyMove(before, move);
        expect(after.position.farHands, [1, (a + b) % 5, 1]);
        expect(before.position.farHands, [1, b, 1]);
        expect(after.position.turn, PlayerSide.far);
        expect(
          after.visitedPositions,
          containsAll([before.position.key, after.position.key]),
        );
        expect(() => after.position.nearHands[0] = 0, throwsUnsupportedError);
      }
    }
    expect(
      engine
          .applyMove(session([1, 2, 1], [4, 1, 1], turn: PlayerSide.far), move)
          .position
          .nearHands,
      [1, 1, 1],
    );
  });
  test('zero hands cannot attack or be attacked', () {
    final s = session([0, 2, 0], [0, 3, 1]);
    expect(engine.legalMoves(s), hasLength(2));
    expect(() => engine.applyMove(s, move), throwsArgumentError);
    expect(
      engine.isLegalMove(
        s,
        const GameMove(HandPosition.center, HandPosition.left),
      ),
      isFalse,
    );
  });
  test('elimination wins before loop adjudication and ends legal moves', () {
    final s = session([2, 1, 0], [0, 3, 0]);
    final next = engine.applyMove(s, move);
    final repeated = GameSession(
      s.position,
      visitedPositions: {s.position.key, next.position.key},
    );
    final end = engine.applyMove(repeated, move);
    expect(end.result!.reason, GameEndReason.eliminated);
    expect(end.result!.outcome, GameOutcome.nearWin);
    expect(engine.legalMoves(end), isEmpty);
  });
  test('loop compares living hands, including a draw with unequal fingers', () {
    for (final (near, far, outcome) in [
      ([1, 0, 0], [2, 1, 0], GameOutcome.farWin),
      ([1, 4, 4], [1, 1, 0], GameOutcome.nearWin),
      ([1, 2, 0], [1, 1, 0], GameOutcome.draw),
      ([1, 3, 0], [1, 1, 0], GameOutcome.draw),
    ]) {
      final s = session(near, far);
      final next = engine.applyMove(s, move);
      final end = engine.applyMove(
        GameSession(
          s.position,
          visitedPositions: {s.position.key, next.position.key},
        ),
        move,
      );
      expect(end.result!.reason, GameEndReason.loop);
      expect(end.result!.outcome, outcome);
    }
  });
  test('one hand each continues, or draws when the position repeats', () {
    for (final side in PlayerSide.values) {
      final s = session(
        side == PlayerSide.near ? [2, 0, 0] : [3, 0, 1],
        side == PlayerSide.near ? [3, 0, 1] : [2, 0, 0],
        turn: side,
      );
      const kill = GameMove(HandPosition.left, HandPosition.left);
      final next = engine.applyMove(s, kill);
      expect(next.result, isNull);
      expect(engine.legalMoves(next), hasLength(1));
      final repeated = GameSession(
        s.position,
        visitedPositions: {s.position.key, next.position.key},
      );
      expect(
        engine.applyMove(repeated, kill).result!.reason,
        GameEndReason.loop,
      );
      expect(
        engine.applyMove(repeated, kill).result!.outcome,
        GameOutcome.draw,
      );
    }
  });
  test(
    'all remaining positions and finger counts continue with one hand each',
    () {
      for (final own in HandPosition.values) {
        for (final other in HandPosition.values) {
          for (var count = 1; count <= 4; count++) {
            final near = [0, 0, 0]..[own.index] = 2;
            final far = [0, 0, 0]..[other.index] = count;
            final extra = (other.index + 1) % 3;
            far[extra] = 3;
            final next = engine.applyMove(
              session(near, far),
              GameMove(own, HandPosition.values[extra]),
            );
            expect(next.result, isNull);
          }
        }
      }
    },
  );
  test('position key distinguishes all positions and both turns', () {
    final keys = <int>{};
    for (var n = 0; n < 15625; n++) {
      var digits = n;
      final hands = List.generate(6, (_) {
        final v = digits % 5;
        digits ~/= 5;
        return v;
      });
      for (final turn in PlayerSide.values) {
        expect(
          keys.add(
            GamePosition(
              nearHands: hands.take(3).toList(),
              farHands: hands.skip(3).toList(),
              turn: turn,
            ).key,
          ),
          isTrue,
        );
      }
    }
    expect(keys, hasLength(31250));
  });
  test('value objects compare by game content, not allocation identity', () {
    final first = session([1, 2, 3], [4, 0, 1]);
    final second = session([1, 2, 3], [4, 0, 1]);
    expect(first, second);
    expect(
      const GameMove(HandPosition.left, HandPosition.right),
      const GameMove(HandPosition.left, HandPosition.right),
    );
  });
  test('a position owns its configurable rule set', () {
    const rules = GameRules(handCount: 2, fingerModulo: 4);
    final position = GamePosition(
      nearHands: [1, 3],
      farHands: [2, 1],
      turn: PlayerSide.near,
      rules: rules,
    );
    final result = engine.applyMove(
      GameSession(position),
      const GameMove(HandPosition.left, HandPosition.left),
    );
    expect(result.position.farHands, [3, 1]);
  });
  test('generator uses the 36 common opening pairs', () {
    const pairs = {
      '1,1,1|1,1,1',
      '1,1,1|1,1,2',
      '1,1,1|1,3,3',
      '1,1,1|2,2,2',
      '1,1,1|2,2,3',
      '1,1,1|2,3,3',
      '1,1,2|1,1,2',
      '1,1,2|1,2,2',
      '1,1,3|1,1,3',
      '1,1,3|1,3,3',
      '1,1,4|2,2,2',
      '1,1,4|2,2,3',
      '1,1,4|2,3,3',
      '1,1,4|3,3,3',
      '1,2,2|1,2,2',
      '1,3,3|1,3,3',
      '1,3,3|3,3,3',
      '1,4,4|2,2,3',
      '1,4,4|2,2,2',
      '1,4,4|2,3,3',
      '1,4,4|3,3,3',
      '2,2,2|2,2,2',
      '2,2,2|2,2,4',
      '2,2,2|4,4,4',
      '2,2,3|4,4,4',
      '2,2,4|2,2,4',
      '2,2,4|2,4,4',
      '2,3,3|4,4,4',
      '2,4,4|2,4,4',
      '3,3,3|3,3,3',
      '3,3,3|3,4,4',
      '3,3,4|3,3,4',
      '3,3,4|3,4,4',
      '3,4,4|3,4,4',
      '3,4,4|4,4,4',
      '4,4,4|4,4,4',
    };
    expect(pairs, hasLength(36));
    expect(
      InitialPositionGenerator.combinations
          .map((p) => '${p.$1.join(',')}|${p.$2.join(',')}')
          .toSet(),
      pairs,
    );
    final generator = InitialPositionGenerator(Random(42));
    final seen = <String>{};
    final turns = <PlayerSide>{};
    for (var i = 0; i < 5000; i++) {
      final s = generator.generate();
      final a = [...s.position.nearHands]..sort();
      final b = [...s.position.farHands]..sort();
      final ordered = [a.join(','), b.join(',')]..sort();
      final key = ordered.join('|');
      expect(pairs, contains(key));
      seen.add(key);
      turns.add(s.position.turn);
      expect(s.visitedPositions, {s.position.key});
      for (final move in engine.legalMoves(s)) {
        final next = engine.applyMove(s, move);
        expect(
          next.position.hands(s.position.turn.opponent),
          isNot(contains(0)),
        );
      }
    }
    expect(seen, pairs);
    expect(turns, PlayerSide.values.toSet());
  });

  test('normal and hard solo opening pool has the specified 28 openings', () {
    const expected = {
      '1,1,1|1,1,3|near',
      '1,1,1|1,2,2|near',
      '2,2,2|2,4,4|near',
      '3,3,3|3,3,4|near',
      '1,2,3|1,1,1|far',
      '3,3,3|1,1,3|near',
      '4,4,4|3,3,4|near',
      '1,1,1|1,1,1|near',
      '1,1,1|1,1,1|far',
      '1,1,1|1,1,2|near',
      '1,1,1|1,1,2|far',
      '1,1,1|1,3,3|near',
      '1,1,1|1,3,3|far',
      '1,1,2|1,1,2|near',
      '1,1,2|1,1,2|far',
      '1,1,2|1,2,2|near',
      '1,1,2|1,2,2|far',
      '1,1,3|1,1,3|near',
      '1,1,3|1,1,3|far',
      '1,1,3|1,3,3|near',
      '1,1,3|1,3,3|far',
      '1,1,1|2,2,2|far',
      '1,1,1|2,2,3|far',
      '1,1,1|2,3,3|far',
      '1,1,4|2,2,3|far',
      '1,1,4|2,3,3|far',
      '1,1,4|2,2,2|far',
      '1,1,4|2,2,2|near',
    };
    final generator = SoloInitialPositionGenerator(Random(7));
    final actual = <String>{};
    for (var i = 0; i < 10000; i++) {
      final position = generator.generate().position;
      final player = [...position.nearHands]..sort();
      final cpu = [...position.farHands]..sort();
      actual.add('${player.join(',')}|${cpu.join(',')}|${position.turn.name}');
    }
    expect(actual, expected);
  });
}
