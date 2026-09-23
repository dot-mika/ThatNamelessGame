import 'dart:math';

import '../config/initial_hands.dart';

/// 画面上の位置を基準にしたプレイヤー側。手番判定にも使う。
enum PlayerSide {
  near,
  far;

  PlayerSide get opponent => this == near ? far : near;
}

/// 各プレイヤーが持つ3本の手の位置。
enum HandPosition { left, center, right }

enum GameEndReason { eliminated, timeout, loop }

enum GameOutcome { nearWin, farWin, draw }

/// Immutable rule set for one match. Keeping rule constants here prevents
/// game logic from depending on unexplained numeric literals.
class GameRules {
  const GameRules({this.handCount = 3, this.fingerModulo = 5})
    : assert(handCount > 0),
      assert(fingerModulo > 1);

  static const standard = GameRules();

  final int handCount;
  final int fingerModulo;
}

/// ある瞬間の手の値と手番だけを表す、不変の局面データ。
class GamePosition {
  GamePosition({
    required List<int> nearHands,
    required List<int> farHands,
    required this.turn,
    this.rules = GameRules.standard,
  }) : nearHands = List.unmodifiable(nearHands),
       farHands = List.unmodifiable(farHands) {
    if (nearHands.length != rules.handCount ||
        farHands.length != rules.handCount ||
        [...nearHands, ...farHands].any(
          (value) => value < 0 || value >= rules.fingerModulo,
        )) {
      throw ArgumentError(
        'Each side needs ${rules.handCount} hands with values '
        '0–${rules.fingerModulo - 1}.',
      );
    }
  }
  final List<int> nearHands, farHands;
  final PlayerSide turn;
  final GameRules rules;
  List<int> hands(PlayerSide side) =>
      side == PlayerSide.near ? nearHands : farHands;
  int get key =>
      [...nearHands, ...farHands].fold(
        turn.index,
        (key, value) => key * rules.fingerModulo + value,
      );

  @override
  bool operator ==(Object other) =>
      other is GamePosition &&
      turn == other.turn &&
      rules.handCount == other.rules.handCount &&
      rules.fingerModulo == other.rules.fingerModulo &&
      _sameHands(nearHands, other.nearHands) &&
      _sameHands(farHands, other.farHands);

  @override
  int get hashCode => Object.hash(
    turn,
    rules.handCount,
    rules.fingerModulo,
    Object.hashAll(nearHands),
    Object.hashAll(farHands),
  );
}

class GameMove {
  const GameMove(this.attackerPosition, this.targetPosition);
  final HandPosition attackerPosition, targetPosition;

  @override
  bool operator ==(Object other) =>
      other is GameMove &&
      attackerPosition == other.attackerPosition &&
      targetPosition == other.targetPosition;

  @override
  int get hashCode => Object.hash(attackerPosition, targetPosition);
}


/// 終局理由と勝敗をまとめた結果データ。
class GameResult {
  const GameResult(this.reason, this.outcome);
  final GameEndReason reason;
  final GameOutcome outcome;
  static GameOutcome winner(PlayerSide side) =>
      side == PlayerSide.near ? GameOutcome.nearWin : GameOutcome.farWin;

  @override
  bool operator ==(Object other) =>
      other is GameResult && reason == other.reason && outcome == other.outcome;

  @override
  int get hashCode => Object.hash(reason, outcome);
}


/// 局面に加えて、ループ判定用の既出局面を持つ対局データ。
class GameSession {
  GameSession(this.position, {Set<int>? visitedPositions, this.result})
    : visitedPositions = Set.unmodifiable(visitedPositions ?? {position.key});
  final GamePosition position;
  final Set<int> visitedPositions;
  final GameResult? result;

  @override
  bool operator ==(Object other) =>
      other is GameSession &&
      position == other.position &&
      result == other.result &&
      visitedPositions.length == other.visitedPositions.length &&
      visitedPositions.containsAll(other.visitedPositions);

  @override
  int get hashCode => Object.hash(position, result, Object.hashAll(visitedPositions));
}

/// UIや音に依存しない、ゲーム規則だけを扱うクラス。
class GameEngine {
  const GameEngine();

  /// 生きた手同士で作れる、現在の全合法手を列挙する。
  List<GameMove> legalMoves(GameSession session) => [
    for (final a in HandPosition.values)
      for (final b in HandPosition.values)
        if (isLegalMove(session, GameMove(a, b))) GameMove(a, b),
  ];

  /// 終局前で、攻撃側・対象側の両方が0以外なら合法とする。
  bool isLegalMove(GameSession session, GameMove move) =>
      session.result == null &&
      move.attackerPosition.index < session.position.rules.handCount &&
      move.targetPosition.index < session.position.rules.handCount &&
      session.position.hands(
            session.position.turn,
          )[move.attackerPosition.index] !=
          0 &&
      session.position.hands(
            session.position.turn.opponent,
          )[move.targetPosition.index] !=
          0;

  /// 1手を適用して、新しい対局データを返す。
  /// 元の[session]は変更しないため、攻撃アニメーション中でも
  /// 適用前と適用後の局面を同時に安全に保持できる。
  GameSession applyMove(GameSession session, GameMove move) {
    if (!isLegalMove(session, move)) throw ArgumentError('Illegal move');
    final old = session.position;
    final positionRules = old.rules;
    final target = [...old.hands(old.turn.opponent)];
    // 指の本数は5で循環する。5になった手は0（消滅）になる。
    target[move.targetPosition.index] =
        (target[move.targetPosition.index] +
            old.hands(old.turn)[move.attackerPosition.index]) %
        positionRules.fingerModulo;
    final next = GamePosition(
        nearHands: old.turn == PlayerSide.near ? old.nearHands : target,
        farHands: old.turn == PlayerSide.far ? old.farHands : target,
        turn: old.turn.opponent,
        rules: positionRules,
    );
    GameResult? result;
    if (target.every((v) => v == 0)) {
      result = GameResult(
        GameEndReason.eliminated,
        GameResult.winner(old.turn),
      );
    } else if (session.visitedPositions.contains(next.key)) {
      // 同一局面へ戻ったら、残っている手の本数でループの勝敗を決める。
      final near = next.nearHands.where((fingers) => fingers != 0).length;
      final far = next.farHands.where((fingers) => fingers != 0).length;
      result = GameResult(
        GameEndReason.loop,
        near == far
            ? GameOutcome.draw
            : near > far
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

bool _sameHands(List<int> first, List<int> second) {
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) return false;
  }
  return true;
}

/// Unordered triples and pairs permitted as starting hands.
/// 2人プレイとかんたん用の通常初期局面を抽選する。
class InitialPositionGenerator {
  InitialPositionGenerator(this.random);
  final Random random;
  static final List<(List<int>, List<int>)> combinations = List.unmodifiable(
    InitialHands.common.map(
      (pair) => (
        List<int>.unmodifiable(pair.first),
        List<int>.unmodifiable(pair.second),
      ),
    ),
  );

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

/// The fixed 28-opening pool used by normal and hard solo play.
/// ふつう・むずかしい用の、仕様で固定された28局面を抽選する。
class SoloInitialPositionGenerator {
  SoloInitialPositionGenerator(this.random);
  final Random random;

  GameSession generate() {
    final opening = InitialHands.solo[random.nextInt(InitialHands.solo.length)];
    final near = [...opening.playerHands]..shuffle(random);
    final far = [...opening.cpuHands]..shuffle(random);
    return GameSession(
      GamePosition(
        nearHands: near,
        farHands: far,
        turn: opening.playerStarts ? PlayerSide.near : PlayerSide.far,
      ),
    );
  }
}
