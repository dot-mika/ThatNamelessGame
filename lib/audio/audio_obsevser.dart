import 'dart:async';

import 'package:flutter/widgets.dart';

import '../settings/settings_state.dart';
import 'audio_controller.dart';

/// 音声の準備前からアプリの状態を追跡し、起動後も再生状態へ反映する。
class AudioObsevser with WidgetsBindingObserver {

  // 今このアプリが前面にいればtrueで初期化する
  AudioObsevser()
    : _foreground =
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed {
    
    // Flutterアプリ全体の状態を管理してる WidgetsBinding を取ってくる
    final binding = WidgetsBinding.instance;

    // AudioObsevser(いまのクラスのインスタンス) を、アプリ状態変化の監視対象として登録する
    binding.addObserver(this);
  }

  // アプリが前面にいるかを格納する変数
  bool _foreground;
  
  AudioController? _audio;

  Future<void> attach(AudioController audio, AppSettings settings) {
    _audio = audio;
    return audio.applySettings(settings, foreground: _foreground);
  }

  void detach() => _audio = null;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    unawaited(_audio?.setForeground(_foreground));
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    detach();
  }
}
