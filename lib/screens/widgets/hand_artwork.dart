import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Figma aligns every hand by width; a selected hand grows vertically.
/// 手のPNGへ外枠と選択状態の見た目を重ねて描画する部品。
class HandArtwork extends StatelessWidget {
  const HandArtwork({
    super.key,
    required this.asset,
    required this.color,
    required this.selected,
  });

  static const frameWidth = 220.0;
  // Selected PNGs are 250 × 300 while ordinary PNGs are 300 × 300.
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
        // Dilate the alpha silhouette without tinting the original artwork.
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
