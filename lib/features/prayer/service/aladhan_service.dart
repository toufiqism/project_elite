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

    return {
      PrayerSlot.fajr: toDateTime(t['Fajr'] as String),
      PrayerSlot.dhuhr: toDateTime(t['Dhuhr'] as String),
      PrayerSlot.asr: toDateTime(t['Asr'] as String),
      PrayerSlot.maghrib: toDateTime(t['Maghrib'] as String),
      PrayerSlot.isha: toDateTime(t['Isha'] as String),
    };
  }
}
