# 名もなきあの遊び 設計書

`specifications_jp.md` を実装するための技術設計をまとめる。仕様と矛盾した場合は仕様書を正とする。

## 基本方針

**「変更の理由が違うものは、別の場所に置く」** を全体の判断基準とする。

- ゲームルール(domain)は Flutter 非依存の純粋 Dart で書き、UI から完全に分離する
- CPU の賢さは Python で事前に全探索し、結果テーブルをアプリに同梱する(実行時の判断は Dart)
- 4画面・小規模のため、過剰な抽象化(usecase 層など)はしない

## ディレクトリ構成

```
ThatNamelessGame/
├── assets/                      # 素材(配置済み)
│   ├── audio/{bgm, se}/
│   ├── data/                    # cpu_table.bin (solver.py が生成)
│   ├── font/
│   ├── home/{直下=共用, en/, jp/}
│   ├── icon/
│   ├── play/{backgrounds, hands, judge, labels, pop, start}/
│   ├── rules/{buttons, en, jp}/
│   └── settings/
│
├── tools/
│   └── solver.py                # 全探索 → cpu_table.bin 生成(ビルド前に1回実行)
│
├── lib/
│   ├── main.dart                # MaterialApp / 横向き固定 / 16:9レターボックス
│   │
│   ├── config/                  # 定数集約(Python の config.py 相当)
│   │   ├── config.dart          # 色・制限時間・レイアウト定数
│   │   ├── assets.dart          # アセットパス生成
│   │   └── strings.dart         # Dart内テキストの訳文辞書(JP/EN)
│   │
│   ├── domain/                  # ゲームルール。Flutter非依存・テスト対象の本丸
│   │   ├── models/
│   │   │   ├── game_state.dart  # 両者の手[3]・手番。イミュータブル
│   │   │   ├── move.dart        # (自分の手index, 相手の手index)
│   │   │   └── game_result.dart # 勝敗 + ループ判定フラグ
│   │   ├── game_engine.dart     # 手の適用・mod5・ループ検出・勝敗判定
│   │   ├── initial_hands.dart   # 初期手52パターン表 + ランダム生成
│   │   └── cpu/
│   │       ├── cpu_strategy.dart    # 抽象クラス
│   │       ├── easy_cpu.dart        # キル手95% + ランダム
│   │       ├── normal_cpu.dart      # 3~4手読み相当
│   │       ├── hard_cpu.dart        # cpu_table.bin 参照(ほぼ最強)
│   │       └── cpu_scheduler.dart   # 選択~けっていのタイミング演出
│   │
│   ├── state/                   # アプリの進行状態
│   │   ├── settings_notifier.dart   # 言語/BGM/SE/制限時間/☆×4
│   │   ├── game_notifier.dart       # GamePhase 状態機械
│   │   └── turn_timer.dart          # DateTime基準の残り時間計算
│   │
│   ├── infrastructure/          # OS機能を包む道具。全画面から使う
│   │   ├── audio_manager.dart       # BGM/SE(1ファイル・起動時全プリロード)
│   │   ├── settings_repository.dart # SharedPreferences ラッパー
│   │   └── lifecycle_observer.dart  # バックグラウンド出入りの処理
│   │
│   └── presentation/            # 画面。複雑な play のみ widgets を分割
│       ├── home/home_screen.dart
│       ├── play/
│       │   ├── play_screen.dart     # Stack + フェーズ→オーバーレイ写像
│       │   └── widgets/
│       │       ├── hand_button.dart
│       │       ├── decide_button.dart
│       │       ├── attack_animation.dart
│       │       ├── start_countdown_overlay.dart
│       │       ├── result_overlay.dart
│       │       └── home_confirm_overlay.dart
│       ├── settings/settings_screen.dart
│       └── rules/rules_screen.dart  # PageView(スワイプ + 矢印)
│
└── test/                        # domain のみテスト対象(UIは目視)
    ├── game_engine_test.dart
    ├── initial_hands_test.dart
    └── cpu_test.dart
```

## 主要な設計判断

### 画面・レイアウト

- 横向き固定は `main.dart` で `SystemChrome.setPreferredOrientations`
- 16:9固定 + 黒余白は `MaterialApp` の `builder:` に1回書く(独立ファイルにしない)
- 内側は **1280×720 の固定キャンバス方式**(`FittedBox` + `SizedBox`)。全レイアウトを px 直指定でき、デザイン画像と突き合わせやすい
- ダイアログ(pop)・スタート演出・勝敗画面は `showDialog` を使わず、`Stack` 上のオーバーレイで統一する

### プレイ画面の状態機械

```dart
enum GamePhase { countdown, selecting, attacking, cpuThinking, paused, finished }
```

play_screen はフェーズを表示に写像するだけ。ロジックは game_notifier に置く。

### タイマー

`Timer.periodic` の刻みは表示更新のみに使い、残り時間は **「ターン開始時刻 + 累計停止時間」からの DateTime 計算**で出す。これにより以下を同一の仕組みで実現する:

- けってい後モーション中(0.8s)の停止
- 確認ダイアログ中の停止
- バックグラウンド経過時間の反映(プレイヤーターンのみ。CPUターンは反映しない)

### CPU テーブル(Python ↔ Dart の契約)

状態数は 5^6 × 2手番 = **31,250状態**。solver.py が全探索し、フラットバイナリ `cpu_table.bin`(約31KB)を生成する。JSON は使わない。

