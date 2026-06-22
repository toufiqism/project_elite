import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Flutter port of the "Project Elite" design prototype atoms (atoms.jsx).
/// Every atom reads color tokens via `context.colors` so it tracks light/dark.
///
/// `EliteCard`, `SectionHeader`, `StatTile` live in elite_card.dart; this file
/// adds the remaining shared primitives: [Pill], [EliteProgressBar],
/// [EliteRing], [EliteSection], [EliteButton], [EliteIconButton].

/// Tabular monospace numerals — used for big numbers (rings, timers, stats) to
/// match the design's Geist Mono treatment. Falls back to the platform mono
/// font since Geist Mono isn't bundled.
const List<String> _monoFallback = ['Geist Mono', 'monospace'];

TextStyle monoStyle({
  required double fontSize,
  FontWeight fontWeight = FontWeight.w500,
  Color? color,
  double letterSpacing = -0.02,
}) =>
    TextStyle(
      fontFamilyFallback: _monoFallback,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

enum PillTone { neutral, accent, success, warn, danger, ghost }

class Pill extends StatelessWidget {
  final Widget child;
  final PillTone tone;
  final EdgeInsetsGeometry padding;

  const Pill({
    super.key,
    required this.child,
    this.tone = PillTone.neutral,
    this.padding = const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    late final Color bg, fg, bd;
    switch (tone) {
      case PillTone.neutral:
        bg = c.surfaceAlt;
        fg = c.muted;
        bd = c.line;
      case PillTone.accent:
        bg = c.accentSoft;
        fg = c.accent;
        bd = Colors.transparent;
      case PillTone.success:
        bg = c.success.withValues(alpha: 0.14);
        fg = c.success;
        bd = Colors.transparent;
      case PillTone.warn:
        bg = c.warning.withValues(alpha: 0.14);
        fg = c.warning;
        bd = Colors.transparent;
      case PillTone.danger:
        bg = c.danger.withValues(alpha: 0.14);
        fg = c.danger;
        bd = Colors.transparent;
      case PillTone.ghost:
        bg = Colors.transparent;
        fg = c.muted;
        bd = c.line;
    }
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: bd, width: 1),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        child: IconTheme.merge(
          data: IconThemeData(color: fg, size: 13),
          child: child,
        ),
      ),
    );
  }
}

enum BarTone { accent, success, warn, text }

class EliteProgressBar extends StatelessWidget {
  final double value;
  final double max;
  final BarTone tone;
  final double height;

  const EliteProgressBar({
    super.key,
    required this.value,
    this.max = 100,
    this.tone = BarTone.accent,
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pct = (max <= 0 ? 0.0 : (value / max)).clamp(0.0, 1.0);
    final color = switch (tone) {
      BarTone.accent => c.accent,
      BarTone.success => c.success,
      BarTone.warn => c.warning,
      BarTone.text => c.text,
    };
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Stack(
        children: [
          Container(height: height, color: c.surfaceAlt),
          FractionallySizedBox(
            widthFactor: pct,
            child: Container(height: height, color: color),
          ),
        ],
      ),
    );
  }
}

class EliteRing extends StatelessWidget {
  final double value; // 0..100
  final double size;
  final double stroke;
  final String? label;
  final String? sublabel;
  final BarTone tone;

  const EliteRing({
    super.key,
    required this.value,
    this.size = 100,
    this.stroke = 8,
    this.label,
    this.sublabel,
    this.tone = BarTone.accent,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = switch (tone) {
      BarTone.accent => c.accent,
      BarTone.success => c.success,
      BarTone.warn => c.warning,
      BarTone.text => c.text,
    };
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _RingPainter(
              pct: (value / 100).clamp(0.0, 1.0),
              track: c.line,
              color: color,
              stroke: stroke,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (label != null)
                Text(label!, style: monoStyle(fontSize: size * 0.22, color: c.text)),
              if (sublabel != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(sublabel!,
                      style: TextStyle(fontSize: size * 0.1, color: c.muted)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double pct;
  final Color track;
  final Color color;
  final double stroke;

  _RingPainter({
    required this.pct,
    required this.track,
    required this.color,
    required this.stroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = (size.width - stroke) / 2;
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawCircle(center, r, trackPaint);
    if (pct > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        -math.pi / 2,
        2 * math.pi * pct,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.pct != pct || old.color != color || old.track != track || old.stroke != stroke;
}

/// Section with an uppercase, letter-spaced muted header and optional trailing
/// action — the design's `Section` atom (distinct from the title-cased
/// `SectionHeader` already used by older screens).
class EliteSection extends StatelessWidget {
  final String? title;
  final Widget? action;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const EliteSection({
    super.key,
    this.title,
    this.action,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 0),
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null || action != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    (title ?? '').toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: c.muted,
                      letterSpacing: 0.96,
                    ),
                  ),
                  ?action,
                ],
              ),
            ),
          child,
        ],
      ),
    );
  }
}

enum EliteButtonVariant { primary, secondary, ghost, dark }

enum EliteButtonSize { sm, md, lg }

class EliteButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final EliteButtonVariant variant;
  final EliteButtonSize size;
  final IconData? leadingIcon;
  final bool full;

  const EliteButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = EliteButtonVariant.primary,
    this.size = EliteButtonSize.md,
    this.leadingIcon,
    this.full = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    late final Color bg, fg, bd;
    switch (variant) {
      case EliteButtonVariant.primary:
        bg = c.accent;
        fg = Colors.white;
        bd = Colors.transparent;
      case EliteButtonVariant.secondary:
        bg = c.surface;
        fg = c.text;
        bd = c.line;
      case EliteButtonVariant.ghost:
        bg = Colors.transparent;
        fg = c.text;
        bd = Colors.transparent;
      case EliteButtonVariant.dark:
        bg = c.text;
        fg = c.background;
        bd = Colors.transparent;
    }
    final (h, px, fs) = switch (size) {
      EliteButtonSize.sm => (32.0, 12.0, 13.0),
      EliteButtonSize.md => (44.0, 18.0, 14.5),
      EliteButtonSize.lg => (52.0, 22.0, 15.5),
    };
    return SizedBox(
      width: full ? double.infinity : null,
      height: h,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: bd, width: 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: px),
            child: Row(
              mainAxisSize: full ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (leadingIcon != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(leadingIcon, size: fs + 2, color: fg),
                  ),
                Text(
                  label,
                  style: TextStyle(
                    color: fg,
                    fontSize: fs,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.07,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum IconButtonTone { neutral, accent, plain }

class EliteIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final IconButtonTone tone;
  final double size;

  const EliteIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tone = IconButtonTone.neutral,
    this.size = 38,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bg = switch (tone) {
      IconButtonTone.accent => c.accentSoft,
      IconButtonTone.plain => Colors.transparent,
      IconButtonTone.neutral => c.surface,
    };
    final fg = tone == IconButtonTone.accent ? c.accent : c.text;
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(size / 2),
          side: tone == IconButtonTone.plain
              ? BorderSide.none
              : BorderSide(color: c.line, width: 1),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Icon(icon, size: size * 0.5, color: fg),
        ),
      ),
    );
  }
}
