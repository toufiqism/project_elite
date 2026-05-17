import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../../core/storage/hive_setup.dart';
import '../../ayanokoji/state/ayanokoji_controller.dart';
import '../../fitness/state/fitness_controller.dart';
import '../../habits/state/habit_controller.dart';
import '../../prayer/state/prayer_controller.dart';
import '../../study/state/study_controller.dart';
import '../models/achievement.dart';
import '../models/level_info.dart';
import '../models/xp.dart';

class GamificationController extends ChangeNotifier {
  static const _seenIdsKey = 'gamification_seen_ids';
  static const _lastSeenLevelKey = 'gamification_last_seen_level';
  final Box _box = Hive.box(HiveBoxes.settings);

  GamificationStats _stats = GamificationStats.zero();
  int _totalXp = 0;
  LevelInfo _level = LevelInfo.fromXp(0);
  Set<String> _unlocked = const {};
  Set<String> _seen = const {};

  GamificationStats get stats => _stats;
  int get totalXp => _totalXp;
  LevelInfo get level => _level;
  String get title => _level.title;
  Set<String> get unlocked => _unlocked;

  /// Achievements unlocked since the user last opened the celebration overlay.
  List<Achievement> get newlyUnlocked => Achievements.all
      .where((a) => _unlocked.contains(a.id) && !_seen.contains(a.id))
      .toList();

  int _lastSeenLevel = 1;
  int get lastSeenLevel => _lastSeenLevel;
  bool get hasLevelUp => _level.level > _lastSeenLevel;

  bool get hasPendingCelebration =>
      newlyUnlocked.isNotEmpty || hasLevelUp;

  GamificationController() {
    final seenRaw = _box.get(_seenIdsKey);
    if (seenRaw is List) {
      _seen = seenRaw.whereType<String>().toSet();
    }
    _lastSeenLevel =
        (_box.get(_lastSeenLevelKey) as num?)?.toInt() ?? 1;
  }

  /// Pull a fresh snapshot from the source controllers and recompute. Called
  /// from a `ChangeNotifierProxyProvider5` whenever any source notifies.
  void recompute({
    required StudyController study,
    required HabitController habits,
    required PrayerController prayer,
    required FitnessController fitness,
    required AyanokojiController ayanokoji,
  }) {
    final next = GamificationStats.from(
      study: study,
      habits: habits,
      prayer: prayer,
      fitness: fitness,
    );
    _stats = next;
    _totalXp = XpRules.totalFor(ayanokoji);
    _level = LevelInfo.fromXp(_totalXp);

    final unlockedNow = <String>{};
    for (final a in Achievements.all) {
      if (a.category == AchievementCategory.milestone) {
        // Milestones evaluate against XP totals / level — not stats.
        if (_isMilestoneUnlocked(a.id)) unlockedNow.add(a.id);
      } else if (a.isUnlocked(next)) {
        unlockedNow.add(a.id);
      }
    }
    _unlocked = unlockedNow;

    notifyListeners();
  }

  bool _isMilestoneUnlocked(String id) {
    switch (id) {
      case 'xp_10k':
        return _totalXp >= 10000;
      case 'xp_50k':
        return _totalXp >= 50000;
      case 'level_5':
        return _level.level >= 5;
      case 'level_10':
        return _level.level >= 10;
      case 'level_20':
        return _level.level >= 20;
      default:
        return false;
    }
  }

  /// Returns (current, target) — for milestones the static `progress` closure
  /// can't see the live XP/level, so we override it here.
  (int, int) progressFor(Achievement a) {
    switch (a.id) {
      case 'xp_10k':
        return (_totalXp, 10000);
      case 'xp_50k':
        return (_totalXp, 50000);
      case 'level_5':
        return (_level.level, 5);
      case 'level_10':
        return (_level.level, 10);
      case 'level_20':
        return (_level.level, 20);
      default:
        return a.progress(_stats);
    }
  }

  /// Mark the celebration overlay as seen — moves currently-unlocked items
  /// into `_seen` and pins the level so future level-ups can fire.
  Future<void> markCelebrationSeen() async {
    _seen = {..._seen, ..._unlocked};
    _lastSeenLevel = _level.level;
    await _box.put(_seenIdsKey, _seen.toList());
    await _box.put(_lastSeenLevelKey, _lastSeenLevel);
    notifyListeners();
  }
}
