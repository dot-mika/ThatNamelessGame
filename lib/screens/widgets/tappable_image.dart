import 'dart:async';

import 'package:flutter/material.dart';

import '../../config/config.dart';

class TappableImage extends StatefulWidget {
  const TappableImage({
    super.key,
    required this.asset,
    required this.onTap,
    this.semanticLabel,
    this.opacity = 1,
    this.fit,
  });

  final String asset;
  final FutureOr<void> Function() onTap;
  final String? semanticLabel;
  final double opacity;
  final BoxFit? fit;

  @override
  State<TappableImage> createState() => _TappableImageState();
}

class _TappableImageState extends State<TappableImage> {
  bool _busy = false;
  Timer? _cooldown;

  Future<void> _handleTap() async {
    if (_busy || (_cooldown?.isActive ?? false)) return;
    _busy = true;
    _cooldown = Timer(AppConfig.tapCooldown, () {});
    try {
      // Navigator.push completes when the destination is closed.
      await widget.onTap();
    } finally {
      _busy = false;
    }
  }

  @override
  void dispose() {
    _cooldown?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: widget.semanticLabel,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _handleTap,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        child: Opacity(
          opacity: widget.opacity,
          child: Image.asset(widget.asset, fit: widget.fit),
        ),
      ),
    ),
  );
}
