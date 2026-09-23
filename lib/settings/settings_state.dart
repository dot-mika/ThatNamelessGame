import 'package:flutter/foundation.dart';

enum AppLanguage { jp, en }

enum TimeLimit {
  seconds5(5),
  seconds10(10),
  seconds15(15),
  seconds20(20),
  seconds30(30),
  seconds45(45),
  seconds60(60),
  unlimited(-1);

  const TimeLimit(this.seconds);

  final int seconds;

  Duration? get duration =>
      this == TimeLimit.unlimited ? null : Duration(seconds: seconds);

  static TimeLimit? fromSeconds(int seconds) {
    for (final value in values) {
      if (value.seconds == seconds) return value;
    }
    return null;
  }
}

enum StarMode { twoPlayer, easy, normal, hard }

enum StarAppearance { clear, blue, yellow }

/// Progress associated with one mode. This gives callers a single value to
/// render and makes the rules for the home-screen star explicit.
@immutable
class ModeProgress {
  const ModeProgress({required this.hasStar, required this.completed});

  final bool hasStar;
  final int completed;

  StarAppearance get appearance {
    if (completed >= 5) return StarAppearance.yellow;
    return hasStar ? StarAppearance.blue : StarAppearance.clear;
  }
}

/// 端末へ保存する設定と、ホーム画面の星進捗を持つ不変データ。
@immutable
class AppSettings {
  const AppSettings({
    required this.language,
    required this.bgmEnabled,
    required this.seEnabled,
    required this.timeLimit,
    required this.star2p,
    required this.starEasy,
    required this.starNormal,
    required this.starHard,
    this.twoPlayerCompleted = 0,
    this.easyWinStreak = 0,
    this.normalWinStreak = 0,
    this.hardWinStreak = 0,
  });

  factory AppSettings.defaults(AppLanguage language) => AppSettings(
    language: language,
    bgmEnabled: true,
    seEnabled: true,
    timeLimit: TimeLimit.seconds15,
    star2p: false,
    starEasy: false,
    starNormal: false,
    starHard: false,
  );

  final AppLanguage language;
  final bool bgmEnabled;
  final bool seEnabled;
  final TimeLimit timeLimit;
  final bool star2p;
  final bool starEasy;
  final bool starNormal;
  final bool starHard;
  final int twoPlayerCompleted;
  final int easyWinStreak;
  final int normalWinStreak;
  final int hardWinStreak;

  AppSettings copyWith({
    AppLanguage? language,
    bool? bgmEnabled,
    bool? seEnabled,
    TimeLimit? timeLimit,
    bool? star2p,
    bool? starEasy,
    bool? starNormal,
    bool? starHard,
    int? twoPlayerCompleted,
    int? easyWinStreak,
    int? normalWinStreak,
    int? hardWinStreak,
  }) => AppSettings(
    language: language ?? this.language,
    bgmEnabled: bgmEnabled ?? this.bgmEnabled,
    seEnabled: seEnabled ?? this.seEnabled,
    timeLimit: timeLimit ?? this.timeLimit,
    star2p: star2p ?? this.star2p,
    starEasy: starEasy ?? this.starEasy,
    starNormal: starNormal ?? this.starNormal,
    starHard: starHard ?? this.starHard,
    twoPlayerCompleted: twoPlayerCompleted ?? this.twoPlayerCompleted,
    easyWinStreak: easyWinStreak ?? this.easyWinStreak,
    normalWinStreak: normalWinStreak ?? this.normalWinStreak,
    hardWinStreak: hardWinStreak ?? this.hardWinStreak,
  );

  bool hasStar(StarMode mode) => switch (mode) {
    StarMode.twoPlayer => star2p,
    StarMode.easy => starEasy,
    StarMode.normal => starNormal,
    StarMode.hard => starHard,
  };

  /// The mode-oriented projection is the preferred read API for new UI.
  /// The individual fields remain temporarily for storage compatibility.
  ModeProgress progressFor(StarMode mode) => ModeProgress(
    hasStar: hasStar(mode),
    completed: mode == StarMode.twoPlayer
        ? twoPlayerCompleted
        : winStreak(mode),
  );

  int winStreak(StarMode mode) => switch (mode) {
    StarMode.twoPlayer => 0,
    StarMode.easy => easyWinStreak,
    StarMode.normal => normalWinStreak,
    StarMode.hard => hardWinStreak,
  };

  AppSettings withStar(StarMode mode, bool value) => switch (mode) {
    StarMode.twoPlayer => copyWith(star2p: value),
    StarMode.easy => copyWith(starEasy: value),
    StarMode.normal => copyWith(starNormal: value),
    StarMode.hard => copyWith(starHard: value),
  };

  AppSettings markStar(StarMode mode) => withStar(mode, true);

  AppSettings withWinStreak(StarMode mode, int value) {
    assert(value >= 0);
    return switch (mode) {
      StarMode.twoPlayer => this,
      StarMode.easy => copyWith(easyWinStreak: value),
      StarMode.normal => copyWith(normalWinStreak: value),
      StarMode.hard => copyWith(hardWinStreak: value),
    };
  }

  /// 終局済みの1試合を進捗へ反映する。
  /// 2人は完了数、1人は勝敗に応じた連勝数を更新する。
  AppSettings recordCompletedGame(
    StarMode mode, {
    required bool won,
    required bool draw,
  }) {
    if (mode == StarMode.twoPlayer) {
      return copyWith(star2p: true, twoPlayerCompleted: twoPlayerCompleted + 1);
    }
    if (won) return markStar(mode).withWinStreak(mode, winStreak(mode) + 1);
    return draw ? this : withWinStreak(mode, 0);
  }

  /// 星の有無と進捗数から、ホーム画面で使う3色状態を決める。
  StarAppearance starAppearance(StarMode mode) {
    return progressFor(mode).appearance;
  }

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      language == other.language &&
      bgmEnabled == other.bgmEnabled &&
      seEnabled == other.seEnabled &&
      timeLimit == other.timeLimit &&
      star2p == other.star2p &&
      starEasy == other.starEasy &&
      starNormal == other.starNormal &&
      starHard == other.starHard &&
      twoPlayerCompleted == other.twoPlayerCompleted &&
      easyWinStreak == other.easyWinStreak &&
      normalWinStreak == other.normalWinStreak &&
      hardWinStreak == other.hardWinStreak;

  @override
  int get hashCode => Object.hash(
    language,
    bgmEnabled,
    seEnabled,
    timeLimit,
    star2p,
    starEasy,
    starNormal,
    starHard,
    twoPlayerCompleted,
    easyWinStreak,
    normalWinStreak,
    hardWinStreak,
  );
}
