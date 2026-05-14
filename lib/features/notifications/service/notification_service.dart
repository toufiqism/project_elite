import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

enum NotificationTone { silent, motivational, discipline }

class NotificationChannels {
  static const prayer = ('elite_prayer', 'Prayer reminders');
  static const study = ('elite_study', 'Study reminders');
  static const water = ('elite_water', 'Water reminders');
  static const streak = ('elite_streak', 'Streak reminders');
  static const test = ('elite_test', 'Test notifications');

  static const all = [prayer, study, water, streak, test];
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

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _ready = true;
  }

  Future<bool> requestPermissions() async {
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
    await _plugin.show(id, title, body, _details(channel, tone));
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
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
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
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
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
