/// CPUの選択演出を一定間隔で進めるための小さなスケジューラ
/// 実際の時計・一時停止・破棄はPlaySessionNotifierが管理する
class CpuScheduler {
  CpuScheduler({
    this.interval = const Duration(milliseconds: 750),
    this.operations = 3,
  });
  final Duration interval;
  final int operations;
  Duration elapsed = Duration.zero;
  int step = 0;

  /// 次の演出操作までの待ち時間
  Duration get untilNext {
    if (step >= operations) return Duration.zero;
    final remaining = interval * (step + 1) - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// 経過時間を進め、次の演出操作を実行すべきか返す
  /// 遅延フレームでも操作は1回に1つしか進めないため、CPUの
  /// 「手選択 → 対象選択 → 決定」の表示間隔が潰れない
  bool advance(Duration delta) {
    elapsed += delta.isNegative ? Duration.zero : delta;
    final due = interval * (step + 1);
    if (step >= operations || elapsed < due) return false;
    elapsed = due;
    step++;
    return true;
  }
}
