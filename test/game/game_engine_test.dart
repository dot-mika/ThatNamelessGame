import 'dart:io';
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
  test('loop compares finger totals, including a draw', () {
    for (final (near, far, outcome) in [
      ([1, 0, 0], [2, 1, 0], GameOutcome.nearWin),
      ([1, 4, 4], [1, 1, 0], GameOutcome.farWin),
      ([1, 2, 0], [1, 1, 0], GameOutcome.draw),
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
  test(
    'generator matches the exact 52 specification pairs and cannot eliminate on first move',
    () {
      final spec = File('docs/specifications_jp.md').readAsStringSync();
      final pairs = RegExp(
        r'\{\[(\d,\d,\d)\], \[(\d,\d,\d)\]\}',
      ).allMatches(spec).map((m) => '${m[1]}|${m[2]}').toSet();
      expect(pairs, hasLength(52));
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
          expect([
            ...next.position.nearHands,
            ...next.position.farHands,
          ], isNot(contains(0)));
        }
      }
      expect(seen, pairs);
      expect(turns, PlayerSide.values.toSet());
    },
  );
}
