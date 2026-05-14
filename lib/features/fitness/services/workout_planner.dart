import '../../profile/models/user_profile.dart';
import '../data/fitness_repository.dart';
import '../models/exercise.dart';
import '../models/workout_plan.dart';

enum WorkoutGoal { weightLoss, muscleGain, fitness, discipline }

class WorkoutPlanner {
  final FitnessRepository repo;
  WorkoutPlanner(this.repo);

  /// Derived goal from profile: weight delta vs goal weight.
  WorkoutGoal deriveGoal(UserProfile p) {
    final delta = p.weightKg - p.goalWeightKg;
    if (delta > 3) return WorkoutGoal.weightLoss;
    if (delta < -3) return WorkoutGoal.muscleGain;
    return WorkoutGoal.fitness;
  }

  ({int sets, int reps, int rest}) _prescription(String fitnessLevel) {
    switch (fitnessLevel) {
      case 'Beginner':
        return (sets: 3, reps: 8, rest: 60);
      case 'Intermediate':
        return (sets: 4, reps: 10, rest: 75);
      case 'Advance':
        return (sets: 4, reps: 12, rest: 90);
      default:
        return (sets: 3, reps: 10, rest: 60);
    }
  }

  /// For a given day-of-week, returns the body parts/targets to train.
  ///
  /// Beginner / Home users get a full-body rotation. Gym users get a
  /// push/pull/legs split. Sunday is always lighter (cardio + stretch).
  List<String> _focusParts({
    required String workoutType,
    required DateTime date,
    required String fitnessLevel,
  }) {
    final dow = date.weekday; // 1 = Mon
    if (dow == DateTime.sunday) {
      return ['cardio'];
    }
    final isGym = workoutType == 'Gym' && fitnessLevel != 'Beginner';
    if (isGym) {
      const split = [
        ['chest', 'shoulders', 'upper arms'], // push
        ['back', 'upper arms'], // pull
        ['upper legs', 'lower legs', 'waist'], // legs
      ];
      return split[(dow - 1) % split.length];
    }
    const fullBody = [
      ['chest', 'upper legs', 'waist'],
      ['back', 'upper arms', 'waist'],
      ['shoulders', 'upper legs', 'lower legs'],
      ['chest', 'back', 'waist'],
      ['upper legs', 'lower legs', 'shoulders'],
      ['back', 'upper arms', 'waist'],
    ];
    return fullBody[(dow - 1) % fullBody.length];
  }

  bool _matchesWorkoutType(Exercise ex, String workoutType) {
    switch (workoutType) {
      case 'Home':
      case 'Bodyweight':
        return ex.isBodyweight;
      case 'Walking':
        return ex.isCardio;
      case 'Gym':
      default:
        return true;
    }
  }

  /// Build today's plan. Returns an empty plan if cache is empty AND no API
  /// key is configured — the UI shows a "set up API key" prompt in that case.
  Future<WorkoutPlan> planFor({
    required UserProfile profile,
    DateTime? date,
  }) async {
    final today = date ?? DateTime.now();
    final p = _prescription(profile.fitnessLevel);
    final focus = _focusParts(
      workoutType: profile.preferredWorkoutType,
      date: today,
      fitnessLevel: profile.fitnessLevel,
    );

    final picked = <Exercise>[];
    final seenIds = <String>{};
    for (final bp in focus) {
      final list = await repo.byBodyPart(bp);
      final filtered = list.where(
        (e) => _matchesWorkoutType(e, profile.preferredWorkoutType),
      );
      // Take 2 per body part; deterministic seed off day-of-year so the plan
      // is stable within a day but rotates across days.
      final seed = today.day + today.month + bp.hashCode;
      final shuffled = filtered.toList()
        ..sort((a, b) => ((a.id.hashCode ^ seed) -
                (b.id.hashCode ^ seed))
            .clamp(-1 << 31, (1 << 31) - 1));
      var added = 0;
      for (final ex in shuffled) {
        if (added >= 2) break;
        if (seenIds.contains(ex.id)) continue;
        picked.add(ex);
        seenIds.add(ex.id);
        added += 1;
      }
    }

    // Target ~5-7 exercises depending on workout-minute goal.
    final targetCount = _targetCount(profile.workoutGoalMinutesPerDay);
    final trimmed = picked.take(targetCount).toList();

    final exercises = trimmed.map((ex) {
      final isHold = ex.name.toLowerCase().contains('plank') ||
          ex.name.toLowerCase().contains('hold');
      return PlannedExercise(
        exercise: ex,
        sets: p.sets,
        reps: p.reps,
        restSeconds: p.rest,
        holdSeconds: isHold ? 30 : null,
      );
    }).toList();

    final label = _planLabel(today, focus);
    return WorkoutPlan(forDate: today, label: label, exercises: exercises);
  }

  int _targetCount(double minutes) {
    if (minutes <= 20) return 4;
    if (minutes <= 35) return 6;
    if (minutes <= 50) return 7;
    return 8;
  }

  String _planLabel(DateTime d, List<String> parts) {
    if (d.weekday == DateTime.sunday) return 'Active recovery';
    final cap = parts
        .map((p) => p.isEmpty ? p : '${p[0].toUpperCase()}${p.substring(1)}')
        .join(' · ');
    return cap;
  }
}
