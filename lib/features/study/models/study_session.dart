class StudySession {
  final String id;
  final String subject;
  final DateTime startedAt;
  final int durationSeconds;
  final String? note;

  const StudySession({
    required this.id,
    required this.subject,
    required this.startedAt,
    required this.durationSeconds,
    this.note,
  });

  Duration get duration => Duration(seconds: durationSeconds);

  Map<String, dynamic> toJson() => {
        'id': id,
        'subject': subject,
        'startedAt': startedAt.toIso8601String(),
        'durationSeconds': durationSeconds,
        'note': note,
      };

  factory StudySession.fromJson(Map json) => StudySession(
        id: json['id'] as String,
        subject: json['subject'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        durationSeconds: (json['durationSeconds'] as num).toInt(),
        note: json['note'] as String?,
      );
}
