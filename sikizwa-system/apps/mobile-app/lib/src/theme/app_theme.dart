import 'package:flutter/material.dart';

class AppTheme {
  static const _primary = Color(0xFF5B2DA4);
  static const _primarySoft = Color(0xFF7C3AED);
  static const _surface = Color(0xFFF8F6FF);
  static const _surfaceDark = Color(0xFF1A102D);
  static const _card = Color(0xFFFFFFFF);
  static const _cardDark = Color(0xFF24163C);

  static ThemeData _base(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primary,
      brightness: brightness,
      primary: _primary,
      secondary: _primarySoft,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? _surfaceDark : _surface,
      cardColor: isDark ? _cardDark : _card,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: Typography.blackMountainView.copyWith(
        bodyMedium: TextStyle(color: isDark ? Colors.white : Colors.black87),
        bodyLarge: TextStyle(color: isDark ? Colors.white : Colors.black87),
      ),
      cardTheme: CardThemeData(
        color: isDark ? _cardDark : _card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF2A1A47) : const Color(0xFFF4F0FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: _primarySoft, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );
  }

  static final light = _base(Brightness.light);
  static final dark = _base(Brightness.dark);
}
