import 'package:flutter/material.dart';

/// ルール/設定⇔ホームの遷移用(仕様書: 「瞬時に切り替える(モーションなし)」)。
Route<T> noAnimationRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, a, b) => page,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
  );
}

/// ホーム→プレイ画面の遷移用(仕様書: 「右方向へスライドするモーションをつける」)。
Route<T> slideFromRightRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, a, b) => page,
    transitionsBuilder: (_, animation, a, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}
