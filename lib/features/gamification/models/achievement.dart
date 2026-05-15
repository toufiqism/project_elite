import 'package:flutter/material.dart';

import 'xp.dart';

enum AchievementCategory { study, habits, prayer, fitness, milestone }

/// Achievement = an objectively-checkable goal with a name, an icon, a
/// category, and a function over [GamificationStats] that tells us if it's
/// unlocked and how close we are.
class Achievement {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final AchievementCategory category;

  /// Returns (current, target). Unlocked iff current >= target.
  final (int, int) Function(GamificationStats) progress;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.progress,
  });

  bool isUnlocked(GamificationStats s) {
    final (current, target) = progress(s);
    return current >= target;
  }
}

class Achievements {
  /// Catalog seeded from PDF section 10 plus natural extensions for streaks
  /// and milestones. Adding to this list is safe — the controller computes
  /// unlocked-state from this set every time and reconciles against what's
  /// been "seen" before.
  static final all = <Achievement>[
    // PDF-specified
    Achievement(
      id: 'study_streak_7',
      name: '7-Day Study Streak',
      description: 'Study at least once a day, seven days in a row.',
      icon: Icons.local_fire_department,
      category: AchievementCategory.study,
      progress: (s) => (s.studyStreakDays, 7),
    ),
    Achievement(
      id: 'workouts_30',
      name: '30 Workouts',
      description: 'Complete 30 total workout sessions.',
      icon: Icons.fitness_center,
      category: AchievementCategory.fitness,
      progress: (s) => (s.workoutSessions, 30),
    ),
    Achievement(
      id: 'prayers_100',
      name: '100 Prayers',
      description: 'Complete 100 prayers across any time period.',
      icon: Icons.mosque,
      category: AchievementCategory.prayer,
      progress: (s) => (s.prayersCompletedTotal, 100),
    ),

    // Study extensions
    Achievement(
      id: 'study_session_first',
      name: 'First Session',
      description: 'Complete your first study session.',
      icon: Icons.menu_book,
      category: AchievementCategory.study,
      progress: (s) => (s.studySessions, 1),
    ),
    Achievement(
      id: 'study_hours_100',
      name: '100 Hours Studied',
      description: 'Spend 100 hours studying total.',
      icon: Icons.timer,
      category: AchievementCategory.study,
      progress: (s) => (s.totalStudyMinutes, 100 * 60),
    ),
    Achievement(
      id: 'study_streak_30',
      name: '30-Day Study Streak',
      description: 'A month of unbroken focus.',
      icon: Icons.whatshot,
      category: AchievementCategory.study,
      progress: (s) => (s.studyStreakDays, 30),
    ),

    // Habit extensions
    Achievement(
      id: 'habit_streak_7',
      name: 'Habit Strong',
      description: 'Hold any habit for 7 days straight.',
      icon: Icons.check_circle,
      category: AchievementCategory.habits,
      progress: (s) => (s.bestHabitStreakDays, 7),
    ),
    Achievement(
      id: 'habit_streak_30',
      name: 'Habit Forged',
      description: 'Hold any habit for 30 days straight.',
      icon: Icons.shield,
      category: AchievementCategory.habits,
      progress: (s) => (s.bestHabitStreakDays, 30),
    ),
    Achievement(
      id: 'habits_500',
      name: '500 Disciplined Days',
      description: '500 total habit check-offs.',
      icon: Icons.format_list_numbered,
      category: AchievementCategory.habits,
      progress: (s) => (s.habitsCompletedTotal, 500),
    ),

    // Prayer extensions
    Achievement(
      id: 'prayer_streak_7',
      name: 'Prayerful Week',
      description: 'All five prayers, every day, for a week.',
      icon: Icons.brightness_3,
      category: AchievementCategory.prayer,
      progress: (s) => (s.prayerStreakDays, 7),
    ),
    Achievement(
      id: 'prayer_streak_30',
      name: 'Prayerful Month',
      description: 'A month of unbroken Salah.',
      icon: Icons.brightness_2,
      category: AchievementCategory.prayer,
      progress: (s) => (s.prayerStreakDays, 30),
    ),

    // Fitness extensions
    Achievement(
      id: 'workout_first',
      name: 'First Workout',
      description: 'Complete your first workout.',
      icon: Icons.directions_run,
      category: AchievementCategory.fitness,
      progress: (s) => (s.workoutSessions, 1),
    ),
    Achievement(
      id: 'workout_streak_7',
      name: 'Daily Mover',
      description: '7 workouts in 7 days.',
      icon: Icons.bolt,
      category: AchievementCategory.fitness,
      progress: (s) => (s.workoutStreakDays, 7),
    ),
    Achievement(
      id: 'workout_hours_50',
      name: '50 Hours Trained',
      description: 'Accumulate 50 hours of workouts.',
      icon: Icons.sports_martial_arts,
      category: AchievementCategory.fitness,
      progress: (s) => (s.totalWorkoutMinutes, 50 * 60),
    ),

    // XP / level milestones — computed from totals rather than stats; we
    // pass a synthetic XP value through `studySessions` is wrong, so these
    // are evaluated separately in the controller via _xpMilestoneCheck.
    // For visibility in the catalog UI they declare their target as an XP
    // number; current is filled in by the controller before display.
    Achievement(
      id: 'xp_10k',
      name: 'Disciple of 10k',
      description: 'Earn 10,000 XP.',
      icon: Icons.workspace_premium,
      category: AchievementCategory.milestone,
      progress: (_) => (0, 10000),
    ),
    Achievement(
      id: 'xp_50k',
      name: 'Master of 50k',
      description: 'Earn 50,000 XP.',
      icon: Icons.military_tech,
      category: AchievementCategory.milestone,
      progress: (_) => (0, 50000),
    ),
    Achievement(
      id: 'level_5',
      name: 'Disciplined',
      description: 'Reach level 5 — earn the Disciplined title.',
      icon: Icons.star,
      category: AchievementCategory.milestone,
      progress: (_) => (0, 5),
    ),
    Achievement(
      id: 'level_10',
      name: 'Elite',
      description: 'Reach level 10 — earn the Elite title.',
      icon: Icons.diamond,
      category: AchievementCategory.milestone,
      progress: (_) => (0, 10),
    ),
    Achievement(
      id: 'level_20',
      name: 'Mastermind',
      description: 'Reach level 20 — earn the Mastermind title.',
      icon: Icons.psychology,
      category: AchievementCategory.milestone,
      progress: (_) => (0, 20),
    ),
  ];

  static Achievement byId(String id) =>
      all.firstWhere((a) => a.id == id, orElse: () => all.first);
}
