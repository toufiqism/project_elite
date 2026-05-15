import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

import '../../../core/storage/hive_setup.dart';

/// Boxes that contain user-generated data and should be synced.
/// Excluded: exerciseCache (external API cache), notifications and settings
/// (device-specific preferences).
const _syncedBoxes = [
  HiveBoxes.profile,
  HiveBoxes.study,
  HiveBoxes.habits,
  HiveBoxes.habitLogs,
  HiveBoxes.prayer,
  HiveBoxes.workoutSessions,
  HiveBoxes.weightLog,
  HiveBoxes.focusSessions,
  HiveBoxes.socialRatings,
  HiveBoxes.gameResults,
  HiveBoxes.tasbih,
];

const _kTimeout = Duration(seconds: 15);

class SyncService {
  static final _db = FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>> _meta(String uid) =>
      _db.collection('users').doc(uid).collection('sync').doc('meta');

  static DocumentReference<Map<String, dynamic>> _boxRef(
          String uid, String boxName) =>
      _db.collection('users').doc(uid).collection('sync').doc(boxName);

  /// Returns the timestamp of the last successful cloud upload, or null if
  /// no backup exists yet.
  static Future<DateTime?> cloudTimestamp(String uid) async {
    final snap = await _meta(uid).get().timeout(
          _kTimeout,
          onTimeout: () => throw Exception(
            'Could not reach Firestore. '
            'Ensure Firestore Database is created in your Firebase console.',
          ),
        );
    if (!snap.exists) return null;
    final ts = snap.data()?['uploadedAt'];
    return ts is Timestamp ? ts.toDate() : null;
  }

  /// Serializes all synced Hive boxes and writes them to Firestore.
  /// Each box is its own document to stay within the 1 MB doc limit.
  static Future<void> upload(String uid) async {
    final batch = _db.batch();

    batch.set(_meta(uid), {'uploadedAt': FieldValue.serverTimestamp()});

    for (final name in _syncedBoxes) {
      batch.set(_boxRef(uid, name), {'data': _serializeBox(Hive.box(name))});
    }

    await batch.commit().timeout(
          _kTimeout,
          onTimeout: () => throw Exception(
            'Upload timed out. '
            'Check that Firestore Database is enabled in your Firebase console '
            'and that your security rules allow writes.',
          ),
        );
  }

  /// Reads all synced box documents from Firestore and writes them to Hive.
  /// Throws if no backup exists.
  static Future<void> restore(String uid) async {
    final metaSnap = await _meta(uid).get().timeout(
          _kTimeout,
          onTimeout: () => throw Exception(
            'Restore timed out. Check your internet connection.',
          ),
        );
    if (!metaSnap.exists) throw Exception('No backup found in the cloud.');

    final boxSnaps = await Future.wait(
      _syncedBoxes.map((name) => _boxRef(uid, name).get()),
    ).timeout(
      _kTimeout,
      onTimeout: () => throw Exception(
        'Restore timed out fetching data. Check your internet connection.',
      ),
    );

    for (int i = 0; i < _syncedBoxes.length; i++) {
      final snap = boxSnaps[i];
      if (!snap.exists) continue;
      final boxData = snap.data()?['data'];
      if (boxData is Map) {
        await _restoreBox(_syncedBoxes[i], boxData);
      }
    }
  }

  static Map<String, dynamic> _serializeBox(Box box) {
    final out = <String, dynamic>{};
    for (final key in box.keys) {
      final val = box.get(key);
      out[key.toString()] =
          val is Map ? Map<String, dynamic>.from(val) : val;
    }
    return out;
  }

  static Future<void> _restoreBox(String name, Map boxData) async {
    final box = Hive.box(name);
    await box.clear();
    for (final entry in boxData.entries) {
      await box.put(entry.key, entry.value);
    }
  }
}
