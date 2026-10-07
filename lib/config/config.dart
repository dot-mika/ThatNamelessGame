import 'dart:ui';

import 'app_language.dart';

/// アプリ共通の色配色の変更はここで行う
abstract final class AppColors {
  // 基本の色　背景画像もこの色名のファイル（play_background_green.pngなど）を使う
  static const green = Color(0xFF8BCD7D);
  static const blue = Color(0xFF81BFE0);
  static const purple = Color(0xFFC297C8);
  static const pink = Color(0xFFF59DBC);
  static const yellow = Color(0xFFDDAF4D);
  static const gray = Color(0xFFCCCCCC);
  static const red = Color(0xFFE54144);

  static const easyPlayer = yellow;
  static const normalPlayer = green;
  static const hardPlayer = blue;
  static const nearPlayer = pink;
  static const farPlayer = purple;
  static const disabled = gray;
  static const settingsBlack = Color(0xFF7F7F7F);
  /// 対局画面とルール画面で使う文字や枠の黒
  static const black = Color(0xFF666666);
  static const cpuTurnOverlay = Color(0x66000000);

  /// 対局画面のカウントダウンと結果表示で、画面全体を暗くする色
  static const dimOverlay = Color(0xB3000000);
  static const white = Color(0xFFFFFFFF);

  // ルール画面2〜9ページの背景色
  static const rules2Yellow = yellow;
  static const rules3Green = green;
  static const rules4Blue = blue;
  static const rules5Purple = purple;
  static const rules6Pink = pink;
  static const rules7Red = red;
  static const rules8Yellow = yellow;
  static const rules9Green = green;

  // ルール画面の「勝ち」「負け」の文字
  static const rulesLoseBlue = Color(0xFF0000A2);
  static const rulesWinRed = Color(0xFFBC0000);
}

/// 画面サイズや音量など、アプリ全体で共有する数値設定
abstract final class AppConfig {

  static const canvasWidth = 1280.0;
  static const canvasHeight = 720.0;
  static const bgmVolume = 0.5;
  static const tapCooldown = Duration(milliseconds: 500);
}

/// 言語に応じて画面文言を返す簡易ローカライズ窓口
abstract final class AppStrings {
  /// 日本語と英語の文言から、指定言語の方を返す
  static String _pick(AppLanguage language, String jp, String en) =>
      language == AppLanguage.jp ? jp : en;

  static String privacyPolicy(AppLanguage l) =>
      _pick(l, 'プライバシーポリシー', 'Privacy Policy');
  static String license(AppLanguage l) => _pick(l, 'ライセンス', 'License');

  // 対局画面
  static String confirm(AppLanguage l) => _pick(l, 'けってい', 'OK');
  static String exitQuestion(AppLanguage l) =>
      _pick(l, '本当にゲームを終わりますか？', 'Are you sure you want to quit the game?');
  static String exitQuestionDisplay(AppLanguage l) =>
      _pick(l, '本当にゲームを\n終わりますか？', 'Are you sure you want\nto quit the game?');
  static String yes(AppLanguage l) => _pick(l, 'はい', 'Yes');
  static String no(AppLanguage l) => _pick(l, 'いいえ', 'No');
  static String playAgain(AppLanguage l) => _pick(l, 'もう一度プレイ', 'Play again');
  static String nearSide(AppLanguage l) => _pick(l, '手前', 'Near');
  static String farSide(AppLanguage l) => _pick(l, '奥', 'Far');

  // 設定画面
  static String settingsTitle(AppLanguage l) => _pick(l, '設定', 'Settings');
  static String timeLimit(AppLanguage l) =>
      _pick(l, '☆ 2人プレイの時間制限', '☆ Time limit for 2 player mode');
  static String soundEffects(AppLanguage l) =>
      _pick(l, '☆ 効果音のON/OFF', '☆ Sound Effects ON/OFF');
  static String bgm(AppLanguage l) => _pick(l, '☆ BGMのON/OFF', '☆ BGM ON/OFF');
  static String language(AppLanguage l) => _pick(l, '☆ 言語', '☆ Language');
  static String unlimited(AppLanguage l) => _pick(l, '無制限', 'Unlimited');

  // ホーム・ルール・起動画面
  static String home(AppLanguage l) => _pick(l, 'ホーム', 'Home');
  static String rules(AppLanguage l) => _pick(l, 'ルール', 'Rules');
  static String playTwo(AppLanguage l) => _pick(l, '2人対戦', '2 players');
  static String playEasy(AppLanguage l) => _pick(l, 'かんたん', 'Easy');
  static String playNormal(AppLanguage l) => _pick(l, 'ふつう', 'Normal');
  static String playHard(AppLanguage l) => _pick(l, 'むずかしい', 'Hard');
  static String retry(AppLanguage l) => _pick(l, '再試行', 'Retry');
  static String restartApp(AppLanguage l) =>
      _pick(l, '問題が発生しました\nアプリを再起動してください', 'Something went wrong.\nPlease restart the app.');
  static String previousPage(AppLanguage l) =>
      _pick(l, '前のページ', 'Previous page');
  static String nextPage(AppLanguage l) => _pick(l, '次のページ', 'Next page');
}

/// ルール画面の説明文と図の文字　`{}`で囲んだ部分は強調色で描く
/// 説明文は1要素が画面上の1行になる
abstract final class RuleStrings {
  static List<String> _pick(
    AppLanguage language,
    List<String> jp,
    List<String> en,
  ) => language == AppLanguage.jp ? jp : en;

