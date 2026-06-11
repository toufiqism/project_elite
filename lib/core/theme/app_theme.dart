import 'package:flutter/material.dart';

import 'palette.dart';

// Re-export so the many screens that already `import app_theme.dart` pick up the
// `context.colors` extension without a second import line.
export 'palette.dart';

class AppTheme {
  static ThemeData dark() => _build(darkPalette, Brightness.dark);
  static ThemeData light() => _build(lightPalette, Brightness.light);
}

ThemeData _build(Palette p, Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final base = isDark
      ? ThemeData.dark(useMaterial3: true)
      : ThemeData.light(useMaterial3: true);
  // Text/icon color that sits on top of a primary-filled button. Dark theme:
  // dark navy on pale-blue. Light theme: white on deep blue.
  final onPrimary = isDark ? p.background : Colors.white;

  final scheme = (isDark ? const ColorScheme.dark() : const ColorScheme.light())
      .copyWith(
    surface: p.surface,
    primary: p.primary,
    secondary: p.accent,
    error: p.danger,
    onSurface: p.text,
  );

  return base.copyWith(
    scaffoldBackgroundColor: p.background,
    colorScheme: scheme,
    appBarTheme: AppBarTheme(
      backgroundColor: p.background,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: p.text,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    ),
    cardTheme: CardThemeData(
      color: p.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: p.text,
      displayColor: p.text,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surfaceAlt,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      labelStyle: TextStyle(color: p.muted),
      hintStyle: TextStyle(color: p.muted),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: p.primary,
        foregroundColor: onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.primary,
        foregroundColor: onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.text,
        side: BorderSide(color: p.surfaceAlt),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: p.surface,
      selectedItemColor: p.primary,
      unselectedItemColor: p.muted,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
    ),
    dividerColor: p.surfaceAlt,
  );
}
