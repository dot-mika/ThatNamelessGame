import 'package:flutter/material.dart';

import '../../config/app_language.dart';
import '../../config/assets.dart';
import '../../config/config.dart';

part 'rules_2_page.dart';
part 'rules_3_animation.dart';
part 'rules_4_animation.dart';
part 'rules_5_animation.dart';
part 'rules_6_animation.dart';
part 'rules_7_page.dart';
part 'rules_8_page.dart';
part 'rules_9_page.dart';

/// 元は静止画だったルール2・7・8・9ページを、対局画面の素材とコードで描くページ
/// 座標は元画像（1440×810）を1280×720へ縮めて実測した値
/// 各ページの中身は rules_N_page.dart にある
class RuleStillPage extends StatelessWidget {
  const RuleStillPage({super.key, required this.page, required this.language});

  final int page;
  final AppLanguage language;

  static bool supports(int page) => _stillPages.containsKey(page);

  @override
  Widget build(BuildContext context) => _stillPages[page]!(language);
}

const _stillPages = {2: _rules2, 7: _rules7, 8: _rules8, 9: _rules9};

/// 元はGIFだったルール3〜6ページを、対局画面の素材とコードで再現するページ
/// 座標と時間は元GIF（1280×720）の各フレームを実測した値
/// 各ページの中身は rules_N_animation.dart にある
class RuleAnimationPage extends StatefulWidget {
  const RuleAnimationPage({
    super.key,
    required this.page,
    required this.language,
    required this.isActive,
  });

  final int page;
  final AppLanguage language;

  /// 画面がこのページで止まっている間だけ再生し、それ以外は先頭フレームで止めておく
  final bool isActive;

  static bool supports(int page) => _scenes.containsKey(page);

  /// 元GIFの経過秒数で指定した時点の1フレームを組み立てる
  @visibleForTesting
  static Widget frame(int page, AppLanguage language, double gifSeconds) =>
      _scenes[page]!.build(language, gifSeconds);

  @override
  State<RuleAnimationPage> createState() => _RuleAnimationPageState();
}

class _RuleAnimationPageState extends State<RuleAnimationPage>
    with SingleTickerProviderStateMixin {
  late final _scene = _scenes[widget.page]!;
  late final _controller = AnimationController(
    vsync: this,
    duration: _scene.duration,
  );

  @override
  void initState() {
    super.initState();
    if (widget.isActive) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant RuleAnimationPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive == oldWidget.isActive) return;
    // 戻ってきた時も先頭から再生するため、離れた時点で先頭へ戻す
    _controller.reset();
    if (widget.isActive) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) => _scene.build(
      widget.language,
      _scene.skip + _controller.value * _scene.duration.inMicroseconds / 1e6,
    ),
  );
}

/// 最初の動きが始まるまでの待ち時間（元GIFは1.6〜2.25秒）
const _firstChangeAt = 1.0;

class _RuleScene {
  /// [gifSeconds]は元GIFの長さ、[firstChange]は元GIFで最初に絵が変わる秒数
  const _RuleScene({
    required this.gifSeconds,
    required double firstChange,
    required this.build,
  }) : skip = firstChange - _firstChangeAt;

  final double gifSeconds;

  /// 冒頭の静止部分を短くするため、元GIFの先頭から飛ばす秒数
  final double skip;
  final Widget Function(AppLanguage language, double gifSeconds) build;

  Duration get duration =>
      Duration(microseconds: ((gifSeconds - skip) * 1e6).round());
}

const _scenes = {
  3: _RuleScene(gifSeconds: 8.25, firstChange: 2.25, build: _rules3),
  4: _RuleScene(gifSeconds: 6.74, firstChange: 2.17, build: _rules4),
  5: _RuleScene(gifSeconds: 8.73, firstChange: 2.25, build: _rules5),
  6: _RuleScene(gifSeconds: 8.44, firstChange: 1.6, build: _rules6),
};

/// [start]〜[end]秒の進み具合を0〜1で返す
double _progress(double seconds, double start, double end) =>
    ((seconds - start) / (end - start)).clamp(0.0, 1.0);

double _lerp(double a, double b, double t) => a + (b - a) * t;

/// 対局背景の上に各要素を1280×720の座標で重ねる
class _RuleStage extends StatelessWidget {
  const _RuleStage({required this.background, required this.children});

  final Color background;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Image(
        image: Assets.image(Assets.ruleBackground(background)),
        fit: BoxFit.cover,
        gaplessPlayback: true,
      ),
      ...children,
    ],
  );
}

/// 左上の説明文　`{}`で囲んだ部分を強調色で描く
class _Caption extends StatelessWidget {
  const _Caption({
    required this.top,
    required this.lines,
    this.left = 53,
    this.fontSize = 40,
    this.lineHeight = 40,
    this.color = AppColors.black,
    this.accent = AppColors.black,
  });

  final double left;
  final double top;
  final double fontSize;
  final double lineHeight;
  final List<String> lines;
  final Color color;
  final Color accent;

