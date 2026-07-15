import 'package:flutter/material.dart';

/// ルール画面(仮実装)。PageView によるスワイプ説明は実装順⑧で追加する。
class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Rules (TODO) - back'),
        ),
      ),
    );
  }
}
