part of 'rule_animations.dart';

/// ⑤ちょうど5本で使えなくなり、6本以上は5で割った余りになる
Widget _rules6(AppLanguage language, double t) {
  const size = 144.0;
  const lefts = [428.0, 568.0, 712.0];
  const farTop = 353.2;
  const nearBottom = 702.9;
  final done = t >= 3.44;
  final farSelected = t >= 1.6 && !done;
  final move = Curves.ease.transform(_progress(t, 2.32, 3.12));
  return _RuleStage(
    background: AppColors.rules6Pink,
    children: [
      _Caption(
        top: 55,
        color: AppColors.settingsBlack,
        accent: AppColors.pink,
        lines: RuleStrings.page6(language),
      ),
      _RuleHand.far(value: 1, left: lefts[0], top: farTop, size: size),
      _RuleHand.far(
        value: done ? 0 : 2,
        left: lefts[1],
        top: farTop,
        size: size,
        selected: farSelected,
      ),
      _RuleHand.far(value: 1, left: lefts[2], top: farTop, size: size),
      _RuleHand.near(value: 1, left: lefts[0], bottom: nearBottom, size: size),
      _RuleHand.near(value: 1, left: lefts[2], bottom: nearBottom, size: size),
      if (done)
        _RuleHand.near(value: 3, left: lefts[1], bottom: nearBottom, size: size)
      else
        // 選択済みの自分の手が、減速しながら相手の手へ近づく
        _RuleHand(
          value: 3,
          left: lefts[1],
          top: _lerp(530.2, 440.0, move),
          size: size,
          selected: true,
        ),
    ],
  );
}
