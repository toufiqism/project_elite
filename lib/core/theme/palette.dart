import 'package:flutter/material.dart';

/// Theme-aware color tokens. Two instances exist — [darkPalette] and
/// [lightPalette] — and screens read whichever matches the active brightness
/// via the [PaletteX.colors] extension (`context.colors.background`).
///
/// These tokens are NOT Material's ColorScheme: accent/success/warning/muted/
/// surfaceAlt don't map onto it cleanly, so a single accessor keeps every call
/// site uniform. The only places that touch a palette directly (not via
/// context) are the [AppTheme] builders below.
@immutable
class Palette {
  const Palette({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.primary,
    required this.accent,
    required this.success,
    required this.warning,
    required this.danger,
    required this.muted,
    required this.text,
  });

  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color primary;
  final Color accent;
  final Color success;
  final Color warning;
  final Color danger;
  final Color muted;
  final Color text;
}

const darkPalette = Palette(
  background: Color(0xFF0B0F14),
  surface: Color(0xFF141A22),
  surfaceAlt: Color(0xFF1C2530),
  primary: Color(0xFF8AB4FF),
  accent: Color(0xFFE7C77B),
  success: Color(0xFF4ADE80),
  warning: Color(0xFFF59E0B),
  danger: Color(0xFFEF4444),
  muted: Color(0xFF7C8794),
  text: Color(0xFFE6EAF2),
);

const lightPalette = Palette(
  background: Color(0xFFF5F7FA),
  surface: Color(0xFFFFFFFF),
  surfaceAlt: Color(0xFFEAEEF3),
  primary: Color(0xFF2563EB),
  accent: Color(0xFFB8860B),
  success: Color(0xFF16A34A),
  warning: Color(0xFFD97706),
  danger: Color(0xFFDC2626),
  muted: Color(0xFF5A6573),
  text: Color(0xFF1A2027),
);

extension PaletteX on BuildContext {
  /// Palette matching the active theme brightness. Repaints automatically when
  /// [ThemeController] flips the app's themeMode.
  Palette get colors =>
      Theme.of(this).brightness == Brightness.dark ? darkPalette : lightPalette;
}
