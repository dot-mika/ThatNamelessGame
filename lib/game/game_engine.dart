import 'dart:math';

enum PlayerSide {
  near,
  far;

  PlayerSide get opponent => this == near ? far : near;
}

enum HandPosition { left, center, right }

enum GameEndReason { eliminated, timeout, loop }

enum GameOutcome { nearWin, farWin, draw }

class GamePosition {
  GamePosition({
    required List<int> nearHands,
    required List<int> farHands,
    required this.turn,
  }) : nearHands = List.unmodifiable(nearHands),
       farHands = List.unmodifiable(farHands) {
    if (nearHands.length != 3 ||
        farHands.length != 3 ||
        [...nearHands, ...farHands].any((v) => v < 0 || v > 4)) {
      throw ArgumentError('Each side needs three hands with values 0–4.');
    }
  }
  final List<int> nearHands, farHands;
  final PlayerSide turn;
  List<int> hands(PlayerSide side) =>
      side == PlayerSide.near ? nearHands : farHands;
  int get key =>
      [...nearHands, ...farHands].fold(turn.index, (key, v) => key * 5 + v);
}

class GameMove {
  const GameMove(this.attackerPosition, this.targetPosition);
  final HandPosition attackerPosition, targetPosition;
}

class GameResult {
  const GameResult(this.reason, this.outcome);
  final GameEndReason reason;
  final GameOutcome outcome;
  static GameOutcome winner(PlayerSide side) =>
      side == PlayerSide.near ? GameOutcome.nearWin : GameOutcome.farWin;
}

class GameSession {
  GameSession(this.position, {Set<int>? visitedPositions, this.result})
    : visitedPositions = Set.unmodifiable(visitedPositions ?? {position.key});
  final GamePosition position;
  final Set<int> visitedPositions;
  final GameResult? result;
}

class GameEngine {
  const GameEngine();
  List<GameMove> legalMoves(GameSession session) => [
    for (final a in HandPosition.values)
      for (final b in HandPosition.values)
        if (isLegalMove(session, GameMove(a, b))) GameMove(a, b),
  ];
  bool isLegalMove(GameSession session, GameMove move) =>
      session.result == null &&
      session.position.hands(
            session.position.turn,
          )[move.attackerPosition.index] !=
          0 &&
      session.position.hands(
            session.position.turn.opponent,
          )[move.targetPosition.index] !=
          0;

  GameSession applyMove(GameSession session, GameMove move) {
    if (!isLegalMove(session, move)) throw ArgumentError('Illegal move');
    final old = session.position;
    final target = [...old.hands(old.turn.opponent)];
    target[move.targetPosition.index] =
        (target[move.targetPosition.index] +
            old.hands(old.turn)[move.attackerPosition.index]) %
        5;
    final next = GamePosition(
      nearHands: old.turn == PlayerSide.near ? old.nearHands : target,
      farHands: old.turn == PlayerSide.far ? old.farHands : target,
      turn: old.turn.opponent,
    );
    GameResult? result;
    if (target.every((v) => v == 0)) {
      result = GameResult(
        GameEndReason.eliminated,
        GameResult.winner(old.turn),
      );
    } else if (session.visitedPositions.contains(next.key)) {
      final near = next.nearHands.reduce((a, b) => a + b);
      final far = next.farHands.reduce((a, b) => a + b);
      result = GameResult(
        GameEndReason.loop,
        near == far
            ? GameOutcome.draw
            : near < far
            ? GameOutcome.nearWin
            : GameOutcome.farWin,
      );
    }
    return GameSession(
      next,
      visitedPositions: {...session.visitedPositions, next.key},
      result: result,
    );
  }
}

/// Unordered triples and pairs: precisely the 52 combinations in the specification.
class InitialPositionGenerator {
  InitialPositionGenerator(this.random);
  final Random random;
  static final List<(List<int>, List<int>)> combinations = _combinations();
  static List<(List<int>, List<int>)> _combinations() {
    final triples = [
      for (var a = 1; a <= 4; a++)
        for (var b = a; b <= 4; b++)
          for (var c = b; c <= 4; c++) [a, b, c],
    ];
    return List.unmodifiable([
      for (var i = 0; i < triples.length; i++)
        for (var j = i; j < triples.length; j++)
          if (!triples[i].any((a) => triples[j].any((b) => a + b == 5)))
            (
              List<int>.unmodifiable(triples[i]),
              List<int>.unmodifiable(triples[j]),
            ),
    ]);
  }

  GameSession generate() {
    final pair = combinations[random.nextInt(combinations.length)];
    final a = [...pair.$1]..shuffle(random);
    final b = [...pair.$2]..shuffle(random);
    final swap = random.nextBool();
    return GameSession(
      GamePosition(
        nearHands: swap ? b : a,
        farHands: swap ? a : b,
        turn: random.nextBool() ? PlayerSide.near : PlayerSide.far,
      ),
    );
  }
}
