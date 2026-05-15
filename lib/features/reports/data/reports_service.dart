import '../../../core/utils/date_utils.dart';
import '../../fitness/state/fitness_controller.dart';
import '../../habits/state/habit_controller.dart';
import '../../prayer/state/prayer_controller.dart';
import '../../profile/models/user_profile.dart';
import '../../study/state/study_controller.dart';
import '../models/period_report.dart';

/// Stateless aggregation layer. Builds a [PeriodReport] from the current
/// controller snapshots for a given date range.
class ReportsService {
  static PeriodReport buildWeek({
    required UserProfile? profile,
    required StudyController study,
    required HabitController habits,
    required PrayerController prayer,
    required FitnessController fitness,
  }) {
    final today = DateX.startOfDay(DateTime.now());
    final start = DateX.startOfWeek(today);
    return _build(
      label: 'This week',
      start: start,
      end: today,
      profile: profile,
      study: study,
      habits: habits,
      prayer: prayer,
      fitness: fitness,
      isMonthly: false,
    );
  }

  static PeriodReport buildMonth({
    required UserProfile? profile,
    required StudyController study,
    required HabitController habits,
    required PrayerController prayer,
    required FitnessController fitness,
  }) {
    final today = DateX.startOfDay(DateTime.now());
    final start = DateTime(today.year, today.month, 1);
    return _build(
      label: 'This month',
      start: start,
      end: today,
      profile: profile,
      study: study,
      habits: habits,
      prayer: prayer,
      fitness: fitness,
      isMonthly: true,
    );
  }

  static PeriodReport _build({
    required String label,
    required DateTime start,
    required DateTime end,
    required UserProfile? profile,
    required StudyController study,
    required HabitController habits,
    required PrayerController prayer,
    required FitnessController fitness,
    required bool isMonthly,
  }) {
    final days = _daysInRange(start, end);

    // Study
    final studyGoalSec = (profile?.studyGoalHoursPerDay ?? 5) * 3600;
    var studyMin = 0;
    var studySessions = 0;
    final studyDayActive = <String>{};
    final studyDayHitGoal = <String>{};
    for (final s in study.sessions) {
      if (s.startedAt.isBefore(start) || s.startedAt.isAfter(end.add(const Duration(days: 1)))) {
        continue;
      }
      studyMin += s.durationSeconds ~/ 60;
      studySessions += 1;
      studyDayActive.add(DateX.dayKey(s.startedAt));
    }
    for (final day in days) {
      if (study.totalOn(day).inSeconds >= studyGoalSec) {
        studyDayHitGoal.add(DateX.dayKey(day));
      }
    }

    // Workout
    var workoutMin = 0;
    var workoutSessions = 0;
    final workoutDays = <String>{};
    for (final s in fitness.sessions) {
      if (s.startedAt.isBefore(start) || s.startedAt.isAfter(end.add(const Duration(days: 1)))) {
        continue;
      }
      workoutMin += s.totalDurationSeconds ~/ 60;
      workoutSessions += 1;
      workoutDays.add(DateX.dayKey(s.startedAt));
    }

    // Prayer
    var prayerCompletions = 0;
    var prayerPerfectDays = 0;
    for (final day in days) {
      var doneToday = 0;
      for (final slot in PrayerSlot.values) {
        if (prayer.isCompleted(slot, day)) {
          prayerCompletions += 1;
          doneToday += 1;
        }
      }
      if (doneToday == 5) prayerPerfectDays += 1;
    }

    // Habits
    var habitCompletions = 0;
    var habitOpportunities = 0;
    final breakdown = <HabitBreakdown>[];
    for (final h in habits.habits) {
      var c = 0;
      var o = 0;
      for (final day in days) {
        o += 1;
        if (habits.isDone(h.id, day)) c += 1;
      }
      habitCompletions += c;
      habitOpportunities += o;
      breakdown.add(HabitBreakdown(
        habitName: h.name,
        completions: c,
        opportunities: o,
      ));
    }

    // Productivity score = average daily score (study/habits/prayer/fitness)
    final dailyScores = <int>[];
    for (final day in days) {
      dailyScores.add(_dailyScoreFor(
        day: day,
        profile: profile,
        study: study,
        habits: habits,
        prayer: prayer,
        fitness: fitness,
      ));
    }
    final productivity = dailyScores.isEmpty
        ? 0
        : (dailyScores.fold<int>(0, (a, b) => a + b) / dailyScores.length).round();

    // XP in period — direct sum using same rules as XpRules but date-scoped.
    final xpInPeriod = studyMin * 1 +
        habitCompletions * 10 +
        prayerCompletions * 8 +
        workoutMin * 1 +
        workoutSessions * 30;

    // Self-improvement score normalises XP. Target: ~50 XP/day = 100 monthly.
    final targetXp = days.length * 50;
    final selfImprovement = targetXp == 0
        ? 0
        : ((xpInPeriod / targetXp) * 100).round().clamp(0, 100);

    // Weight (monthly only). Closest entry on/before the start and end.
    double? weightStart;
    double? weightEnd;
    if (isMonthly && fitness.weights.isNotEmpty) {
      for (final w in fitness.weights) {
        if (w.date.isBefore(start.add(const Duration(days: 1)))) {
          weightStart = w.weightKg;
        }
        if (!w.date.isAfter(end.add(const Duration(days: 1)))) {
          weightEnd = w.weightKg;
        }
      }
    }
    final weightChange = (weightStart != null && weightEnd != null)
        ? weightEnd - weightStart
        : null;

    return PeriodReport(
      label: label,
      start: start,
      end: end,
      totalDaysInPeriod: days.length,
      studyMinutes: studyMin,
      studySessions: studySessions,
      studyDaysActive: studyDayActive.length,
      studyDaysHitGoal: studyDayHitGoal.length,
      workoutMinutes: workoutMin,
      workoutSessions: workoutSessions,
      workoutDaysActive: workoutDays.length,
      prayerCompletions: prayerCompletions,
      prayerPerfectDays: prayerPerfectDays,
      habitCompletions: habitCompletions,
      habitOpportunities: habitOpportunities,
      habitBreakdown: breakdown,
      productivityScore: productivity,
      selfImprovementScore: selfImprovement,
      xpInPeriod: xpInPeriod,
      weightChangeKg: weightChange,
      weightStartKg: weightStart,
      weightEndKg: weightEnd,
    );
  }

