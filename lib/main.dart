import 'package:flutter/material.dart';
import 'package:speech_translator/ui/screens/conversation_screen.dart';
import 'package:speech_translator/ui/screens/fln_curriculum_hub_screen.dart';
import 'package:speech_translator/ui/screens/history_screen.dart';
import 'package:speech_translator/ui/screens/home_screen.dart';
import 'package:speech_translator/ui/screens/phrasebook_screen.dart';
import 'package:speech_translator/ui/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SantaliTranslatorApp());
}

class SantaliTranslatorApp extends StatefulWidget {
  const SantaliTranslatorApp({super.key});

  @override
  State<SantaliTranslatorApp> createState() => _SantaliTranslatorAppState();
}

class _SantaliTranslatorAppState extends State<SantaliTranslatorApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Santali Classroom Translator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: MainNavigationContainer(onToggleTheme: _toggleTheme),
    );
  }
}

class MainNavigationContainer extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const MainNavigationContainer({super.key, required this.onToggleTheme});

  @override
  State<MainNavigationContainer> createState() => _MainNavigationContainerState();
}

class _MainNavigationContainerState extends State<MainNavigationContainer> {
  int _currentIndex = 0;

  void _navigateToTab(int index) {
    if (index >= 0 && index < 5) {
      setState(() => _currentIndex = index);
    }
  }

  late final List<Widget> _screens = [
    const HomeScreen(),
    const FlnCurriculumHubScreen(),
    const ConversationScreen(),
    const PhrasebookScreen(),
    HistoryScreen(onNavigateToTranslate: () => _navigateToTab(0)),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
        ),
      ),
      bottomNavigationBar: Container(
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
              color: isDark ? Colors.black.withValues(alpha: 0.25) : const Color(0x0F24332F),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.0,
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (idx) {
                setState(() => _currentIndex = idx);
              },
              backgroundColor: Colors.transparent,
              indicatorColor: isDark ? const Color(0xFF174238) : AppTheme.softGreen,
              height: 66,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.translate_outlined),
                  selectedIcon: Icon(Icons.translate_rounded),
                  label: "Translate",
                ),
                NavigationDestination(
                  icon: Icon(Icons.auto_stories_outlined),
                  selectedIcon: Icon(Icons.auto_stories_rounded),
                  label: "FLN Hub",
                ),
                NavigationDestination(
                  icon: Icon(Icons.record_voice_over_outlined),
                  selectedIcon: Icon(Icons.record_voice_over_rounded),
                  label: "Conversation",
                ),
                NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book_rounded),
                  label: "Phrasebook",
                ),
                NavigationDestination(
                  icon: Icon(Icons.history_edu_outlined),
                  selectedIcon: Icon(Icons.history_edu_rounded),
                  label: "History",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
