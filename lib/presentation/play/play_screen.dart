import 'package:flutter/material.dart';

import '../../config/config.dart';

/// プレイ画面(仮実装)。フェーズ状態機械などは実装順⑦で追加する。
class PlayScreen extends StatelessWidget {
  const PlayScreen({super.key, required this.mode});

  final PlayMode mode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          'Play: $mode',
          style: const TextStyle(color: Colors.white, fontSize: 32),
        ),
      ),
    );
  }
}
