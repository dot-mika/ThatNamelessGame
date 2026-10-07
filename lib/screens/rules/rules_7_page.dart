part of 'rule_animations.dart';

/// ⑥全部の手が使えなくなった方が負け
Widget _rules7(AppLanguage language) {
  const size = 144.0;
  const lefts = [423.4, 567.6, 712.4];
  const farTop = 292.2;
  const nearBottom = 581.0;
  const near = [1, 3, 1];
  return _RuleStage(
    background: AppColors.rules7Red,
    children: [
      _Caption(top: 58, lines: RuleStrings.page7(language)),
      for (final left in lefts)
        _RuleHand.far(value: 0, left: left, top: farTop, size: size),
      for (final (i, left) in lefts.indexed)
        _RuleHand.near(
          value: near[i],
          left: left,
          bottom: nearBottom,
          size: size,
        ),
      _CenteredText(
        RuleStrings.lose(language),
        centerX: 640,
        top: 228,
        fontSize: 64.5,
        color: AppColors.rulesLoseBlue,
        outlined: true,
      ),
      _CenteredText(
        RuleStrings.win(language),
        centerX: 640,
        top: 580.5,
        fontSize: 64.5,
        color: AppColors.rulesWinRed,
        outlined: true,
      ),
    ],
  );
}
