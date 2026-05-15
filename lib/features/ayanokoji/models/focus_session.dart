class FocusSession {
  final String id;
  final DateTime startedAt;
  final int durationSeconds;
  final bool completed; // false if user aborted before plannedSeconds
  final int plannedSeconds;

  const FocusSession({
    required this.id,
    required this.startedAt,
    required this.durationSeconds,
    required this.completed,
    required this.plannedSeconds,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'startedAt': startedAt.toIso8601String(),
        'durationSeconds': durationSeconds,
        'completed': completed,
        'plannedSeconds': plannedSeconds,
      };

  factory FocusSession.fromJson(Map json) => FocusSession(
        id: json['id'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        durationSeconds: (json['durationSeconds'] as num).toInt(),
        completed: json['completed'] as bool? ?? false,
        plannedSeconds: (json['plannedSeconds'] as num).toInt(),
      );
}
