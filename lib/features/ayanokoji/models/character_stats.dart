/// Six character stats from PDF section 8.
///
/// Each stat carries its own XP. Level for a stat = floor(sqrt(xp / 50)).
/// So level 5 = 1250 XP, level 10 = 5000 XP, level 20 = 20000 XP. Cheaper
/// than the global XP curve so the stat bars feel responsive.
enum CharacterStat {
  intelligence,
  discipline,
  strength,
  focus,
  consistency,
  social,
}

extension CharacterStatX on CharacterStat {
  String get label {
    switch (this) {
      case CharacterStat.intelligence:
        return 'Intelligence';
      case CharacterStat.discipline:
        return 'Discipline';
      case CharacterStat.strength:
        return 'Strength';
      case CharacterStat.focus:
        return 'Focus';
      case CharacterStat.consistency:
        return 'Consistency';
      case CharacterStat.social:
        return 'Social';
    }
  }

  /// Short two-letter code for the radar chart.
  String get code {
    switch (this) {
      case CharacterStat.intelligence:
        return 'INT';
      case CharacterStat.discipline:
        return 'DSC';
      case CharacterStat.strength:
        return 'STR';
      case CharacterStat.focus:
        return 'FOC';
      case CharacterStat.consistency:
        return 'CON';
      case CharacterStat.social:
        return 'SOC';
    }
  }

  String get sourceHint {
    switch (this) {
      case CharacterStat.intelligence:
        return 'Study minutes + Digit Span + Stroop';
      case CharacterStat.discipline:
        return 'Habit + prayer completions';
      case CharacterStat.strength:
        return 'Workout minutes + sessions';
      case CharacterStat.focus:
        return 'Focus / deep-work minutes + Reaction Time';
      case CharacterStat.consistency:
        return 'Best running streak across pillars';
      case CharacterStat.social:
        return 'Daily social-confidence self-rating';
    }
  }
}

class StatValue {
  final CharacterStat stat;
  final int xp;
  const StatValue(this.stat, this.xp);

  /// Level for a stat = floor(sqrt(xp / 50)). Returns at least 1.
  int get level {
    if (xp <= 0) return 1;
    final raw = (xp / 50);
    var lvl = 1;
    while ((lvl + 1) * (lvl + 1) <= raw) {
      lvl += 1;
    }
    return lvl;
  }

  int get xpAtThisLevel => level * level * 50;
  int get xpAtNextLevel => (level + 1) * (level + 1) * 50;

  /// Fractional progress through the current level.
  double get progress {
    final span = xpAtNextLevel - xpAtThisLevel;
    if (span <= 0) return 0;
    return ((xp - xpAtThisLevel) / span).clamp(0.0, 1.0);
  }
}
