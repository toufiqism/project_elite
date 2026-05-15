import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/elite_card.dart';
import '../../profile/state/profile_controller.dart';
import '../../settings/screens/settings_screen.dart';
import '../models/workout_plan.dart';
import '../state/fitness_controller.dart';
import 'weight_screen.dart';
import 'workout_history_screen.dart';
import 'workout_session_screen.dart';

class FitnessHomeScreen extends StatefulWidget {
  const FitnessHomeScreen({super.key});

  @override
  State<FitnessHomeScreen> createState() => _FitnessHomeScreenState();
}

class _FitnessHomeScreenState extends State<FitnessHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensurePlan());
  }

  Future<void> _ensurePlan() async {
    final profile = context.read<ProfileController>().profile;
    if (profile == null) return;
    final fc = context.read<FitnessController>();
    if (fc.todayPlan == null && fc.hasApiKey) {
      await fc.buildTodayPlan(profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fc = context.watch<FitnessController>();
    final profile = context.watch<ProfileController>().profile;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fitness'),
        actions: [
          IconButton(
            tooltip: 'Weight',
            icon: const Icon(Icons.monitor_weight_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WeightScreen()),
            ),
          ),
          IconButton(
            tooltip: 'History',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WorkoutHistoryScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (profile != null) await fc.buildTodayPlan(profile);
        },
        child: ListView(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
          children: [
            _summaryCard(fc, profile?.bmi),
            const SizedBox(height: 20),
            if (!fc.hasApiKey)
              _apiKeyPrompt(context)
            else if (fc.loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (fc.planError != null)
              _errorCard(fc.planError!, () {
                if (profile != null) fc.buildTodayPlan(profile);
              })
            else if (fc.todayPlan == null || fc.todayPlan!.exercises.isEmpty)
              _emptyPlanCard(context, fc, profile?.preferredWorkoutType)
            else
              _planCard(context, fc.todayPlan!),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(FitnessController fc, double? bmi) {
    return EliteCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Today',
                    style: TextStyle(
                        color: AppColors.muted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(
                  fc.didWorkoutToday() ? 'Workout done' : 'Plan ready',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.local_fire_department,
                        color: AppColors.warning, size: 16),
                    const SizedBox(width: 4),
                    Text('${fc.currentWorkoutStreak()}d streak',
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 12)),
                    const SizedBox(width: 12),
                    Text('${fc.sessions.length} total',
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          if (bmi != null && bmi > 0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(bmi.toStringAsFixed(1),
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    )),
                const Text('BMI',
                    style: TextStyle(color: AppColors.muted, fontSize: 12)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _apiKeyPrompt(BuildContext context) {
    return EliteCard(
      child: Column(
        children: [
          const Icon(Icons.vpn_key, color: AppColors.accent, size: 36),
          const SizedBox(height: 10),
          const Text(
            'Set up your ExerciseDB API key',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'Fitness uses the ExerciseDB API on RapidAPI to fetch the exercise catalog. '
            'Free tier ~50 requests/day. Paste your key in Settings to start.',
            style: TextStyle(color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            icon: const Icon(Icons.settings),
            label: const Text('Open settings'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorCard(String msg, VoidCallback retry) {
    return EliteCard(
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 32),
          const SizedBox(height: 8),
          Text(msg,
              style: const TextStyle(color: AppColors.muted),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: retry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _emptyPlanCard(BuildContext context, FitnessController fc, String? type) {
    return EliteCard(
      child: Column(
        children: [
          const Icon(Icons.inbox, color: AppColors.muted, size: 32),
          const SizedBox(height: 10),
          Text(
            type == 'Walking'
                ? 'No cardio exercises cached yet.\nPull down to refresh.'
                : 'No exercises matched today\'s plan.\nPull down to refresh.',
            style: const TextStyle(color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _planCard(BuildContext context, WorkoutPlan plan) {
    final est = plan.estimatedDuration();
    final kcal = plan.estimatedKcal();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EliteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(plan.label,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        )),
                  ),
                  Text('${plan.exercises.length} ex · ${formatDuration(est)} · ~${kcal.round()} kcal',
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start workout'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WorkoutSessionScreen(plan: plan),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SectionHeader(title: 'Today\'s exercises'),
        ...plan.exercises.map((pe) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: EliteCard(
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: pe.exercise.gifUrl.isNotEmpty
                        ? Image.network(
                            pe.exercise.gifUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.fitness_center,
                              color: AppColors.muted,
                            ),
                          )
                        : const Icon(Icons.fitness_center,
                            color: AppColors.muted),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _toTitle(pe.exercise.name),
                          style: const TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${pe.exercise.target} · ${pe.exercise.equipment}',
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          pe.holdSeconds != null
                              ? '${pe.sets} × ${pe.holdSeconds}s'
                              : '${pe.sets} × ${pe.reps} reps',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Search on YouTube',
                    icon: const Icon(Icons.play_circle_outline,
                        color: AppColors.muted),
                    onPressed: () => launchUrl(
                      Uri.parse(
                          'https://www.youtube.com/results?search_query=${Uri.encodeComponent(pe.exercise.name)}'),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  String _toTitle(String s) {
    if (s.isEmpty) return s;
    return s.split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1);
    }).join(' ');
  }
}
