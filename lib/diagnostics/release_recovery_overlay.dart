import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/config.dart';
import '../settings/settings_notifier.dart';
import 'app_runtime_policy.dart';

/// リリースで復旧不能な例外が起きたことをアプリ全体へ通知する
abstract final class ReleaseRecovery {
  static final _showing = ValueNotifier<bool>(false); // Recovery UIが表示中か否か
  static var _queued = false; // callbackが予約されてるか否か

  static ValueListenable<bool> get isShowing => _showing;

  /// リリースで復旧不能な例外が起きたことをアプリ全体へ通知する
  static void show() {
    if (!AppRuntimePolicy.showReleaseRecoveryUi ||
        _showing.value ||
        _queued) {
      return;
    }

    _queued = true;
    
    // 今のフレームの描画処理が終わったら、確実に次のフレームを発生させる
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _queued = false;
      if (AppRuntimePolicy.showReleaseRecoveryUi) _showing.value = true;
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }
}

/// 壊れた状態を続行せず、再起動を案内するリリース専用の全画面表示
class ReleaseRecoveryOverlay extends ConsumerWidget { // ConsumerWidget は、普通の StatelessWidget + Riverpod の ref が使える
  const ReleaseRecoveryOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    /// 「アプリを再起動してください」画面に使う言語の情報を取得
    final language = ref.watch(appSettingsProvider.select((s) => s.language));
    
    return ValueListenableBuilder<bool>( // ある値を監視して、その値が変わったらbuilderを呼び直すWidget
      valueListenable: ReleaseRecovery.isShowing, // 今回は ReleaseRecovery.isShowing を監視
      child: child,
      builder: (context, showing, child) => Stack(
        fit: StackFit.expand,
        children: [
          child!,
          if (showing)
            ColoredBox(
              color: AppColors.white,
              child: Center(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    AppStrings.restartApp(language),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.settingsBlack,
                      fontSize: 42,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
