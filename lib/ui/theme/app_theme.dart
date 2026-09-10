import 'package:flutter/material.dart';

class AppTheme {
  // --- "Warm Classroom + Tribal Heritage" Color Palette ---
  // Classroom Parchment & Surfaces
  static const Color warmParchment = Color(0xFFFFF8ED);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFFFFBF5);

  // Classroom Primary (Forest Green / Slate Teal)
  static const Color primary = Color(0xFF176B5B);
  static const Color primaryDark = Color(0xFF0F5145);
  static const Color primaryLight = Color(0xFF238472);

  // Cultural Accents
  static const Color terracotta = Color(0xFFE46A3A);
  static const Color terracottaDark = Color(0xFFB84C23);
  static const Color mustard = Color(0xFFE9B949);
  static const Color mustardDark = Color(0xFFC7982B);

  // Compatibility aliases
  static const Color primaryColor = primary;
  static const Color secondaryColor = Color(0xFF2D6A4F);
  static const Color accentColor = terracotta;
  static const Color lightBg = warmParchment;
  static const Color lightCard = surface;

  // Text Colors
  static const Color textPrimary = Color(0xFF24332F);
  static const Color textSecondary = Color(0xFF6F7A75);
  static const Color textMuted = Color(0xFF9AA5A0);

  // Soft Tint Fills
  static const Color softGreen = Color(0xFFE5F1EC);
  static const Color softTerracotta = Color(0xFFFCE9DE);
  static const Color softYellow = Color(0xFFFFF4D6);
  static const Color softMustard = Color(0xFFFCF4E2);

  // Borders & Dividers
  static const Color borderWarm = Color(0xFFEADBCE);
  static const Color borderSubtle = Color(0xFFF2EAE0);

  // Dark Theme Equivalents (Calm deep spruce classroom at night)
  static const Color darkBg = Color(0xFF141D1A);
  static const Color darkSurface = Color(0xFF1C2724);
  static const Color darkCard = Color(0xFF23302C);
  static const Color darkTextPrimary = Color(0xFFF1F5F3);
  static const Color darkTextSecondary = Color(0xFFA6B7B0);
  static const Color darkBorder = Color(0xFF2F403B);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        primaryContainer: softGreen,
        onPrimaryContainer: primaryDark,
        secondary: terracotta,
        onSecondary: Colors.white,
        secondaryContainer: softTerracotta,
        onSecondaryContainer: terracottaDark,
        tertiary: mustard,
        onTertiary: Color(0xFF3F2E04),
        tertiaryContainer: softYellow,
        surface: surface,
        onSurface: textPrimary,
      ),
      scaffoldBackgroundColor: warmParchment,
      canvasColor: warmParchment,
      appBarTheme: const AppBarTheme(
        backgroundColor: warmParchment,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1.5,
        shadowColor: Color(0x1A24332F),
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: textPrimary, size: 24),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: borderWarm, width: 1.2),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          minimumSize: const Size(48, 44),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceSubtle,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(
          color: textSecondary,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: const TextStyle(
          color: textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderWarm, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderWarm, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        elevation: 2,
        shadowColor: const Color(0x1F24332F),
        indicatorColor: softGreen,
        height: 66,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: -0.3,
            color: isSelected ? primary : textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primary, size: 24);
          }
          return const IconThemeData(color: textSecondary, size: 24);
        }),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: textSecondary,
        indicatorColor: primary,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceSubtle,
        selectedColor: softGreen,
        secondarySelectedColor: softGreen,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        secondaryLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: primary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderWarm, width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      dividerTheme: const DividerThemeData(
        color: borderSubtle,
        thickness: 1,
        space: 16,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF38B29D),
        onPrimary: Colors.black,
        primaryContainer: Color(0xFF174238),
        onPrimaryContainer: Color(0xFFB4EAE0),
        secondary: Color(0xFFFF8B5E),
        onSecondary: Colors.black,
        secondaryContainer: Color(0xFF4A2518),
        onSecondaryContainer: Color(0xFFFFD4C4),
        surface: darkSurface,
        onSurface: darkTextPrimary,
      ),
      scaffoldBackgroundColor: darkBg,
      canvasColor: darkBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: darkTextPrimary, size: 24),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: darkBorder, width: 1.2),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF38B29D),
          foregroundColor: Colors.black,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurface,
        elevation: 2,
        indicatorColor: const Color(0xFF174238),
        height: 66,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: -0.3,
            color: isSelected ? const Color(0xFF38B29D) : darkTextSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Color(0xFF38B29D), size: 24);
          }
          return const IconThemeData(color: darkTextSecondary, size: 24);
        }),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: Color(0xFF38B29D),
        unselectedLabelColor: darkTextSecondary,
        indicatorColor: Color(0xFF38B29D),
      ),
    );
  }
}
