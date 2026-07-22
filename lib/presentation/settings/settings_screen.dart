import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/assets.dart';
import '../../config/config.dart';
import '../../config/settings_strings.dart';
import '../../infrastructure/audio_manager.dart';
import '../../state/providers.dart';
import '../widgets/debounced_tap.dart';
import '../widgets/navigation_tap.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);
    final lang = settings.language;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(Assets.settingsBackground, fit: BoxFit.cover),
          ),
          Positioned(
            left: 110,
            top: 60,
            child: _label(SettingsStrings.of('settingsTitle', lang), fontSize: 64),
          ),
          Positioned(
            left: 160,
            top: 185,
            child: _label(
              SettingsStrings.of('twoPlayerTimeLimit', lang),
              fontSize: 48,
            ),
          ),
          Positioned(
            left: 314,
            top: 265,
            child: _TimeLimitSelector(lang: lang),
          ),
          Positioned(
            left: 160,
            top: 390,
            child: _label(SettingsStrings.of('seOnOff', lang), fontSize: 48),
          ),
          Positioned(
            left: 885,
            top: 375,
            child: _OnOffSelector(
              lang: lang,
              value: settings.seOn,
              onChanged: (value) => settings.setSeOn(value),
            ),
          ),
          Positioned(
            left: 160,
            top: 500,
            child: _label(SettingsStrings.of('bgmOnOff', lang), fontSize: 48),
          ),
          Positioned(
            left: 885,
            top: 485,
            child: _OnOffSelector(
              lang: lang,
              value: settings.bgmOn,
              onChanged: (value) => settings.setBgmOn(value),
            ),
          ),
          Positioned(
            left: 160,
            top: 610,
            child: _label(SettingsStrings.of('language', lang), fontSize: 48),
          ),
          Positioned(
            left: 843,
            top: 595,
            child: _LanguageSelector(lang: lang),
          ),
          Positioned(
            right: 20,
            top: 20,
            child: _HomeButton(lang: lang),
          ),
        ],
      ),
    );
  }

  Widget _label(String text, {required double fontSize}) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Rwi',
        fontSize: fontSize,
        color: AppColors.blackHomeSettings,
      ),
    );
  }
}

class _HomeButton extends ConsumerWidget {
  const _HomeButton({required this.lang});

  final String lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NavigationTap(
      onTap: () async {
        await ref.read(audioManagerProvider).playSe(Se.tapButton);
        if (context.mounted) Navigator.of(context).pop();
      },
      child: Image.asset(Assets.settingsHome, width: 100, height: 100),
    );
  }
}

/// 「5s 10s 15s ... 無制限」のピル型セグメントセレクタ。
class _TimeLimitSelector extends ConsumerWidget {
  const _TimeLimitSelector({required this.lang});

  final String lang;

  static const double _height = 80;
  // 外枠の左右パディング合計(EdgeInsets.all(6))。
  static const double _outerPadding = 12;

  // 秒数の枠は全部同じ大きさの真ん丸(直径固定・jp/en共通)。
  static const double _numberDiameter = 60;
  static const double _numberColumnWidth = 70;

  // 「無制限」/「Unlimited」だけ固定幅の横長ピル。英語の方が文字が長いので広め。
  // 縦幅は秒数の丸(直径固定)と別に調整できるようにしておく。
  static const double _unlimitedWidthJp = 130;
  static const double _unlimitedWidthEn = 175;
  static const double _unlimitedBorderRadius = 40;
  static const double _unlimitedVerticalMargin = 5;

  double get _unlimitedWidth =>
      lang == 'jp' ? _unlimitedWidthJp : _unlimitedWidthEn;

