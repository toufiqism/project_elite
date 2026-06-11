import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/elite_card.dart';
import '../../profile/state/profile_controller.dart';
import '../state/study_controller.dart';
import 'study_history_screen.dart';
import 'study_timer_screen.dart';

class StudyHomeScreen extends StatelessWidget {
  const StudyHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final study = context.watch<StudyController>();
    final profile = context.watch<ProfileController>().profile;

    final today = study.totalToday();
    final goalHours = profile?.studyGoalHoursPerDay ?? 5;
    final progress =
        (today.inSeconds / (goalHours * 3600)).clamp(0.0, 1.0).toDouble();

    final subjects = profile?.caSubjects ?? const <String>[];
    final weekTotals = study.last7DaysTotals();
    final maxHours = weekTotals.values
        .map((d) => d.inMinutes / 60.0)
        .fold<double>(0, (a, b) => b > a ? b : a)
        .clamp(1.0, double.infinity);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study'),
        actions: [
          IconButton(
            tooltip: 'History',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StudyHistoryScreen()),
            ),
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
        children: [
          EliteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Today',
                        style: TextStyle(
                          color: context.colors.muted,
                          fontWeight: FontWeight.w600,
                        )),
                    const Spacer(),
                    Text('Goal ${goalHours.toStringAsFixed(1)} h',
                        style: TextStyle(color: context.colors.muted)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(formatDuration(today),
                    style: TextStyle(
                      color: context.colors.text,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                    )),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: context.colors.surfaceAlt,
                    color: progress >= 1 ? context.colors.success : context.colors.accent,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _miniStat(context, 'Week',
                          '${(study.totalThisWeek().inMinutes / 60).toStringAsFixed(1)}h'),
                    ),
                    Expanded(
                      child:
                          _miniStat(context, 'Streak', '${study.currentStreak()} d'),
                    ),
                    Expanded(
                      child: _miniStat(context, 'Sessions',
                          '${study.sessions.where((s) => DateX.dayKey(s.startedAt) == DateX.todayKey()).length}'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Start a focus session'),
          if (subjects.isEmpty)
            EliteCard(
              child: Text(
                'Add subjects in your profile to start tracking.',
                style: TextStyle(color: context.colors.muted),
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: subjects.map((s) {
                return SizedBox(
                  width: (MediaQuery.of(context).size.width - 50) / 2,
                  child: EliteCard(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudyTimerScreen(subject: s),
                      ),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Icon(Icons.play_circle,
                            color: context.colors.primary, size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            s,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: context.colors.text,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Last 7 days'),
          EliteCard(
            child: SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxHours + 0.5,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, m) {
                          final days = DateX.last7Days();
                          if (v.toInt() < 0 || v.toInt() >= days.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              DateX.shortDay(days[v.toInt()]).substring(0, 1),
                              style: TextStyle(
                                  color: context.colors.muted, fontSize: 11),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(7, (i) {
                    final day = DateX.last7Days()[i];
                    final hrs = (weekTotals[DateX.dayKey(day)] ?? Duration.zero)
                            .inMinutes /
                        60.0;
                    return BarChartGroupData(x: i, barRods: [
                      BarChartRodData(
                        toY: hrs,
                        width: 18,
                        borderRadius: BorderRadius.circular(6),
                        color: context.colors.primary,
                      ),
                    ]);
                  }),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'This week by subject'),
          _subjectBreakdown(context, study.subjectTotalsThisWeek()),
        ],
      ),
    );
  }

  Widget _miniStat(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: TextStyle(
              color: context.colors.text,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            )),
        Text(label,
            style: TextStyle(color: context.colors.muted, fontSize: 12)),
      ],
    );
  }

  Widget _subjectBreakdown(BuildContext context, Map<String, Duration> totals) {
    if (totals.isEmpty) {
      return EliteCard(
        child: Text('No sessions this week yet.',
            style: TextStyle(color: context.colors.muted)),
      );
    }
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxMin = sorted.first.value.inMinutes.clamp(1, 1 << 30);
    return EliteCard(
      child: Column(
        children: sorted.map((e) {
          final pct = e.value.inMinutes / maxMin;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(e.key,
                          style: TextStyle(color: context.colors.text)),
                    ),
                    Text(formatDuration(e.value),
                        style: TextStyle(color: context.colors.muted)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    backgroundColor: context.colors.surfaceAlt,
                    color: context.colors.accent,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
