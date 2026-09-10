import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_translator/ui/theme/app_theme.dart';

class OlChikiKeyboard extends StatelessWidget {
  final Function(String char) onKeyTap;
  final VoidCallback onBackspace;
  final VoidCallback onSpace;
  final VoidCallback? onClear;
  final VoidCallback? onClose;

  const OlChikiKeyboard({
    super.key,
    required this.onKeyTap,
    required this.onBackspace,
    required this.onSpace,
    this.onClear,
    this.onClose,
  });

  static const List<List<String>> rows = [
    ['ᱚ', 'ᱛ', 'ᱜ', 'ᱝ', 'ᱞ', 'ᱟ', 'ᱠ', 'ᱡ'],
    ['ᱢ', 'ᱣ', 'ᱤ', 'ᱥ', 'ᱦ', 'ᱧ', 'ᱨ', 'ᱩ'],
    ['ᱪ', 'ᱫ', 'ᱬ', 'ᱭ', 'ᱮ', 'ᱯ', 'ᱰ', 'ᱱ'],
    ['ᱲ', 'ᱳ', 'ᱴ', 'ᱵ', 'ᱶ', 'ᱷ', 'ᱸ', 'ᱹ'],
    ['ᱺ', 'ᱻ', 'ᱼ', '᱾', '᱿', '᱐', '᱑', '᱒'],
    ['᱓', '᱔', '᱕', '᱖', '᱗', '᱘', '᱙', '0'],
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final kbBg = isDark ? AppTheme.darkSurface : AppTheme.warmParchment;
    final keyBg = isDark ? AppTheme.darkCard : Colors.white;
    final keyBorder = isDark ? AppTheme.darkBorder : AppTheme.borderWarm;
    final textColor = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: kbBg,
        border: Border(
          top: BorderSide(
            color: isDark ? AppTheme.darkBorder : AppTheme.borderWarm,
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.3) : const Color(0x1424332F),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Keyboard Header Toolbar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkBorder : AppTheme.softGreen,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.keyboard_rounded,
                          size: 16,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "ᱚᱞ ᱪᱤᱠᱤ ᱠᱤᱵᱳᱨᱰ (Ol Chiki Script)",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (onClear != null)
                        TextButton(
                          onPressed: onClear,
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            foregroundColor: AppTheme.terracotta,
                          ),
                          child: const Text(
                            "Clear",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      if (onClose != null)
                        IconButton(
                          tooltip: "Hide Keyboard",
                          icon: const Icon(Icons.keyboard_hide_rounded, size: 20),
                          onPressed: onClose,
                          visualDensity: VisualDensity.compact,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // Alphabet and Numeral Rows
            for (var row in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: row.map((char) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.5),
                        child: Material(
                          color: keyBg,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              HapticFeedback.lightImpact();
                              onKeyTap(char);
                            },
                            child: Container(
                              height: 42,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: keyBorder, width: 1.0),
                              ),
                              child: Text(
                                char,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

            // Action Row: Space, Backspace
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: onSpace,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: keyBg,
                          foregroundColor: textColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: keyBorder, width: 1.2),
                          ),
                        ),
                        icon: const Icon(Icons.space_bar_rounded, size: 20),
                        label: const Text(
                          "Space (ᱡᱟᱭᱜᱟ)",
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: onBackspace,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.terracotta,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Icon(Icons.backspace_outlined, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
