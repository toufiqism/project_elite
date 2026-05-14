import 'package:intl/intl.dart';

class DateX {
  static String dayKey(DateTime d) =>
      DateFormat('yyyy-MM-dd').format(DateTime(d.year, d.month, d.day));

  static String todayKey() => dayKey(DateTime.now());

  static DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime startOfWeek(DateTime d) {
    final s = startOfDay(d);
    return s.subtract(Duration(days: s.weekday - 1));
  }

  static List<DateTime> last7Days({DateTime? from}) {
    final base = startOfDay(from ?? DateTime.now());
    return List.generate(7, (i) => base.subtract(Duration(days: 6 - i)));
  }

  static String shortDay(DateTime d) => DateFormat('EEE').format(d);
  static String monthDay(DateTime d) => DateFormat('MMM d').format(d);
  static String prettyTime(DateTime d) => DateFormat('h:mm a').format(d);
}

String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  if (h > 0) {
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }
  if (m > 0) {
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }
  return '${s}s';
}

String formatHms(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  return '${h.toString().padLeft(2, '0')}:'
      '${m.toString().padLeft(2, '0')}:'
      '${s.toString().padLeft(2, '0')}';
}
