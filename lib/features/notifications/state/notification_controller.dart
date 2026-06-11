import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../../core/storage/hive_setup.dart';
import '../../prayer/state/prayer_controller.dart';
import '../models/notification_settings.dart';
import '../service/notification_service.dart';

/// IDs are partitioned by category so reschedules can cancel/replace without
/// stomping on other categories.
///
/// 1000-1099: prayer — 1000 + dayOffset*10 + slot.index*2 (at-time), +1 (heads-up).
///            Supports up to 10 days × 5 slots × 2 notifications.
/// 2000-2009: study daily
/// 3000-3099: water (one per slot in the day)
/// 4000-4009: streak end-of-day
/// 9000-9099: test
class _NotifIds {
  static int prayerAt(int dayOffset, PrayerSlot s) =>
      1000 + dayOffset * 10 + s.index * 2;
  static int prayerHeadsUp(int dayOffset, PrayerSlot s) =>
      1001 + dayOffset * 10 + s.index * 2;
  static const int studyDaily = 2000;
  static int waterSlot(int i) => 3000 + i;
  static const int streakEod = 4000;
  static const int test = 9000;
}

class NotificationController extends ChangeNotifier {
  static const _key = 'settings_v1';
  final Box _box = Hive.box(HiveBoxes.notifications);
  final NotificationService _svc = NotificationService.instance;

  NotificationSettings _settings = NotificationSettings.defaults();
  NotificationSettings get settings => _settings;

  bool _initialized = false;

  /// When true, all scheduled notifications use the Discipline tone regardless
  /// of the user-chosen `_settings.tone`. Toggled by Ayanokoji discipline mode.
  bool _disciplineOverride = false;
  int _lastPrayerVersion = -1;
  Map<DateTime, Map<PrayerSlot, DateTime>>? _lastPrayerByDay;

  NotificationTone get _effectiveTone =>
      _disciplineOverride ? NotificationTone.discipline : _settings.tone;

  /// Called from the provider proxy with the current discipline-mode state.
  /// Cheaply guarded by [prayerVersion] so we only do work when prayer cache
  /// or discipline mode actually changed.
  Future<void> applyContext({
    required Map<DateTime, Map<PrayerSlot, DateTime>> prayerTimesByDay,
    required int prayerVersion,
    required bool disciplineMode,
  }) async {
    final overrideChanged = _disciplineOverride != disciplineMode;
    final versionChanged = _lastPrayerVersion != prayerVersion;
    _disciplineOverride = disciplineMode;
    _lastPrayerVersion = prayerVersion;
    _lastPrayerByDay = prayerTimesByDay;
    if (overrideChanged || versionChanged) {
      await reschedule(prayerTimesByDay: prayerTimesByDay);
    }
  }

  NotificationController() {
    final raw = _box.get(_key);
    if (raw is Map) {
      try {
        _settings = NotificationSettings.fromJson(
          Map<String, dynamic>.from(raw),
        );
      } catch (_) {
        _settings = NotificationSettings.defaults();
      }
    }
  }

  /// Plugin init only — does NOT request perms. requestExactAlarmsPermission
  /// launches a Settings activity on Android 14+, which would background the
  /// app mid-await and cause callers (showNow / fireTest) to never resolve.
  /// Perms are requested separately: POST_NOTIFICATIONS at boot,
  /// SCHEDULE_EXACT_ALARM lazily by [_ensureExactAlarmsPermission].
  Future<void> ensureInitialized() async {
    if (_initialized) return;
    await _svc.init();
    _initialized = true;
  }

  bool _exactAlarmsRequested = false;
  Future<void> _ensureExactAlarmsPermission() async {
    if (_exactAlarmsRequested) return;
    _exactAlarmsRequested = true;
    await _svc.requestExactAlarmsOnly();
  }

