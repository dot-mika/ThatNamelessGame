import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/app_settings_notifier.dart';
import '../../config/config.dart';
import '../../settings/app_settings.dart';
import '../../config/assets.dart';
import '../../audio/audio_manager.dart';
import '../widgets/tappable_image.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _tapSound(WidgetRef ref) =>
      unawaited(ref.read(audioManagerProvider).play(SoundEffect.tapButton));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final language = settings.language;
    final notifier = ref.read(appSettingsProvider.notifier);

    return Scaffold(
      key: const Key('settingsScreen'),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              Assets.settingsBackground,
              fit: BoxFit.cover,
              cacheWidth: AppConfig.canvasWidth.toInt(),
              cacheHeight: AppConfig.canvasHeight.toInt(),
            ),
          ),
          Positioned(
            left: 110,
            top: 40,
            child: _Label(AppStrings.settingsTitle(language), 58),
          ),
          Positioned(
            left: 155,
            top: 145,
            child: _Label(AppStrings.timeLimit(language), 45),
          ),
          Positioned(
            left: 300,
            top: 222,
            child: _TimeLimitSelector(
              language: language,
              selected: settings.timeLimit,
              onSelected: (value) {
                _tapSound(ref);
                notifier.setTimeLimit(value);
              },
            ),
          ),
          Positioned(
            left: 155,
            top: 350,
            child: _Label(AppStrings.soundEffects(language), 45),
          ),
          Positioned(
            left: 875,
            top: 345,
            child: _OnOffSelector(
              key: const Key('seSelector'),
              value: settings.seEnabled,
              onChanged: (value) {
                _tapSound(ref);
                notifier.setSeEnabled(value);
              },
            ),
          ),
          Positioned(
            left: 155,
            top: 465,
            child: _Label(AppStrings.bgm(language), 45),
          ),
          Positioned(
            left: 875,
            top: 460,
            child: _OnOffSelector(
              key: const Key('bgmSelector'),
              value: settings.bgmEnabled,
              onChanged: (value) {
                _tapSound(ref);
                notifier.setBgmEnabled(value);
              },
            ),
          ),
          Positioned(
            left: 155,
            top: 580,
            child: _Label(AppStrings.language(language), 45),
          ),
          Positioned(
            left: 835,
            top: 575,
            child: _LanguageSelector(
              language: language,
              onChanged: (value) {
                _tapSound(ref);
                notifier.setLanguage(value);
              },
            ),
          ),
          Positioned(
            right: 22,
            top: 20,
            width: 100,
            height: 100,
            child: TappableImage(
              key: const Key('settingsHomeButton'),
              asset: Assets.settingsHome,
              semanticLabel: 'Home',
              onTap: () {
                _tapSound(ref);
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, this.size);
  final String text;
  final double size;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color: AppColors.settingsBlack,
      fontFamily: 'Rwi',
      fontSize: size,
      height: 1.1,
    ),
  );
}

class _TimeLimitSelector extends StatelessWidget {
  const _TimeLimitSelector({
    required this.language,
    required this.selected,
    required this.onSelected,
  });

  final AppLanguage language;
  final TimeLimit selected;
  final ValueChanged<TimeLimit> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('timeLimitSelector'),
    height: 78,
    padding: const EdgeInsets.all(7),
    decoration: BoxDecoration(
      color: AppColors.settingsBlack,
      borderRadius: BorderRadius.circular(40),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final limit in TimeLimit.values)
          SizedBox(
            width: limit == TimeLimit.unlimited
                ? (language == AppLanguage.jp ? 125 : 170)
                : 70,
            child: _Choice(
              selected: selected == limit,
              label: limit == TimeLimit.unlimited
                  ? AppStrings.unlimited(language)
                  : '${limit.seconds}s',
              onTap: () => onSelected(limit),
              round: limit != TimeLimit.unlimited,
              height: limit == TimeLimit.unlimited ? 53 : null,
              width: limit == TimeLimit.unlimited
                  ? (language == AppLanguage.jp ? 121 : 158)
                  : null,
            ),
          ),
      ],
    ),
  );
}

class _OnOffSelector extends StatelessWidget {
  const _OnOffSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    width: 178,
    height: 72,
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: AppColors.settingsBlack,
      borderRadius: BorderRadius.circular(36),
    ),
    child: Row(
      children: [
        Expanded(
          child: _Choice(
            selected: value,
            label: 'ON',
            onTap: () => onChanged(true),
            round: true,
          ),
        ),
        Expanded(
          child: _Choice(
            selected: !value,
            label: 'OFF',
            onTap: () => onChanged(false),
            round: true,
          ),
        ),
      ],
    ),
  );
}

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({required this.language, required this.onChanged});
  final AppLanguage language;
  final ValueChanged<AppLanguage> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('languageSelector'),
    width: 270,
    height: 72,
    padding: const EdgeInsets.all(7),
    decoration: BoxDecoration(
      color: AppColors.settingsBlack,
      borderRadius: BorderRadius.circular(36),
    ),
    child: Row(
      children: [
        Expanded(
          child: _Choice(
            selected: language == AppLanguage.jp,
            label: '日本語',
            onTap: () => onChanged(AppLanguage.jp),
          ),
        ),
        Expanded(
          child: _Choice(
            selected: language == AppLanguage.en,
            label: 'English',
            onTap: () => onChanged(AppLanguage.en),
          ),
        ),
      ],
    ),
  );
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.selected,
    required this.label,
    required this.onTap,
    this.round = false,
    this.height,
    this.width,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;
  final bool round;
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: Container(
          width: width ?? (round ? 60 : null),
          height: height ?? (round ? 60 : 54),
          alignment: Alignment.center,
          padding: round
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.white : Colors.transparent,
            shape: round ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: round ? null : BorderRadius.circular(28),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: selected ? AppColors.settingsBlack : AppColors.white,
                fontFamily: 'Rwi',
                fontSize: 25,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
