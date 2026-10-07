part of 'rule_animations.dart';

/// ④相手のターン：相手の指の本数が自分の手に足される
Widget _rules5(AppLanguage language, double t) {
  const size = 140.0;
  const lefts = [431.0, 571.0, 711.0];
  const farTop = 299.9;
  const nearBottom = 638.9;
  final done = t >= 4.73;
  final farSelected = t >= 2.25 && !done;
  final nearSelected = t >= 3.25 && !done;
  final move = _progress(t, 4.17, 4.65);
  return _RuleStage(
    background: AppColors.rules5Purple,
    children: [
      _Caption(top: 58, lines: RuleStrings.page5(language)),
      _SideLabels(language: language, opponentTop: 261),
      _RuleHand.far(value: 1, left: lefts[0], top: farTop, size: size),
      _RuleHand.far(value: 1, left: lefts[2], top: farTop, size: size),
      for (final left in [lefts[0], lefts[2]])
        _RuleHand.near(value: 1, left: left, bottom: nearBottom, size: size),
      // このページだけ、選択中の手は通常時より外側へはみ出して描かれている
      if (nearSelected)
        _RuleHand(
          value: 1,
          left: lefts[1],
          top: 476.4,
          size: size,
          selected: true,
        )
      else
        _RuleHand.near(
          value: done ? 3 : 1,
          left: lefts[1],
          bottom: nearBottom,
          size: size,
        ),
      if (farSelected)
        // 相手の選んだ手が真下へ等速で動く
        _RuleHand(
          value: 2,
          left: lefts[1],
          top: _lerp(296.9, 391.2, move),
          size: size,
          selected: true,
          upsideDown: true,
        )
      else
        _RuleHand.far(value: 2, left: lefts[1], top: farTop, size: size),
    ],
  );
}