  Future<void> update(
    NotificationSettings next, {
    Map<PrayerSlot, DateTime>? prayerTimes,
    Map<DateTime, Map<PrayerSlot, DateTime>>? prayerTimesByDay,
  }) async {
    _settings = next;
    await _box.put(_key, next.toJson());
    notifyListeners();
    final multiDay = prayerTimesByDay ??
        _lastPrayerByDay ??
        (prayerTimes != null
            ? {DateTime.now(): prayerTimes}
            : <DateTime, Map<PrayerSlot, DateTime>>{});
    await reschedule(prayerTimesByDay: multiDay);
  }

  Future<void> reschedule({
    Map<DateTime, Map<PrayerSlot, DateTime>>? prayerTimesByDay,
  }) async {
    if (!_initialized) await ensureInitialized();

    final s = _settings;
    final tone = _effectiveTone;
    final byDay = prayerTimesByDay ?? _lastPrayerByDay ?? const {};

    // Request SCHEDULE_EXACT_ALARM only when we are about to schedule something.
    // This is the right moment: user has just enabled a reminder, so the
    // Settings page bounce is expected, not jarring at boot.
    final wantsSchedule = (s.prayerOn && byDay.isNotEmpty) ||
        s.studyOn || s.waterOn || s.streakOn;
    if (wantsSchedule) {
      unawaited(_ensureExactAlarmsPermission());
    }

    await _svc.cancelAll();

    if (s.prayerOn && byDay.isNotEmpty) {
      await _scheduleAllPrayers(byDay, tone);
    }
    if (s.studyOn) {
      await _svc.scheduleDaily(
        id: _NotifIds.studyDaily,
        channel: NotificationChannels.study,
        hour: s.studyHour,
        minute: s.studyMinute,
        title: _copy(tone, _Pack.study).title,
        body: _copy(tone, _Pack.study).body,
        tone: tone,
      );
    }
    if (s.waterOn) {
      await _scheduleWater(s, tone);
    }
    if (s.streakOn) {
      await _svc.scheduleDaily(
        id: _NotifIds.streakEod,
        channel: NotificationChannels.streak,
        hour: s.streakHour,
        minute: s.streakMinute,
        title: _copy(tone, _Pack.streak).title,
        body: _copy(tone, _Pack.streak).body,
        tone: tone,
      );
    }
  }

  Future<void> _scheduleAllPrayers(
    Map<DateTime, Map<PrayerSlot, DateTime>> byDay,
    NotificationTone tone,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sortedDays = byDay.keys.toList()..sort();
    for (final day in sortedDays) {
      final normalized = DateTime(day.year, day.month, day.day);
      final dayOffset = normalized.difference(today).inDays;
      // Days that have already passed take ID space we can't safely reuse.
      // Days more than 9 ahead overflow our 10-slot-per-day partition.
      if (dayOffset < 0 || dayOffset > 9) continue;
      final times = byDay[day];
      if (times == null) continue;
      for (final slot in PrayerSlot.values) {
        final at = times[slot];
        if (at == null) continue;
        final headsUp = at.subtract(const Duration(minutes: 10));
        final atCopy = _prayerCopy(slot, at, tone, atTime: true);
        final huCopy = _prayerCopy(slot, at, tone, atTime: false);

        await _svc.scheduleAt(
          id: _NotifIds.prayerHeadsUp(dayOffset, slot),
          channel: NotificationChannels.prayer,
          when: headsUp,
          title: huCopy.title,
          body: huCopy.body,
          tone: tone,
        );
        await _svc.scheduleAt(
          id: _NotifIds.prayerAt(dayOffset, slot),
          channel: NotificationChannels.prayer,
          when: at,
          title: atCopy.title,
          body: atCopy.body,
          tone: tone,
        );
      }
    }
  }

