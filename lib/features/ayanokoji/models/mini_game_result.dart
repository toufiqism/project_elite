enum MiniGameKind { digitSpan, reactionTime, stroop }

extension MiniGameKindX on MiniGameKind {
  String get label {
    switch (this) {
      case MiniGameKind.digitSpan:
        return 'Digit Span';
      case MiniGameKind.reactionTime:
        return 'Reaction Time';
      case MiniGameKind.stroop:
        return 'Stroop';
    }
  }
}

class MiniGameResult {
  final String id;
  final MiniGameKind kind;
  final DateTime playedAt;

  /// Game-specific score. Interpretation by kind:
  ///   digitSpan    — max digit span reached
  ///   reactionTime — average ms (lower = better)
  ///   stroop       — correct answers within 30s
  final int score;

  /// XP awarded by this play (Intelligence / Focus, depending on game).
  final int xpEarned;

  const MiniGameResult({
    required this.id,
    required this.kind,
    required this.playedAt,
    required this.score,
    required this.xpEarned,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'playedAt': playedAt.toIso8601String(),
        'score': score,
        'xpEarned': xpEarned,
      };

  factory MiniGameResult.fromJson(Map json) {
    final kindStr = (json['kind'] as String?) ?? MiniGameKind.digitSpan.name;
    final kind = MiniGameKind.values.firstWhere(
      (k) => k.name == kindStr,
      orElse: () => MiniGameKind.digitSpan,
    );
    return MiniGameResult(
      id: json['id'] as String,
      kind: kind,
      playedAt: DateTime.parse(json['playedAt'] as String),
      score: (json['score'] as num).toInt(),
      xpEarned: (json['xpEarned'] as num).toInt(),
    );
  }
}
