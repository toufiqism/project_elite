import 'package:hive/hive.dart';

import '../../../core/config/api_keys.dart';
import '../../../core/storage/hive_setup.dart';
import '../models/exercise.dart';
import 'exercise_db_client.dart';

/// Mediates between the API and the local Hive cache.
///
/// First fetch hits the API and writes the resulting list into the cache keyed
/// by body part (`bodyPart:<name>`) or equipment (`equipment:<name>`). After
/// that we serve from cache unless [forceRefresh] is set.
class FitnessRepository {
  static const _apiKeySettingsKey = 'fitness_api_key';

  final Box _cache = Hive.box(HiveBoxes.exerciseCache);
  final Box _settings = Hive.box(HiveBoxes.settings);

  /// Resolution order:
  /// 1. Key stored in Hive via the in-app Settings dialog (user-pasted).
  /// 2. Compile-time fallback in `lib/core/config/api_keys.dart` (gitignored).
  ///
  /// The fallback lets the app work without a manual paste step at the cost
  /// of carrying the key in the local source tree. See the FIXME in that file.
  String get apiKey {
    final stored = (_settings.get(_apiKeySettingsKey) as String?) ?? '';
    if (stored.trim().isNotEmpty) return stored;
    return kExerciseDbApiKey;
  }

  bool get hasApiKey => apiKey.trim().isNotEmpty;

  Future<void> setApiKey(String key) async {
    await _settings.put(_apiKeySettingsKey, key.trim());
  }

  ExerciseDbClient _client() => ExerciseDbClient(apiKey: apiKey);

  Future<List<Exercise>> byBodyPart(
    String bodyPart, {
    bool forceRefresh = false,
    int limit = 30,
  }) async {
    final cacheKey = 'bodyPart:$bodyPart';
    if (!forceRefresh) {
      final cached = _readList(cacheKey);
      if (cached.isNotEmpty) return cached;
    }
    if (!hasApiKey) return const [];
    final client = _client();
    try {
      final fresh = await client.byBodyPart(bodyPart, limit: limit);
      await _writeList(cacheKey, fresh);
      return fresh;
    } finally {
      client.dispose();
    }
  }

  Future<List<Exercise>> byEquipment(
    String equipment, {
    bool forceRefresh = false,
    int limit = 30,
  }) async {
    final cacheKey = 'equipment:$equipment';
    if (!forceRefresh) {
      final cached = _readList(cacheKey);
      if (cached.isNotEmpty) return cached;
    }
    if (!hasApiKey) return const [];
    final client = _client();
    try {
      final fresh = await client.byEquipment(equipment, limit: limit);
      await _writeList(cacheKey, fresh);
      return fresh;
    } finally {
      client.dispose();
    }
  }

  Future<List<Exercise>> byTarget(
    String target, {
    bool forceRefresh = false,
    int limit = 30,
  }) async {
    final cacheKey = 'target:$target';
    if (!forceRefresh) {
      final cached = _readList(cacheKey);
      if (cached.isNotEmpty) return cached;
    }
    if (!hasApiKey) return const [];
    final client = _client();
    try {
      final fresh = await client.byTarget(target, limit: limit);
      await _writeList(cacheKey, fresh);
      return fresh;
    } finally {
      client.dispose();
    }
  }

  List<Exercise> _readList(String key) {
    final raw = _cache.get(key);
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((m) => Exercise.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<void> _writeList(String key, List<Exercise> ex) async {
    await _cache.put(key, ex.map((e) => e.toJson()).toList());
  }

  Future<void> clearCache() async => _cache.clear();
}
