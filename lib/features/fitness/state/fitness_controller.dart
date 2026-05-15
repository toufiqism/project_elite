import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/hive_setup.dart';
import '../../../core/utils/date_utils.dart';
import '../../profile/models/user_profile.dart';
import '../data/fitness_repository.dart';
import '../models/weight_entry.dart';
import '../models/workout_plan.dart';
import '../models/workout_session.dart';
import '../services/workout_planner.dart';

class FitnessController extends ChangeNotifier {
  static const _uuid = Uuid();

  final FitnessRepository repository;
  final WorkoutPlanner planner;
  final Box _sessionsBox = Hive.box(HiveBoxes.workoutSessions);
  final Box _weightBox = Hive.box(HiveBoxes.weightLog);

  WorkoutPlan? _todayPlan;
  WorkoutPlan? get todayPlan => _todayPlan;

  bool _loading = false;
  bool get loading => _loading;
  String? _planError;
  String? get planError => _planError;

  List<WorkoutSession> _sessions = [];
  List<WorkoutSession> get sessions => List.unmodifiable(_sessions);

  List<WeightEntry> _weights = [];
  List<WeightEntry> get weights => List.unmodifiable(_weights);

  FitnessController({
    FitnessRepository? repository,
    WorkoutPlanner? planner,
  })  : repository = repository ?? FitnessRepository(),
        planner =
            planner ?? WorkoutPlanner(repository ?? FitnessRepository()) {
    _loadHistory();
  }

  bool get hasApiKey => repository.hasApiKey;

  Future<void> setApiKey(String key) async {
    await repository.setApiKey(key);
    notifyListeners();
  }

  void _loadHistory() {
    _sessions = _sessionsBox.values
        .whereType<Map>()
        .map((m) => WorkoutSession.fromJson(Map<String, dynamic>.from(m)))
        .toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

    _weights = _weightBox.values
        .whereType<Map>()
        .map((m) => WeightEntry.fromJson(Map<String, dynamic>.from(m)))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<void> buildTodayPlan(UserProfile profile) async {
    if (_loading) return;
    _loading = true;
    _planError = null;
    notifyListeners();
    try {
      _todayPlan = await planner.planFor(profile: profile);
    } catch (e) {
      _planError = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> saveSession({
    required Duration duration,
    required List<CompletedExercise> exercises,
    required double kcal,
  }) async {
    final s = WorkoutSession(
      id: _uuid.v4(),
      startedAt: DateTime.now().subtract(duration),
      totalDurationSeconds: duration.inSeconds,
      exercises: exercises,
      totalKcal: kcal,
    );
    await _sessionsBox.put(s.id, s.toJson());
    _sessions.insert(0, s);
    notifyListeners();
  }

  Future<void> deleteSession(String id) async {
    await _sessionsBox.delete(id);
    _sessions.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  bool didWorkoutToday() {
    final key = DateX.todayKey();
    return _sessions.any((s) => DateX.dayKey(s.startedAt) == key);
  }

  int currentWorkoutStreak() {
    int streak = 0;
    var day = DateTime.now();
    while (true) {
      final key = DateX.dayKey(day);
      final has = _sessions.any((s) => DateX.dayKey(s.startedAt) == key);
      if (!has) break;
      streak += 1;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Duration totalWorkoutToday() {
    final key = DateX.todayKey();
    final secs = _sessions
        .where((s) => DateX.dayKey(s.startedAt) == key)
        .fold<int>(0, (a, s) => a + s.totalDurationSeconds);
    return Duration(seconds: secs);
  }

  Future<void> logWeight(double kg, {DateTime? on}) async {
    final entry = WeightEntry(
      id: _uuid.v4(),
      date: on ?? DateTime.now(),
      weightKg: kg,
    );
    await _weightBox.put(entry.id, entry.toJson());
    _weights.add(entry);
    _weights.sort((a, b) => a.date.compareTo(b.date));
    notifyListeners();
  }

  Future<void> deleteWeight(String id) async {
    await _weightBox.delete(id);
    _weights.removeWhere((w) => w.id == id);
    notifyListeners();
  }

  double? get latestWeight =>
      _weights.isEmpty ? null : _weights.last.weightKg;

  void reload() {
    _loadHistory();
    notifyListeners();
  }
}
