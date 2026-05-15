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
        padding: const EdgeInsets.all(20),
        children: [
          EliteCard(
            child: SizedBox(
              height: 280,
              child: CustomPaint(
                painter: _RadarPainter(stats),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Detail'),
          ...stats.map(_statRow),
          const SizedBox(height: 24),
          _socialCard(context, ctrl),
        ],
      ),
    );
  }

  Widget _statRow(StatValue sv) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: EliteCard(
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accent),
              ),
              alignment: Alignment.center,
              child: Text('${sv.level}',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w800,
                  )),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sv.stat.label,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      )),
                  Text(sv.stat.sourceHint,
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 11)),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: sv.progress,
                      minHeight: 5,
                      backgroundColor: AppColors.surfaceAlt,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text('${sv.xp}',
                style: const TextStyle(
                    color: AppColors.text, fontWeight: FontWeight.w700)),
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
          const Text('Social confidence — today',
              style: TextStyle(
                  color: AppColors.muted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            today == null
                ? 'Not rated yet — slide to log it.'
                : 'Rated $today/5',
            style: const TextStyle(color: AppColors.text),
          ),
          Slider(
            value: (today ?? 3).toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: '${today ?? 3}',
            activeColor: AppColors.accent,
            onChanged: (v) => ctrl.setSocialRatingToday(v.round()),
          ),
        ],
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final List<StatValue> stats;
  _RadarPainter(this.stats);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 36;

    final gridPaint = Paint()
      ..color = AppColors.surfaceAlt
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final axisPaint = Paint()
      ..color = AppColors.surfaceAlt
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final fillPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = AppColors.accent
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
          style: const TextStyle(
            color: AppColors.muted,
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
        Paint()..color = AppColors.accent,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) =>
      !_listEq(old.stats, stats);

  bool _listEq(List<StatValue> a, List<StatValue> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].xp != b[i].xp) return false;
    }
    return true;
  }
}
