import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/hive_setup.dart';
import '../../../core/utils/date_utils.dart';
import '../models/habit.dart';

class HabitController extends ChangeNotifier {
  static const _uuid = Uuid();
  final Box _habits = Hive.box(HiveBoxes.habits);
  final Box _logs = Hive.box(HiveBoxes.habitLogs);

  List<Habit> _list = [];
  List<Habit> get habits => List.unmodifiable(_list);

  HabitController() {
    _load();
    if (_list.isEmpty) {
      _seedDefaults();
    }
  }

  void _load() {
    _list = _habits.values
        .whereType<Map>()
        .map((m) => Habit.fromJson(Map<String, dynamic>.from(m)))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> _seedDefaults() async {
    final now = DateTime.now();
    final defaults = <Habit>[
      Habit(id: _uuid.v4(), name: 'Drink water', icon: 'water_drop', negative: false, createdAt: now),
      Habit(id: _uuid.v4(), name: 'Read', icon: 'menu_book', negative: false, createdAt: now),
      Habit(id: _uuid.v4(), name: 'Meditation', icon: 'self_improvement', negative: false, createdAt: now),
      Habit(id: _uuid.v4(), name: 'Journaling', icon: 'edit_note', negative: false, createdAt: now),
      Habit(id: _uuid.v4(), name: 'Sleep on time', icon: 'bedtime', negative: false, createdAt: now),
      Habit(id: _uuid.v4(), name: 'No social media', icon: 'do_not_disturb_on', negative: true, createdAt: now),
      Habit(id: _uuid.v4(), name: 'No NSFW content', icon: 'shield_moon', negative: true, createdAt: now),
    ];
    for (final h in defaults) {
      await _habits.put(h.id, h.toJson());
    }
    _list = defaults;
    notifyListeners();
  }

  Future<Habit> add({required String name, String icon = 'check_circle', bool negative = false}) async {
    final h = Habit(
      id: _uuid.v4(),
      name: name.trim(),
      icon: icon,
      negative: negative,
      createdAt: DateTime.now(),
    );
    await _habits.put(h.id, h.toJson());
    _list.add(h);
    notifyListeners();
    return h;
  }

  Future<void> remove(String id) async {
    await _habits.delete(id);
    final keys = _logs.keys.where((k) => k.toString().startsWith('$id|')).toList();
    for (final k in keys) {
      await _logs.delete(k);
    }
    _list.removeWhere((h) => h.id == id);
    notifyListeners();
  }

  String _logKey(String habitId, DateTime day) => '$habitId|${DateX.dayKey(day)}';

  bool isDone(String habitId, DateTime day) {
    return (_logs.get(_logKey(habitId, day)) as bool?) ?? false;
  }

  Future<void> toggle(String habitId, DateTime day) async {
    final key = _logKey(habitId, day);
    final current = (_logs.get(key) as bool?) ?? false;
    if (current) {
      await _logs.delete(key);
    } else {
      await _logs.put(key, true);
    }
    notifyListeners();
  }

  int streak(String habitId) {
    int s = 0;
    var d = DateTime.now();
    while (isDone(habitId, d)) {
      s += 1;
      d = d.subtract(const Duration(days: 1));
    }
    return s;
  }

  int doneTodayCount() {
    final today = DateTime.now();
    return _list.where((h) => isDone(h.id, today)).length;
  }

  double monthSuccessRate(String habitId) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    int done = 0;
    int counted = 0;
    for (int i = 1; i <= daysInMonth; i++) {
      final d = DateTime(now.year, now.month, i);
      if (d.isAfter(now)) break;
      counted += 1;
      if (isDone(habitId, d)) done += 1;
    }
    if (counted == 0) return 0;
    return done / counted;
  }

  void reload() {
    _load();
    if (_list.isEmpty) {
      _seedDefaults();
    } else {
      notifyListeners();
    }
  }
}
