part of 'rule_animations.dart';

/// ⑧プレイ回数や連勝数に応じてホーム画面の星が変わる
Widget _rules9(AppLanguage language) {
  final jp = language == AppLanguage.jp;
  return _RuleStage(
    background: AppColors.rules9Green,
    children: [
      _Caption(
        top: jp ? 57 : 57.5,
        lineHeight: jp ? 40 : 40.3,
        lines: RuleStrings.page9(language),
      ),
      _Caption(
        left: 97,
        top: jp ? 239 : 238,
        fontSize: 26.67,
        lineHeight: 27,
        lines: RuleStrings.page9Note(language),
      ),
      // ホーム画面の「1人プレイ むずかしい」ボタンを元画像のカードと同じ大きさで置く
      Positioned(
        left: 456.9,
        top: 360,
        width: 364.9,
        height: 229.7,
        child: _HomeHardButton(language: language),
      ),
      const _Syuchusen(left: 738.7, top: 526.1),
    ],
  );
}

/// ホーム画面のモード選択ボタン（_ModeButton）と同じ組み方で、
/// 278×175の枠にボタン画像と黄色い星を重ねて拡大表示する
class _HomeHardButton extends StatelessWidget {
  const _HomeHardButton({required this.language});

  final AppLanguage language;

  @override
  Widget build(BuildContext context) => FittedBox(
    child: SizedBox(
      width: 278,
      height: 175,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image(
              image: Assets.image(Assets.playHard(language)),
              gaplessPlayback: true,
            ),
          ),
          Positioned(
            right: 21,
            bottom: 17,
            width: 60,
            height: 60,
            child: Image(
              image: Assets.image(Assets.starYellow),
              gaplessPlayback: true,
            ),
          ),
        ],
      ),
    ),
  );
}
