import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/dua.dart';

/// Loads the bundled `assets/duas.json` once and serves access methods.
/// Lazy-init so it doesn't add to startup time.
class DuaService {
  DuaService._();
  static final DuaService instance = DuaService._();

  List<Dua>? _all;
  List<String>? _categories;

  Future<void> load() async {
    if (_all != null) return;
    final raw = await rootBundle.loadString('assets/duas.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final list = (decoded['duas'] as List).cast<Map<String, dynamic>>();
    _all = list.map(Dua.fromJson).toList(growable: false);
    _categories =
        ((decoded['categories'] as List?) ?? const []).cast<String>();
  }

  List<Dua> all() => _all ?? const [];
  List<String> categories() => _categories ?? const [];

  List<Dua> byCategory(String category) =>
      all().where((d) => d.category == category).toList();

  /// Pick a deterministic dua-of-the-day based on the date. Same dua all day,
  /// rotates next day.
  Dua? duaOfTheDay({DateTime? on}) {
    final list = all();
    if (list.isEmpty) return null;
    final d = on ?? DateTime.now();
    final dayNumber = d.year * 1000 + d.month * 50 + d.day;
    return list[dayNumber % list.length];
  }
}
