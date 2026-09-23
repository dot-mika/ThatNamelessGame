import 'dart:async';

import 'package:flutter/material.dart';

import '../../../config/config.dart';
import '../../../settings/settings_state.dart';

/// The exit-confirmation overlay is independent from match state and can be
/// rendered or tested without the game board.
class ExitConfirmation extends StatelessWidget {
  const ExitConfirmation({
    super.key,
    required this.language,
    required this.onYes,
    required this.onNo,
  });

  final AppLanguage language;
  final FutureOr<void> Function() onYes;
  final VoidCallback onNo;
  static const _dialogGray = Color(0xFF666666);

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: AppStrings.exitQuestion(language),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _dialogGray, width: 5),
      ),
      child: Stack(
        children: [
          Positioned(
            left: language == AppLanguage.jp ? 182 : 35,
            top: 95,
            width: language == AppLanguage.jp ? 446 : 747,
            child: ExcludeSemantics(
              child: Text(
                AppStrings.exitQuestion(language),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 64,
                  height: 1,
                  color: _dialogGray,
                ),
              ),
            ),
          ),
          Positioned(
            left: 100,
            top: 275,
            child: _DialogButton(
              key: const Key('exitYes'),
              text: AppStrings.yes(language),
              onTap: onYes,
            ),
          ),
          Positioned(
            left: 450,
            top: 275,
            child: _DialogButton(
              key: const Key('exitNo'),
              text: AppStrings.no(language),
              onTap: onNo,
            ),
          ),
        ],
      ),
    ),
  );
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({super.key, required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;
  static const _dialogGray = Color(0xFF666666);

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: text,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        height: 130,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _dialogGray,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 64, color: Colors.white),
        ),
      ),
    ),
  );
}
