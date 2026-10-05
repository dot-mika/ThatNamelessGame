import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:that_nameless_game/config/app_language.dart';
import 'package:that_nameless_game/config/assets.dart';
import 'package:that_nameless_game/initialization/image_preloader.dart';

void main() {
  testWidgets('startup preload excludes rule screen images', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (value) {
            context = value;
            return const SizedBox();
          },
        ),
      ),
    );
    final cache = PaintingBinding.instance.imageCache;
    final previousLimit = cache.maximumSizeBytes;
    addTearDown(() {
      cache.clear();
      cache.maximumSizeBytes = previousLimit;
    });
    await tester.runAsync(() async {
      final bundle = DefaultAssetBundle.of(context);
      final configuration = createLocalImageConfiguration(context);
      await preloadAllImages(context);
      final manifest = await AssetManifest.loadFromAssetBundle(bundle);
      final pngs = manifest.listAssets().where(
        (path) => path.startsWith('assets/') && path.endsWith('.png'),
      );
      expect(pngs.any((path) => path.startsWith('assets/play/')), isTrue);
      expect(pngs.any((path) => path.startsWith('assets/settings/')), isTrue);
      expect(pngs.any((path) => path.startsWith('assets/rules/')), isTrue);
      for (final path in pngs) {
        if (path.startsWith('assets/icon/') || path.startsWith('assets/rules/')) {
          continue;
        }
        final provider = Assets.image(path, bundle: bundle);
        final key = await provider.obtainKey(configuration);
        expect(cache.statusForKey(key).keepAlive, isTrue, reason: path);
      }
    });
  });

  testWidgets('rule screen preload loads its images and GIFs on demand', (
    tester,
  ) async {
    late BuildContext context;
    final bundle = _TrackingAssetBundle();
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: bundle,
        child: MaterialApp(
          home: Builder(
            builder: (value) {
              context = value;
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    await tester.runAsync(() => preloadRuleImages(context, AppLanguage.en));

    expect(bundle.loadedAssets, containsAll(Assets.ruleScreenImages(AppLanguage.en)));
    expect(bundle.loadedAssets.where(Assets.isRuleGif), hasLength(4));
  });
}

class _TrackingAssetBundle extends CachingAssetBundle {
  final loadedAssets = <String>[];

  @override
  Future<ByteData> load(String key) {
    loadedAssets.add(key);
    return rootBundle.load(key);
  }
}
