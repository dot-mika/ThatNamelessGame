import 'package:flutter/foundation.dart';

import '../config/app_language.dart';

// 既存の利用側がsettings_stateからAppLanguageを参照できるよう再公開する
export '../config/app_language.dart';

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

  /// 保存値の秒数から対応する制限時間を取得する
  static TimeLimit? fromSeconds(int seconds) {
    for (final value in values) {
      if (value.seconds == seconds) return value;
    }
    return null;
  }
}

enum StarMode { twoPlayer, easy, normal, hard }

enum StarAppearance { clear, blue, yellow }

/// ホーム画面のスター表示に必要な値をまとめて提供する
@immutable
class ModeProgress {
  const ModeProgress({required this.hasStar, required this.completed});

  final bool hasStar;
  final int completed;

  /// 進捗に応じたスターの見た目を返す
  StarAppearance get appearance {
    if (completed >= 5) return StarAppearance.yellow;
    return hasStar ? StarAppearance.blue : StarAppearance.clear;
  }
}

/// 端末へ保存する設定と、ホーム画面の星進捗を持つ不変データ
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

  /// 指定された項目だけを差し替えた設定を作る
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

  /// 指定モードでスターを取得済みか判定する
  bool hasStar(StarMode mode) => switch (mode) {
    StarMode.twoPlayer => star2p,
    StarMode.easy => starEasy,
    StarMode.normal => starNormal,
    StarMode.hard => starHard,
  };

  /// モード単位で進捗を参照するための読み取りAPI
  /// 個別フィールドは保存形式との互換性のために残している
  ModeProgress progressFor(StarMode mode) =>
      ModeProgress(hasStar: hasStar(mode), completed: progressCount(mode));

  /// 星の色に使う進捗数2人は完了数、1人は連勝数
  int progressCount(StarMode mode) => switch (mode) {
    StarMode.twoPlayer => twoPlayerCompleted,
    StarMode.easy => easyWinStreak,
    StarMode.normal => normalWinStreak,
    StarMode.hard => hardWinStreak,
  };

  /// 指定モードのスター取得状態を差し替える
  AppSettings withStar(StarMode mode, bool value) => switch (mode) {
    StarMode.twoPlayer => copyWith(star2p: value),
    StarMode.easy => copyWith(starEasy: value),
    StarMode.normal => copyWith(starNormal: value),
    StarMode.hard => copyWith(starHard: value),
  };

  /// 指定モードをスター取得済みにする
  AppSettings markStar(StarMode mode) => withStar(mode, true);

  /// 指定モードの進捗数（2人は完了数、1人は連勝数）を差し替える
  AppSettings withProgressCount(StarMode mode, int value) {
    assert(value >= 0);
    return switch (mode) {
      StarMode.twoPlayer => copyWith(twoPlayerCompleted: value),
      StarMode.easy => copyWith(easyWinStreak: value),
      StarMode.normal => copyWith(normalWinStreak: value),
      StarMode.hard => copyWith(hardWinStreak: value),
    };
  }

  /// 終局済みの1試合を進捗へ反映する
  /// 2人は完了数、1人は勝敗に応じた連勝数を更新する
  AppSettings recordCompletedGame(
    StarMode mode, {
    required bool won,
    required bool draw,
  }) {
    if (mode == StarMode.twoPlayer || won) {
      return markStar(mode).withProgressCount(mode, progressCount(mode) + 1);
    }
    return draw ? this : withProgressCount(mode, 0);
  }

  /// 星の有無と進捗数から、ホーム画面で使う3色状態を決める
  StarAppearance starAppearance(StarMode mode) {
    return progressFor(mode).appearance;
  }

  /// 等価判定の対象フィールドを追加したらここにも加える
  List<Object> get _props => [
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
  ];

  @override
  bool operator ==(Object other) =>
      other is AppSettings && listEquals(_props, other._props);

  @override
  int get hashCode => Object.hashAll(_props);
}
