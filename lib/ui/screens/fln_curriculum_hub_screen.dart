import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_translator/models/fln_models.dart';
import 'package:speech_translator/service/fln/fln_curriculum_data.dart';
import 'package:speech_translator/service/fln/worksheet_generator_service.dart';
import 'package:speech_translator/service/fln/worksheet_pdf_service.dart';
import 'package:speech_translator/service/offline/santali_dictionary.dart';
import 'package:speech_translator/service/voice/voice_service.dart';
import 'package:speech_translator/ui/theme/app_theme.dart';
import 'package:speech_translator/ui/widgets/app_card.dart';
import 'package:speech_translator/ui/widgets/audio_button.dart';
import 'package:speech_translator/ui/widgets/empty_state.dart';

class FlnCurriculumHubScreen extends StatefulWidget {
  final int initialTabIndex;
  const FlnCurriculumHubScreen({super.key, this.initialTabIndex = 0});

  @override
  State<FlnCurriculumHubScreen> createState() => _FlnCurriculumHubScreenState();
}

class _FlnCurriculumHubScreenState extends State<FlnCurriculumHubScreen> {
  final VoiceService _voiceService = VoiceService();

  // Lesson script filters
  FlnGrade _selectedGrade = FlnGrade.balvatika;
  FlnSubject _selectedSubject = FlnSubject.literacy;

  // Classroom instruction filter
  String _selectedInstructionCategory = "All";

  // Vocabulary search state
  final TextEditingController _vocabSearchController = TextEditingController();
  String _vocabSearch = "";

  // Worksheet generator state
  late BilingualWorksheet _currentWorksheet;
  bool _showAnswerKey = false;
  bool _isGeneratingPdf = false;

  // AI Worksheet Chatbot Prototype state
  final TextEditingController _chatInputController = TextEditingController();
  bool _isChatProcessing = false;
  String? _chatStatusText;
  Timer? _chatProcessingTimer;
  Timer? _chatStepTimer1;
  Timer? _chatStepTimer2;
  Timer? _chatResetTimer;

  @override
  void initState() {
    super.initState();
    _currentWorksheet = WorksheetGeneratorService.generateWorksheet(
      grade: _selectedGrade,
      subject: _selectedSubject,
    );
  }

  @override
  void dispose() {
    _vocabSearchController.dispose();
    _chatInputController.dispose();
    _chatProcessingTimer?.cancel();
    _chatStepTimer1?.cancel();
    _chatStepTimer2?.cancel();
    _chatResetTimer?.cancel();
    super.dispose();
  }

  void _speakSantali(String text, String phonetic) {
    _voiceService.speak(
      text: text,
      langCode: 'sat',
      phoneticFallback: phonetic,
    );
  }

  Future<void> _downloadPdf() async {
    setState(() => _isGeneratingPdf = true);
    try {
      final msg = await WorksheetPdfService.downloadOrPrintPdf(
        _currentWorksheet,
        includeAnswerKey: _showAnswerKey,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("PDF बनाने में समस्या हुई: $e")),
      );
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  void _handleChatSubmit() {
    if (_isChatProcessing) return;
    final query = _chatInputController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("कृपया कार्यपत्रक के लिए अपना अनुरोध लिखें (Please enter a request)"),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isChatProcessing = true;
      _chatStatusText = "Preparing your worksheet...";
    });

    // 0 - 2 sec: Preparing worksheet...
    _chatStepTimer1?.cancel();
    _chatStepTimer1 = Timer(const Duration(milliseconds: 2000), () {
      if (mounted && _isChatProcessing) {
        setState(() {
          _chatStatusText = "Formatting activities...";
        });
      }
    });

    // 2 - 4 sec: Formatting activities... -> at 4 sec: Creating PDF...
    _chatStepTimer2?.cancel();
    _chatStepTimer2 = Timer(const Duration(milliseconds: 4000), () {
      if (mounted && _isChatProcessing) {
        setState(() {
          _chatStatusText = "Creating PDF...";
        });
      }
    });

