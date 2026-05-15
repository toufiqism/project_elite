import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../../core/storage/hive_setup.dart';
import '../../../core/utils/date_utils.dart';
import '../service/aladhan_service.dart';

enum PrayerSlot { fajr, dhuhr, asr, maghrib, isha }

extension PrayerSlotX on PrayerSlot {
  String get label {
    switch (this) {
      case PrayerSlot.fajr:
        return 'Fajr';
      case PrayerSlot.dhuhr:
        return 'Dhuhr';
      case PrayerSlot.asr:
        return 'Asr';
      case PrayerSlot.maghrib:
        return 'Maghrib';
      case PrayerSlot.isha:
        return 'Isha';
    }
  }
}

class PrayerController extends ChangeNotifier {
  final Box _box = Hive.box(HiveBoxes.prayer);

  /// Effective times for today (API base + any user overrides applied).
  Map<PrayerSlot, DateTime>? _times;
  Map<PrayerSlot, DateTime>? get times => _times;

  String? _address;
  String? get address => _address;

  String? _locationError;
  String? get locationError => _locationError;

  bool _loading = false;
  bool get loading => _loading;

  PrayerController({String? address}) {
    if (address != null && address.isNotEmpty) {
      _address = address;
      _loadCached(); // Show cached times immediately, no network flash
    }
  }

  // ── Address management ──────────────────────────────────────────────────────

  /// Called from the ProxyProvider when the profile's prayer address changes.
  void setAddress(String? address) {
    if (address == _address) return;
    _address = address;
    _locationError = null;
    if (address != null && address.isNotEmpty) {
      _loadCached();
    } else {
      _times = null;
      notifyListeners();
    }
  }

  /// Fetch fresh times from the AlAdhan API, cache result, and update state.
  Future<void> fetchByAddress(String address) async {
    _address = address;
    _loading = true;
    _locationError = null;
    notifyListeners();
    try {
      final today = DateTime.now();
      final fetched = await AladhanService.fetchTimings(address, today);
      await _box.put(_cacheKey(today), _toStorable(fetched));
      _times = _withOverrides(fetched, today);
    } catch (e) {
      _locationError = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Manual overrides ────────────────────────────────────────────────────────

  /// Set a user-chosen time for a prayer slot today.
  Future<void> setOverride(PrayerSlot slot, DateTime time) async {
    final hhmm =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    await _box.put(_overrideKey(slot, DateTime.now()), hhmm);
    _reapplyOverrides();
  }

  /// Remove user override for a slot (reverts to API value).
  Future<void> clearOverride(PrayerSlot slot) async {
    await _box.delete(_overrideKey(slot, DateTime.now()));
    _reapplyOverrides();
  }

  bool hasOverride(PrayerSlot slot) =>
      _box.containsKey(_overrideKey(slot, DateTime.now()));

  // ── Completion tracking ─────────────────────────────────────────────────────

  bool isCompleted(PrayerSlot slot, [DateTime? day]) =>
      (_box.get(_completionKey(slot, day ?? DateTime.now())) as bool?) ?? false;

  Future<void> toggle(PrayerSlot slot, [DateTime? day]) async {
    final key = _completionKey(slot, day ?? DateTime.now());
    final current = (_box.get(key) as bool?) ?? false;
    if (current) {
      await _box.delete(key);
    } else {
      await _box.put(key, true);
    }
    notifyListeners();
  }

  int completedToday() =>
      PrayerSlot.values.where((s) => isCompleted(s)).length;

  PrayerSlot? nextSlot() {
    final now = DateTime.now();
    for (final s in PrayerSlot.values) {
      final t = timeOf(s);
      if (t != null && t.isAfter(now)) return s;
    }
    return null;
  }

  DateTime? timeOf(PrayerSlot slot) => _times?[slot];

  // ── Private helpers ─────────────────────────────────────────────────────────

  String _cacheKey(DateTime day) => 'cache|${DateX.dayKey(day)}';
  String _overrideKey(PrayerSlot slot, DateTime day) =>
      'override|${DateX.dayKey(day)}|${slot.name}';
  String _completionKey(PrayerSlot slot, DateTime day) =>
      '${DateX.dayKey(day)}|${slot.name}';

  void _loadCached() {
    final raw = _box.get(_cacheKey(DateTime.now()));
    if (raw is Map) {
      final base = _fromStorable(Map<String, dynamic>.from(raw), DateTime.now());
      _times = _withOverrides(base, DateTime.now());
      notifyListeners();
    }
  }

  void _reapplyOverrides() {
    final raw = _box.get(_cacheKey(DateTime.now()));
    if (raw is Map) {
      final base = _fromStorable(Map<String, dynamic>.from(raw), DateTime.now());
      _times = _withOverrides(base, DateTime.now());
      notifyListeners();
    }
  }

  Map<PrayerSlot, DateTime> _withOverrides(
    Map<PrayerSlot, DateTime> base,
    DateTime day,
  ) {
    final result = Map<PrayerSlot, DateTime>.from(base);
    for (final slot in PrayerSlot.values) {
      final hhmm = _box.get(_overrideKey(slot, day)) as String?;
      if (hhmm != null) {
        final parts = hhmm.split(':');
        result[slot] = DateTime(
          day.year,
          day.month,
          day.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
      }
    }
    return result;
  }

  static Map<String, String> _toStorable(Map<PrayerSlot, DateTime> times) =>
      times.map(
        (slot, dt) => MapEntry(
          slot.name,
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
        ),
      );

  static Map<PrayerSlot, DateTime> _fromStorable(
    Map<String, dynamic> raw,
    DateTime day,
  ) {
    final result = <PrayerSlot, DateTime>{};
    for (final slot in PrayerSlot.values) {
      final hhmm = raw[slot.name] as String?;
      if (hhmm != null) {
        final parts = hhmm.split(':');
        result[slot] = DateTime(
          day.year,
          day.month,
          day.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
      }
    }
    return result;
  }
}
