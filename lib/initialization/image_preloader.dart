import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/config.dart';
import '../config/assets.dart';

/// バンドルに登録された全画面の静止画像を、言語を問わず先読みする。
Future<void> preloadAllImages(BuildContext context) async {
  final bundle = DefaultAssetBundle.of(context);
  final configuration = createLocalImageConfiguration(context);
  final manifest = await AssetManifest.loadFromAssetBundle(bundle);
  final assets = manifest.listAssets().where((asset) {
    final path = asset.toLowerCase();
    return (path.startsWith('assets/home/') ||
            path.startsWith('assets/settings/') ||
            path.startsWith('assets/play/') ||
            path.startsWith('assets/rules/')) &&
        (path.endsWith('.png') ||
            path.endsWith('.jpg') ||
            path.endsWith('.jpeg') ||
            path.endsWith('.webp'));
  });

  // 現在の全画像が収まる容量にする。素材追加時には使用量も見直す。
  final cache = PaintingBinding.instance.imageCache;
  const cacheBytes = 128 * 1024 * 1024;
  if (cache.maximumSizeBytes < cacheBytes) {
    cache.maximumSizeBytes = cacheBytes;
  }

  // 最大4枚ずつ並行して読み込み、全画像の準備完了を待つ。
  const batchSize = 4;
  final batch = <Future<void>>[];
  for (final asset in assets) {
    ImageProvider provider = AssetImage(asset, bundle: bundle);
    if (asset == Assets.backgroundRainbow ||
        asset == Assets.settingsBackground) {
      // 表示側の cacheWidth / cacheHeight とキャッシュキーを揃える。
      provider = ResizeImage.resizeIfNeeded(
        AppConfig.canvasWidth.toInt(),
        AppConfig.canvasHeight.toInt(),
        provider,
      );
    }
    batch.add(_loadImage(provider, configuration));
    if (batch.length == batchSize) {
      await Future.wait(batch);
      batch.clear();
    }
  }
  await Future.wait(batch);
}

Future<void> _loadImage(
  ImageProvider provider,
  ImageConfiguration configuration,
) async {
  final completer = Completer<void>();
  final stream = provider.resolve(configuration);
  final listener = ImageStreamListener(
    (image, synchronousCall) {
      image.dispose();
      if (!completer.isCompleted) completer.complete();
    },
    onError: (Object error, StackTrace? stackTrace) {
      if (!completer.isCompleted) completer.completeError(error, stackTrace);
    },
  );
  stream.addListener(listener);
  try {
    await completer.future;
  } finally {
    stream.removeListener(listener);
  }
}
