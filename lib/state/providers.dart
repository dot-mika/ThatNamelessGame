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

/// runApp 前に生成済みの実体を overrides で差し込んだ ProviderContainer を作る
ProviderContainer createAppProviderContainer({
  required SettingsRepository settingsRepository,
  required AudioManager audioManager,
}) {
  final container = ProviderContainer(
    overrides: [
      settingsRepositoryProvider.overrideWithValue(settingsRepository),
      audioManagerProvider.overrideWithValue(audioManager),
    ],
  );
  // SettingsNotifier は Provider が最初に watch/read された時点で作られる(遅延生成)。
  // ここで先に読んでおかないと、HomeScreen.initState() の playBgm() が
  // 保存済みの bgmOn/seOn より先に走り、AudioManager のデフォルト値(true)で
  // 再生されてしまう(= 前回OFFにしていてもBGMが鳴る不具合の原因)。
  container.read(settingsNotifierProvider);
  return container;
}
