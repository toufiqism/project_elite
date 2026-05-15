import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/hive_setup.dart';
import '../../../core/utils/date_utils.dart';
import '../../fitness/state/fitness_controller.dart';
import '../../habits/state/habit_controller.dart';
import '../../prayer/state/prayer_controller.dart';
import '../../study/state/study_controller.dart';
import '../models/character_stats.dart';
import '../models/focus_session.dart';
import '../models/mini_game_result.dart';
import '../models/social_rating.dart';

class AyanokojiController extends ChangeNotifier {
  static const _uuid = Uuid();
  static const _disciplineModeKey = 'ayanokoji_discipline_mode';

  final Box _settings = Hive.box(HiveBoxes.settings);
  final Box _focusBox = Hive.box(HiveBoxes.focusSessions);
  final Box _socialBox = Hive.box(HiveBoxes.socialRatings);
  final Box _gameBox = Hive.box(HiveBoxes.gameResults);

  // Discipline mode
  bool _disciplineMode = false;
  bool get disciplineMode => _disciplineMode;

  // Cached per-stat XP, recomputed by [recompute].
  Map<CharacterStat, int> _statXp = {
    for (final s in CharacterStat.values) s: 0,
  };

  // Latest snapshot of source-controller derived counters.
  int _studyMinutes = 0;
  int _habitCompletions = 0;
  int _prayerCompletions = 0;
  int _workoutMinutes = 0;
  int _workoutSessions = 0;
  int _bestStreak = 0;

  AyanokojiController() {
    _disciplineMode = (_settings.get(_disciplineModeKey) as bool?) ?? false;
  }

  StatValue stat(CharacterStat s) => StatValue(s, _statXp[s] ?? 0);

  List<StatValue> get allStats =>
      CharacterStat.values.map((s) => stat(s)).toList();

  Future<void> setDisciplineMode(bool on) async {
    _disciplineMode = on;
    await _settings.put(_disciplineModeKey, on);
    notifyListeners();
  }

  // ── Focus sessions ────────────────────────────────────────────────────────

  List<FocusSession> get focusSessions => _focusBox.values
      .whereType<Map>()
      .map((m) => FocusSession.fromJson(Map<String, dynamic>.from(m)))
      .toList()
    ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

  int get focusMinutesTotal => focusSessions.fold<int>(
        0,
        (a, s) => a + s.durationSeconds,
      ) ~/
      60;

  int get focusMinutesToday {
    final key = DateX.todayKey();
    return focusSessions
            .where((s) => DateX.dayKey(s.startedAt) == key)
            .fold<int>(0, (a, s) => a + s.durationSeconds) ~/
        60;
  }

  Future<void> recordFocusSession({
    required Duration completed,
    required Duration planned,
    required bool completedFully,
  }) async {
    final s = FocusSession(
      id: _uuid.v4(),
      startedAt: DateTime.now().subtract(completed),
      durationSeconds: completed.inSeconds,
      plannedSeconds: planned.inSeconds,
      completed: completedFully,
    );
    await _focusBox.put(s.id, s.toJson());
    _recomputeStats();
    notifyListeners();
  }

  // ── Social rating ─────────────────────────────────────────────────────────

  List<SocialRating> get socialRatings => _socialBox.values
      .whereType<Map>()
      .map((m) => SocialRating.fromJson(Map<String, dynamic>.from(m)))
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  int? socialRatingForToday() {
    final key = DateX.todayKey();
    for (final r in socialRatings) {
      if (DateX.dayKey(r.date) == key) return r.rating;
    }
    return null;
  }

  Future<void> setSocialRatingToday(int rating) async {
    // 1 entry per day. Use date-key as the storage key so re-saves overwrite.
    final key = DateX.todayKey();
    final entry = SocialRating(date: DateTime.now(), rating: rating);
    await _socialBox.put(key, entry.toJson());
    _recomputeStats();
    notifyListeners();
  }

  int get socialRatingSum =>
      socialRatings.fold<int>(0, (a, r) => a + r.rating);

  // ── Mini-game results ─────────────────────────────────────────────────────

  List<MiniGameResult> get gameResults => _gameBox.values
      .whereType<Map>()
      .map((m) => MiniGameResult.fromJson(Map<String, dynamic>.from(m)))
      .toList()
    ..sort((a, b) => b.playedAt.compareTo(a.playedAt));

  int xpFromGames(MiniGameKind kind) => gameResults
      .where((r) => r.kind == kind)
      .fold<int>(0, (a, r) => a + r.xpEarned);

  Future<void> recordGameResult({
    required MiniGameKind kind,
    required int score,
    required int xp,
  }) async {
    final r = MiniGameResult(
      id: _uuid.v4(),
      kind: kind,
      playedAt: DateTime.now(),
      score: score,
      xpEarned: xp,
    );
    await _gameBox.put(r.id, r.toJson());
    _recomputeStats();
    notifyListeners();
  }

  // ── Recompute (called from proxy provider when sources change) ───────────

  void recompute({
    required StudyController study,
    required HabitController habits,
    required PrayerController prayer,
    required FitnessController fitness,
  }) {
    _studyMinutes = study.sessions
            .fold<int>(0, (a, s) => a + s.durationSeconds) ~/
        60;

    // Habit completions across last 365 days × habits.
    var habitCount = 0;
    var maxHabitStreak = 0;
    for (final h in habits.habits) {
      final s = habits.streak(h.id);
      if (s > maxHabitStreak) maxHabitStreak = s;
      for (int i = 0; i < 365; i++) {
        final day = DateTime.now().subtract(Duration(days: i));
        if (habits.isDone(h.id, day)) habitCount += 1;
      }
    }
    _habitCompletions = habitCount;

    // Prayers across last 365 days × 5 slots.
    var prayerCount = 0;
    var prayerStreak = 0;
    var streakActive = true;
    for (int i = 0; i < 365; i++) {
      final day = DateTime.now().subtract(Duration(days: i));
      var done = 0;
      for (final slot in PrayerSlot.values) {
        if (prayer.isCompleted(slot, day)) {
          prayerCount += 1;
          done += 1;
        }
      }
      if (streakActive) {
        if (done == 5) {
          prayerStreak += 1;
        } else if (i == 0 && done < 5) {
          // today still in progress
        } else {
          streakActive = false;
        }
      }
    }
    _prayerCompletions = prayerCount;

    _workoutMinutes = fitness.sessions
            .fold<int>(0, (a, s) => a + s.totalDurationSeconds) ~/
        60;
    _workoutSessions = fitness.sessions.length;

    final streaks = <int>[
      study.currentStreak(),
      maxHabitStreak,
      prayerStreak,
      fitness.currentWorkoutStreak(),
    ];
    _bestStreak = streaks.fold<int>(0, (a, b) => b > a ? b : a);

    _recomputeStats();
    notifyListeners();
  }

  void _recomputeStats() {
    final digitSpanXp = xpFromGames(MiniGameKind.digitSpan);
    final reactionTimeXp = xpFromGames(MiniGameKind.reactionTime);
    final stroopXp = xpFromGames(MiniGameKind.stroop);

    _statXp = {
      CharacterStat.intelligence:
          _studyMinutes * 1 + digitSpanXp + stroopXp,
      CharacterStat.discipline:
          _habitCompletions * 5 + _prayerCompletions * 4,
      CharacterStat.strength:
          _workoutMinutes * 2 + _workoutSessions * 30,
      CharacterStat.focus: focusMinutesTotal * 2 + reactionTimeXp,
      CharacterStat.consistency: _bestStreak * 10,
      CharacterStat.social: socialRatingSum * 5,
    };
  }
}
