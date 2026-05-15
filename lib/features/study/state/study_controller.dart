import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/hive_setup.dart';
import '../../../core/utils/date_utils.dart';
import '../models/study_session.dart';

class StudyController extends ChangeNotifier {
  static const _uuid = Uuid();
  final Box _box = Hive.box(HiveBoxes.study);

  List<StudySession> _sessions = [];
  List<StudySession> get sessions => List.unmodifiable(_sessions);

  StudyController() {
    _load();
  }

  void _load() {
    _sessions = _box.values
        .whereType<Map>()
        .map((m) => StudySession.fromJson(Map<String, dynamic>.from(m)))
        .toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
  }

  Future<void> addSession({
    required String subject,
    required DateTime startedAt,
    required Duration duration,
    String? note,
  }) async {
    final s = StudySession(
      id: _uuid.v4(),
      subject: subject,
      startedAt: startedAt,
      durationSeconds: duration.inSeconds,
      note: note,
    );
    await _box.put(s.id, s.toJson());
    _sessions.insert(0, s);
    notifyListeners();
  }

  Future<void> deleteSession(String id) async {
    await _box.delete(id);
    _sessions.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  Duration totalToday() => totalOn(DateTime.now());

  Duration totalOn(DateTime day) {
    final key = DateX.dayKey(day);
    final seconds = _sessions
        .where((s) => DateX.dayKey(s.startedAt) == key)
        .fold<int>(0, (a, s) => a + s.durationSeconds);
    return Duration(seconds: seconds);
  }

  Map<String, Duration> last7DaysTotals() {
    final out = <String, Duration>{};
    for (final d in DateX.last7Days()) {
      out[DateX.dayKey(d)] = totalOn(d);
    }
    return out;
  }

  Map<String, Duration> subjectTotalsThisWeek() {
    final start = DateX.startOfWeek(DateTime.now());
    final out = <String, Duration>{};
    for (final s in _sessions) {
      if (s.startedAt.isBefore(start)) continue;
      out.update(
        s.subject,
        (v) => v + s.duration,
        ifAbsent: () => s.duration,
      );
    }
    return out;
  }

  int currentStreak() {
    int streak = 0;
    var day = DateTime.now();
    while (totalOn(day).inSeconds > 0) {
      streak += 1;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Duration totalThisWeek() {
    final start = DateX.startOfWeek(DateTime.now());
    final seconds = _sessions
        .where((s) => !s.startedAt.isBefore(start))
        .fold<int>(0, (a, s) => a + s.durationSeconds);
    return Duration(seconds: seconds);
  }

  void reload() {
    _load();
    notifyListeners();
  }
}
