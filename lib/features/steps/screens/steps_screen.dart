import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/elite_card.dart';
import '../../profile/state/profile_controller.dart';
import '../state/step_controller.dart';

class StepsScreen extends StatelessWidget {
  const StepsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final steps = context.watch<StepController>();
    final goal = context.watch<ProfileController>().profile?.stepGoalPerDay ??
        10000;

    return Scaffold(
      appBar: AppBar(title: const Text('Steps')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
        children: [
          if (!steps.available)
            _enableCard(context, steps)
          else ...[
            _todayCard(context, steps.todaySteps, goal),
            const SizedBox(height: 20),
            const SectionHeader(title: 'Last 7 days'),
            _weekChart(context, steps.last7DaySteps, goal),
            const SizedBox(height: 20),
            _allTimeCard(context, steps.allTimeSteps),
          ],
        ],
      ),
    );
  }

  Widget _enableCard(BuildContext context, StepController steps) {
    return EliteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.directions_walk,
              color: context.colors.primary, size: 40),
          const SizedBox(height: 12),
          Text('Step counting is off',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.colors.text,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              )),
          const SizedBox(height: 8),
          Text(
            'Grant activity-recognition access so Project Elite can count your '
            'daily steps from your device sensor. Steps then count toward your '
            'daily score and strength XP. If your device has no step sensor, '
            'this stays off.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.colors.muted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () async {
              final ok = await steps.requestAndStart();
              if (!ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Permission denied or no step sensor available.'),
                  ),
                );
              }
            },
            icon: const Icon(Icons.bolt, size: 18),
            label: const Text('Enable step counting'),
          ),
        ],
      ),
    );
  }

  Widget _todayCard(BuildContext context, int today, int goal) {
    final pct = (today / goal).clamp(0.0, 1.0).toDouble();
    return EliteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Today',
              style: TextStyle(
                  color: context.colors.muted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$today',
                  style: TextStyle(
                    color: context.colors.text,
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  )),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('/ $goal steps',
                    style: TextStyle(color: context.colors.muted)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: context.colors.surfaceAlt,
              color: today >= goal
                  ? context.colors.success
                  : context.colors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            today >= goal
                ? 'Goal reached. Strong.'
                : '${goal - today} steps to your goal',
            style: TextStyle(color: context.colors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _weekChart(BuildContext context, List<int> week, int goal) {
    final maxVal = week.fold<int>(goal, (a, b) => b > a ? b : a).toDouble();
    final days = DateX.last7Days();
    return EliteCard(
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            maxY: maxVal * 1.15,
            alignment: BarChartAlignment.spaceAround,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (v) => FlLine(
                color: context.colors.surfaceAlt,
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= days.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(DateX.shortDay(days[i]),
                          style: TextStyle(
                              color: context.colors.muted, fontSize: 11)),
                    );
                  },
                ),
              ),
            ),
            barGroups: [
              for (int i = 0; i < week.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: week[i].toDouble(),
                      width: 16,
                      borderRadius: BorderRadius.circular(4),
                      color: week[i] >= goal
                          ? context.colors.success
                          : context.colors.primary,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _allTimeCard(BuildContext context, int allTime) {
    return EliteCard(
      child: Row(
        children: [
          Icon(Icons.timeline, color: context.colors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text('All-time steps',
                style: TextStyle(color: context.colors.text)),
          ),
          Text('$allTime',
              style: TextStyle(
                color: context.colors.text,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              )),
        ],
      ),
    );
  }
}