  List<TextSpan> _spans(String line) {
    final spans = <TextSpan>[];
    for (final (index, part) in line.split(RegExp('[{}]')).indexed) {
      if (part.isEmpty) continue;
      spans.add(
        TextSpan(
          text: part,
          style: index.isOdd ? TextStyle(color: accent) : null,
        ),
      );
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      for (final (index, line) in lines.indexed)
        Positioned(
          left: left,
          top: top + index * lineHeight,
          child: Text.rich(
            TextSpan(children: _spans(line)),
            maxLines: 1,
            softWrap: false,
            style: _ruleTextStyle(fontSize, color),
          ),
        ),
    ],
  );
}

/// [foreground]を渡すと、[color]の代わりにその描き方（縁取りなど）を使う
TextStyle _ruleTextStyle(double fontSize, Color color, {Paint? foreground}) =>
    TextStyle(
      fontFamily: 'Rwi',
      fontSize: fontSize,
      height: 1,
      // 元画像の文字間隔は標準よりわずかに詰まっている
      letterSpacing: -0.125,
      color: foreground == null ? color : null,
      foreground: foreground,
    );

/// [centerX]を中心にした1行の文字　[outlined]なら白いふちを付ける
class _CenteredText extends StatelessWidget {
  const _CenteredText(
    this.text, {
    required this.centerX,
    required this.top,
    required this.fontSize,
    this.color = AppColors.black,
    this.outlined = false,
  });

  final String text;
  final double centerX;
  final double top;
  final double fontSize;
  final Color color;
  final bool outlined;

  /// 「勝ち」「負け」などの白いふちの太さ（文字の外側に出る幅はこの半分）
  static const _outlineWidth = 6.0;

  Widget _text(TextStyle style) =>
      Text(text, textAlign: TextAlign.center, maxLines: 1, style: style);

  @override
  Widget build(BuildContext context) {
    final style = _ruleTextStyle(fontSize, color);
    return Positioned(
      left: centerX - 200,
      width: 400,
      top: top,
      child: outlined
          // 白い線で縁取った文字の上に、同じ位置で本体の文字を重ねる
          ? Stack(
              alignment: Alignment.topCenter,
              children: [
                _text(
                  _ruleTextStyle(
                    fontSize,
                    color,
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = _outlineWidth
                      ..strokeJoin = StrokeJoin.round
                      ..color = AppColors.white,
                  ),
                ),
                _text(style),
              ],
            )
          : _text(style),
    );
  }
}

/// ボタンを押した瞬間を表す集中線　rules_3とrules_9で同じ大きさ
class _Syuchusen extends StatelessWidget {
  const _Syuchusen({required this.left, required this.top});

  final double left;
  final double top;

  @override
  Widget build(BuildContext context) => Positioned(
    left: left,
    top: top,
    width: 149.6,
    height: 132.9,
    child: IgnorePointer(
      child: Image(
        image: Assets.image(Assets.rulesSyuchusen),
        fit: BoxFit.fill,
        gaplessPlayback: true,
      ),
    ),
  );
}

/// 手の上下にある「相手」「自分」
class _SideLabels extends StatelessWidget {
  const _SideLabels({required this.language, required this.opponentTop});

  static const youTop = 655.0;

  final AppLanguage language;
  final double opponentTop;

  Widget _label(String text, double top) => Positioned(
    left: 0,
    right: 0,
    top: top,
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: _ruleTextStyle(26.67, AppColors.black),
    ),
  );

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      _label(RuleStrings.opponent(language), opponentTop),
      _label(RuleStrings.you(language), youTop),
    ],
  );
}

/// 対局画面の手の画像　選択時は幅を保ったまま縦に1.2倍の画像になる
class _RuleHand extends StatelessWidget {
  const _RuleHand({
    required this.value,
    required this.left,
    required this.top,
    required this.size,
    this.selected = false,
    this.upsideDown = false,
  });

  /// 相手側の手　上端をそろえて逆さに描く
  const _RuleHand.far({
    required this.value,
    required this.left,
    required this.top,
    required this.size,
    this.selected = false,
  }) : upsideDown = true;

  /// 自分側の手　下端をそろえて描く
  _RuleHand.near({
    required this.value,
    required this.left,
    required double bottom,
    required this.size,
    this.selected = false,
  }) : upsideDown = false,
       top = bottom - _height(size, selected);

  static double _height(double size, bool selected) =>
      selected ? size * 1.2 : size;

  final int value;
  final double left;
  final double top;
  final double size;
  final bool selected;
  final bool upsideDown;

  @override
  Widget build(BuildContext context) => Positioned(
    left: left,
    top: top,
    width: size,
    height: _height(size, selected),
    child: RotatedBox(
      quarterTurns: upsideDown ? 2 : 0,
      child: Image(
        image: Assets.image(Assets.hand(value, selected)),
        fit: BoxFit.fill,
        gaplessPlayback: true,
      ),
    ),
  );
}
