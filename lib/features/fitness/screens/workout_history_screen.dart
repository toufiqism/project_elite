import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/elite_card.dart';
import '../state/fitness_controller.dart';

class WorkoutHistoryScreen extends StatelessWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sessions = context.watch<FitnessController>().sessions;
    return Scaffold(
      appBar: AppBar(title: const Text('Workout history')),
      body: sessions.isEmpty
          ? const Center(
              child: Text('No workouts logged yet.',
                  style: TextStyle(color: AppColors.muted)),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: sessions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final s = sessions[i];
                return EliteCard(
                  child: Row(
                    children: [
                      const Icon(Icons.fitness_center,
                          color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${s.exercises.length} exercises',
                              style: const TextStyle(
                                color: AppColors.text,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${DateX.monthDay(s.startedAt)} · ${DateX.prettyTime(s.startedAt)}',
                              style: const TextStyle(
                                  color: AppColors.muted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(formatDuration(s.totalDuration),
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w700,
                              )),
                          Text('~${s.totalKcal.round()} kcal',
                              style: const TextStyle(
                                  color: AppColors.muted, fontSize: 12)),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.muted),
                        onPressed: () => context
                            .read<FitnessController>()
                            .deleteSession(s.id),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
