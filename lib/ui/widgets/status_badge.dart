import 'package:flutter/material.dart';
import 'package:speech_translator/ui/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final bool isOffline;
  final ValueChanged<bool>? onToggle;

  const StatusBadge({
    super.key,
    required this.isOffline,
    this.onToggle,
  });

  void _showOfflineInfo(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isOffline ? AppTheme.softGreen : AppTheme.softTerracotta,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isOffline ? Icons.offline_pin_rounded : Icons.cloud_done_rounded,
                      color: isOffline ? AppTheme.primary : AppTheme.terracotta,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOffline ? "Ready for Offline Use" : "AI4Bharat Online Connected",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          isOffline ? "Local school resources active" : "Cloud neural translation active",
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : AppTheme.warmParchment,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppTheme.darkBorder : AppTheme.borderWarm,
                  ),
                ),
                child: Column(
                  children: [
                    _infoRow(
                      Icons.check_circle_outline_rounded,
                      "Full Santali Offline Dictionary & Phrases",
                      "Instant translations without internet connection",
                      isDark,
                    ),
                    const SizedBox(height: 12),
                    _infoRow(
                      Icons.keyboard_outlined,
                      "Virtual Ol Chiki Keyboard",
                      "Type in native Santali script anytime",
                      isDark,
                    ),
                    const SizedBox(height: 12),
                    _infoRow(
                      Icons.cloud_outlined,
                      "AI4Bharat Hybrid Fallback",
                      "Connects automatically to cloud model when online",
                      isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (onToggle != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      onToggle!(!isOffline);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isOffline ? AppTheme.terracotta : AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: Icon(isOffline ? Icons.cloud_queue_rounded : Icons.offline_pin_rounded),
                    label: Text(
                      isOffline ? "Switch to Online (AI4Bharat)" : "Switch to Offline Mode",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String title, String subtitle, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isOffline
        ? (isDark ? const Color(0xFF143329) : AppTheme.softGreen)
        : (isDark ? const Color(0xFF382319) : AppTheme.softTerracotta);

    final border = isOffline
        ? (isDark ? const Color(0xFF265646) : const Color(0xFFBFE0D4))
        : (isDark ? const Color(0xFF5E3929) : const Color(0xFFF3C7B5));

    final textColor = isOffline
        ? (isDark ? const Color(0xFF7CE4C7) : AppTheme.primaryDark)
        : (isDark ? const Color(0xFFFFAB8B) : AppTheme.terracottaDark);

    return InkWell(
      onTap: () => _showOfflineInfo(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOffline ? const Color(0xFF2E9A6F) : AppTheme.terracotta,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              isOffline ? "Offline Ready" : "Online Mode",
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 16,
              color: textColor,
            ),
          ],
        ),
      ),
    );
  }
}
