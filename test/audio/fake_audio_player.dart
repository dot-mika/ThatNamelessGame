import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

class FakeAudioPlayer implements AudioPlayer {
  final calls = <String>[];
  final completion = StreamController<void>.broadcast(sync: true);
  Future<void> Function()? onResume;
  Future<void> Function()? onPause;
  Future<void> Function()? onStop;
  bool playing = false;
  bool disposed = false;

  @override
  Stream<void> get onPlayerComplete => completion.stream;

  @override
  Future<void> resume() async {
    if (disposed) throw StateError('resume after disposal');
    calls.add('resume');
    await onResume?.call();
    playing = true;
  }

  @override
  Future<void> pause() async {
    if (disposed) throw StateError('pause after disposal');
    calls.add('pause');
    await onPause?.call();
    playing = false;
  }

  @override
  Future<void> stop() async {
    if (disposed) throw StateError('stop after disposal');
    calls.add('stop');
    await onStop?.call();
    playing = false;
  }

  @override
  Future<void> dispose() async {
    calls.add('dispose');
    disposed = true;
    playing = false;
    await completion.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
