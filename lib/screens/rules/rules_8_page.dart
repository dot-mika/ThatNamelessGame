part of 'rule_animations.dart';

/// ⑦ループしたら残りの手が多い方が勝ち、同じなら引き分け
Widget _rules8(AppLanguage language) {
  const size = 119.0;
  const farTop = 306.5;
  const cases = [
    // 相手の手、自分の手の本数を左から並べる
    (
      lefts: [240.5, 358.7, 477.0],
      far: [0, 0, 1],
      near: [1, 3, 0],
      nearBottom: 545.2,
    ),
    (
      lefts: [683.2, 802.0, 920.5],
      far: [0, 0, 1],
      near: [0, 3, 0],
      nearBottom: 556.3,
    ),
  ];
  final jp = language == AppLanguage.jp;
  // 英語版は図全体が少し下にずれている
  final dy = jp ? 0.0 : 10.5;
  final loseCenter = cases[0].lefts[1] + size / 2;
  final drawCenter = cases[1].lefts[1] + size / 2;
  return _RuleStage(
    background: AppColors.rules8Yellow,
    children: [
      _Caption(
        top: jp ? 59 : 60,
        accent: AppColors.yellow,
        lines: RuleStrings.page8(language),
      ),
      for (final hands in cases)
        for (final (i, left) in hands.lefts.indexed) ...[
          _RuleHand.far(
            value: hands.far[i],
            left: left,
            top: farTop + dy,
            size: size,
          ),
          _RuleHand.near(
            value: hands.near[i],
            left: left,
            bottom: hands.nearBottom + dy,
            size: size,
          ),
        ],
      _CenteredText(
        RuleStrings.lose(language),
        centerX: loseCenter,
        top: 264 + dy,
        fontSize: 43.5,
        color: AppColors.rulesLoseBlue,
        outlined: true,
      ),
      _CenteredText(
        RuleStrings.win(language),
        centerX: loseCenter,
        top: 545.5 + dy,
        fontSize: 43.5,
        outlined: true,
        color: AppColors.rulesWinRed,
      ),
      _CenteredText(
        RuleStrings.draw(language),
        centerX: drawCenter,
        top: 394.5 + dy,
        fontSize: 43.5,
        outlined: true,
      ),
    ],
  );
}