    // Exactly 5 seconds: trigger existing PDF generation
    _chatProcessingTimer?.cancel();
    _chatProcessingTimer = Timer(const Duration(milliseconds: 5000), () async {
      if (!mounted) return;
      await _downloadPdf();
      if (mounted) {
        setState(() {
          _chatStatusText = "✓ Worksheet PDF ready";
        });
        _chatResetTimer?.cancel();
        _chatResetTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _isChatProcessing = false;
              _chatStatusText = null;
              _chatInputController.clear();
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return DefaultTabController(
      length: 6,
      initialIndex: widget.initialTabIndex,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "PALASH MTB-MLE & NIPUN Bharat",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              Text(
                "झारखंड प्राथमिक शिक्षक संथाली शिक्षण साथी",
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          bottom: TabBar(
            isScrollable: true,
            labelColor: primary,
            indicatorColor: primary,
            tabs: const [
              Tab(icon: Icon(Icons.menu_book), text: "पाठ योजना (Scripts)"),
              Tab(icon: Icon(Icons.record_voice_over), text: "कक्षा निर्देश (Phrases)"),
              Tab(icon: Icon(Icons.translate), text: "शब्दावली (Vocabulary)"),
              Tab(icon: Icon(Icons.school), text: "वर्णमाला (Ol Chiki)"),
              Tab(icon: Icon(Icons.quiz), text: "आकलन (Assessments)"),
              Tab(icon: Icon(Icons.description), text: "कार्यपत्रक (Worksheets)"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildLessonScriptsTab(),
            _buildClassroomInstructionsTab(),
            _buildVocabularyTab(),
            _buildAlphabetTab(),
            _buildAssessmentPromptsTab(),
            _buildWorksheetsTab(),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 1: LESSON SCRIPTS (पाठ योजना एवं शिक्षक संवाद)
  // =========================================================================
  Widget _buildLessonScriptsTab() {
    final scripts = FlnCurriculumData.lessonScripts;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Intro banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.shade300),
          ),
          child: Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber.shade800, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "हिंदी-माध्यम प्रशिक्षित शिक्षक इन पाठ योजनाओं के संथाली संवाद को सुनकर बच्चों के साथ मातृभाषा में कक्षा संचालित कर सकते हैं।",
                  style: TextStyle(fontSize: 13, color: Colors.brown, height: 1.3),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Lesson list
        ...scripts.map((script) => _buildLessonCard(script)),
      ],
    );
  }

  Widget _buildLessonCard(LessonScript script) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: primary.withValues(alpha: 0.15),
          child: Icon(
            script.subject == FlnSubject.literacy ? Icons.auto_stories : Icons.calculate,
            color: primary,
          ),
        ),
        title: Text(
          script.titleHindi,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                script.titleSantali,
                style: TextStyle(color: primary, fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      script.competencyCode,
                      style: TextStyle(color: Colors.blue.shade900, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text("⏱ ${script.totalDurationMinutes} मिनट", style: const TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                // Outcome
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 18, color: Colors.green.shade800),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "अपेक्षित सीख: ${script.learningOutcome}",
                          style: TextStyle(fontSize: 12, color: Colors.green.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                const Text("कक्षा संचालन चरण (Step-by-Step Flow):", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                // Phases
                ...script.phases.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final phase = entry.value;
                  return _buildPhaseTile(idx + 1, phase);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseTile(int stepNumber, LessonPhase phase) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                phase.phaseNameHindi,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.indigo),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text("${phase.durationMinutes} min", style: const TextStyle(fontSize: 11, color: Colors.indigo)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "शिक्षक निर्देश (Hindi): ${phase.teacherDialogueHindi}",
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 8),

          // Santali Box with Audio
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.deepOrange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "संथाली संवाद (ओल चिकी):",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                    ),
                    IconButton(
                      icon: const Icon(Icons.volume_up, color: Colors.deepOrange),
                      tooltip: "संथाली में बोलें",
                      onPressed: () => _speakSantali(phase.santaliOlChiki, phase.santaliLatin),
                    ),
                  ],
                ),
                Text(
                  phase.santaliOlChiki,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                ),
                const SizedBox(height: 4),
                Text(
                  "उच्चारण (Phonetic): ${phase.santaliLatin}",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                ),
                Text(
                  "देवनागरी: ${phase.santaliDevanagari}",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 2: CLASSROOM INSTRUCTIONS SOUNDBOARD
  // =========================================================================
  Widget _buildClassroomInstructionsTab() {
    final allInstructions = FlnCurriculumData.classroomInstructions;
    final categories = ["All", "Classroom Management", "Praise & Encouragement", "Focus & Attention", "Movement & Action", "Questioning & Interaction"];

    final filtered = allInstructions.where((item) {
      if (_selectedInstructionCategory == "All") return true;
      return item.category == _selectedInstructionCategory;
    }).toList();

    return Column(
      children: [
        // Category Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: categories.map((cat) {
              final isSelected = _selectedInstructionCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cat == "All" ? "सभी निर्देश" : cat),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) setState(() => _selectedInstructionCategory = cat);
                  },
                ),
              );
            }).toList(),
          ),
        ),

        // Soundboard Grid / List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: filtered.length,
            itemBuilder: (context, idx) {
              final item = filtered[idx];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Audio Trigger Button
                      Container(
                        margin: const EdgeInsets.only(right: 12, top: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.volume_up),
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          onPressed: () => _speakSantali(item.santaliOlChiki, item.santaliLatin),
                        ),
                      ),
                      // Text Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.hindi,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.santaliOlChiki,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "बोलो: ${item.santaliLatin}",
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.info_outline, size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    item.pedagogicalTip,
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // TAB 3: VOCABULARY (संथाली - हिन्दी शब्दावली)
  // =========================================================================
  Widget _buildVocabularyTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredVocab = SantaliDictionary.vocabulary.where((w) {
      if (_vocabSearch.isEmpty) return true;
      final q = _vocabSearch.toLowerCase().trim();
      return w.hindi.toLowerCase().contains(q) ||
          w.santaliOlChiki.contains(q) ||
          w.santaliLatin.toLowerCase().contains(q) ||
          w.santaliDevanagari.contains(q);
    }).toList();

    return Column(
      children: [
        // Search Input Box
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: TextField(
            controller: _vocabSearchController,
            onChanged: (val) => setState(() => _vocabSearch = val),
            decoration: InputDecoration(
              hintText: "Search word in Hindi or Santali...",
              prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primary),
              suffixIcon: _vocabSearch.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _vocabSearchController.clear();
                        setState(() => _vocabSearch = "");
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
                  description: "No dictionary entries match '$_vocabSearch'. Try searching in Hindi or Ol Chiki script.",
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
    );
  }

  // =========================================================================
  // TAB 4: OL CHIKI ALPHABET (ओल चिकी वर्णमाला)
  // =========================================================================
  Widget _buildAlphabetTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
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
    );
  }

  // =========================================================================
  // TAB 5: ASSESSMENT PROMPTS (निपुण भारत आकलन)
  // =========================================================================
  Widget _buildAssessmentPromptsTab() {
    final prompts = FlnCurriculumData.assessmentPrompts;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: prompts.length,
      itemBuilder: (context, idx) {
        final ap = prompts[idx];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "दक्षता: ${ap.competencyCode}",
                        style: TextStyle(color: Colors.purple.shade900, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    Text(ap.grade.shortLabel, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),

                // Question Prompt
                const Text("शिक्षक द्वारा पूछा जाने वाला प्रश्न:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(
                  ap.promptHindi,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 6),

                // Santali Prompt with audio
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ap.promptSantaliOlChiki,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.purple.shade900),
                            ),
                            Text(
                              ap.promptSantaliLatin,
                              style: TextStyle(fontSize: 12, color: Colors.purple.shade800, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.volume_up, color: Colors.purple),
                        onPressed: () => _speakSantali(ap.promptSantaliOlChiki, ap.promptSantaliLatin),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Expected response
                Text("अपेक्षित संथाली उत्तर: ${ap.expectedResponseSantali}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal)),
                const SizedBox(height: 12),

                // Rubric
                const Text("मूल्यांकन रुब्रिक (3-Level Criteria):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 6),
                _buildRubricRow("स्तर 1 (शुरुआती)", ap.rubricBeginning, Colors.red.shade100, Colors.red.shade900),
                _buildRubricRow("स्तर 2 (प्रगतिशील)", ap.rubricProgressing, Colors.orange.shade100, Colors.orange.shade900),
                _buildRubricRow("स्तर 3 (दक्ष)", ap.rubricProficient, Colors.green.shade100, Colors.green.shade900),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRubricRow(String level, String desc, Color bgColor, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(level, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: textColor)),
          ),
          Expanded(
            child: Text(desc, style: TextStyle(fontSize: 11, color: textColor)),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 4: BILINGUAL WORKSHEETS (द्विभाषी कार्यपत्रक निर्माता)
  // =========================================================================
  Widget _buildWorksheetsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        // Controls card
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "निपुण भारत कार्यपत्रक विन्यास (Worksheet Settings):",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<FlnGrade>(
                  isExpanded: true,
                  initialValue: _selectedGrade,
                  decoration: const InputDecoration(
                    labelText: "कक्षा (Grade)",
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(),
                  ),
                  items: FlnGrade.values.map((g) {
                    return DropdownMenuItem(value: g, child: Text(g.label));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedGrade = val;
                        _currentWorksheet = WorksheetGeneratorService.generateWorksheet(
                          grade: _selectedGrade,
                          subject: _selectedSubject,
                        );
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<FlnSubject>(
                  isExpanded: true,
                  initialValue: _selectedSubject,
                  decoration: const InputDecoration(
                    labelText: "विषय (Subject)",
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: FlnSubject.literacy, child: Text("भाषा (Literacy)")),
                    DropdownMenuItem(value: FlnSubject.numeracy, child: Text("गणित (Numeracy)")),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedSubject = val;
                        _currentWorksheet = WorksheetGeneratorService.generateWorksheet(
                          grade: _selectedGrade,
                          subject: _selectedSubject,
                        );
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text("नया कार्यपत्रक बनाएं"),
                      onPressed: () {
                        setState(() {
                          _currentWorksheet = WorksheetGeneratorService.generateWorksheet(
                            grade: _selectedGrade,
                            subject: _selectedSubject,
                          );
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("नया कार्यपत्रक तैयार हो गया!"), duration: Duration(seconds: 1)),
                        );
                      },
                    ),
                    OutlinedButton.icon(
                      icon: Icon(_showAnswerKey ? Icons.visibility_off : Icons.visibility),
                      label: Text(_showAnswerKey ? "उत्तर छिपाएं" : "उत्तर कुंजी"),
                      onPressed: () => setState(() => _showAnswerKey = !_showAnswerKey),
                    ),
                    FilledButton.tonalIcon(
                      icon: _isGeneratingPdf
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.picture_as_pdf),
                      label: const Text("PDF डाउनलोड / प्रिंट"),
                      onPressed: _isGeneratingPdf ? null : _downloadPdf,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildChatAssistant(context, Theme.of(context).brightness == Brightness.dark),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Printable layout header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  "JHARKHAND PALASH MTB-MLE PROGRAMME",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.1),
                  textAlign: TextAlign.center,
                ),
              ),
              const Center(
                child: Text(
                  "निपुण भारत द्विभाषी अभ्यास कार्यपत्रक (संथाली - हिन्दी)",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 12,
                runSpacing: 6,
                children: [
                  Text("कक्षा: ${_currentWorksheet.grade.shortLabel}", style: const TextStyle(fontSize: 12)),
                  Text("दक्षता: ${_currentWorksheet.competencyCode}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const Text("दिनांक: ________", style: TextStyle(fontSize: 12)),
                ],
              ),
              const SizedBox(height: 6),
              const Text("विद्यार्थी का नाम: ________________________", style: TextStyle(fontSize: 12)),
              const Divider(),
              Text(
                "निर्देश: ${_currentWorksheet.instructionsHindi}",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
              ),
              Text(
                "ᱫᱤᱥᱟᱹ: ${_currentWorksheet.instructionsSantali}",
                style: TextStyle(fontSize: 12, color: Colors.indigo.shade800, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),

        // Worksheet Items
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            border: Border.all(color: Colors.grey.shade300),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._currentWorksheet.items.map((item) => _buildWorksheetItemWidget(item)),

              // Answer key view
              if (_showAnswerKey) ...[
                const Divider(thickness: 2),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "शिक्षक उत्तर कुंजी (Teacher Answer Key):",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
                      ),
                      const SizedBox(height: 6),
                      ..._currentWorksheet.items.map((it) {
                        return Text(
                          "प्र. ${it.itemNumber}: ${it.correctAnswer}",
                          style: TextStyle(fontSize: 12, color: Colors.green.shade900, fontWeight: FontWeight.w600),
                        );
                      }),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
              // Action buttons: PDF Download and Text Copy
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    icon: _isGeneratingPdf
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.download_for_offline),
                    label: const Text("कार्यपत्रक PDF डाउनलोड करें"),
                    onPressed: _isGeneratingPdf ? null : _downloadPdf,
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.copy),
                    label: const Text("टेक्स्ट कॉपी करें (Copy)"),
                    onPressed: () {
                      final text = WorksheetGeneratorService.formatWorksheetAsText(
                        _currentWorksheet,
                        includeAnswerKey: _showAnswerKey,
                      );
                      Clipboard.setData(ClipboardData(text: text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("कार्यपत्रक क्लिपबोर्ड पर कॉपी हो गया! इसे प्रिंट या शेयर कर सकते हैं।")),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildChatAssistant(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.surfaceSubtle,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.borderWarm,
          width: 1.1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row: ✨ PALASH Worksheet Assistant
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                size: 15,
                color: AppTheme.terracotta,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "PALASH Worksheet Assistant",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.primaryDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF174238) : AppTheme.softGreen,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "AI Assistant",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFB4EAE0) : AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Subtitle / Simulated processing status / Result status
          if (_chatStatusText != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF174238) : AppTheme.softGreen,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? const Color(0xFF238472) : AppTheme.primary.withValues(alpha: 0.3),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  if (_isChatProcessing)
                    const SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primary,
                      ),
                    )
                  else
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 15,
                      color: AppTheme.primary,
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _chatStatusText!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFB4EAE0) : AppTheme.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                "Tell me what you need — I'll prepare the worksheet.",
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                ),
              ),
            ),

          // Input field row with Send button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatInputController,
                  enabled: !_isChatProcessing,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleChatSubmit(),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: "Type your request...",
                    hintStyle: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: isDark ? AppTheme.darkCard : Colors.white,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: isDark ? AppTheme.darkBorder : AppTheme.borderWarm,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: isDark ? AppTheme.darkBorder : AppTheme.borderWarm,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: isDark ? AppTheme.darkBorder.withValues(alpha: 0.5) : AppTheme.borderSubtle,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: "Send request",
                child: Material(
                  color: _isChatProcessing
                      ? (isDark ? AppTheme.darkBorder : AppTheme.softGreen)
                      : AppTheme.primary,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: _isChatProcessing ? null : _handleChatSubmit,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      child: _isChatProcessing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primary,
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Example suggestion
          InkWell(
            onTap: _isChatProcessing
                ? null
                : () {
                    _chatInputController.text = "Make this worksheet ready";
                    _chatInputController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _chatInputController.text.length),
                    );
                  },
            borderRadius: BorderRadius.circular(4),
            child: Text(
              'Example: "Make this worksheet ready"',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorksheetItemWidget(BilingualWorksheetItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "प्र. ${item.itemNumber}. ${item.promptHindi}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          Text(
            item.promptSantali,
            style: TextStyle(fontSize: 12, color: Colors.indigo.shade800),
          ),
          const SizedBox(height: 8),

          // Stimulus display
          if (item.stimulusIcon != null || item.stimulusText.isNotEmpty || item.countQuantity != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  if (item.countQuantity != null)
                    Wrap(
                      spacing: 4,
                      children: List.generate(
                        item.countQuantity!,
                        (_) => Icon(item.stimulusIcon ?? Icons.star, color: Colors.amber.shade700, size: 28),
                      ),
                    )
                  else if (item.stimulusIcon != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item.stimulusIcon, size: 30, color: Colors.blue.shade800),
                    ),
                  if (item.stimulusText.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Text(
                      item.stimulusText,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
            ),

          const SizedBox(height: 6),
          // Options
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: item.options.map((opt) {
              final isCorrect = _showAnswerKey && opt == item.correctAnswer;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isCorrect ? Colors.green.shade100 : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isCorrect ? Colors.green : Colors.grey.shade400,
                    width: isCorrect ? 2 : 1,
                  ),
                ),
                child: Text(
                  opt,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                    color: isCorrect ? Colors.green.shade900 : Colors.black87,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
