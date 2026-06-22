import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/atoms.dart';
import '../../gamification/screens/achievements_screen.dart';
import '../../gamification/state/gamification_controller.dart';
import '../models/character_stats.dart';
import '../state/ayanokoji_controller.dart';
import 'character_stats_screen.dart';
import 'focus_timer_screen.dart';
import 'mini_games_screen.dart';

// The Elite screen is always rendered dark, matching the design's character
// sheet. These tokens are used in place of context.colors here.
const _bg = Color(0xFF0A0A0A);
const _text = Color(0xFFFAFAFA);
const _muted = Color(0xFFA1A1AA);
final _hair = Colors.white.withValues(alpha: 0.06);
final _hairStrong = Colors.white.withValues(alpha: 0.1);
final _fill = Colors.white.withValues(alpha: 0.03);

class AyanokojiHomeScreen extends StatelessWidget {
  const AyanokojiHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.accent;
    final ctrl = context.watch<AyanokojiController>();
    final gam = context.watch<GamificationController>();
    final stats = ctrl.allStats;

    double radarValue(StatValue sv) =>
        ((sv.level + sv.progress) / 12 * 100).clamp(4.0, 100.0);

    return Scaffold(
      backgroundColor: _bg,
      body: ListView(
        padding: EdgeInsets.only(
            bottom: 32 + MediaQuery.of(context).padding.bottom),
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 54, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _circleBtn(Icons.chevron_left, () => Navigator.pop(context)),
                Text('ELITE MODE',
                    style: TextStyle(
                      fontSize: 12,
                      color: _muted,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w600,
                    )),
                _circleBtn(
                  ctrl.disciplineMode ? Icons.shield : Icons.shield_outlined,
                  () => ctrl.setDisciplineMode(!ctrl.disciplineMode),
                  active: ctrl.disciplineMode,
                  accent: accent,
                ),
              ],
            ),
          ),

          // Level hero
          Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.white.withValues(alpha: 0.06),
                        blurRadius: 0,
                        spreadRadius: 4),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text('◆',
                    style: TextStyle(
                        fontSize: 32,
                        color: Colors.white,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 14),
              Text('TITLE',
                  style: TextStyle(
                      fontSize: 11, color: _muted, letterSpacing: 1.1)),
              const SizedBox(height: 2),
              Text(gam.title,
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                      color: _text)),
              const SizedBox(height: 2),
              Text('Level ${gam.level.level} · ${gam.totalXp} XP',
                  style: const TextStyle(fontSize: 13, color: _muted)),
              Padding(
                padding: const EdgeInsets.fromLTRB(40, 16, 40, 0),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: Stack(
                        children: [
                          Container(height: 6, color: _hairStrong),
                          FractionallySizedBox(
                            widthFactor: gam.level.progress,
                            child: Container(height: 6, color: accent),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${gam.totalXp} XP',
                            style:
                                const TextStyle(fontSize: 11, color: _muted)),
                        Text('${gam.level.xpToNextLevel} to level ${gam.level.level + 1}',
                            style:
                                const TextStyle(fontSize: 11, color: _muted)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Radar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
            child: Center(
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CharacterStatsScreen()),
                ),
                child: CustomPaint(
                  size: const Size(240, 240),
                  painter: _RadarPainter(
                    values: [for (final s in stats) radarValue(s)],
                    labels: [for (final s in stats) s.stat.code],
                    accent: accent,
                  ),
                ),
              ),
            ),
          ),

          // Stat list
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              children: [
                for (final s in stats)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: _hair)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(s.stat.label,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _text)),
                        ),
                        SizedBox(
                          width: 120,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: Stack(
                              children: [
                                Container(height: 4, color: _hairStrong),
                                FractionallySizedBox(
                                  widthFactor: radarValue(s) / 100,
                                  child: Container(height: 4, color: accent),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 36,
                          child: Text('${radarValue(s).round()}',
                              textAlign: TextAlign.right,
                              style: monoStyle(fontSize: 14, color: _text)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Deep work CTA
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _fill,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _hairStrong),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DEEP WORK TIMER',
                            style: TextStyle(
                                fontSize: 11,
                                color: _muted,
                                letterSpacing: 0.66,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        const Text('Block distractions · 50 min',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: _text)),
                        const SizedBox(height: 4),
                        Text('${ctrl.focusMinutesToday}m focused today',
                            style:
                                const TextStyle(fontSize: 12, color: _muted)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const FocusTimerScreen()),
                    ),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration:
                          BoxDecoration(color: accent, shape: BoxShape.circle),
                      child: const Icon(Icons.play_arrow,
                          color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Mental development + Achievements
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              children: [
                _navTile(
                  context,
                  Icons.psychology_outlined,
                  'Mini-games',
                  'Digit Span · Reaction · Stroop',
                  accent,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MiniGamesScreen()),
                  ),
                ),
                const SizedBox(height: 8),
                _navTile(
                  context,
                  Icons.emoji_events_outlined,
                  'Achievements',
                  '${gam.unlocked.length} unlocked',
                  accent,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AchievementsScreen()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap,
      {bool active = false, Color? accent}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: active ? (accent ?? _text) : _fill,
          shape: BoxShape.circle,
          border: Border.all(color: _hairStrong),
        ),
        child: Icon(icon, size: 18, color: active ? Colors.white : _text),
      ),
    );
  }

  Widget _navTile(BuildContext context, IconData icon, String title,
      String sub, Color accent, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _fill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _hairStrong),
        ),
        child: Row(
          children: [
            Icon(icon, color: accent, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _text)),
                  Text(sub,
                      style: const TextStyle(fontSize: 12, color: _muted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _muted),
          ],
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final List<double> values; // 0..100
  final List<String> labels;
  final Color accent;

  _RadarPainter(
      {required this.values, required this.labels, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const radius = 90.0;
    final n = values.length;

    Offset point(int i, double v) {
      final a = (math.pi * 2 * i) / n - math.pi / 2;
      final r = (v / 100) * radius;
      return Offset(cx + math.cos(a) * r, cy + math.sin(a) * r);
    }

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.08);
    for (final p in [25.0, 50.0, 75.0, 100.0]) {
      final path = Path();
      for (var i = 0; i < n; i++) {
        final o = point(i, p);
        if (i == 0) {
          path.moveTo(o.dx, o.dy);
        } else {
          path.lineTo(o.dx, o.dy);
        }
      }
      path.close();
      canvas.drawPath(path, ringPaint);
    }

    final spokePaint = Paint()
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.06);
    for (var i = 0; i < n; i++) {
      final o = point(i, 100);
      canvas.drawLine(Offset(cx, cy), o, spokePaint);
    }

    final dataPath = Path();
    for (var i = 0; i < n; i++) {
      final o = point(i, values[i]);
      if (i == 0) {
        dataPath.moveTo(o.dx, o.dy);
      } else {
        dataPath.lineTo(o.dx, o.dy);
      }
    }
    dataPath.close();
    canvas.drawPath(
        dataPath,
        Paint()
          ..style = PaintingStyle.fill
          ..color = accent.withValues(alpha: 0.22));
    canvas.drawPath(
        dataPath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = accent);
    final dot = Paint()..color = accent;
    for (var i = 0; i < n; i++) {
      canvas.drawCircle(point(i, values[i]), 3, dot);
    }

    for (var i = 0; i < n; i++) {
      final a = (math.pi * 2 * i) / n - math.pi / 2;
      const r = radius + 22;
      final lx = cx + math.cos(a) * r;
      final ly = cy + math.sin(a) * r;
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(
            color: _muted,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(lx - tp.width / 2, ly - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.values != values || old.accent != accent;
}
