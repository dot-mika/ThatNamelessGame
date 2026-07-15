import 'dart:async';

import 'package:flutter/material.dart';

/// 画面遷移・確認ダイアログの選択など「その場に留まったまま連打されうる」
/// 操作用の GestureDetector 代替。
///
/// [DebouncedTap] のような時間ベースの間引きではなく、[onTap] の実行中は
/// 完全にタップを無視し、完了したら再度タップ可能に戻る。遷移先の画面が
/// push されている間に同じ画面が Navigator に積み重なる、SE の再生要求が
/// 重複する、といった連打による不具合を確実に防ぐため、ルール・設定・
/// 各プレイボタン・ホームへ戻る・確認ダイアログの選択肢に使う。
class NavigationTap extends StatefulWidget {
  const NavigationTap({super.key, required this.onTap, required this.child});

  final FutureOr<void> Function() onTap;
  final Widget child;

  @override
  State<NavigationTap> createState() => _NavigationTapState();
}

class _NavigationTapState extends State<NavigationTap> {
  bool _busy = false;

  Future<void> _handleTap() async {
    if (_busy) return;
    _busy = true;
    await widget.onTap();
    if (mounted) _busy = false;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: _handleTap, child: widget.child);
  }
}
