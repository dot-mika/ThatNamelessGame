import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 手のPNGにプレイヤー色の縁取りを付けて描画する部品
/// 選択時は幅を固定したまま縦方向へ拡大する
class HandArtwork extends StatelessWidget {
  const HandArtwork({
    super.key,
    required this.asset,
    required this.color,
    required this.selected,
  });

  static const frameWidth = 220.0;
  // 選択時PNGは250×300、通常PNGは300×300である
  static double frameHeight(bool selected) => selected ? 261 : frameWidth;
  static const _outlineRadius = 5.0;
  static const _outlineSamples = 12;

  final String asset;
  final Color color;
  final bool selected;

  Widget _image({Color? tint}) => Image.asset(
    asset,
    fit: BoxFit.fitWidth,
    alignment: Alignment.bottomCenter,
    color: tint,
    colorBlendMode: tint == null ? null : BlendMode.srcIn,
  );

  @override
  Widget build(BuildContext context) => SizedBox(
    width: frameWidth,
    height: frameHeight(selected),
    child: Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        // 元画像の色を変えず、アルファ形状だけを膨張させて縁取りする
        for (var i = 0; i < _outlineSamples; i++)
          Transform.translate(
            offset: Offset(
              math.cos(i * math.pi / (_outlineSamples / 2)) * _outlineRadius,
              math.sin(i * math.pi / (_outlineSamples / 2)) * _outlineRadius,
            ),
            child: _image(tint: color),
          ),
        _image(),
      ],
    ),
  );
}
