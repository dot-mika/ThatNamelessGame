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

  AppSettings copyWith({
    AppLanguage? language,
    bool? bgmEnabled,
    bool? seEnabled,
    TimeLimit? timeLimit,
    bool? star2p,
    bool? starEasy,
    bool? starNormal,
    bool? starHard,
  }) => AppSettings(
    language: language ?? this.language,
    bgmEnabled: bgmEnabled ?? this.bgmEnabled,
    seEnabled: seEnabled ?? this.seEnabled,
    timeLimit: timeLimit ?? this.timeLimit,
    star2p: star2p ?? this.star2p,
    starEasy: starEasy ?? this.starEasy,
    starNormal: starNormal ?? this.starNormal,
    starHard: starHard ?? this.starHard,
  );

  bool hasStar(StarMode mode) => switch (mode) {
    StarMode.twoPlayer => star2p,
    StarMode.easy => starEasy,
    StarMode.normal => starNormal,
    StarMode.hard => starHard,
  };

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
      starHard == other.starHard;

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
  );
}
