import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_translator/hybrid_translation_service.dart';
import 'package:speech_translator/service/offline/santali_dictionary.dart';
import 'package:speech_translator/service/voice/voice_service.dart';
import 'package:speech_translator/ui/theme/app_theme.dart';
import 'package:speech_translator/ui/widgets/conversation_bubble.dart';
import 'package:speech_translator/ui/widgets/empty_state.dart';

class ConversationMessage {
  final String text;
  final String translated;
  final String phonetic;
  final String speakerLang; // 'hi' or 'sat'
  final DateTime time;

  ConversationMessage({
    required this.text,
    required this.translated,
    required this.phonetic,
    required this.speakerLang,
    required this.time,
  });
}

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> with SingleTickerProviderStateMixin {
  final HybridTranslationService _hybridService = HybridTranslationService();
  final VoiceService _voiceService = VoiceService();
  final List<ConversationMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();

  String _liveTranscript = '';
  String _currentSpeaker = ''; // 'hi' or 'sat' or ''
  bool _isProcessing = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startListening(String speakerLang) async {
    HapticFeedback.heavyImpact();
    if (_voiceService.isListening) {
      await _voiceService.stopListening();
      final text = _liveTranscript.trim();
      setState(() {
        _currentSpeaker = '';
        _liveTranscript = '';
      });
      if (text.isNotEmpty) {
        _processCompletedSentence(text, speakerLang);
      }
      return;
    }

    setState(() {
      _currentSpeaker = speakerLang;
      _liveTranscript = '';
    });

    await _voiceService.startListening(
      languageCode: speakerLang == 'hi' ? 'hi_IN' : 'en_IN',
      onError: (err) {
        setState(() {
          _currentSpeaker = '';
          _liveTranscript = '';
        });
        if (mounted) {
          _showOfflineAssistant(speakerLang);
        }
      },
      onResult: (recognized, isFinal) async {
        if (!mounted) return;

        if (!isFinal) {
          setState(() {
            _liveTranscript = recognized;
          });
        } else {
          final text = recognized.trim();
          setState(() {
            _liveTranscript = '';
            _currentSpeaker = '';
          });
          if (text.isNotEmpty) {
            _processCompletedSentence(text, speakerLang);
          }
        }
      },
    );
  }

  void _processCompletedSentence(String text, String speakerLang) async {
    setState(() => _isProcessing = true);
    final targetLang = speakerLang == 'hi' ? 'sat' : 'hi';
    final result = await _hybridService.translate(
      text: text,
      sourceLang: speakerLang,
      targetLang: targetLang,
    );

    if (mounted) {
      setState(() {
        _messages.add(ConversationMessage(
          text: text,
          translated: result.translatedText,
          phonetic: result.phonetic,
          speakerLang: speakerLang,
          time: DateTime.now(),
        ));
        _isProcessing = false;
      });

      // Speak final translation once
      _voiceService.speak(
        text: result.translatedText,
        langCode: targetLang,
        phoneticFallback: result.phonetic,
      );

      // Scroll to bottom
      Future.delayed(const Duration(milliseconds: 120), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _showOfflineAssistant(String speakerLang) {
    final isTeacher = speakerLang == 'hi';
    final TextEditingController customController = TextEditingController();

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
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
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
                Row(
                  children: [
                    Icon(
                      Icons.offline_bolt_rounded,
                      color: isTeacher ? AppTheme.primary : AppTheme.terracotta,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isTeacher ? "Offline Teacher Input (Hindi)" : "Offline Student Input (Santali)",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Type a phrase or pick from classroom presets below to translate and announce offline:",
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),

                // Manual input field
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: customController,
                        decoration: InputDecoration(
                          hintText: isTeacher
                              ? "यहाँ लिखें (उदा. पाठ पढ़ो / किताब खोलो)..."
                              : "ᱱᱚᱰᱮ ᱚᱞ ᱢᱮ (e.g. ᱡᱚᱦᱟᱨ / Johar)...",
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isTeacher ? AppTheme.primary : AppTheme.terracotta,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        final text = customController.text.trim();
                        if (text.isNotEmpty) {
                          Navigator.pop(context);
                          _processCompletedSentence(text, speakerLang);
                        }
                      },
                      child: const Icon(Icons.send_rounded, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  "Quick Classroom Tap & Speak:",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: SantaliDictionary.phrases
                      .where((p) => p.category == "Classroom" || p.category == "Greetings")
                      .take(10)
                      .map((phrase) {
                    final label = isTeacher ? phrase.hindi : phrase.santaliOlChiki;
                    return ActionChip(
                      label: Text(label, style: const TextStyle(fontSize: 13)),
                      avatar: const Icon(Icons.volume_up_rounded, size: 14),
                      onPressed: () {
                        Navigator.pop(context);
                        _processCompletedSentence(label, speakerLang);
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Determine current textual state
    String statusText;
    IconData statusIcon;
    Color statusColor;

    if (_isProcessing) {
      statusText = "Processing translation...";
      statusIcon = Icons.sync_rounded;
      statusColor = AppTheme.mustardDark;
    } else if (_currentSpeaker.isNotEmpty) {
      final speakerTitle = _currentSpeaker == 'hi' ? 'Teacher (Hindi)' : 'Student (Santali)';
      if (_liveTranscript.isNotEmpty) {
        statusText = 'Listening to $speakerTitle: "$_liveTranscript"';
      } else {
        statusText = "Listening to $speakerTitle...";
      }
      statusIcon = Icons.mic_rounded;
      statusColor = _currentSpeaker == 'hi' ? AppTheme.primary : AppTheme.terracotta;
    } else if (_messages.isNotEmpty) {
      statusText = "Translation ready • Tap mic to speak";
      statusIcon = Icons.check_circle_outline_rounded;
      statusColor = AppTheme.primary;
    } else {
      statusText = "Tap microphone below to start speaking";
      statusIcon = Icons.record_voice_over_outlined;
      statusColor = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Classroom Conversation"),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              tooltip: "Clear conversation",
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Clear conversation?"),
                    content: const Text("This will clear all current messages on this screen."),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text("Clear"),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  setState(() => _messages.clear());
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Live Classroom Status Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : AppTheme.surfaceSubtle,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppTheme.darkBorder : AppTheme.borderWarm,
                  width: 1.0,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isProcessing)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(statusIcon, size: 18, color: statusColor),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    statusText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: statusColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Messages List / Empty State
          Expanded(
            child: _messages.isEmpty
                ? EmptyState(
                    icon: Icons.school_rounded,
                    title: "Live Classroom Two-Way Speech",
                    description:
                        "Facilitates real-time conversation between Hindi-speaking teachers and Santali-speaking students.\n\n• Tap 'Speak Hindi' for teacher instructions\n• Tap 'Speak Santali' for student answers",
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isTeacher = msg.speakerLang == 'hi';

                      return ConversationBubble(
                        speakerLang: msg.speakerLang,
                        originalText: msg.text,
                        translatedText: msg.translated,
                        phonetic: msg.phonetic,
                        time: msg.time,
                        onPlayAudio: () {
                          _voiceService.speak(
                            text: msg.translated,
                            langCode: isTeacher ? 'sat' : 'hi',
                            phoneticFallback: msg.phonetic,
                          );
                        },
                      );
                    },
                  ),
          ),

          // Bottom Dual Microphone Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : AppTheme.surface,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppTheme.darkBorder : AppTheme.borderWarm,
                  width: 1.2,
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
              child: Row(
                children: [
                  // Teacher (Hindi) Microphone
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        final active = _currentSpeaker == 'hi';
                        return Transform.scale(
                          scale: active ? _pulseAnimation.value : 1.0,
                          child: ElevatedButton.icon(
                            onPressed: () => _startListening('hi'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: active ? Colors.red : AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            icon: Icon(active ? Icons.mic : Icons.mic_none_rounded, size: 22),
                            label: Text(
                              active ? "Listening..." : "Speak Hindi\n(Teacher)",
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Offline Sheet / Text helper button
                  IconButton(
                    tooltip: "Offline Classroom Phrases",
                    style: IconButton.styleFrom(
                      backgroundColor: isDark ? AppTheme.darkBorder : AppTheme.softGreen,
                      foregroundColor: AppTheme.primary,
                      padding: const EdgeInsets.all(12),
                    ),
                    icon: const Icon(Icons.offline_bolt_rounded, size: 22),
                    onPressed: () => _showOfflineAssistant(
                      _currentSpeaker.isNotEmpty ? _currentSpeaker : 'hi',
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Student (Santali) Microphone
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        final active = _currentSpeaker == 'sat';
                        return Transform.scale(
                          scale: active ? _pulseAnimation.value : 1.0,
                          child: ElevatedButton.icon(
                            onPressed: () => _startListening('sat'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: active ? Colors.red : AppTheme.terracotta,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            icon: Icon(active ? Icons.mic : Icons.mic_none_rounded, size: 22),
                            label: Text(
                              active ? "Listening..." : "Speak Santali\n(Student)",
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
