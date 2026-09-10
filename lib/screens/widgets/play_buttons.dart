import 'package:flutter/material.dart';

import '../../config/config.dart';

/// Shared by every play mode. Layout and game actions belong to the caller.
class PlayHomeButton extends StatelessWidget {
  const PlayHomeButton({
    super.key,
    required this.color,
    required this.semanticLabel,
    required this.onTap,
  });

  final Color color;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 85,
    height: 85,
    child: Semantics(
      label: semanticLabel,
      button: true,
      enabled: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: const Center(
            child: Text(
              '←',
              style: TextStyle(
                fontFamily: 'Rwi',
                fontSize: 72,
                height: 1,
                color: AppColors.settingsBlack,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// A null callback disables confirmation and applies the shared disabled color.
class PlayConfirmButton extends StatelessWidget {
  const PlayConfirmButton({
    super.key,
    required this.color,
    required this.text,
    required this.onTap,
  });

  final Color color;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 238,
    height: 143,
    child: Semantics(
      button: true,
      enabled: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: onTap == null ? AppColors.disabled : color,
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 4,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Rwi',
                fontSize: 53,
                color: AppColors.settingsBlack,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
