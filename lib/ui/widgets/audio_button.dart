import 'package:flutter/material.dart';
import 'package:speech_translator/ui/theme/app_theme.dart';

class AudioButton extends StatelessWidget {
  final VoidCallback onPressed;
  final double size;
  final Color? color;
  final Color? backgroundColor;
  final String tooltip;

  const AudioButton({
    super.key,
    required this.onPressed,
    this.size = 22,
    this.color,
    this.backgroundColor,
    this.tooltip = "Listen to pronunciation",
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = color ?? (isDark ? const Color(0xFF38B29D) : AppTheme.primary);
    final bgColor = backgroundColor ?? (isDark ? AppTheme.darkBorder : AppTheme.softGreen);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: bgColor,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            child: Icon(
              Icons.volume_up_rounded,
              size: size,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}
