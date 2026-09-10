import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_translator/service/offline/santali_dictionary.dart';
import 'package:speech_translator/service/voice/voice_service.dart';
import 'package:speech_translator/ui/theme/app_theme.dart';
import 'package:speech_translator/ui/widgets/app_card.dart';
import 'package:speech_translator/ui/widgets/audio_button.dart';
import 'package:speech_translator/ui/widgets/category_chip.dart';
import 'package:speech_translator/ui/widgets/empty_state.dart';

class PhrasebookScreen extends StatefulWidget {
  const PhrasebookScreen({super.key});

  @override
  State<PhrasebookScreen> createState() => _PhrasebookScreenState();
}

class _PhrasebookScreenState extends State<PhrasebookScreen> {
  final VoiceService _voiceService = VoiceService();
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = "All";
  String _searchQuery = "";

  static const List<Map<String, dynamic>> _categories = [
    {"name": "All", "icon": Icons.grid_view_rounded},
    {"name": "Education", "icon": Icons.auto_stories_rounded},
    {"name": "Classroom", "icon": Icons.school_rounded},
    {"name": "Greetings", "icon": Icons.waving_hand_rounded},
    {"name": "Emergency", "icon": Icons.health_and_safety_rounded},
    {"name": "Food & Water", "icon": Icons.restaurant_rounded},
    {"name": "Travel", "icon": Icons.directions_bus_rounded},
    {"name": "Shopping", "icon": Icons.shopping_bag_rounded},
    {"name": "Family", "icon": Icons.family_restroom_rounded},
    {"name": "Conversation", "icon": Icons.chat_bubble_outline_rounded},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = SantaliDictionary.phrases.where((phrase) {
      final matchesCategory = _selectedCategory == "All" || phrase.category == _selectedCategory;
      final q = _searchQuery.toLowerCase().trim();
      final matchesSearch = q.isEmpty ||
          phrase.hindi.toLowerCase().contains(q) ||
          phrase.santaliOlChiki.contains(q) ||
          phrase.santaliLatin.toLowerCase().contains(q) ||
          phrase.santaliDevanagari.contains(q);
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Classroom Phrasebook"),
      ),
      body: Column(
        children: [
          // Search Box
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: "Search phrases in Hindi or Santali...",
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = "");
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
          ),

          // Horizontal Category Selector
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final name = cat["name"] as String;
                final icon = cat["icon"] as IconData;
                final isSelected = _selectedCategory == name;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: CategoryChip(
                    label: name,
                    icon: icon,
                    isSelected: isSelected,
                    onSelected: () {
                      setState(() => _selectedCategory = name);
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Phrases List / Empty State
          Expanded(
            child: filtered.isEmpty
                ? EmptyState(
                    icon: Icons.search_off_rounded,
                    title: "No phrases found",
                    description: "No phrases match '$_searchQuery'. Try checking spelling or choosing another category.",
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final phrase = filtered[index];
                      final isClassroom = phrase.category == "Classroom";

                      return AppCard(
                        accentColor: isClassroom ? AppTheme.primary : AppTheme.terracotta,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Hindi Phrase & Audio Button Row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    phrase.hindi,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AudioButton(
                                      size: 20,
                                      onPressed: () {
                                        HapticFeedback.lightImpact();
                                        _voiceService.speak(
                                          text: phrase.santaliOlChiki,
                                          langCode: 'sat',
                                          phoneticFallback: phrase.santaliLatin,
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      tooltip: "Copy Ol Chiki text",
                                      icon: const Icon(Icons.copy_rounded, size: 18),
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(text: phrase.santaliOlChiki));
                                        HapticFeedback.lightImpact();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text("Copied Ol Chiki phrase"),
                                            duration: Duration(seconds: 1),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Santali Ol Chiki Text
                            SelectableText(
                              phrase.santaliOlChiki,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFF5CE5C0) : AppTheme.primary,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Phonetic & Category Row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppTheme.darkBorder : AppTheme.softYellow,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      "Phonetic: ${phrase.santaliLatin}",
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF5A4408),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppTheme.darkBorder : AppTheme.softGreen,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    phrase.category,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? const Color(0xFF5CE5C0) : AppTheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
