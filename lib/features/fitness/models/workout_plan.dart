import 'exercise.dart';

/// A planned exercise inside a daily workout — exercise + prescribed sets/reps.
class PlannedExercise {
  final Exercise exercise;
  final int sets;
  final int reps;
  final int restSeconds;
  final int? holdSeconds; // for planks, etc.

  const PlannedExercise({
    required this.exercise,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    this.holdSeconds,
  });

  int estimatedDurationSeconds() {
    final perSet = holdSeconds ?? (reps * 4); // ~4s per rep
    return sets * perSet + (sets - 1) * restSeconds;
  }

  /// Very rough kcal estimate. Strength: ~0.05 kcal/sec, cardio: ~0.12.
  double estimatedKcal({double bodyWeightKg = 70}) {
    final dur = estimatedDurationSeconds();
    final rate = exercise.isCardio ? 0.14 : 0.06;
    return dur * rate * (bodyWeightKg / 70);
  }
}

class WorkoutPlan {
  final DateTime forDate;
  final String label; // e.g. "Upper push day"
  final List<PlannedExercise> exercises;

  const WorkoutPlan({
    required this.forDate,
    required this.label,
    required this.exercises,
  });

  Duration estimatedDuration() {
    final seconds = exercises.fold<int>(
      0,
      (a, e) => a + e.estimatedDurationSeconds(),
    );
    return Duration(seconds: seconds);
  }

  double estimatedKcal({double bodyWeightKg = 70}) {
    return exercises.fold<double>(
      0,
      (a, e) => a + e.estimatedKcal(bodyWeightKg: bodyWeightKg),
    );
  }
}
