import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../storage/hive_setup.dart';

/// Owns the app-wide light/dark/system preference. Persists to the Hive
/// `settings` box under `theme_mode` and drives `MaterialApp.themeMode`.
class ThemeController extends ChangeNotifier {
  ThemeController() {
    _load();
  }

  static const _key = 'theme_mode';

  ThemeMode _mode = ThemeMode.dark;
  ThemeMode get mode => _mode;

  void _load() {
    final box = Hive.box(HiveBoxes.settings);
    final stored = box.get(_key) as String?;
    if (stored != null) {
      _mode = _parse(stored);
      return;
    }
    // No stored preference. Existing installs (those with any prior data) keep
    // dark so an update doesn't surprise testers mid-cycle; a genuinely fresh
    // install has no data and follows the OS instead.
    final isUpgrade = box.get('last_uid') != null ||
        Hive.box(HiveBoxes.profile).isNotEmpty;
    _mode = isUpgrade ? ThemeMode.dark : ThemeMode.system;
  }

  Future<void> setMode(ThemeMode m) async {
    if (m == _mode) return;
    _mode = m;
    notifyListeners();
    await Hive.box(HiveBoxes.settings).put(_key, _encode(m));
  }

  ThemeMode _parse(String s) => switch (s) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  String _encode(ThemeMode m) => switch (m) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
}
