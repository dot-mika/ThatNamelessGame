part of 'rule_animations.dart';

/// ①3本の手で向かい合い、最初の本数はランダムに決まる
Widget _rules2(AppLanguage language) {
  const size = 130.5;
  const farTop = 302.0;
  const nearBottom = 605.6;
  const cases = [
    // 相手の手、自分の手の本数を左から並べる
    (lefts: [205.8, 335.5, 467.2], far: [1, 1, 1], near: [1, 1, 1]),
    (lefts: [672.5, 803.0, 933.6], far: [1, 2, 1], near: [2, 2, 1]),
  ];
  final jp = language == AppLanguage.jp;
  // 英語版は文章が1行多いぶん、図全体が右下へずれている
  final dx = jp ? 0.0 : 5.5;
  final dy = jp ? 0.0 : 25.5;
  return _RuleStage(
    background: AppColors.rules2Yellow,
    children: [
      _Caption(
        top: 58.5,
        fontSize: 46.67,
        lines: RuleStrings.page2Title(language),
      ),
      _Caption(
        left: 106,
        top: 142,
        accent: AppColors.yellow,
        lines: RuleStrings.page2(language),
      ),
      for (final (index, hands) in cases.indexed) ...[
        for (final (i, left) in hands.lefts.indexed) ...[
          _RuleHand.far(
            value: hands.far[i],
            left: left + dx,
            top: farTop + dy,
            size: size,
          ),
          _RuleHand.near(
            value: hands.near[i],
            left: left + dx,
            bottom: nearBottom + dy,
            size: size,
          ),
        ],
        _CenteredText(
          RuleStrings.caseLabel(language, index + 1),
          centerX: hands.lefts[1] + size / 2 + dx,
          top: jp ? 617 : 635.5,
          fontSize: 26,
        ),
      ],
    ],
  );
}
