import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/elite_card.dart';
import '../../profile/state/profile_controller.dart';
import '../state/fitness_controller.dart';

class WeightScreen extends StatelessWidget {
  const WeightScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fc = context.watch<FitnessController>();
    final profile = context.watch<ProfileController>().profile;
    final weights = fc.weights;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weight'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _logWeightDialog(context, fc, profile?.weightKg),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          EliteCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Latest',
                          style: TextStyle(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(
                        weights.isEmpty
                            ? (profile?.weightKg != null
                                ? '${profile!.weightKg.toStringAsFixed(1)} kg'
                                : '-- kg')
                            : '${weights.last.weightKg.toStringAsFixed(1)} kg',
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                if (profile != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Goal',
                          style: TextStyle(color: AppColors.muted)),
                      const SizedBox(height: 6),
                      Text(
                        '${profile.goalWeightKg.toStringAsFixed(1)} kg',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (weights.length < 2)
            const EliteCard(
              child: Text(
                'Log at least two weigh-ins to see a trend.',
                style: TextStyle(color: AppColors.muted),
              ),
            )
          else
            _weightChart(weights),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Log'),
          if (weights.isEmpty)
            const EliteCard(
              child: Text('No entries yet. Tap + to log a weight.',
                  style: TextStyle(color: AppColors.muted)),
            )
          else
            ...weights.reversed.map((w) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: EliteCard(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.monitor_weight,
                          color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(DateX.monthDay(w.date),
                            style: const TextStyle(color: AppColors.text)),
                      ),
                      Text('${w.weightKg.toStringAsFixed(1)} kg',
                          style: const TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.w700,
                          )),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.muted),
                        onPressed: () => fc.deleteWeight(w.id),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _weightChart(List weights) {
    final spots = <FlSpot>[];
    for (var i = 0; i < weights.length; i++) {
      spots.add(FlSpot(i.toDouble(), (weights[i].weightKg as double)));
    }
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 1;
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 1;
    return EliteCard(
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            minY: minY,
            maxY: maxY,
            titlesData: const FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 40),
              ),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (v) => const FlLine(
                color: AppColors.surfaceAlt,
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: AppColors.primary,
                barWidth: 3,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.primary.withValues(alpha: 0.08),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _logWeightDialog(
      BuildContext context, FitnessController fc, double? hint) {
    final ctrl = TextEditingController(
      text: hint?.toStringAsFixed(1) ?? '',
    );
    showDialog(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Log weight'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(suffixText: 'kg'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text);
              if (v == null || v <= 0) return;
              fc.logWeight(v);
              Navigator.pop(dctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
