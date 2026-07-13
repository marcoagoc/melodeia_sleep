import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../journal/domain/sleep_log.dart';
import '../domain/sleep_session_config.dart';

class SleepRepository {
  SleepRepository({
    FirebaseFirestore? firestore,
    Future<SharedPreferences>? sharedPreferences,
  }) : _sharedPreferences =
           sharedPreferences ?? SharedPreferences.getInstance() {
    _firestore = firestore;
  }

  FirebaseFirestore? _firestore;
  final Future<SharedPreferences> _sharedPreferences;

  static const _lastConfigKey = 'last_session_config';
  static const _logsKey = 'sleep_logs';

  Future<void> saveLastConfig(SleepSessionConfig config) async {
    final prefs = await _sharedPreferences;
    await prefs.setString(_lastConfigKey, jsonEncode(config.toMap()));
  }

  Future<SleepSessionConfig> loadLastConfig() async {
    final prefs = await _sharedPreferences;
    final encoded = prefs.getString(_lastConfigKey);
    if (encoded == null) return SleepSessionConfig.defaults();
    return SleepSessionConfig.fromMap(
      Map<String, Object?>.from(jsonDecode(encoded) as Map),
    );
  }

  Future<void> saveLogLocally(SleepLog log) async {
    final prefs = await _sharedPreferences;
    final logs = await loadLocalLogs();
    final updated = [log, ...logs.where((entry) => entry.id != log.id)];
    await prefs.setString(
      _logsKey,
      jsonEncode(updated.map((entry) => entry.toMap()).toList()),
    );
  }

  Future<List<SleepLog>> loadLocalLogs() async {
    final prefs = await _sharedPreferences;
    final encoded = prefs.getString(_logsKey);
    if (encoded == null) return const [];
    final decoded = jsonDecode(encoded) as List;
    return decoded
        .map(
          (entry) => SleepLog.fromMap(Map<String, Object?>.from(entry as Map)),
        )
        .toList();
  }

  Future<void> syncLog({
    required String uid,
    required SleepLog log,
    required bool firebaseReady,
  }) async {
    if (!firebaseReady) return;
    final firestore = _firestore ??= FirebaseFirestore.instance;
    await firestore
        .collection('users')
        .doc(uid)
        .collection('logs')
        .doc(log.id)
        .set(log.toMap(), SetOptions(merge: true));
  }

  Future<void> syncAllLocalLogs({
    required String uid,
    required bool firebaseReady,
  }) async {
    if (!firebaseReady) return;
    final logs = await loadLocalLogs();
    for (final log in logs) {
      await syncLog(uid: uid, log: log, firebaseReady: firebaseReady);
    }
  }
}
