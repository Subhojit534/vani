import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_translator/hybrid_translation_service.dart';
import 'package:speech_translator/service/offline/offline_translator.dart';
import 'package:speech_translator/service/offline/santali_dictionary.dart';
import 'package:speech_translator/service/storage/storage_service.dart';
import 'package:speech_translator/service/voice/voice_service.dart';
import 'package:speech_translator/ui/theme/app_theme.dart';
import 'package:speech_translator/ui/widgets/app_card.dart';
import 'package:speech_translator/ui/widgets/audio_button.dart';
import 'package:speech_translator/ui/widgets/ol_chiki_keyboard.dart';
import 'package:speech_translator/ui/widgets/section_header.dart';
import 'package:speech_translator/ui/widgets/status_badge.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  final HybridTranslationService _hybridService = HybridTranslationService();
  final VoiceService _voiceService = VoiceService();
  final StorageService _storageService = StorageService();

  String _sourceLang = 'hi'; // 'hi' or 'sat'
  String _targetLang = 'sat';
  bool _isOffline = true;
  bool _showKeyboard = false;
  bool _isLoading = false;
  bool _isFavorite = false;

  // Language selector UI state
  String _selectedSourceLang = "हिंदी (Hindi)";
  String _selectedTargetLang = "Santali";
  bool _isSourceMenuOpen = false;
  bool _isTargetMenuOpen = false;

  static const List<String> _sourceLanguageOptions = [
    "हिंदी (Hindi)",
    "English",
  ];

  static const List<String> _targetLanguageOptions = [
    "Santali",
    "Mundari",
    "Ho",
  ];

  Color _getLanguageDotColor(String lang) {
    switch (lang) {
      case 'Santali':
      case 'Mundari':
      case 'Ho':
        return AppTheme.terracotta;
      case 'हिंदी (Hindi)':
      case 'English':
      default:
        return AppTheme.primary;
    }
  }

  void _onSourceLanguageSelected(String lang) {
    setState(() {
      _selectedSourceLang = lang;
      if (lang == "हिंदी (Hindi)") {
        _sourceLang = 'hi';
        _showKeyboard = false;
      } else if (lang == "English") {
        _sourceLang = 'hi';
        _showKeyboard = false;
      }
    });
  }

  void _onTargetLanguageSelected(String lang) {
    setState(() {
      _selectedTargetLang = lang;
      if (lang == "Santali") {
        _targetLang = 'sat';
      }
    });
  }

  TranslationResult? _currentResult;
  Timer? _debounceTimer;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initSettings();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.20).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _inputController.addListener(_onTextChanged);
  }

  Future<void> _initSettings() async {
    final offline = await _storageService.getOfflineMode();
    if (mounted) {
      setState(() {
        _isOffline = offline;
        _hybridService.isOfflineMode = offline;
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _inputController.removeListener(_onTextChanged);
    _inputController.dispose();
    _focusNode.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _debounceTimer?.cancel();
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _currentResult = null;
        _isFavorite = false;
        _isLoading = false;
      });
    } else {
      _debounceTimer = Timer(const Duration(milliseconds: 350), () {
        if (mounted && _inputController.text.trim().isNotEmpty) {
          _performTranslation(_inputController.text.trim());
        }
      });
    }
  }

  Future<void> _performTranslation(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;

    setState(() => _isLoading = true);
    final result = await _hybridService.translate(
      text: clean,
      sourceLang: _sourceLang,
      targetLang: _targetLang,
    );

    if (mounted) {
      setState(() {
        _currentResult = result;
        _isLoading = false;
      });

      // Save to history for meaningful inputs
      if (result.translatedText.isNotEmpty && clean.length >= 2) {
        final historyItem = HistoryItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          sourceText: result.sourceText,
          translatedText: result.translatedText,
          sourceLang: result.sourceLang,
          targetLang: result.targetLang,
          phonetic: result.phonetic,
          timestamp: DateTime.now(),
        );
        await _storageService.addHistoryItem(historyItem);
      }
    }
  }

  void _swapLanguages() {
    HapticFeedback.selectionClick();
    _debounceTimer?.cancel();
    _inputController.removeListener(_onTextChanged);

    final prevTranslation = _currentResult?.translatedText;

    setState(() {
      final temp = _sourceLang;
      _sourceLang = _targetLang;
      _targetLang = temp;

      final tempUi = _selectedSourceLang;
      _selectedSourceLang = _selectedTargetLang;
      _selectedTargetLang = tempUi;

      if (prevTranslation != null && prevTranslation.isNotEmpty) {
        _inputController.text = prevTranslation;
      } else {
        _inputController.clear();
      }
      _showKeyboard = _sourceLang == 'sat';
      _currentResult = null;
    });

    _inputController.addListener(_onTextChanged);

    if (_inputController.text.trim().isNotEmpty) {
      _performTranslation(_inputController.text.trim());
    }
  }

  void _toggleVoiceInput() async {
    HapticFeedback.heavyImpact();
    if (_voiceService.isListening) {
      await _voiceService.stopListening();
      if (_inputController.text.trim().isNotEmpty) {
        _performTranslation(_inputController.text.trim());
      }
      setState(() {});
    } else {
      setState(() {});
      await _voiceService.startListening(
        languageCode: _sourceLang == 'hi' ? 'hi_IN' : 'en_IN',
        onResult: (recognized, isFinal) {
          if (!mounted) return;
          setState(() {
            _inputController.text = recognized;
            _inputController.selection = TextSelection.fromPosition(
              TextPosition(offset: recognized.length),
            );
          });
          if (isFinal && recognized.trim().isNotEmpty) {
            _performTranslation(recognized.trim());
          }
        },
        onError: (err) {
          setState(() {});
          if (mounted) {
            _showOfflineVoiceSheet();
          }
        },
      );
      setState(() {});
    }
  }

  void _showOfflineVoiceSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
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
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.offline_bolt_rounded, color: AppTheme.primary, size: 22),
                    SizedBox(width: 8),
                    Text(
                      "Offline Classroom Phrases",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Speech recognition requires offline language pack. Tap any classroom phrase below for instant offline translation and audio:",
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: SantaliDictionary.phrases
                      .where((p) => p.category == "Classroom" || p.category == "Greetings")
                      .take(14)
                      .map((phrase) {
                    final label = _sourceLang == 'hi' ? phrase.hindi : phrase.santaliOlChiki;
                    return ActionChip(
                      label: Text(label, style: const TextStyle(fontSize: 13)),
                      avatar: const Icon(Icons.volume_up_rounded, size: 16),
                      onPressed: () {
                        Navigator.pop(context);
                        _inputController.text = label;
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _speakText(String text, String lang, {String? phonetic}) {
    HapticFeedback.lightImpact();
    _voiceService.speak(
      text: text,
      langCode: lang,
      phoneticFallback: phonetic,
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Copied to clipboard"),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleFavorite() {
    if (_currentResult == null) return;
    setState(() {
      _isFavorite = !_isFavorite;
    });
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFavorite ? "Saved to Classroom Favorites" : "Removed from Favorites"),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkBorder : AppTheme.softGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.school_rounded,
                size: 20,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Santali Translator",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Classroom Edition",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: StatusBadge(
              isOffline: _isOffline,
              onToggle: (val) async {
                setState(() {
                  _isOffline = val;
                  _hybridService.isOfflineMode = val;
                });
                await _storageService.setOfflineMode(val);
                if (_inputController.text.isNotEmpty) {
                  _performTranslation(_inputController.text);
                }
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Language Switcher Banner
          Container(
            margin: const EdgeInsets.fromLTRB(14, 4, 14, 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: isDark ? AppTheme.darkBorder : AppTheme.borderWarm,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withValues(alpha: 0.15) : const Color(0x0A24332F),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Source Language Selector
                Expanded(
                  child: _buildLanguageSelector(
                    context: context,
                    currentLang: _selectedSourceLang,
                    headerTitle: "SOURCE LANGUAGE",
                    options: _sourceLanguageOptions,
                    isOpen: _isSourceMenuOpen,
                    onOpenChanged: (val) => setState(() => _isSourceMenuOpen = val),
                    onSelected: _onSourceLanguageSelected,
                  ),
                ),

                // Swap Button
                IconButton(
                  tooltip: "Swap languages",
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkBorder : AppTheme.softGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.swap_horiz_rounded,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                  ),
                  onPressed: _swapLanguages,
                ),

                // Target Language Selector
                Expanded(
                  child: _buildLanguageSelector(
                    context: context,
                    currentLang: _selectedTargetLang,
                    headerTitle: "TARGET LANGUAGE",
                    options: _targetLanguageOptions,
                    isOpen: _isTargetMenuOpen,
                    onOpenChanged: (val) => setState(() => _isTargetMenuOpen = val),
                    onSelected: _onTargetLanguageSelected,
                  ),
                ),
              ],
            ),
          ),

          // Scrollable content area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Source Input Card ---
                  AppCard(
                    accentColor: AppTheme.primary,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _sourceLang == 'hi' ? "TEACHER / HINDI INPUT" : "SANTALI (OL CHIKI) INPUT",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                if (_sourceLang == 'sat')
                                  IconButton(
                                    tooltip: "Toggle Ol Chiki Virtual Keyboard",
                                    icon: Icon(
                                      _showKeyboard ? Icons.keyboard_hide_rounded : Icons.keyboard_rounded,
                                      size: 20,
                                      color: _showKeyboard ? AppTheme.primary : Colors.grey,
                                    ),
                                    onPressed: () {
                                      setState(() => _showKeyboard = !_showKeyboard);
                                    },
                                  ),
                                if (_inputController.text.isNotEmpty)
                                  IconButton(
                                    tooltip: "Clear input",
                                    icon: const Icon(Icons.close_rounded, size: 18),
                                    onPressed: () {
                                      _inputController.clear();
                                    },
                                  ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Text Field
                        TextField(
                          controller: _inputController,
                          focusNode: _focusNode,
                          maxLines: 4,
                          minLines: 2,
                          style: TextStyle(
                            fontSize: 17,
                            height: 1.35,
                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: _sourceLang == 'hi'
                                ? "यहाँ लिखें या बोलें (उदा. किताब खोलो / आप कैसे हैं?)..."
                                : "ᱱᱚᱰᱮ ᱚᱞ ᱢᱮ (e.g. ᱪᱮᱫ ᱞᱮᱠᱟ ᱢᱮᱱᱟᱜ ᱵᱤᱱᱟ)...",
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),

                        const Divider(height: 20),

                        // Input Card Action Bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  tooltip: "Paste",
                                  icon: const Icon(Icons.content_paste_rounded, size: 20),
                                  onPressed: () async {
                                    final data = await Clipboard.getData('text/plain');
                                    if (data?.text != null) {
                                      _inputController.text = data!.text!;
                                    }
                                  },
                                ),
                                if (_inputController.text.isNotEmpty)
                                  AudioButton(
                                    size: 18,
                                    tooltip: "Listen to input",
                                    onPressed: () {
                                      _speakText(_inputController.text, _sourceLang);
                                    },
                                  ),
                              ],
                            ),

                            // Microphone Button
                            AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                final isListening = _voiceService.isListening;
                                return Transform.scale(
                                  scale: isListening ? _pulseAnimation.value : 1.0,
                                  child: ElevatedButton.icon(
                                    onPressed: _toggleVoiceInput,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isListening ? Colors.red : AppTheme.primary,
                                      foregroundColor: Colors.white,
                                      elevation: isListening ? 4 : 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                    ),
                                    icon: Icon(
                                      isListening ? Icons.mic : Icons.mic_none_rounded,
                                      size: 20,
                                    ),
                                    label: Text(
                                      isListening ? "Listening..." : "Tap to Speak",
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // --- Translation Output Card ---
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(28.0),
                      child: Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(strokeWidth: 2.5),
                            SizedBox(height: 12),
                            Text(
                              "Translating classroom text...",
                              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_currentResult != null && _currentResult!.translatedText.isNotEmpty)
                    AppCard(
                      accentColor: AppTheme.terracotta,
                      backgroundColor: isDark ? const Color(0xFF261E1A) : AppTheme.surfaceSubtle,
                      borderColor: isDark ? const Color(0xFF4A3226) : const Color(0xFFF0DDD1),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Target Language Header Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _targetLang == 'sat' ? "SANTALI (ᱚᱞ ᱪᱤᱠᱤ)" : "HINDI (हिंदी)",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                      color: AppTheme.terracotta,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (_currentResult!.isExactMatch)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.softGreen,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        "Verified",
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryDark,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              IconButton(
                                tooltip: _isFavorite ? "Remove favorite" : "Save favorite",
                                icon: Icon(
                                  _isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                                  color: _isFavorite ? AppTheme.mustard : Colors.grey,
                                  size: 24,
                                ),
                                onPressed: _toggleFavorite,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Large Primary Translation Output
                          SelectableText(
                            _currentResult!.translatedText,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppTheme.textPrimary,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Phonetic pronunciation pill
                          if (_currentResult!.phonetic.isNotEmpty &&
                              _currentResult!.phonetic != _currentResult!.translatedText)
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.darkBorder : AppTheme.softYellow,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.record_voice_over_outlined, size: 14, color: AppTheme.mustardDark),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      "Pronunciation: ${_currentResult!.phonetic}",
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF5A4408),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Devanagari transliteration
                          if (_targetLang == 'sat' &&
                              _currentResult!.devanagari.isNotEmpty &&
                              _currentResult!.devanagari != _currentResult!.translatedText)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                "संथाली (देवनागरी): ${_currentResult!.devanagari}",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                                ),
                              ),
                            ),

                          const Divider(height: 20),

                          // Action Toolbar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  AudioButton(
                                    size: 22,
                                    tooltip: "Speak translation",
                                    color: AppTheme.terracotta,
                                    backgroundColor: isDark ? const Color(0xFF4A3226) : AppTheme.softTerracotta,
                                    onPressed: () {
                                      _speakText(
                                        _currentResult!.translatedText,
                                        _targetLang,
                                        phonetic: _currentResult!.phonetic,
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    tooltip: "Copy text",
                                    icon: const Icon(Icons.copy_rounded, size: 20),
                                    onPressed: () {
                                      _copyToClipboard(_currentResult!.translatedText);
                                    },
                                  ),
                                  IconButton(
                                    tooltip: "Classroom Flashcard Mode",
                                    icon: const Icon(Icons.fullscreen_rounded, size: 22),
                                    onPressed: () {
                                      _showFullscreenDialog(_currentResult!);
                                    },
                                  ),
                                ],
                              ),
                              Flexible(
                                child: Text(
                                  _isOffline ? "🟢 Offline Engine" : "🟠 AI4Bharat Neural",
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // --- Quick Classroom Phrases ---
                  const SectionHeader(
                    title: "Quick Classroom Phrases",
                    subtitle: "Tap to quickly translate and announce to students",
                    icon: Icons.lightbulb_outline_rounded,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: SantaliDictionary.phrases
                        .where((p) => p.category == "Classroom" || p.category == "Greetings")
                        .take(8)
                        .map((phrase) {
                      final label = _sourceLang == 'hi' ? phrase.hindi : phrase.santaliOlChiki;
                      return ActionChip(
                        label: Text(label, style: const TextStyle(fontSize: 13)),
                        avatar: const Icon(Icons.volume_up_rounded, size: 14),
                        onPressed: () {
                          _inputController.text = label;
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Virtual Ol Chiki Keyboard
          if (_showKeyboard)
            OlChikiKeyboard(
              onKeyTap: (char) {
                final text = _inputController.text;
                final selection = _inputController.selection;
                final newText = text.replaceRange(
                  selection.start < 0 ? text.length : selection.start,
                  selection.end < 0 ? text.length : selection.end,
                  char,
                );
                final newCursorPos = (selection.start < 0 ? text.length : selection.start) + char.length;
                _inputController.value = TextEditingValue(
                  text: newText,
                  selection: TextSelection.collapsed(offset: newCursorPos),
                );
              },
              onSpace: () {
                final text = _inputController.text;
                final selection = _inputController.selection;
                final newText = text.replaceRange(
                  selection.start < 0 ? text.length : selection.start,
                  selection.end < 0 ? text.length : selection.end,
                  ' ',
                );
                _inputController.value = TextEditingValue(
                  text: newText,
                  selection: TextSelection.collapsed(offset: (selection.start < 0 ? text.length : selection.start) + 1),
                );
              },
              onBackspace: () {
                final text = _inputController.text;
                final selection = _inputController.selection;
                if (text.isEmpty) return;
                if (selection.start > 0) {
                  final newText = text.replaceRange(selection.start - 1, selection.end, '');
                  _inputController.value = TextEditingValue(
                    text: newText,
                    selection: TextSelection.collapsed(offset: selection.start - 1),
                  );
                } else if (selection.start < 0 && text.isNotEmpty) {
                  _inputController.text = text.substring(0, text.length - 1);
                }
              },
              onClear: () {
                _inputController.clear();
              },
              onClose: () {
                setState(() => _showKeyboard = false);
              },
            ),
        ],
      ),
    );
  }

  void _showFullscreenDialog(TranslationResult result) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        child: Scaffold(
          backgroundColor: isDark ? AppTheme.darkBg : AppTheme.warmParchment,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: const Text("Classroom Card"),
            leading: IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.pop(ctx),
            ),
            actions: [
              IconButton(
                tooltip: "Speak audio",
                icon: const Icon(Icons.volume_up_rounded, color: AppTheme.primary),
                onPressed: () {
                  _speakText(result.translatedText, result.targetLang, phonetic: result.phonetic);
                },
              ),
            ],
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                  accentColor: AppTheme.terracotta,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        result.sourceText,
                        style: TextStyle(
                          fontSize: 20,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      SelectableText(
                        result.translatedText,
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          height: 1.35,
                          color: isDark ? Colors.white : AppTheme.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (result.phonetic.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkBorder : AppTheme.softYellow,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "Pronunciation: ${result.phonetic}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF5A4408),
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector({
    required BuildContext context,
    required String currentLang,
    required String headerTitle,
    required List<String> options,
    required bool isOpen,
    required ValueChanged<bool> onOpenChanged,
    required ValueChanged<String> onSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Theme(
      data: Theme.of(context).copyWith(
        hoverColor: isDark ? const Color(0xFF174238) : AppTheme.softGreen,
        highlightColor: isDark ? const Color(0xFF174238) : AppTheme.softGreen,
      ),
      child: PopupMenuButton<String>(
        tooltip: '',
        position: PopupMenuPosition.under,
        elevation: 4,
        shadowColor: const Color(0x1F24332F),
        surfaceTintColor: Colors.transparent,
        color: isDark ? AppTheme.darkCard : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? AppTheme.darkBorder : AppTheme.borderWarm,
            width: 1.2,
          ),
        ),
        onOpened: () => onOpenChanged(true),
        onCanceled: () => onOpenChanged(false),
        onSelected: (val) {
          onOpenChanged(false);
          HapticFeedback.selectionClick();
          onSelected(val);
        },
        itemBuilder: (BuildContext popupContext) {
          final List<PopupMenuEntry<String>> items = [];

          // Header: SOURCE LANGUAGE or TARGET LANGUAGE
          items.add(
            PopupMenuItem<String>(
              enabled: false,
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Text(
                headerTitle,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                ),
              ),
            ),
          );

          // Subtle divider below header
          items.add(
            PopupMenuItem<String>(
              enabled: false,
              height: 1,
              padding: EdgeInsets.zero,
              child: Divider(
                height: 1,
                thickness: 1,
                color: isDark ? AppTheme.darkBorder : AppTheme.borderSubtle,
              ),
            ),
          );

          // Language options
          for (final lang in options) {
            final isSelected = lang == currentLang;
            final dotColor = _getLanguageDotColor(lang);

            items.add(
              PopupMenuItem<String>(
                value: lang,
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? const Color(0xFF174238) : AppTheme.softGreen)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 18,
                        child: isSelected
                            ? Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: isDark ? const Color(0xFF38B29D) : AppTheme.primary,
                              )
                            : null,
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: dotColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          lang,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? (isDark ? const Color(0xFFB4EAE0) : AppTheme.primaryDark)
                                : (isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return items;
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: isOpen
                ? (isDark ? AppTheme.darkBorder : AppTheme.softGreen.withValues(alpha: 0.6))
                : (isDark ? Colors.white.withValues(alpha: 0.04) : AppTheme.surfaceSubtle),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isOpen
                  ? (isDark ? const Color(0xFF38B29D) : AppTheme.primary.withValues(alpha: 0.5))
                  : (isDark ? AppTheme.darkBorder : AppTheme.borderSubtle),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getLanguageDotColor(currentLang),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  currentLang,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              AnimatedRotation(
                turns: isOpen ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