  Future<void> _scheduleWater(
    NotificationSettings s,
    NotificationTone tone,
  ) async {
    final start = s.waterStartHour;
    final end = s.waterEndHour;
    if (end <= start) return;
    final step = Duration(seconds: s.waterEverySeconds);
    final firstSlot = DateTime.now().copyWith(
      hour: start,
      minute: 0,
      second: 0,
      millisecond: 0,
      microsecond: 0,
    );
    final endSlot = DateTime.now().copyWith(
      hour: end,
      minute: 0,
      second: 0,
      millisecond: 0,
      microsecond: 0,
    );

    var i = 0;
    var when = firstSlot;
    while (!when.isAfter(endSlot) && i < 100) {
      // For inexact-once-at-this-time we schedule a daily for that hour:minute
      await _svc.scheduleDaily(
        id: _NotifIds.waterSlot(i),
        channel: NotificationChannels.water,
        hour: when.hour,
        minute: when.minute,
        title: _copy(tone, _Pack.water).title,
        body: _copy(tone, _Pack.water).body,
        tone: tone,
      );
      i += 1;
      when = when.add(step);
    }
  }

  Future<int> pendingCount() async {
    if (!_initialized) await ensureInitialized();
    final list = await _svc.pending();
    return list.length;
  }

  Future<void> fireTest() async {
    if (!_initialized) await ensureInitialized();
    await _svc.showNow(
      id: _NotifIds.test,
      channel: NotificationChannels.test,
      title: _copy(_settings.tone, _Pack.test).title,
      body: _copy(_settings.tone, _Pack.test).body,
      tone: _settings.tone,
    );
  }
}

enum _Pack { study, water, streak, test }

class _Copy {
  final String title;
  final String body;
  const _Copy(this.title, this.body);
}

_Copy _copy(NotificationTone tone, _Pack p) {
  switch (tone) {
    case NotificationTone.silent:
      switch (p) {
        case _Pack.study:
          return const _Copy('Study reminder', 'Time set aside for study.');
        case _Pack.water:
          return const _Copy('Water', 'A small reminder to drink water.');
        case _Pack.streak:
          return const _Copy(
            'End of day',
            'Habit checklist still has open items.',
          );
        case _Pack.test:
          return const _Copy('Test', 'This is a silent test notification.');
      }
    case NotificationTone.motivational:
      switch (p) {
        case _Pack.study:
          return const _Copy(
            'Time to study',
            'Five focused hours start with one. Open the timer.',
          );
        case _Pack.water:
          return const _Copy('Hydrate', 'Drink a glass of water. You\'ve got this.');
        case _Pack.streak:
          return const _Copy(
            'Don\'t break your streak',
            'A few habits are still open. Close them out before bed.',
          );
        case _Pack.test:
          return const _Copy('You\'re ready', 'This is a test notification.');
      }
    case NotificationTone.discipline:
      switch (p) {
        case _Pack.study:
          return const _Copy('Open the book.', 'No excuses. Start the timer.');
        case _Pack.water:
          return const _Copy('Drink. Now.', 'Discipline starts in the body.');
        case _Pack.streak:
          return const _Copy(
            'Finish the day.',
            'You don\'t leave habits unfinished. Move.',
          );
        case _Pack.test:
          return const _Copy('Test fired.', 'Discipline mode is live.');
      }
  }
}

_Copy _prayerCopy(
  PrayerSlot slot,
  DateTime day,
  NotificationTone tone, {
  required bool atTime,
}) {
  final name = slot.labelOn(day);
  switch (tone) {
    case NotificationTone.silent:
      return atTime
          ? _Copy(name, '$name prayer time.')
          : _Copy('$name in 10 min', '$name prayer is in 10 minutes.');
    case NotificationTone.motivational:
      return atTime
          ? _Copy('$name time', 'It is time for $name. Be present.')
          : _Copy(
              '$name in 10 minutes',
              'Wind down what you\'re doing. $name is in 10.',
            );
    case NotificationTone.discipline:
      return atTime
          ? _Copy('$name. Now.', 'Pray $name. No delay.')
          : _Copy(
              '$name in 10.',
              'Ten minutes. Close the laptop. Walk to the prayer mat.',
            );
  }
}