  static int _dailyScoreFor({
    required DateTime day,
    required UserProfile? profile,
    required StudyController study,
    required HabitController habits,
    required PrayerController prayer,
    required FitnessController fitness,
  }) {
    final goalHours = profile?.studyGoalHoursPerDay ?? 5;
    final workoutGoalMin = profile?.workoutGoalMinutesPerDay ?? 30;

    final studyPct =
        (study.totalOn(day).inSeconds / (goalHours * 3600)).clamp(0.0, 1.0);

    final habitDone = habits.habits.where((h) => habits.isDone(h.id, day)).length;
    final habitPct = habits.habits.isEmpty ? 0.0 : habitDone / habits.habits.length;

    var prayed = 0;
    for (final slot in PrayerSlot.values) {
      if (prayer.isCompleted(slot, day)) prayed += 1;
    }
    final prayerPct = prayed / 5.0;

    final workoutMin = fitness.sessions
            .where((s) => DateX.dayKey(s.startedAt) == DateX.dayKey(day))
            .fold<int>(0, (a, s) => a + s.totalDurationSeconds) ~/
        60;
    final fitnessPct =
        (workoutMin / workoutGoalMin).clamp(0.0, 1.0).toDouble();

    return ((studyPct * 0.35 +
                habitPct * 0.25 +
                prayerPct * 0.2 +
                fitnessPct * 0.2) *
            100)
        .round();
  }

  static List<DateTime> _daysInRange(DateTime start, DateTime endInclusive) {
    final out = <DateTime>[];
    var d = DateX.startOfDay(start);
    final last = DateX.startOfDay(endInclusive);
    while (!d.isAfter(last)) {
      out.add(d);
      d = d.add(const Duration(days: 1));
    }
    return out;
  }

  /// Plain-text summary for the system share sheet.
  static String formatShareText(PeriodReport r) {
    final buf = StringBuffer();
    buf.writeln('Project Elite — ${r.label}');
    buf.writeln('${_d(r.start)} → ${_d(r.end)}');
    buf.writeln('');
    buf.writeln('Productivity:     ${r.productivityScore}/100');
    buf.writeln('Self-improvement: ${r.selfImprovementScore}/100');
    buf.writeln('XP earned:        ${r.xpInPeriod}');
    buf.writeln('');
    buf.writeln(
        'Study:   ${(r.studyMinutes / 60).toStringAsFixed(1)}h · ${r.studySessions} sessions · ${(r.studyConsistency * 100).round()}% on goal');
    buf.writeln(
        'Workout: ${r.workoutMinutes}min · ${r.workoutSessions} sessions · ${(r.workoutConsistency * 100).round()}% days');
    buf.writeln(
        'Prayer:  ${r.prayerCompletions} prayers · ${r.prayerPerfectDays} perfect days · ${(r.prayerConsistency * 100).round()}%');
    buf.writeln(
        'Habits:  ${r.habitCompletions}/${r.habitOpportunities} (${(r.habitSuccessRate * 100).round()}%)');
    if (r.weightChangeKg != null) {
      final sign = r.weightChangeKg! >= 0 ? '+' : '';
      buf.writeln(
          'Weight:  $sign${r.weightChangeKg!.toStringAsFixed(1)} kg');
    }
    return buf.toString();
  }

  static String _d(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
