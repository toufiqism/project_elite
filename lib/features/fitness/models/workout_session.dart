class CompletedExercise {
  final String exerciseId;
  final String exerciseName;
  final int setsCompleted;
  final int repsPerSet;
  final int durationSeconds;
  final double? kcal;

  const CompletedExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.setsCompleted,
    required this.repsPerSet,
    required this.durationSeconds,
    this.kcal,
  });

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'setsCompleted': setsCompleted,
        'repsPerSet': repsPerSet,
        'durationSeconds': durationSeconds,
        'kcal': kcal,
      };

  factory CompletedExercise.fromJson(Map json) => CompletedExercise(
        exerciseId: json['exerciseId'] as String,
        exerciseName: json['exerciseName'] as String,
        setsCompleted: (json['setsCompleted'] as num).toInt(),
        repsPerSet: (json['repsPerSet'] as num).toInt(),
        durationSeconds: (json['durationSeconds'] as num).toInt(),
        kcal: (json['kcal'] as num?)?.toDouble(),
      );
}

class WorkoutSession {
  final String id;
  final DateTime startedAt;
  final int totalDurationSeconds;
  final List<CompletedExercise> exercises;
  final double totalKcal;

  const WorkoutSession({
    required this.id,
    required this.startedAt,
    required this.totalDurationSeconds,
    required this.exercises,
    required this.totalKcal,
  });

  Duration get totalDuration => Duration(seconds: totalDurationSeconds);

  Map<String, dynamic> toJson() => {
        'id': id,
        'startedAt': startedAt.toIso8601String(),
        'totalDurationSeconds': totalDurationSeconds,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'totalKcal': totalKcal,
      };

  factory WorkoutSession.fromJson(Map json) => WorkoutSession(
        id: json['id'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        totalDurationSeconds: (json['totalDurationSeconds'] as num).toInt(),
        exercises: ((json['exercises'] as List?) ?? const [])
            .whereType<Map>()
            .map((m) =>
                CompletedExercise.fromJson(Map<String, dynamic>.from(m)))
            .toList(),
        totalKcal: (json['totalKcal'] as num).toDouble(),
      );
}
