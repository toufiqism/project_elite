import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/elite_card.dart';
import '../models/character_stats.dart';
import '../state/ayanokoji_controller.dart';

class CharacterStatsScreen extends StatelessWidget {
  const CharacterStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<AyanokojiController>();
    final stats = ctrl.allStats;

    return Scaffold(
      appBar: AppBar(title: const Text('Character stats')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
        children: [
          EliteCard(
            child: SizedBox(
              height: 280,
              child: CustomPaint(
                painter: _RadarPainter(
                  stats,
                  gridColor: context.colors.surfaceAlt,
                  accentColor: context.colors.accent,
                  mutedColor: context.colors.muted,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Detail'),
          ...stats.map((sv) => _statRow(context, sv)),
          const SizedBox(height: 24),
          _socialCard(context, ctrl),
        ],
      ),
    );
  }

  Widget _statRow(BuildContext context, StatValue sv) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: EliteCard(
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: context.colors.accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: context.colors.accent),
              ),
              alignment: Alignment.center,
              child: Text('${sv.level}',
                  style: TextStyle(
                    color: context.colors.accent,
                    fontWeight: FontWeight.w800,
                  )),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sv.stat.label,
                      style: TextStyle(
                        color: context.colors.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      )),
                  Text(sv.stat.sourceHint,
                      style: TextStyle(
                          color: context.colors.muted, fontSize: 11)),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: sv.progress,
                      minHeight: 5,
                      backgroundColor: context.colors.surfaceAlt,
                      color: context.colors.accent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text('${sv.xp}',
                style: TextStyle(
                    color: context.colors.text, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _socialCard(BuildContext context, AyanokojiController ctrl) {
    final today = ctrl.socialRatingForToday();
    return EliteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Social confidence — today',
              style: TextStyle(
                  color: context.colors.muted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            today == null
                ? 'Not rated yet — slide to log it.'
                : 'Rated $today/5',
            style: TextStyle(color: context.colors.text),
          ),
          Slider(
            value: (today ?? 3).toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: '${today ?? 3}',
            activeColor: context.colors.accent,
            onChanged: (v) => ctrl.setSocialRatingToday(v.round()),
          ),
        ],
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final List<StatValue> stats;
  final Color gridColor;
  final Color accentColor;
  final Color mutedColor;
  _RadarPainter(
    this.stats, {
    required this.gridColor,
    required this.accentColor,
    required this.mutedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 36;

    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final axisPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final fillPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final n = stats.length;
    for (var ring = 1; ring <= 4; ring++) {
      final r = radius * ring / 4;
      final path = Path();
      for (var i = 0; i < n; i++) {
        final a = -math.pi / 2 + (i * 2 * math.pi / n);
        final p = center + Offset(math.cos(a) * r, math.sin(a) * r);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    for (var i = 0; i < n; i++) {
      final a = -math.pi / 2 + (i * 2 * math.pi / n);
      final p = center + Offset(math.cos(a) * radius, math.sin(a) * radius);
      canvas.drawLine(center, p, axisPaint);

      // Label
      final labelPos = center +
          Offset(math.cos(a) * (radius + 18), math.sin(a) * (radius + 18));
      final tp = TextPainter(
        text: TextSpan(
          text: stats[i].stat.code,
          style: TextStyle(
            color: mutedColor,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, labelPos - Offset(tp.width / 2, tp.height / 2));
    }

    // Stat polygon — normalize each stat's level by some target (e.g., 20).
    const target = 20.0;
    final dataPath = Path();
    for (var i = 0; i < n; i++) {
      final a = -math.pi / 2 + (i * 2 * math.pi / n);
      final ratio = (stats[i].level / target).clamp(0.0, 1.0);
      final r = radius * ratio;
      final p = center + Offset(math.cos(a) * r, math.sin(a) * r);
      if (i == 0) {
        dataPath.moveTo(p.dx, p.dy);
      } else {
        dataPath.lineTo(p.dx, p.dy);
      }
    }
    dataPath.close();
    canvas.drawPath(dataPath, fillPaint);
    canvas.drawPath(dataPath, strokePaint);

    // Vertex markers
    for (var i = 0; i < n; i++) {
      final a = -math.pi / 2 + (i * 2 * math.pi / n);
      final ratio = (stats[i].level / target).clamp(0.0, 1.0);
      final r = radius * ratio;
      final p = center + Offset(math.cos(a) * r, math.sin(a) * r);
      canvas.drawCircle(
        p,
        4,
        Paint()..color = accentColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) =>
      !_listEq(old.stats, stats) ||
      old.accentColor != accentColor ||
      old.gridColor != gridColor ||
      old.mutedColor != mutedColor;

  bool _listEq(List<StatValue> a, List<StatValue> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].xp != b[i].xp) return false;
    }
    return true;
  }
}