  static String _pickText(AppLanguage language, String jp, String en) =>
      language == AppLanguage.jp ? jp : en;

  // 図の文字
  static String opponent(AppLanguage l) => _pickText(l, '相手', 'Opponent');
  static String you(AppLanguage l) => _pickText(l, '自分', 'You');
  static String caseLabel(AppLanguage l, int number) =>
      _pickText(l, 'ケース$number', 'Case $number');
  static String lose(AppLanguage l) => _pickText(l, '負け', 'Lose');
  static String win(AppLanguage l) => _pickText(l, '勝ち', 'Win');
  static String draw(AppLanguage l) => _pickText(l, 'ひきわけ', 'Draw');

  static List<String> page2Title(AppLanguage l) => _pick(
    l,
    const ['~名もなきあの遊び ルール~'],
    const ['~Rules of "That Nameless Game"~'],
  );

  static List<String> page2(AppLanguage l) => _pick(
    l,
    const ['①３本の手をもった２人がむかい合い、指を立てます', '　スタート時、各指の本数は{ランダム}で決まります'],
    const [
      '①Two players with 3 hands each face each other and',
      'hold up their fingers. At the start of the game, the',
      'number of fingers on each hand is chosen {randomly}.',
    ],
  );

  static List<String> page3(AppLanguage l) => _pick(
    l,
    const [
      '②自分のターンの時',
      '　「{自分のどの手から}」「{相手のどの手に}」手をたたくかを選び、',
      '　「{けってい}」を押します',
      '　（制限時間以内に手を選ばないと負けになるので注意！）',
    ],
    const [
      '②On your turn, “{choose one of your hands}” and',
      '“{one of your opponent\'s hands},” then press “{OK}”',
      '(Be careful! If you do not choose your hands within',
      'the time limit, you lose.)',
    ],
  );

  static List<String> page4(AppLanguage l) => _pick(
    l,
    const ['③選んだ手について、自分の指の本数が、', '　相手の指の本数に足されます'],
    const [
      '③For the selected hands, the number of fingers on',
      'your hand will be added to the number of fingers on',
      'your opponent\'s hand.',
    ],
  );

  static List<String> page5(AppLanguage l) => _pick(
    l,
    const [
      '④相手のターンの時',
      '　相手の手のうちどれか１本の指の本数が',
      '　自分の手のうちどれか１本に加えられます',
      '　どの手からどの手に足すかは相手が決めます',
    ],
    const [
      '④On your opponent\'s turn, the number of fingers',
      'on one of their hands is added to one of your',
      'hands. Your opponent chooses which hand adds to',
      'which hand.',
    ],
  );

  static List<String> page6(AppLanguage l) => _pick(
    l,
    const [
      '⑤手の本数が{ちょうど５本}になったら、',
      '　その手は{それ以降使えなくなります}',
      '　足した手が{６本以上}になる場合は、その数を５でわったあまりの数が',
      '　手の本数になります',
      '　（足して{６}本になる場合→{１}本になる）',
      '　（足して{７}本になる場合→{２}本になる）',
      '　（足して{８}本になる場合→{３}本になる）',
    ],
    const [
      '⑤When the number of fingers on a hand becomes',
      '{exactly 5}, that hand can {no longer be used}.',
      'If the total becomes {6 or more}, divide the number by',
      '5 and use the remainder.',
      '(Total of {6} fingers → Becomes {1})',
      '(Total of {7} fingers → Becomes {2})',
      '(Total of {8} fingers → Becomes {3})',
    ],
  );

  static List<String> page7(AppLanguage l) => _pick(
    l,
    const [
      '⑥これをくり返して、',
      '　自分の手が全て使えなくなったら負け、',
      '　相手の手が全て使えなくなったら勝ちです',
    ],
    const [
      '⑥Repeat this process. If all of your hands become',
      'unusable, you lose. If all of your opponent\'s hands',
      'become unusable, you win.',
    ],
  );

  static List<String> page8(AppLanguage l) => _pick(
    l,
    const [
      '⑦同じ状態がもう一度出て{ループ}するようになったら、',
      '　その時残っている{手の本数}が多い方が{勝ち}です',
      '　同じ本数残っていたら引き分けです',
    ],
    const [
      '⑦If the game {loops}, the player with {more hands}',
      'remaining wins. If tied, it\'s a {draw}.',
    ],
  );

  static List<String> page9(AppLanguage l) => _pick(
    l,
    const [
      '⑧２人プレイでは累計プレイ回数、',
      '　１人プレイでは連続勝利数※ に応じて、',
      '　ホーム画面の星が変化します',
      '　すべてのモードで、黄色の星を目指しましょう！',
    ],
    const [
      '⑧In 2-player mode, your star changes based',
      'on total games played. In 1-player mode, it changes',
      'based on your win streak*.',
      'Aim for the yellow star in every mode!',
    ],
  );

  static List<String> page9Note(AppLanguage l) => _pick(
    l,
    const ['※連続勝利数：連続でCPUに勝った回数。', '　なお、引き分けた場合はこれまでのカウントはリセットされません'],
    const [
      '*Win streak: The number of consecutive wins against the CPU.',
      'A draw does not reset your current streak.',
    ],
  );
}

/// 効果音の種類
enum SoundEffect {
  tapButton,
  tapHand,
  win,
  tapOk,
  countdown,
  draw,
  lose;
}
