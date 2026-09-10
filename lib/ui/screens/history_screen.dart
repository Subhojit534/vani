import 'package:flutter/material.dart';
import 'package:speech_translator/service/storage/storage_service.dart';
import 'package:speech_translator/service/voice/voice_service.dart';
import 'package:speech_translator/ui/theme/app_theme.dart';
import 'package:speech_translator/ui/widgets/app_card.dart';
import 'package:speech_translator/ui/widgets/audio_button.dart';
import 'package:speech_translator/ui/widgets/empty_state.dart';

class HistoryScreen extends StatefulWidget {
  final VoidCallback? onNavigateToTranslate;
  const HistoryScreen({super.key, this.onNavigateToTranslate});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final StorageService _storageService = StorageService();
  final VoiceService _voiceService = VoiceService();

  List<HistoryItem> _allHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final items = await _storageService.getHistory();
    if (mounted) {
      setState(() {
        _allHistory = items;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favorites = _allHistory.where((x) => x.isFavorite).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("History & Favorites"),
        actions: [
          if (_allHistory.isNotEmpty)
            IconButton(
              tooltip: "Clear history",
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Clear all history?"),
                    content: const Text("This will remove all recent translation history. Saved favorites will remain."),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text("Clear"),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await _storageService.clearHistory();
                  _loadHistory();
                }
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.history_rounded, size: 20),
              text: "Recent (${_allHistory.length})",
            ),
            Tab(
              icon: const Icon(Icons.star_rounded, size: 20),
              text: "Favorites (${favorites.length})",
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(
                  _allHistory,
                  isFavorites: false,
                ),
                _buildList(
                  favorites,
                  isFavorites: true,
                ),
              ],
            ),
    );
  }

  Widget _buildList(List<HistoryItem> items, {required bool isFavorites}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (items.isEmpty) {
      return EmptyState(
        icon: isFavorites ? Icons.star_outline_rounded : Icons.history_edu_rounded,
        title: isFavorites ? "No classroom favorites yet" : "No translation history yet",
        description: isFavorites
            ? "Tap the star icon on any translation card to save essential classroom phrases for instant lesson recall."
            : "Phrases translated during lessons will be recorded here so you can review and practice them with students.",
        buttonText: "Start Translating",
        onButtonPressed: widget.onNavigateToTranslate,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isHindiSource = item.sourceLang == 'hi';

        return Dismissible(
          key: Key(item.id),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.red.shade400,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
          ),
          onDismissed: (_) async {
            final messenger = ScaffoldMessenger.of(context);
            await _storageService.deleteHistoryItem(item.id);
            _loadHistory();
            messenger.showSnackBar(
              const SnackBar(
                content: Text("Translation removed from history"),
                duration: Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: AppCard(
            accentColor: isHindiSource ? AppTheme.primary : AppTheme.terracotta,
            margin: const EdgeInsets.symmetric(vertical: 5),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Language direction & Star/Audio Toolbar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkBorder : AppTheme.softGreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${isHindiSource ? 'Hindi' : 'Santali'} ➔ ${item.targetLang == 'sat' ? 'Santali' : 'Hindi'}",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFF5CE5C0) : AppTheme.primary,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          tooltip: item.isFavorite ? "Remove favorite" : "Save favorite",
                          icon: Icon(
                            item.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                            color: item.isFavorite ? AppTheme.mustard : Colors.grey,
                            size: 22,
                          ),
                          onPressed: () async {
                            await _storageService.toggleFavorite(item.id);
                            _loadHistory();
                          },
                        ),
                        AudioButton(
                          size: 18,
                          onPressed: () {
                            _voiceService.speak(
                              text: item.translatedText,
                              langCode: item.targetLang,
                              phoneticFallback: item.phonetic,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Source Text
                Text(
                  item.sourceText,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),

                // Translated Text
                SelectableText(
                  item.translatedText,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                    height: 1.3,
                  ),
                ),

                // Phonetic Guide
                if (item.phonetic.isNotEmpty && item.phonetic != item.translatedText) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkBorder : AppTheme.softYellow,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "Phonetic: ${item.phonetic}",
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF5A4408),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
