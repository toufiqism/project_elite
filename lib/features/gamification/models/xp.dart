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

/// XP rules (user-chosen 2026-05-15):
/// - 1 XP per minute studied
/// - 10 XP per habit completion
/// - 8 XP per prayer
/// - 1 XP per minute of workout + 30 XP per workout session
class XpRules {
  static int totalFor(GamificationStats s) {
    return s.totalStudyMinutes * 1 +
        s.habitsCompletedTotal * 10 +
        s.prayersCompletedTotal * 8 +
        s.totalWorkoutMinutes * 1 +
        s.workoutSessions * 30;
  }
}

