/// Aggregated stats over a date range — covers both "this week" and "this
/// month" by varying the range.
class PeriodReport {
  final String label; // "This week", "This month"
  final DateTime start;
  final DateTime end; // inclusive (clamped to today)
  final int totalDaysInPeriod;

  // Study
  final int studyMinutes;
  final int studySessions;
  final int studyDaysActive;
  final int studyDaysHitGoal;

  // Workout
  final int workoutMinutes;
  final int workoutSessions;
  final int workoutDaysActive;

  // Prayer
  final int prayerCompletions;
  final int prayerPerfectDays; // days with all 5

  // Habit
  final int habitCompletions;
  final int habitOpportunities;
  final List<HabitBreakdown> habitBreakdown;

  // Weight (monthly only — null on weekly)
  final double? weightChangeKg;
  final double? weightStartKg;
  final double? weightEndKg;

  // Scores
  final int productivityScore; // average daily score, 0..100
  final int selfImprovementScore; // normalised XP/period, 0..100
  final int xpInPeriod;

  const PeriodReport({
    required this.label,
    required this.start,
    required this.end,
    required this.totalDaysInPeriod,
    required this.studyMinutes,
    required this.studySessions,
    required this.studyDaysActive,
    required this.studyDaysHitGoal,
    required this.workoutMinutes,
    required this.workoutSessions,
    required this.workoutDaysActive,
    required this.prayerCompletions,
    required this.prayerPerfectDays,
    required this.habitCompletions,
    required this.habitOpportunities,
    required this.habitBreakdown,
    required this.productivityScore,
    required this.selfImprovementScore,
    required this.xpInPeriod,
    this.weightChangeKg,
    this.weightStartKg,
    this.weightEndKg,
  });

  /// Habit success across the entire period. 0..1.
  double get habitSuccessRate {
    if (habitOpportunities == 0) return 0;
    return habitCompletions / habitOpportunities;
  }

  /// Workout consistency = days with at least one workout / period days. 0..1.
  double get workoutConsistency {
    if (totalDaysInPeriod == 0) return 0;
    return workoutDaysActive / totalDaysInPeriod;
  }

  /// Prayer consistency = perfect days / period days. 0..1.
  double get prayerConsistency {
    if (totalDaysInPeriod == 0) return 0;
    return prayerPerfectDays / totalDaysInPeriod;
  }

  /// Study consistency = days hit goal / period days. 0..1.
  double get studyConsistency {
    if (totalDaysInPeriod == 0) return 0;
    return studyDaysHitGoal / totalDaysInPeriod;
  }
}

class HabitBreakdown {
  final String habitName;
  final int completions;
  final int opportunities;

  const HabitBreakdown({
    required this.habitName,
    required this.completions,
    required this.opportunities,
  });

  double get rate => opportunities == 0 ? 0 : completions / opportunities;
}