  // 全体幅は各列の幅から求める(バラバラに固定値を持つとズレる/はみ出るため)。
  double get _width =>
      _outerPadding + _numberColumnWidth * 7 + _unlimitedWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(settingsNotifierProvider).twoPlayerTimeLimit;
    return Container(
      width: _width,
      height: _height,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.blackHomeSettings,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        children: TwoPlayerTimeLimit.values.map((option) {
          final isSelected = option == selected;
          final isUnlimited = option == TwoPlayerTimeLimit.unlimited;
          final label = isUnlimited
              ? SettingsStrings.of('unlimited', lang)
              : '${option.seconds}s';
          final pill = _SegmentPill(
            label: label,
            isSelected: isSelected,
            onTap: () {
              ref.read(audioManagerProvider).playSe(Se.tapButton);
              ref.read(settingsNotifierProvider).setTwoPlayerTimeLimit(option);
            },
            borderRadius: _unlimitedBorderRadius,
            diameter: isUnlimited ? null : _numberDiameter,
            verticalMargin: _unlimitedVerticalMargin,
          );
          return SizedBox(
            width: isUnlimited ? _unlimitedWidth : _numberColumnWidth,
            child: pill,
          );
        }).toList(),
      ),
    );
  }
}

/// ON/OFF のピル型セグメントセレクタ(効果音・BGM共用)。
class _OnOffSelector extends ConsumerWidget {
  const _OnOffSelector({
    required this.lang,
    required this.value,
    required this.onChanged,
  });

  final String lang;
  final bool value;
  final ValueChanged<bool> onChanged;

  static const double _width = 183.33;
  static const double _height = 80;
  static const double _diameter = 65;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: _width,
      height: _height,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.blackHomeSettings,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentPill(
              label: SettingsStrings.of('on', lang),
              isSelected: value,
              onTap: () {
                ref.read(audioManagerProvider).playSe(Se.tapButton);
                onChanged(true);
              },
              borderRadius: 40,
              diameter: _diameter,
            ),
          ),
          Expanded(
            child: _SegmentPill(
              label: SettingsStrings.of('off', lang),
              isSelected: !value,
              onTap: () {
                ref.read(audioManagerProvider).playSe(Se.tapButton);
                onChanged(false);
              },
              borderRadius: 40,
              diameter: _diameter,
            ),
          ),
        ],
      ),
    );
  }
}

/// 「日本語 / English」のピル型セグメントセレクタ。
class _LanguageSelector extends ConsumerWidget {
  const _LanguageSelector({required this.lang});

  final String lang;

  static const double _width = 268;
  static const double _height = 80;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: _width,
      height: _height,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.blackHomeSettings,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        children: [
          Expanded(child: _pill(ref, 'jp', SettingsStrings.of('japanese', lang))),
          Expanded(child: _pill(ref, 'en', SettingsStrings.of('english', lang))),
        ],
      ),
    );
  }

  Widget _pill(WidgetRef ref, String code, String label) {
    return _SegmentPill(
      label: label,
      isSelected: lang == code,
      onTap: () {
        ref.read(audioManagerProvider).playSe(Se.tapButton);
        ref.read(settingsNotifierProvider).setLanguage(code);
      },
      borderRadius: 40,
      verticalMargin: 5,
    );
  }
}

/// 文字幅に依存しない、親から与えられた幅いっぱいに広がるピル
/// (セグメント選択肢1つ分)。呼び出し側で Expanded に包んで使う。
///
/// [diameter] を指定すると、幅いっぱいのピルではなく直径固定の真ん丸として
/// 中央に描画する(秒数のように短いラベル向け)。
class _SegmentPill extends StatelessWidget {
  const _SegmentPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.borderRadius,
    this.diameter,
    this.verticalMargin = 0,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final double borderRadius;
  final double? diameter;
  final double verticalMargin;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'Rwi',
        fontSize: 28,
        color: isSelected ? AppColors.blackHomeSettings : AppColors.white,
      ),
    );

    final child = diameter != null
        ? Center(
            child: Container(
              width: diameter,
              height: diameter,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.white : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: text,
            ),
          )
        : Container(
            margin: EdgeInsets.symmetric(
              horizontal: 3,
              vertical: verticalMargin,
            ),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: text,
          );

    return DebouncedTap(onTap: onTap, child: child);
  }
}
