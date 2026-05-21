import 'dart:convert';

import 'package:http/http.dart' as http;

import '../state/prayer_controller.dart';

class AladhanService {
  static const _base = 'https://api.aladhan.com/v1';
  // Method 1 = University of Islamic Sciences, Karachi
  static const _method = '1';

  static Future<Map<PrayerSlot, DateTime>> fetchTimings(
    String address,
    DateTime date,
  ) async {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final uri =
        Uri.parse('$_base/timingsByAddress/$day-$month-${date.year}').replace(
      queryParameters: {'address': address, 'method': _method},
    );

    final res = await http.get(uri).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) {
      throw Exception('AlAdhan API returned ${res.statusCode}');
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if ((body['code'] as int?) != 200) {
      throw Exception(body['status'] ?? 'Unknown AlAdhan error');
    }

    final timings =
        (body['data']['timings'] as Map<String, dynamic>);
    return _parse(timings, date);
  }

  /// Fetches a calendar month at once — far cheaper than N day-by-day calls.
  /// Returns a map keyed by day-of-month (1..31) → prayer times for that day.
  /// Used to seed the multi-day notification window without N HTTP requests.
  static Future<Map<int, Map<PrayerSlot, DateTime>>> fetchMonth(
    String address,
    int year,
    int month,
  ) async {
    final uri =
        Uri.parse('$_base/calendarByAddress/$year/$month').replace(
      queryParameters: {'address': address, 'method': _method},
    );
    final res = await http.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw Exception('AlAdhan API returned ${res.statusCode}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if ((body['code'] as int?) != 200) {
      throw Exception(body['status'] ?? 'Unknown AlAdhan error');
    }
    final days = body['data'] as List<dynamic>;
    final result = <int, Map<PrayerSlot, DateTime>>{};
    for (final entry in days) {
      final d = entry as Map<String, dynamic>;
      final dateMeta = d['date'] as Map<String, dynamic>;
      final gregorian = dateMeta['gregorian'] as Map<String, dynamic>;
      final dayOfMonth = int.parse(gregorian['day'] as String);
      final dateForDay = DateTime(year, month, dayOfMonth);
      final timings = d['timings'] as Map<String, dynamic>;
      result[dayOfMonth] = _parse(timings, dateForDay);
    }
    return result;
  }

  static Map<PrayerSlot, DateTime> _parse(
    Map<String, dynamic> t,
    DateTime date,
  ) {
    DateTime toDateTime(String hhmm) {
      // AlAdhan may return "04:39 (UTC+6)" — take only the HH:MM part
      final clean = hhmm.split(' ').first;
      final parts = clean.split(':');
      return DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
    }

    // On Fridays, prefer AlAdhan's `Jumua` field if present — some calculation
    // methods return a dedicated Jummah time that differs from Dhuhr. With
    // method=1 (Karachi) it isn't returned, so we fall back to Dhuhr, which is
    // the canonical Jummah time anyway.
    final isFriday = date.weekday == DateTime.friday;
    final dhuhrRaw = (isFriday ? t['Jumua'] : null) ?? t['Dhuhr'];

    return {
      PrayerSlot.fajr: toDateTime(t['Fajr'] as String),
      PrayerSlot.dhuhr: toDateTime(dhuhrRaw as String),
      PrayerSlot.asr: toDateTime(t['Asr'] as String),
      PrayerSlot.maghrib: toDateTime(t['Maghrib'] as String),
      PrayerSlot.isha: toDateTime(t['Isha'] as String),
    };
  }
}
