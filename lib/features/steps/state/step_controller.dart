import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/storage/hive_setup.dart';
import '../../../core/utils/date_utils.dart';

/// Counts daily steps from the hardware STEP_COUNTER sensor (via `pedometer`).
///
/// The sensor only reports a value cumulative-since-boot, so we reconcile by
/// delta-accumulation: each event's positive delta over the last seen reading
/// is added to today's tally in the [HiveBoxes.stepLog] box (keyed by day).
/// A negative delta means the counter reset (device reboot) and is treated as
/// "start fresh from the new reading". Because the hardware keeps counting
/// while the app is closed, the first reading after a cold start captures the
/// background steps accrued since the last reading (attributed to the current
/// day — a reboot or a midnight-while-closed window can lose/misattribute a
/// slice, which is an accepted tradeoff of the sensor-only approach).
class StepController extends ChangeNotifier {
  static const _lastCumulativeKey = 'step_last_cumulative';
  // Guards against absurd jumps (sensor glitch / first-boot huge value being
  // mis-attributed): ignore any single delta larger than this.
  static const _maxPlausibleDelta = 60000;

  final Box _settings = Hive.box(HiveBoxes.settings);
  final Box _stepLog = Hive.box(HiveBoxes.stepLog);

  StreamSubscription<StepCount>? _sub;

  // True once the sensor has delivered at least one reading. False if the
  // permission is denied or the device has no step sensor.
  bool _available = false;
  bool get available => _available;

  StepController() {
    _initIfAlreadyGranted();
  }

  // ── Reads ──────────────────────────────────────────────────────────────────

  int stepsForDay(DateTime day) =>
      (_stepLog.get(DateX.dayKey(day)) as num?)?.toInt() ?? 0;

  int get todaySteps => stepsForDay(DateTime.now());

  /// Steps for each of the last 7 calendar days, oldest first.
  List<int> get last7DaySteps =>
      DateX.last7Days().map(stepsForDay).toList();

  /// All-time step total across every recorded day. Feeds strength XP.
  int get allTimeSteps => _stepLog.values
      .whereType<num>()
      .fold<int>(0, (a, v) => a + v.toInt());

  // ── Permission + stream lifecycle ───────────────────────────────────────────

  /// Subscribe silently if the permission was already granted in a prior run
  /// (existing users / returning sessions). Never prompts.
  Future<void> _initIfAlreadyGranted() async {
    if (await Permission.activityRecognition.isGranted) {
      _subscribe();
    }
  }

  /// Request the runtime permission and start counting. Returns whether the
  /// sensor is now active. Call from onboarding / settings / the steps screen.
  Future<bool> requestAndStart() async {
    final status = await Permission.activityRecognition.request();
    if (!status.isGranted) {
      _available = false;
      notifyListeners();
      return false;
    }
    _subscribe();
    return true;
  }

  void _subscribe() {
    if (_sub != null) return;
    _sub = Pedometer.stepCountStream.listen(
      _onStep,
      onError: _onError,
      cancelOnError: false,
    );
  }

  void _onStep(StepCount event) {
    final cumulative = event.steps;
    final last = (_settings.get(_lastCumulativeKey) as num?)?.toInt();

    if (last == null) {
      // First ever reading: anchor, can't attribute prior steps.
      _settings.put(_lastCumulativeKey, cumulative);
    } else {
      var delta = cumulative - last;
      if (delta < 0) {
        // Counter reset (reboot): the new cumulative is steps-since-boot.
        delta = cumulative;
      }
      if (delta > 0 && delta <= _maxPlausibleDelta) {
        final key = DateX.todayKey();
        final current = (_stepLog.get(key) as num?)?.toInt() ?? 0;
        _stepLog.put(key, current + delta);
      }
      _settings.put(_lastCumulativeKey, cumulative);
    }

    final wasAvailable = _available;
    _available = true;
    if (!wasAvailable) {
      notifyListeners(); // first reading flips availability on
    } else {
      notifyListeners(); // step count changed
    }
  }

  void _onError(Object error) {
    // No step sensor on this device, or the stream died.
    _available = false;
    notifyListeners();
  }

  /// Re-read after an external mutation (e.g. cloud restore clears the box).
  void reload() => notifyListeners();

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
