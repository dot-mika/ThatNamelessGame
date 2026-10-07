part of 'rule_animations.dart';

/// ②自分のターン：手を2つ選び、けっていを押す
Widget _rules3(AppLanguage language, double t) {
  const size = 133.0;
  const lefts = [427.2, 567.2, 707.2];
  const farTop = 300.2;
  const nearBottom = 633.0;
  final nearSelected = t >= 2.25;
  final farSelected = t >= 3.25;
  return _RuleStage(
    background: AppColors.rules3Green,
    children: [
      _Caption(
        top: 56,
        lineHeight: 40.6,
        accent: AppColors.green,
        lines: RuleStrings.page3(language),
      ),
      _SideLabels(language: language, opponentTop: 253),
      for (final left in lefts)
        _RuleHand.far(
          value: 1,
          left: left,
          top: farTop,
          size: size,
          selected: farSelected && left == lefts[1],
        ),
      for (final left in lefts)
        _RuleHand.near(
          value: 1,
          left: left,
          bottom: nearBottom,
          size: size,
          selected: nearSelected && left == lefts[2],
        ),
      _ConfirmLabel(language: language),
      if (t >= 4.25) const _Syuchusen(left: 892.7, top: 500.6),
    ],
  );
}

/// rules_3の「けってい」ボタン
class _ConfirmLabel extends StatelessWidget {
  const _ConfirmLabel({required this.language});

  final AppLanguage language;

  @override
  Widget build(BuildContext context) => Positioned(
    left: 831,
    top: 436,
    width: 140,
    height: 86,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.rules3Green,
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 2,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          AppStrings.confirm(language),
          style: _ruleTextStyle(32, AppColors.black),
        ),
      ),
    ),
  );
}
