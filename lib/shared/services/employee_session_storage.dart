import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists employee app session (Firestore user document id only — no PIN stored).
class EmployeeSessionStorage {
  static const _keyPersistedUid = 'employee_persist_firestore_uid';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  Future<void> savePersistedEmployeeUid(String uid) async {
    if (uid.isEmpty) return;
    await _storage.write(key: _keyPersistedUid, value: uid);
  }

  Future<String?> readPersistedEmployeeUid() async {
    return _storage.read(key: _keyPersistedUid);
  }

  Future<void> clearPersistedEmployee() async {
    await _storage.delete(key: _keyPersistedUid);
  }
}
