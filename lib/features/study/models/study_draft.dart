/// An in-progress study session persisted to disk so it survives an app kill
/// (low-memory eviction, force-stop, reboot). Elapsed time is reconstructed
/// from wall-clock timestamps, matching the live timer: time that passes while
/// the app is dead still counts as study time when [running] is true.
class StudyDraft {
  final String subject;
  final DateTime startedAt; // first-ever start, used for the saved session
  final int accumulatedSeconds; // time from finished (paused) segments
  final DateTime? segmentStart; // wall-clock start of the running segment
  final bool running;
  final String? note;

  const StudyDraft({
    required this.subject,
    required this.startedAt,
    required this.accumulatedSeconds,
    required this.segmentStart,
    required this.running,
    this.note,
  });

  Duration get elapsed {
    var total = Duration(seconds: accumulatedSeconds);
    if (running && segmentStart != null) {
      total += DateTime.now().difference(segmentStart!);
    }
    return total;
  }

  Map<String, dynamic> toJson() => {
        'subject': subject,
        'startedAt': startedAt.toIso8601String(),
        'accumulatedSeconds': accumulatedSeconds,
        'segmentStart': segmentStart?.toIso8601String(),
        'running': running,
        'note': note,
      };

  factory StudyDraft.fromJson(Map json) => StudyDraft(
        subject: json['subject'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        accumulatedSeconds: (json['accumulatedSeconds'] as num).toInt(),
        segmentStart: json['segmentStart'] == null
            ? null
            : DateTime.parse(json['segmentStart'] as String),
        running: json['running'] as bool,
        note: json['note'] as String?,
      );
}
