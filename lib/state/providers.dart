import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../infrastructure/audio_manager.dart';
import '../infrastructure/settings_repository.dart';
import 'settings_notifier.dart';

/// main() で runApp 前に生成した実体を ProviderScope(overrides: ...) で
/// 差し込む(非同期の init()/preload() を runApp 前に済ませたいため)。
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  throw UnimplementedError('main() の ProviderScope(overrides: ...) で上書きされる想定');
});

final audioManagerProvider = Provider<AudioManager>((ref) {
  throw UnimplementedError('main() の ProviderScope(overrides: ...) で上書きされる想定');
});

final settingsNotifierProvider = ChangeNotifierProvider<SettingsNotifier>((ref) {
  return SettingsNotifier(
    ref.watch(settingsRepositoryProvider),
    ref.watch(audioManagerProvider),
  );
});
