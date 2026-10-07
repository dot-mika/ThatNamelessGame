part of 'rule_animations.dart';

/// ③自分の指の本数が相手の手に足される
Widget _rules4(AppLanguage language, double t) {
  const size = 156.0;
  const farTop = 253.0;
  const nearBottom = 630.8;
  final done = t >= 2.74;
  final move = _progress(t, 2.17, 2.65);
  return _RuleStage(
    background: AppColors.rules4Blue,
    children: [
      _Caption(top: 58, lines: RuleStrings.page4(language)),
      _SideLabels(language: language, opponentTop: 208),
      _RuleHand.far(value: 1, left: 407.1, top: farTop, size: size),
      _RuleHand.far(
        value: done ? 2 : 1,
        left: 563.0,
        // 足された後の2本の手だけ、元画像では少し下に置かれている
        top: done ? 254.7 : farTop,
        size: size,
        selected: !done,
      ),
      _RuleHand.far(value: 1, left: 717.1, top: farTop, size: size),
      _RuleHand.near(value: 1, left: 407.1, bottom: nearBottom, size: size),
      _RuleHand.near(value: 1, left: 563.1, bottom: nearBottom, size: size),
      if (done)
        _RuleHand.near(value: 1, left: 719.1, bottom: nearBottom, size: size)
      else
        // 選んだ自分の手が、相手の選んだ手の指先まで等速で動く
        _RuleHand(
          value: 1,
          left: _lerp(716.9, 562.9, move),
          top: _lerp(442.8, 347.5, move),
          size: size,
          selected: true,
        ),
    ],
  );
}
