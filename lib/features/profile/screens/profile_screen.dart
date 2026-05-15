import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/elite_card.dart';
import '../../ayanokoji/screens/ayanokoji_home_screen.dart';
import '../../gamification/screens/achievements_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../state/profile_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProfileController>().profile;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Ayanokoji Mode',
            icon: const Icon(Icons.shield_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AyanokojiHomeScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Achievements',
            icon: const Icon(Icons.emoji_events_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AchievementsScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: p == null
          ? const Center(child: Text('No profile yet'))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                EliteCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: AppColors.primary,
                            child: Text(
                              p.name.isEmpty ? '?' : p.name[0].toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.background,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name,
                                    style: const TextStyle(
                                      color: AppColors.text,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    )),
                                Text(
                                  '${p.caLevel} level · ${p.occupation}',
                                  style: const TextStyle(color: AppColors.muted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: p.caSubjects
                            .map((s) => Chip(
                                  label: Text(s),
                                  backgroundColor: AppColors.surfaceAlt,
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const SectionHeader(title: 'Body & fitness'),
                EliteCard(
                  child: Column(
                    children: [
                      _row('Age', '${p.age}'),
                      _row('Gender', p.gender),
                      _row('Height', '${p.heightCm.toStringAsFixed(0)} cm'),
                      _row('Weight', '${p.weightKg.toStringAsFixed(1)} kg'),
                      _row('Goal', '${p.goalWeightKg.toStringAsFixed(1)} kg'),
                      _row('BMI', p.bmi.toStringAsFixed(1)),
                      _row('Fitness', p.fitnessLevel),
                      _row('Workout style', p.preferredWorkoutType),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const SectionHeader(title: 'Lifestyle goals'),
                EliteCard(
                  child: Column(
                    children: [
                      _row('Free time', '${p.dailyFreeHours} h/day'),
                      _row('Sleep', p.sleepSchedule),
                      _row('Study goal', '${p.studyGoalHoursPerDay} h/day'),
                      _row('Workout goal', '${p.workoutGoalMinutesPerDay} min'),
                      _row('Water goal', '${p.waterGoalLiters} L'),
                      _row('Stress', '${p.stressLevel}/5'),
                      _row('Prayer reminders', p.prayerRemindersOn ? 'On' : 'Off'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh, color: AppColors.danger),
                  label: const Text('Reset profile',
                      style: TextStyle(color: AppColors.danger)),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: AppColors.surface,
                        title: const Text('Reset profile?'),
                        content: const Text(
                            'This will return you to onboarding. Study, habits, and prayer history are kept.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel')),
                          FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Reset')),
                        ],
                      ),
                    );
                    if (ok == true && context.mounted) {
                      await context.read<ProfileController>().clear();
                    }
                  },
                ),
              ],
            ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: AppColors.muted)),
          ),
          Text(value,
              style: const TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }
}
