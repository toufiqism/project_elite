import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

enum NotificationTone { silent, motivational, discipline }

class NotificationChannels {
  static const prayer = ('elite_prayer', 'Prayer reminders');
  static const study = ('elite_study', 'Study reminders');
  static const water = ('elite_water', 'Water reminders');
  static const walk = ('elite_walk', 'Walk reminders');
  static const streak = ('elite_streak', 'Streak reminders');
  static const test = ('elite_test', 'Test notifications');

  static const all = [prayer, study, water, walk, streak, test];
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      // Fall back to UTC if the platform call fails. Schedules still work.
    }

    // Status-bar icon MUST be a white-on-transparent silhouette per Android
    // guidelines; colored mipmap icons get rendered as a solid white square.
    // NB: pass the bare drawable name — the '@drawable/' prefix makes the
    // plugin's getIdentifier lookup fail with invalid_icon, which throws inside
    // initialize() and leaves the whole notification subsystem dead.
    const android = AndroidInitializationSettings('ic_stat_notification');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      // Show notifications while the app is in the foreground.
      // Without these, iOS silently drops banners when the app is open.
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
      defaultPresentBanner: true,
      defaultPresentList: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _ready = true;
  }

  /// POST_NOTIFICATIONS (Android 13+) / iOS alert+badge+sound. Cheap, just a
  /// system dialog. Safe to call at boot — does NOT open Settings.
  Future<bool> requestNotificationsOnly() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    var ok = true;
    if (android != null) {
      final n = await android.requestNotificationsPermission();
      ok = n ?? ok;
    }
    if (ios != null) {
      final n = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      ok = n ?? ok;
    }
    return ok;
  }

  /// SCHEDULE_EXACT_ALARM only. Launches a system Settings page on Android 14+,
  /// so the awaiting coroutine pauses until the activity returns. Callers must
  /// not gate critical code (showNow, schedules) on this completing.
  Future<void> requestExactAlarmsOnly() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.requestExactAlarmsPermission();
    }
  }

  Future<bool> requestPermissions() async {
    final ok = await requestNotificationsOnly();
    await requestExactAlarmsOnly();
    return ok;
  }

  /// True if the OS will exempt this app from Doze / battery optimization.
  /// Returns true on iOS (concept doesn't apply).
  Future<bool> isIgnoringBatteryOptimizations() async {
    final status = await Permission.ignoreBatteryOptimizations.status;
    return status.isGranted;
  }

  /// Asks the OS to exempt this app from battery optimization. On Android this
  /// opens the system dialog; on aggressive OEMs (Xiaomi, OPPO, Huawei) this
  /// is the difference between alarms firing and the app being killed.
  Future<bool> requestIgnoreBatteryOptimizations() async {
    final status = await Permission.ignoreBatteryOptimizations.request();
    return status.isGranted;
  }

  NotificationDetails _details(
    (String, String) channel,
    NotificationTone tone,
  ) {
    final importance = switch (tone) {
      NotificationTone.silent => Importance.low,
      NotificationTone.motivational => Importance.high,
      NotificationTone.discipline => Importance.max,
    };
    final priority = switch (tone) {
      NotificationTone.silent => Priority.low,
      NotificationTone.motivational => Priority.high,
      NotificationTone.discipline => Priority.max,
    };
    final playSound = tone != NotificationTone.silent;
    final enableVibration = tone != NotificationTone.silent;

    final androidDetails = AndroidNotificationDetails(
      channel.$1,
      channel.$2,
      importance: importance,
      priority: priority,
      playSound: playSound,
      enableVibration: enableVibration,
      category: AndroidNotificationCategory.reminder,
      icon: 'ic_stat_notification',
      color: const Color(0xFFE7C77B),
    );
    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: playSound,
      interruptionLevel: tone == NotificationTone.discipline
          ? InterruptionLevel.timeSensitive
          : InterruptionLevel.active,
    );
    return NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  Future<void> showNow({
    required int id,
    required (String, String) channel,
    required String title,
    required String body,
    required NotificationTone tone,
  }) async {
    if (!_ready) await init();
    await _plugin.show(id, title, body, _details(channel, tone));
  }

  /// Picks exact scheduling when the user has granted SCHEDULE_EXACT_ALARM,
  /// otherwise falls back to inexact. Using exactAllowWhileIdle without the
  /// grant throws PlatformException(exact_alarms_not_permitted) on Android 14+,
  /// which would abort the whole reschedule and leave nothing queued.
  Future<AndroidScheduleMode> _scheduleMode() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return AndroidScheduleMode.exactAllowWhileIdle;
    final canExact = await android.canScheduleExactNotifications() ?? false;
    return canExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  Future<void> scheduleAt({
    required int id,
    required (String, String) channel,
    required DateTime when,
    required String title,
    required String body,
    required NotificationTone tone,
  }) async {
    final scheduled = tz.TZDateTime.from(when, tz.local);
    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      _details(channel, tone),
      androidScheduleMode: await _scheduleMode(),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleDaily({
    required int id,
    required (String, String) channel,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required NotificationTone tone,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!when.isAfter(now)) {
      when = when.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      when,
      _details(channel, tone),
      androidScheduleMode: await _scheduleMode(),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelAll() async => _plugin.cancelAll();
  Future<void> cancel(int id) async => _plugin.cancel(id);
  Future<List<PendingNotificationRequest>> pending() =>
      _plugin.pendingNotificationRequests();
}
