import 'package:flutter/material.dart';
import 'package:speech_translator/ui/theme/app_theme.dart';
import 'package:speech_translator/ui/widgets/audio_button.dart';

class ConversationBubble extends StatelessWidget {
  final String speakerLang; // 'hi' (Teacher) or 'sat' (Student)
  final String originalText;
  final String translatedText;
  final String phonetic;
  final DateTime time;
  final VoidCallback onPlayAudio;

  const ConversationBubble({
    super.key,
    required this.speakerLang,
    required this.originalText,
    required this.translatedText,
    required this.phonetic,
    required this.time,
    required this.onPlayAudio,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTeacher = speakerLang == 'hi';

    final cardBg = isTeacher
        ? (isDark ? const Color(0xFF1B2A26) : AppTheme.softGreen)
        : (isDark ? const Color(0xFF33231B) : AppTheme.softTerracotta);

    final borderColor = isTeacher
        ? (isDark ? const Color(0xFF28483F) : const Color(0xFFBFE0D4))
        : (isDark ? const Color(0xFF5A3626) : const Color(0xFFF3C7B5));

    final roleColor = isTeacher
        ? (isDark ? const Color(0xFF5CE5C0) : AppTheme.primary)
        : (isDark ? const Color(0xFFFF9E7A) : AppTheme.terracotta);

    final roleLabel = isTeacher ? "TEACHER (HINDI)" : "STUDENT (SANTALI)";
    final roleIcon = isTeacher ? Icons.person_rounded : Icons.face_rounded;

    return Align(
      alignment: isTeacher ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width > 600
              ? 540
              : MediaQuery.of(context).size.width * 0.88,
        ),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.4),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.25) : const Color(0x0A24332F),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Speaker Role Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(roleIcon, size: 14, color: roleColor),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            roleLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: roleColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AudioButton(
                  onPressed: onPlayAudio,
                  size: 20,
                  color: roleColor,
                  backgroundColor: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.8),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Original Speech Text
            Text(
              originalText,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),

            // Subtle arrow divider
            Row(
              children: [
                Icon(
                  Icons.arrow_downward_rounded,
                  size: 14,
                  color: roleColor.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Divider(
                    color: borderColor,
                    thickness: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Translated Text (Prominent Ol Chiki if Santali)
            SelectableText(
              translatedText,
              style: TextStyle(
                fontSize: isTeacher ? 21 : 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppTheme.textPrimary,
                height: 1.35,
              ),
            ),

            // Phonetic guide
            if (phonetic.isNotEmpty && phonetic != translatedText) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "Phonetic: $phonetic",
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