```
index = p0 + p1*5 + p2*25 + o0*125 + o1*625 + o2*3125 + turn*15625
        (各手 0~4、turn: 0=手前側の手番, 1=相手側)
table[index] 1バイト:
  上位4bit: 最善手 = (自分の手 0~2)*3 + (相手の手 0~2)  … 0~8
  下位4bit: 評価値(負け確定/引き分け/勝ち確定/ループ勝ち 等)
```

- インデックス計算式は Python と Dart で同じ式を書き、テストで一致を確認する
- Dart 側は `rootBundle.load()` → `Uint8List` 添字アクセスのみ。パース不要
- むずかしい: テーブル最善手。「全パターン把握者は勝てる」ように次善手を混ぜる調整余地を残す
- ふつう: 3~4手読み相当の制限評価
- やさしい: テーブル不使用。キル手があれば95%で選択、なければランダム
- 思考とは別に `cpu_scheduler` が「選ぶ→(選び直し15%)→けってい」の時刻を先に抽選し、モード別の間隔制約(1s/0.5s/0.25s)を守る

### 音声

- `audioplayers` を使用。BGM 用と SE 用でプレイヤーを分ける
- **SE 8種 + BGM は起動時に全プリロード**(遅延ロードは初回タップの音遅れの原因になる)
- API: `playBgm / pauseBgm / resumeBgm / playSe(Se.xxx) / playSeInterruptingBgm(Se.win)`
  (最後のものが「SE中はBGM停止→SE終了後に再開」を担う)
- 「いつ何を鳴らすか」の判断は各画面/notifier 側の責務。audio_manager は仕組みのみ

### 永続化

`shared_preferences` を使用。キーは8個:

```
language, bgmOn, seOn, twoPlayerTimeLimit,
starTwoPlayer, starEasy, starNormal, starHard
```

- ☆の確定は **勝敗決定画面からの画面遷移時**(内部で勝敗が決まった時点ではない)。
  ダイアログ経由で離脱した場合に☆を付けない仕様に対応するため
- タスクキル後は常にホーム画面から起動(プレイ状態は永続化しない)

### 言語

- 素材はフォルダ(en/jp)+ ファイル名サフィックス(`_jp`/`_en`)の両方で言語を持つ(仕様書のファイル名と1:1対応を維持)
- パス生成例: `Assets.home('jp', 'title_logo')` → `assets/home/jp/title_logo_jp.png`
- Dart 内テキスト(けってい・タイマー・pop 等)は `config/strings.dart` の辞書で JP/EN 切替
- ルール→ホームのボタンは `rules_home.png`、設定→ホームは `settings_home.png`(別素材)

## pubspec.yaml の注意

- assets 宣言はサブフォルダを再帰しない。**末端フォルダを全列挙**する(glob `**` 不可)
- 親フォルダ直下にもファイルを置く場合(home/ 等)は親の行も必要
- 空フォルダはビルドエラーになる。素材が揃うまで `.gitkeep` 等を置く
- font は `assets:` ではなく `fonts:` セクションで宣言する
- bundle 確認は `AssetManifest` で行える

## テスト方針

- 対象: **domain 全部**(engine / initial_hands / cpu) + テーブルのインデックス計算の Python-Dart 一致
- 対象外: presentation(目視確認の方が早い)
- 仕様由来の必須ケース: mod5、合計ちょうど5で手が消える、消えた手は使えない、ループ検出(手の位置と手番を区別)、初期手52パターンに初手キルが含まれないことの全列挙チェック

## 実装順

```
① main.dart ─ 額縁(16:9固定キャンバス)+ 4画面の空遷移
     理由: 全画面の座標指定の土台。最初じゃないと後で書き直しになる

② config/ + infrastructure/ ─ 定数・SharedPreferences・audio_manager
     理由: 設定画面が読み書きする「裏側」を先に

③ 設定画面
     理由: ホーム画面が表示する設定値(言語・☆)の供給元

④ ホーム画面
     理由: ここまでで「起動→ホーム→設定→戻る」が完成。BGMも鳴る

⑤ tools/solver.py ─ Pythonでルール実装+全探索 → cpu_table.bin
     理由: ルールを一度目に実装する場所。頭がルールモードになる

⑥ domain/ ─ ⑤のルールをDartに移植 + CPU 3種 + テスト
     理由: ⑤の直後なら移植が一番速い。プレイ画面の前提

⑦ プレイ画面 ─ フェーズ状態機械、オーバーレイ、タイマー
     理由: 最大の山。⑥までの部品が全部揃ってから登る

⑧ ルール画面
     理由: 独立してて簡単。gifの重さ検証もこの頃には実機感覚がある

⑨ 結合 ─ lifecycle_observer(バックグラウンド処理)、☆判定
     理由: 複数画面にまたがる横断機能は、画面が揃ってから
```

## gif の重さ対策(ルール画面)

仕様書の予防線「重い場合は Dart 再現に転換」に沿って、軽い順に3段階で対応する:

1. まず現物で試す。PageView のデフォルトは隣ページを事前ビルドしないため、同時にメモリに乗る gif は1枚
2. gif 自体を軽量化(解像度を表示サイズ相当に、フレーム間引き、減色)
3. それでも重ければ静止画 + Flutter アニメーションで Dart 再現(最終手段)
