/// Title bands match PDF section 10: Beginner → Disciplined → Elite →
/// Mastermind → Ayanokoji.
class TitleBand {
  final int minLevel;
  final String title;
  const TitleBand(this.minLevel, this.title);
}

class Titles {
  static const ladder = <TitleBand>[
    TitleBand(1, 'Beginner'),
    TitleBand(5, 'Disciplined'),
    TitleBand(10, 'Elite'),
    TitleBand(20, 'Mastermind'),
    TitleBand(50, 'Ayanokoji'),
  ];

  static String forLevel(int level) {
    var current = ladder.first.title;
    for (final band in ladder) {
      if (level >= band.minLevel) current = band.title;
    }
    return current;
  }

  static TitleBand? nextBandAfter(int level) {
    for (final band in ladder) {
      if (level < band.minLevel) return band;
    }
    return null;
  }
}

/// Quadratic level curve: total XP required to *reach* level N is N² × 100.
/// Reaching level 1 is free (0 XP). Level 2 requires 400 total, etc.
class LevelInfo {
  final int level;
  final int totalXp;
  final int xpAtStartOfLevel;
  final int xpAtNextLevel;

  const LevelInfo({
    required this.level,
    required this.totalXp,
    required this.xpAtStartOfLevel,
    required this.xpAtNextLevel,
  });

  int get xpIntoLevel => totalXp - xpAtStartOfLevel;
  int get xpToNextLevel => xpAtNextLevel - totalXp;
  int get xpSpanThisLevel => xpAtNextLevel - xpAtStartOfLevel;

  double get progress {
    if (xpSpanThisLevel <= 0) return 0;
    return (xpIntoLevel / xpSpanThisLevel).clamp(0.0, 1.0);
  }

  String get title => Titles.forLevel(level);

  factory LevelInfo.fromXp(int totalXp) {
    // Find the highest level L such that L²×100 <= totalXp.
    var level = 1;
    while ((level + 1) * (level + 1) * 100 <= totalXp) {
      level += 1;
    }
    final start = (level == 1) ? 0 : level * level * 100;
    final next = (level + 1) * (level + 1) * 100;
    return LevelInfo(
      level: level,
      totalXp: totalXp,
      xpAtStartOfLevel: start,
      xpAtNextLevel: next,
    );
  }

  /// Total XP required to reach an arbitrary level (for "next milestone" calc).
  static int xpForLevel(int level) {
    if (level <= 1) return 0;
    return level * level * 100;
  }
}
