import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../../core/storage/hive_setup.dart';
import '../../../core/utils/date_utils.dart';

/// Three canonical phrases at 33 each = 99 dhikr after fard prayer.
class TasbihPreset {
  final String label;
  final String arabic;
  final int target;
  const TasbihPreset({
    required this.label,
    required this.arabic,
    required this.target,
  });
}

class TasbihPresets {
  static const subhanallah = TasbihPreset(
    label: "Subhan'Allah",
    arabic: 'سُبْحَانَ اللَّهِ',
    target: 33,
  );
  static const alhamdulillah = TasbihPreset(
    label: 'Alhamdulillah',
    arabic: 'الْحَمْدُ لِلَّهِ',
    target: 33,
  );
  static const allahuakbar = TasbihPreset(
    label: "Allahu Akbar",
    arabic: 'اللَّهُ أَكْبَرُ',
    target: 34,
  );

  static const all = [subhanallah, alhamdulillah, allahuakbar];
}

class TasbihController extends ChangeNotifier {
  final Box _box = Hive.box(HiveBoxes.tasbih);

  /// In-memory state for the active counter screen. Persisted to `_box` per
  /// preset+day so today's count survives backgrounding.
  int currentCount = 0;
  TasbihPreset _activePreset = TasbihPresets.subhanallah;
  TasbihPreset get activePreset => _activePreset;

  TasbihController() {
    currentCount = countFor(_activePreset, DateTime.now());
  }

  String _key(TasbihPreset p, DateTime day) =>
      '${p.label}|${DateX.dayKey(day)}';

  int countFor(TasbihPreset p, DateTime day) =>
      (_box.get(_key(p, day)) as num?)?.toInt() ?? 0;

  int totalAllTime() {
    var total = 0;
    for (final v in _box.values) {
      if (v is num) total += v.toInt();
    }
    return total;
  }

  int todayTotalAcrossPresets() {
    final today = DateTime.now();
    var t = 0;
    for (final p in TasbihPresets.all) {
      t += countFor(p, today);
    }
    return t;
  }

  Future<void> increment() async {
    currentCount += 1;
    await _box.put(_key(_activePreset, DateTime.now()), currentCount);
    notifyListeners();
  }

  Future<void> resetCurrent() async {
    currentCount = 0;
    await _box.put(_key(_activePreset, DateTime.now()), 0);
    notifyListeners();
  }

  void setActive(TasbihPreset p) {
    _activePreset = p;
    currentCount = countFor(p, DateTime.now());
    notifyListeners();
  }

  void reload() {
    currentCount = countFor(_activePreset, DateTime.now());
    notifyListeners();
  }

  /// True once the user has reached the target for the active preset today.
  bool get atOrPastTarget => currentCount >= _activePreset.target;
}
