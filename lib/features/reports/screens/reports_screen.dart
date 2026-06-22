import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/atoms.dart';
import '../../../shared/widgets/elite_card.dart';
import '../../fitness/state/fitness_controller.dart';
import '../../habits/state/habit_controller.dart';
import '../../prayer/state/prayer_controller.dart';
import '../../profile/state/profile_controller.dart';
import '../../study/state/study_controller.dart';
import '../data/reports_service.dart';
import '../models/period_report.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _range = 0; // 0 = week, 1 = month

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final profile = context.watch<ProfileController>().profile;
    final study = context.watch<StudyController>();
    final habits = context.watch<HabitController>();
    final prayer = context.watch<PrayerController>();
    final fitness = context.watch<FitnessController>();

    final r = _range == 0
        ? ReportsService.buildWeek(
            profile: profile,
            study: study,
            habits: habits,
            prayer: prayer,
            fitness: fitness,
          )
        : ReportsService.buildMonth(
            profile: profile,
            study: study,
            habits: habits,
            prayer: prayer,
            fitness: fitness,
          );
    final unit = _range == 0 ? 'this week' : 'this month';

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.only(
            bottom: 32 + MediaQuery.of(context).padding.bottom),
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Self-improvement score · ${r.selfImprovementScore}',
                    style: TextStyle(fontSize: 12, color: c.muted)),
                const SizedBox(height: 2),
                Text('Stats',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.6,
                      color: c.text,
                    )),
              ],
            ),
          ),

          // Range segmented control
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: c.surfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _segment('Week', 0),
                    _segment('Month', 1),
                  ],
                ),
              ),
            ),
          ),

          // Hero score
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: EliteCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SELF-IMPROVEMENT SCORE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: c.muted,
                        letterSpacing: 0.88,
                      )),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('${r.selfImprovementScore}',
                          style: monoStyle(fontSize: 44, color: c.text)),
                      const SizedBox(width: 6),
                      Text('/ 100',
                          style: TextStyle(fontSize: 16, color: c.muted)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Pill(
                    tone: PillTone.accent,
                    child: Text('Productivity ${r.productivityScore}'),
                  ),
                  const SizedBox(height: 18),
                  _bar(context, 'Study days at goal', r.studyConsistency),
                  const SizedBox(height: 10),
                  _bar(context, 'Workout days', r.workoutConsistency),
                  const SizedBox(height: 10),
                  _bar(context, 'Prayer (5/5 days)', r.prayerConsistency),
                  const SizedBox(height: 10),
                  _bar(context, 'Habit success', r.habitSuccessRate),
                ],
              ),
            ),
          ),

          // Breakdown grid
          EliteSection(
            title: 'Breakdown',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _breakdown(
                          context,
                          Icons.menu_book_outlined,
                          'Study',
                          (r.studyMinutes / 60).toStringAsFixed(1),
                          'hours $unit',
                          '${r.studyDaysHitGoal}/${r.totalDaysInPeriod}',
                          r.studyConsistency),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _breakdown(
                          context,
                          Icons.fitness_center,
                          'Workouts',
                          '${r.workoutDaysActive}/${r.totalDaysInPeriod}',
                          'active days',
                          '${(r.workoutConsistency * 100).round()}%',
                          r.workoutConsistency),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _breakdown(
                          context,
                          Icons.mosque_outlined,
                          'Prayer',
                          '${r.prayerCompletions}',
                          'completed',
                          '${(r.prayerConsistency * 100).round()}%',
                          r.prayerConsistency),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _breakdown(
                          context,
                          Icons.check_circle_outline,
                          'Habits',
                          '${(r.habitSuccessRate * 100).round()}%',
                          'success',
                          '${r.habitCompletions}/${r.habitOpportunities}',
                          r.habitSuccessRate),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Body weight
          if (r.weightChangeKg != null)
            EliteSection(
              title: 'Body',
              child: _weightCard(context, r),
            ),

          // Habit breakdown
          if (r.habitBreakdown.isNotEmpty)
            EliteSection(
              title: 'Habit breakdown',
              child: _habitBreakdownCard(context, r),
            ),

          // Share
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: EliteButton(
              label: 'Share ${_range == 0 ? 'weekly' : 'monthly'} summary',
              variant: EliteButtonVariant.secondary,
              full: true,
              leadingIcon: Icons.ios_share,
              onPressed: () => _share(r),
            ),
          ),
        ],
      ),
    );
  }

  Widget _segment(String label, int value) {
    final c = context.colors;
    final on = _range == value;
    return GestureDetector(
      onTap: () => setState(() => _range = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: on ? c.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: on ? c.text : c.muted,
            )),
      ),
    );
  }

  Widget _bar(BuildContext context, String label, double pct) {
    final c = context.colors;
    return Row(
      children: [
        SizedBox(
          width: 130,
          child:
              Text(label, style: TextStyle(color: c.muted, fontSize: 12)),
        ),
        Expanded(child: EliteProgressBar(value: pct * 100, height: 6)),
        const SizedBox(width: 10),
        SizedBox(
          width: 40,
          child: Text('${(pct * 100).round()}%',
              textAlign: TextAlign.end,
              style: monoStyle(fontSize: 12, color: c.text)),
        ),
      ],
    );
  }

  Widget _breakdown(BuildContext context, IconData icon, String label,
      String value, String unit, String trend, double pct) {
    final c = context.colors;
    return EliteCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                    color: c.surfaceAlt,
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 16, color: c.muted),
              ),
              Text(trend,
                  style: monoStyle(
                      fontSize: 11,
                      color: c.accent,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 12),
          Text(label, style: TextStyle(fontSize: 11.5, color: c.muted)),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: monoStyle(fontSize: 20, color: c.text)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(unit,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: c.muted)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          EliteProgressBar(value: pct * 100, height: 3, tone: BarTone.text),
        ],
      ),
    );
  }

  Widget _weightCard(BuildContext context, PeriodReport r) {
    final c = context.colors;
    final change = r.weightChangeKg ?? 0;
    final positive = change >= 0;
    return EliteCard(
      child: Row(
        children: [
          Icon(positive ? Icons.trending_up : Icons.trending_down,
              color: positive ? c.warning : c.success),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Weight change',
                    style:
                        TextStyle(color: c.text, fontWeight: FontWeight.w600)),
                Text(
                  '${r.weightStartKg!.toStringAsFixed(1)} → ${r.weightEndKg!.toStringAsFixed(1)} kg',
                  style: TextStyle(color: c.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Text('${positive ? '+' : ''}${change.toStringAsFixed(1)} kg',
              style: monoStyle(
                  fontSize: 18,
                  color: positive ? c.warning : c.success,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _habitBreakdownCard(BuildContext context, PeriodReport r) {
    final c = context.colors;
    return EliteCard(
      child: Column(
        children: [
          for (var i = 0; i < r.habitBreakdown.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(r.habitBreakdown[i].habitName,
                      style: TextStyle(color: c.text, fontSize: 13)),
                ),
                SizedBox(
                  width: 100,
                  child: EliteProgressBar(
                      value: r.habitBreakdown[i].rate * 100,
                      height: 5,
                      tone: BarTone.success),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 52,
                  child: Text(
                    '${r.habitBreakdown[i].completions}/${r.habitBreakdown[i].opportunities}',
                    textAlign: TextAlign.end,
                    style: monoStyle(fontSize: 11, color: c.muted),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _share(PeriodReport r) {
    final text = ReportsService.formatShareText(r);
    Share.share(text, subject: r.label);
  }
}
