import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/elite_card.dart';
import '../../fitness/state/fitness_controller.dart';
import '../../habits/state/habit_controller.dart';
import '../../prayer/state/prayer_controller.dart';
import '../../profile/state/profile_controller.dart';
import '../../study/state/study_controller.dart';
import '../data/reports_service.dart';
import '../models/period_report.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>().profile;
    final study = context.watch<StudyController>();
    final habits = context.watch<HabitController>();
    final prayer = context.watch<PrayerController>();
    final fitness = context.watch<FitnessController>();

    final week = ReportsService.buildWeek(
      profile: profile,
      study: study,
      habits: habits,
      prayer: prayer,
      fitness: fitness,
    );
    final month = ReportsService.buildMonth(
      profile: profile,
      study: study,
      habits: habits,
      prayer: prayer,
      fitness: fitness,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
        children: [
          _scoreCard(month),
          const SizedBox(height: 24),
          const SectionHeader(title: 'This week'),
          ..._weeklyBody(week),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.ios_share),
            label: const Text('Share weekly summary'),
            onPressed: () => _share(week),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'This month'),
          ..._monthlyBody(month),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.ios_share),
            label: const Text('Share monthly summary'),
            onPressed: () => _share(month),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _share(PeriodReport r) {
    final text = ReportsService.formatShareText(r);
    Share.share(text, subject: r.label);
  }

  Widget _scoreCard(PeriodReport month) {
    return EliteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('This month',
              style: TextStyle(
                  color: AppColors.muted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _scoreTile(
                      'Productivity', month.productivityScore, AppColors.primary)),
              const SizedBox(width: 10),
              Expanded(
                child: _scoreTile('Self-improvement',
                    month.selfImprovementScore, AppColors.accent),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('${month.xpInPeriod} XP earned',
              style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _scoreTile(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text('$value / 100',
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              )),
        ],
      ),
    );
  }

  List<Widget> _weeklyBody(PeriodReport r) {
    return [
      _consistencyCard(r),
      const SizedBox(height: 12),
      _summaryGrid(r),
      const SizedBox(height: 12),
      if (r.habitBreakdown.isNotEmpty) _habitBreakdownCard(r),
    ];
  }

  List<Widget> _monthlyBody(PeriodReport r) {
    return [
      _consistencyCard(r),
      const SizedBox(height: 12),
      _summaryGrid(r),
      const SizedBox(height: 12),
      if (r.weightChangeKg != null) _weightCard(r),
      if (r.habitBreakdown.isNotEmpty) ...[
        const SizedBox(height: 12),
        _habitBreakdownCard(r),
      ],
    ];
  }

  Widget _consistencyCard(PeriodReport r) {
    return EliteCard(
      child: Column(
        children: [
          _bar('Study days at goal', r.studyConsistency, AppColors.primary),
          const SizedBox(height: 10),
          _bar('Workout days', r.workoutConsistency, AppColors.warning),
          const SizedBox(height: 10),
          _bar('Prayer (5/5 days)', r.prayerConsistency, AppColors.accent),
          const SizedBox(height: 10),
          _bar('Habit success', r.habitSuccessRate, AppColors.success),
        ],
      ),
    );
  }

  Widget _bar(String label, double pct, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(label,
              style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: AppColors.surfaceAlt,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 44,
          child: Text('${(pct * 100).round()}%',
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              )),
        ),
      ],
    );
  }

  Widget _summaryGrid(PeriodReport r) {
    return EliteCard(
      child: Column(
        children: [
          _row('Total study', '${(r.studyMinutes / 60).toStringAsFixed(1)} h',
              sub: '${r.studySessions} sessions · ${r.studyDaysHitGoal}/${r.totalDaysInPeriod} on goal'),
          const Divider(color: AppColors.surfaceAlt, height: 18),
          _row('Workout', '${r.workoutMinutes} min',
              sub: '${r.workoutSessions} sessions · ${r.workoutDaysActive}/${r.totalDaysInPeriod} days'),
          const Divider(color: AppColors.surfaceAlt, height: 18),
          _row('Prayers completed', '${r.prayerCompletions}',
              sub: '${r.prayerPerfectDays}/${r.totalDaysInPeriod} perfect days'),
          const Divider(color: AppColors.surfaceAlt, height: 18),
          _row(
            'Habits',
            '${r.habitCompletions}/${r.habitOpportunities}',
            sub: '${(r.habitSuccessRate * 100).round()}% success',
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {String? sub}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppColors.text, fontWeight: FontWeight.w600)),
              if (sub != null)
                Text(sub,
                    style: const TextStyle(color: AppColors.muted, fontSize: 11)),
            ],
          ),
        ),
        Text(value,
            style: const TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            )),
      ],
    );
  }

  Widget _weightCard(PeriodReport r) {
    final change = r.weightChangeKg ?? 0;
    final positive = change >= 0;
    final sign = positive ? '+' : '';
    return EliteCard(
      child: Row(
        children: [
          Icon(
            positive ? Icons.trending_up : Icons.trending_down,
            color: positive ? AppColors.warning : AppColors.success,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Weight change',
                    style: TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w600)),
                Text(
                  '${r.weightStartKg!.toStringAsFixed(1)} → ${r.weightEndKg!.toStringAsFixed(1)} kg',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Text('$sign${change.toStringAsFixed(1)} kg',
              style: TextStyle(
                color: positive ? AppColors.warning : AppColors.success,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              )),
        ],
      ),
    );
  }

  Widget _habitBreakdownCard(PeriodReport r) {
    return EliteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Habit breakdown',
              style: TextStyle(
                  color: AppColors.muted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...r.habitBreakdown.map((h) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(h.habitName,
                        style: const TextStyle(color: AppColors.text)),
                  ),
                  SizedBox(
                    width: 100,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: h.rate,
                        minHeight: 5,
                        backgroundColor: AppColors.surfaceAlt,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 56,
                    child: Text(
                      '${h.completions}/${h.opportunities}',
                      textAlign: TextAlign.end,
                      style:
                          const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
