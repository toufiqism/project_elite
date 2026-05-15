import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../../core/storage/hive_setup.dart';
import '../models/user_profile.dart';

class ProfileController extends ChangeNotifier {
  static const _key = 'profile';
  final Box _box = Hive.box(HiveBoxes.profile);

  UserProfile? _profile;
  UserProfile? get profile => _profile;
  bool get hasProfile => _profile != null;

  ProfileController() {
    _load();
  }

  void _load() {
    final raw = _box.get(_key);
    if (raw is Map) {
      try {
        _profile = UserProfile.fromJson(Map<String, dynamic>.from(raw));
      } catch (_) {
        _profile = null;
      }
    }
  }

  Future<void> save(UserProfile profile) async {
    _profile = profile;
    await _box.put(_key, profile.toJson());
    notifyListeners();
  }

  Future<void> update(UserProfile Function(UserProfile current) update) async {
    if (_profile == null) return;
    await save(update(_profile!));
  }

  Future<void> clear() async {
    _profile = null;
    await _box.delete(_key);
    notifyListeners();
  }

  void reload() {
    _load();
    notifyListeners();
  }
}
