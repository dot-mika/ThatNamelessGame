import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/audio_controller.dart';
import '../audio/audio_observer.dart';
import '../config/config.dart';
import '../diagnostics/app_error_handler.dart';
import '../settings/settings_notifier.dart';
import '../settings/settings_repository.dart';
import '../settings/settings_state.dart';
import 'image_preloader.dart';

// 設定や音声など、ホーム画面を表示する前の準備を行う
class Bootstrap extends StatefulWidget {
  /// コンストラクタ
  const Bootstrap({
    super.key, // 親クラス StatefulWidget のコンストラクタへ key を渡す
    required this.child, // アプリ本体を入れる
    this.createAudio = AudioController.create, // 音声の作成を行う関数
    this.preloadImages = preloadAllImages, // 画面素材をロードする関数
  });

  final Widget child;
  final Future<AudioController> Function() createAudio;
  final Future<void> Function(BuildContext) preloadImages;

  @override
  State<Bootstrap> createState() => _BootstrapState();
}

/// 初期化の成功・失敗と、生成途中リソースの後始末を管理
class _BootstrapState extends State<Bootstrap> {
  late final AudioObserver _audioObserver;
  ProviderContainer? _container;
  AudioController? _audio;
  Object? _error;
  bool _initializing = false;
  AppLanguage _language = AppLanguage.en;

  @override
  void initState() {
    super.initState();

    _audioObserver = AudioObserver();
    unawaited(_initialize());
  }

  /// 設定読込、音声作成、画像プリロードを完了してからProviderを公開する
  Future<void> _initialize() async {
    if (_initializing) return;
    _initializing = true;
    setState(() => _error = null);
    AudioController? pendingAudio;
    ProviderContainer? pendingContainer;
    try {
      // 端末に保存されている設定を読み込む
      final repository = await SettingsRepository.create();
      final settings = await repository.loadOrCreate();

      if (!mounted) return;
      _language = settings.language;

      // 全画面の画像と全音声を並行して準備し、両方の完了を待つ
      final (audio, _) = await (
        widget.createAudio().then((audio) {
          pendingAudio = audio;
          return audio;
        }),
        widget.preloadImages(context),
      ).wait;

      // 準備中に画面が破棄された場合は、音声も破棄して終了する
      if (!mounted) {
        return;
      }
      await _audioObserver.attach(audio, settings);
      if (!mounted) return;

      // 読み込んだ実体をRiverpodへ渡す
      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(repository),
          audioControllerProvider.overrideWithValue(audio),
          initialSettingsProvider.overrideWithValue(settings),
        ],
      );
      pendingContainer = container;
      container.read(appSettingsProvider);

      // 起動準備が完了したらホーム画面へ切り替える
      setState(() {
        _audio = audio;
        _container = container;
      });
      pendingAudio = null;
      pendingContainer = null;
    } catch (error, stackTrace) {
      // 起動に失敗した場合は、記録して再試行ボタンを表示する
      AppErrorHandler.recordHandled(
        error,
        stackTrace,
        source: ErrorSource.startup,
        message: 'App initialization failed; showing retry.',
      );
      if (mounted) setState(() => _error = error);
    } finally {
      // 起動失敗や画面破棄で引き渡せなかった音声を片付ける
      pendingContainer?.dispose();
      if (pendingAudio != null) {
        _audioObserver.detach();
        await pendingAudio?.dispose();
      }
      _initializing = false;
    }
  }

  @override
  void dispose() {
    // アプリ終了時に監視と外部リソースを破棄する
    _audioObserver.dispose();
    _container?.dispose();
    unawaited(_audio?.dispose());
    super.dispose();
  }

  @override
  /// 初期化前は黒画面、失敗時はリトライ、成功時はアプリ本体を返す
  Widget build(BuildContext context) {
    final container = _container;
    if (container != null) {
      return UncontrolledProviderScope(
        container: container,
        child: widget.child,
      );
    }

    // 設定や画像の読み込み中は専用の起動画面を表示する
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ColoredBox(
        key: const Key('startupScreen'),
        color: Colors.black,
        child: Center(
          child: _error == null
              ? const SizedBox.shrink()
              : TextButton(
                  onPressed: _initialize,
                  child: Text(AppStrings.retry(_language)),
                ),
        ),
      ),
    );
  }
}
