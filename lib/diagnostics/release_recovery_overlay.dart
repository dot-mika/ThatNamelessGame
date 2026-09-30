import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/config.dart';
import '../settings/settings_notifier.dart';
import 'app_runtime_policy.dart';

/// リリースで復旧不能な例外が起きたことをアプリ全体へ通知する。
abstract final class ReleaseRecovery {
  static final _showing = ValueNotifier<bool>(false);
  static var _queued = false;

  static ValueListenable<bool> get isShowing => _showing;

  static void show() {
    if (!AppRuntimePolicy.showReleaseRecoveryUi ||
        _showing.value ||
        _queued) {
      return;
    }
    // build中の例外ハンドラからも安全に表示を切り替える。
    _queued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _queued = false;
      if (AppRuntimePolicy.showReleaseRecoveryUi) _showing.value = true;
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }
}

/// 壊れた状態を続行せず、再起動を案内するリリース専用の全画面表示。
class ReleaseRecoveryOverlay extends ConsumerWidget {
  const ReleaseRecoveryOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(appSettingsProvider.select((s) => s.language));
    return ValueListenableBuilder<bool>(
      valueListenable: ReleaseRecovery.isShowing,
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
