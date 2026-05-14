import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/exercise.dart';

class ExerciseDbException implements Exception {
  final String message;
  final int? statusCode;
  ExerciseDbException(this.message, [this.statusCode]);
  @override
  String toString() =>
      'ExerciseDbException${statusCode != null ? ' ($statusCode)' : ''}: $message';
}

/// Thin client for the ExerciseDB RapidAPI service.
///
/// Get a key at https://rapidapi.com/justin-WFnsXH_t6/api/exercisedb/
/// (free tier ~50 reqs/day). The key lives in Hive (entered in Settings) so
/// this client is constructed with whatever's currently stored — the
/// repository takes care of injecting the right key.
class ExerciseDbClient {
  static const _host = 'exercisedb.p.rapidapi.com';
  static const _baseUrl = 'https://$_host';

  final String apiKey;
  final http.Client _http;

  ExerciseDbClient({required this.apiKey, http.Client? client})
      : _http = client ?? http.Client();

  Map<String, String> get _headers => {
        'x-rapidapi-key': apiKey,
        'x-rapidapi-host': _host,
        'Accept': 'application/json',
      };

  Future<List<Exercise>> _getList(String path) async {
    if (apiKey.trim().isEmpty) {
      throw ExerciseDbException('No API key configured.');
    }
    final url = Uri.parse('$_baseUrl$path');
    final res = await _http.get(url, headers: _headers).timeout(
          const Duration(seconds: 20),
        );
    if (res.statusCode != 200) {
      throw ExerciseDbException(
        'Request to $path failed: ${res.reasonPhrase ?? res.body}',
        res.statusCode,
      );
    }
    final decoded = jsonDecode(res.body);
    if (decoded is! List) {
      throw ExerciseDbException('Unexpected payload shape for $path.');
    }
    return decoded
        .whereType<Map>()
        .map((m) => Exercise.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<List<String>> _getStringList(String path) async {
    if (apiKey.trim().isEmpty) {
      throw ExerciseDbException('No API key configured.');
    }
    final url = Uri.parse('$_baseUrl$path');
    final res = await _http.get(url, headers: _headers).timeout(
          const Duration(seconds: 20),
        );
    if (res.statusCode != 200) {
      throw ExerciseDbException(
        'Request to $path failed: ${res.reasonPhrase ?? res.body}',
        res.statusCode,
      );
    }
    final decoded = jsonDecode(res.body);
    if (decoded is! List) {
      throw ExerciseDbException('Unexpected payload shape for $path.');
    }
    return decoded.whereType<String>().toList();
  }

  Future<List<String>> bodyParts() => _getStringList('/exercises/bodyPartList');
  Future<List<String>> equipmentList() =>
      _getStringList('/exercises/equipmentList');
  Future<List<String>> targets() => _getStringList('/exercises/targetList');

  Future<List<Exercise>> byBodyPart(String part, {int limit = 30}) =>
      _getList('/exercises/bodyPart/${Uri.encodeComponent(part)}?limit=$limit');

  Future<List<Exercise>> byEquipment(String equipment, {int limit = 30}) =>
      _getList(
        '/exercises/equipment/${Uri.encodeComponent(equipment)}?limit=$limit',
      );

  Future<List<Exercise>> byTarget(String target, {int limit = 30}) =>
      _getList('/exercises/target/${Uri.encodeComponent(target)}?limit=$limit');

  void dispose() => _http.close();
}
