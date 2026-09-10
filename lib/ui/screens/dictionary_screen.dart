import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_translator/service/offline/santali_dictionary.dart';
import 'package:speech_translator/service/voice/voice_service.dart';
import 'package:speech_translator/ui/theme/app_theme.dart';
import 'package:speech_translator/ui/widgets/app_card.dart';
import 'package:speech_translator/ui/widgets/audio_button.dart';
import 'package:speech_translator/ui/widgets/empty_state.dart';

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final VoiceService _voiceService = VoiceService();
  final TextEditingController _searchController = TextEditingController();
  String _search = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredVocab = SantaliDictionary.vocabulary.where((w) {
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase().trim();
      return w.hindi.toLowerCase().contains(q) ||
          w.santaliOlChiki.contains(q) ||
          w.santaliLatin.toLowerCase().contains(q) ||
          w.santaliDevanagari.contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dictionary & Literacy"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Vocabulary", icon: Icon(Icons.menu_book_rounded, size: 20)),
            Tab(text: "Ol Chiki Alphabet", icon: Icon(Icons.school_rounded, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ================= Tab 1: Vocabulary =================
          Column(
            children: [
              // Search Input Box
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _search = val),
                  decoration: InputDecoration(
                    hintText: "Search word in Hindi or Santali...",
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primary),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _search = "");
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                ),
              ),

              // Word list / Empty state
              Expanded(
                child: filteredVocab.isEmpty
                    ? EmptyState(
                        icon: Icons.search_off_rounded,
                        title: "No words found",
                        description: "No dictionary entries match '$_search'. Try searching in Hindi or Ol Chiki script.",
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        itemCount: filteredVocab.length,
                        itemBuilder: (context, index) {
                          final word = filteredVocab[index];

                          return AppCard(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top row: Hindi Word & Audio
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              word.hindi,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 18,
                                                color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isDark ? AppTheme.darkBorder : AppTheme.softGreen,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              word.partOfSpeech,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? const Color(0xFF5CE5C0) : AppTheme.primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    AudioButton(
                                      size: 20,
                                      onPressed: () {
                                        HapticFeedback.lightImpact();
                                        _voiceService.speak(
                                          text: word.santaliOlChiki,
                                          langCode: 'sat',
                                          phoneticFallback: word.santaliLatin,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),

                                // Santali Ol Chiki Word
                                SelectableText(
                                  word.santaliOlChiki,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? const Color(0xFF5CE5C0) : AppTheme.primary,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 6),

                                // Secondary Info: Phonetic & Devanagari
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppTheme.darkBorder : AppTheme.softYellow,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        "Phonetic: ${word.santaliLatin}",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                          color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF5A4408),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      "देवनागरी: ${word.santaliDevanagari}",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
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

          // ================= Tab 2: Ol Chiki Alphabet =================
          LayoutBuilder(
            builder: (context, constraints) {
              final isTablet = constraints.maxWidth >= 680;
              final crossAxisCount = isTablet ? 3 : 2;

              return CustomScrollView(
                slivers: [
                  // Educational Banner
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: AppCard(
                        accentColor: AppTheme.mustard,
                        backgroundColor: isDark ? const Color(0xFF282319) : AppTheme.softMustard,
                        borderColor: isDark ? const Color(0xFF4A3B20) : const Color(0xFFEBD8B2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.school_rounded,
                                color: AppTheme.mustardDark,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "ᱚᱞ ᱪᱤᱠᱤ (Ol Chiki Script Literacy)",
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Created in 1925 by Pandit Raghunath Murmu. Each letter represents a sound shaped after natural objects, body gestures, and traditional Santal heritage.",
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 1.35,
                                      color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF4A3B20),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Alphabet Grid
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: isTablet ? 2.1 : 1.75,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final letter = SantaliDictionary.olChikiAlphabet[index];
                          final char = letter["char"]!;
                          final name = letter["name"]!;
                          final ipa = letter["ipa"]!;
                          final meaning = letter["meaning"]!;

                          return AppCard(
                            padding: const EdgeInsets.all(12),
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _voiceService.speak(
                                text: char,
                                langCode: 'sat',
                                phoneticFallback: name,
                              );
                            },
                            child: Row(
                              children: [
                                // Glyph Box
                                Container(
                                  width: 48,
                                  height: 48,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isDark ? AppTheme.darkBorder : AppTheme.softGreen,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF2F403B) : const Color(0xFFCDE3DA),
                                    ),
                                  ),
                                  child: Text(
                                    char,
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? const Color(0xFF5CE5C0) : AppTheme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // Letter Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      Text(
                                        ipa,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        meaning,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF8A7750),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.volume_up_rounded,
                                  size: 16,
                                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                                ),
                              ],
                            ),
                          );
                        },
                        childCount: SantaliDictionary.olChikiAlphabet.length,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
