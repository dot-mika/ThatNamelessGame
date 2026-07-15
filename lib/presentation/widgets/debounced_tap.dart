import 'package:flutter/material.dart';

import '../../config/config.dart';

/// 連打対策つきの GestureDetector 代替。
///
/// 直前のタップから [AppConfig.tapCooldown] 以内の再タップは無視する。
/// 画面遷移+SE のような処理が終わる前に何度もタップされて、同じ画面が
/// Navigator に積み重なったり同じ音声プレイヤーに再生要求が殺到したりする
/// (エミュレータで顕著)のを防ぐため、全画面のタップ操作で共通して使う。
class DebouncedTap extends StatefulWidget {
  const DebouncedTap({super.key, required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  State<DebouncedTap> createState() => _DebouncedTapState();
}

class _DebouncedTapState extends State<DebouncedTap> {
  DateTime? _lastTap;

  void _handleTap() {
    final now = DateTime.now();
    if (_lastTap != null && now.difference(_lastTap!) < AppConfig.tapCooldown) {
      return;
    }
    _lastTap = now;
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: _handleTap, child: widget.child);
  }
}
