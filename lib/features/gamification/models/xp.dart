import '../../ayanokoji/state/ayanokoji_controller.dart';
import '../../fitness/state/fitness_controller.dart';
import '../../habits/state/habit_controller.dart';
import '../../prayer/state/prayer_controller.dart';
import '../../study/state/study_controller.dart';

/// Read-only snapshot of everything the gamification layer needs.
/// Built fresh on every recompute — cheap and avoids stale joins.
class GamificationStats {
  // Study
  final int totalStudyMinutes;
  final int studyStreakDays;
  final int studySessions;

  // Habits
  final int habitsCompletedTotal;
  final int bestHabitStreakDays;

  // Prayer
  final int prayersCompletedTotal;
  final int prayerStreakDays;

  // Fitness
  final int workoutSessions;
  final int totalWorkoutMinutes;
  final int workoutStreakDays;

  const GamificationStats({
    required this.totalStudyMinutes,
    required this.studyStreakDays,
    required this.studySessions,
    required this.habitsCompletedTotal,
    required this.bestHabitStreakDays,
    required this.prayersCompletedTotal,
    required this.prayerStreakDays,
    required this.workoutSessions,
    required this.totalWorkoutMinutes,
    required this.workoutStreakDays,
  });

  factory GamificationStats.zero() => const GamificationStats(
        totalStudyMinutes: 0,
        studyStreakDays: 0,
        studySessions: 0,
        habitsCompletedTotal: 0,
        bestHabitStreakDays: 0,
        prayersCompletedTotal: 0,
        prayerStreakDays: 0,
        workoutSessions: 0,
        totalWorkoutMinutes: 0,
        workoutStreakDays: 0,
      );

  factory GamificationStats.from({
    required StudyController study,
    required HabitController habits,
    required PrayerController prayer,
    required FitnessController fitness,
  }) {
    // Study
    final totalStudyMin = study.sessions.fold<int>(
          0,
          (a, s) => a + s.durationSeconds,
        ) ~/
        60;

    // Habits — total completions across all habits across history.
    // Walk per-habit current-streak as a stand-in for best streak (cheap).
    var habitCount = 0;
    var bestHabitStreak = 0;
    for (final h in habits.habits) {
      final s = habits.streak(h.id);
      if (s > bestHabitStreak) bestHabitStreak = s;
      // Probe last 365 days for completions on this habit.
      for (int i = 0; i < 365; i++) {
        final day = DateTime.now().subtract(Duration(days: i));
        if (habits.isDone(h.id, day)) habitCount += 1;
      }
    }

    // Prayers — count completions across last 365 days × 5 slots.
    var prayerCount = 0;
    var prayerStreak = 0;
    var streakRunning = true;
    for (int i = 0; i < 365; i++) {
      final day = DateTime.now().subtract(Duration(days: i));
      var doneToday = 0;
      for (final slot in PrayerSlot.values) {
        if (prayer.isCompleted(slot, day)) {
          prayerCount += 1;
          doneToday += 1;
        }
      }
      if (streakRunning) {
        if (doneToday == 5) {
          prayerStreak += 1;
        } else if (i == 0 && doneToday < 5) {
          // today still in progress — don't break the streak yet, just don't add
        } else {
          streakRunning = false;
        }
      }
    }

    return GamificationStats(
      totalStudyMinutes: totalStudyMin,
      studyStreakDays: study.currentStreak(),
      studySessions: study.sessions.length,
      habitsCompletedTotal: habitCount,
      bestHabitStreakDays: bestHabitStreak,
      prayersCompletedTotal: prayerCount,
      prayerStreakDays: prayerStreak,
      workoutSessions: fitness.sessions.length,
      totalWorkoutMinutes: fitness.sessions
              .fold<int>(0, (a, s) => a + s.totalDurationSeconds) ~/
          60,
      workoutStreakDays: fitness.currentWorkoutStreak(),
    );
  }
}

/// Global XP = sum of all six CharacterStats. Single source of truth.
/// Per-stat formulas live in [AyanokojiController._recomputeStats] and cover:
/// study minutes, habits, prayers, workouts, focus sessions, mini-games
/// (digit-span, reaction-time, stroop), streaks, and social ratings.
class XpRules {
  static int totalFor(AyanokojiController ayanokoji) =>
      ayanokoji.allStats.fold<int>(0, (a, s) => a + s.xp);
}

