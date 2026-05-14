import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';

import '../../../core/storage/hive_setup.dart';
import '../../../core/utils/date_utils.dart';

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

  PrayerTimes? _times;
  PrayerTimes? get times => _times;

  double? _lat;
  double? _lng;
  String? _locationError;
  String? get locationError => _locationError;

  bool _loading = false;
  bool get loading => _loading;

  PrayerController({double? lat, double? lng}) {
    if (lat != null && lng != null) {
      setLocation(lat, lng);
    }
  }

  void setLocation(double lat, double lng) {
    _lat = lat;
    _lng = lng;
    _locationError = null;
    _recompute();
  }

  Future<void> fetchLocation() async {
    _loading = true;
    _locationError = null;
    notifyListeners();
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        _locationError = 'Location services are disabled.';
        _loading = false;
        notifyListeners();
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _locationError = 'Location permission denied.';
        _loading = false;
        notifyListeners();
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      setLocation(pos.latitude, pos.longitude);
    } catch (e) {
      _locationError = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void _recompute() {
    if (_lat == null || _lng == null) {
      _times = null;
      notifyListeners();
      return;
    }
    final coords = Coordinates(_lat!, _lng!);
    final params = CalculationMethod.karachi.getParameters();
    params.madhab = Madhab.hanafi;
    _times = PrayerTimes.today(coords, params);
    notifyListeners();
  }

  DateTime? timeOf(PrayerSlot slot) {
    final t = _times;
    if (t == null) return null;
    switch (slot) {
      case PrayerSlot.fajr:
        return t.fajr;
      case PrayerSlot.dhuhr:
        return t.dhuhr;
      case PrayerSlot.asr:
        return t.asr;
      case PrayerSlot.maghrib:
        return t.maghrib;
      case PrayerSlot.isha:
        return t.isha;
    }
  }

  String _key(PrayerSlot slot, DateTime day) =>
      '${DateX.dayKey(day)}|${slot.name}';

  bool isCompleted(PrayerSlot slot, [DateTime? day]) {
    return (_box.get(_key(slot, day ?? DateTime.now())) as bool?) ?? false;
  }

  Future<void> toggle(PrayerSlot slot, [DateTime? day]) async {
    final key = _key(slot, day ?? DateTime.now());
    final current = (_box.get(key) as bool?) ?? false;
    if (current) {
      await _box.delete(key);
    } else {
      await _box.put(key, true);
    }
    notifyListeners();
  }

  int completedToday() {
    return PrayerSlot.values.where((s) => isCompleted(s)).length;
  }

  PrayerSlot? nextSlot() {
    final now = DateTime.now();
    for (final s in PrayerSlot.values) {
      final t = timeOf(s);
      if (t != null && t.isAfter(now)) return s;
    }
    return null;
  }
}
