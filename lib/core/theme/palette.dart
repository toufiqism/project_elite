import 'package:flutter/material.dart';

/// Theme-aware color tokens. Two instances exist — [darkPalette] and
/// [lightPalette] — and screens read whichever matches the active brightness
/// via the [PaletteX.colors] extension (`context.colors.background`).
///
/// These tokens are NOT Material's ColorScheme: accent/success/warning/muted/
/// surfaceAlt don't map onto it cleanly, so a single accessor keeps every call
/// site uniform. The only places that touch a palette directly (not via
/// context) are the [AppTheme] builders below.
///
/// Values track the "Project Elite" design prototype (theme.jsx): flat
/// surfaces, 1px hairline borders ([line]/[lineStrong]), an indigo [accent]
/// with a tinted [accentSoft] backing, and a two-step muted scale
/// ([muted]/[mutedSoft]). [primary] is kept as an alias of [accent] so the
/// existing Material theme + call sites keep working.
@immutable
class Palette {
  const Palette({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.line,
    required this.lineStrong,
    required this.primary,
    required this.accent,
    required this.accentSoft,
    required this.success,
    required this.warning,
    required this.danger,
    required this.muted,
    required this.mutedSoft,
    required this.text,
  });

  final Color background;
  final Color surface;
  final Color surfaceAlt;

  /// Hairline border on cards/dividers. [lineStrong] is the higher-contrast
  /// variant for emphasized edges.
  final Color line;
  final Color lineStrong;

  final Color primary;

  /// Brand action color (indigo). [accentSoft] is its low-contrast tinted
  /// background used for chips/pills and selected states.
  final Color accent;
  final Color accentSoft;

  final Color success;
  final Color warning;
  final Color danger;

  /// Primary secondary-text color. [mutedSoft] is the dimmer tier used for
  /// inactive tab labels and tertiary captions.
  final Color muted;
  final Color mutedSoft;
  final Color text;
}

const darkPalette = Palette(
  background: Color(0xFF0A0A0A),
  surface: Color(0xFF141414),
  surfaceAlt: Color(0xFF1C1C1C),
  line: Color(0xFF262626),
  lineStrong: Color(0xFF3A3A3A),
  primary: Color(0xFF4F46E5),
  accent: Color(0xFF4F46E5),
  accentSoft: Color(0xFF1E1B4B),
  success: Color(0xFF10B981),
  warning: Color(0xFFF59E0B),
  danger: Color(0xFFEF4444),
  muted: Color(0xFFA1A1AA),
  mutedSoft: Color(0xFF71717A),
  text: Color(0xFFFAFAFA),
);

const lightPalette = Palette(
  background: Color(0xFFFAFAFA),
  surface: Color(0xFFFFFFFF),
  surfaceAlt: Color(0xFFF4F4F5),
  line: Color(0xFFE4E4E7),
  lineStrong: Color(0xFFD4D4D8),
  primary: Color(0xFF4F46E5),
  accent: Color(0xFF4F46E5),
  accentSoft: Color(0xFFEEF2FF),
  success: Color(0xFF059669),
  warning: Color(0xFFD97706),
  danger: Color(0xFFDC2626),
  muted: Color(0xFF52525B),
  mutedSoft: Color(0xFFA1A1AA),
  text: Color(0xFF0A0A0A),
);

extension PaletteX on BuildContext {
  /// Palette matching the active theme brightness. Repaints automatically when
  /// [ThemeController] flips the app's themeMode.
  Palette get colors =>
      Theme.of(this).brightness == Brightness.dark ? darkPalette : lightPalette;
}
