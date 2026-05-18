import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for securely storing user credentials and biometric enrollment data
/// Uses platform-specific secure storage (Keychain on iOS, EncryptedSharedPreferences on Android)
class SecureStorageService {
  // Secure storage instance with platform-specific options
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // Storage keys
  static const String _keyEmail = 'user_email';
  static const String _keyPassword = 'user_password';
  static const String _keyUID = 'user_uid';
  static const String _keyBiometricEnabled = 'biometric_enabled';

  // ===== CREDENTIAL STORAGE =====

  /// Save user credentials for biometric login
  Future<void> saveUserCredentials({
    required String email,
    required String password,
    required String uid,
  }) async {
    await Future.wait([
      _storage.write(key: _keyEmail, value: email),
      _storage.write(key: _keyPassword, value: password),
      _storage.write(key: _keyUID, value: uid),
      _storage.write(key: _keyBiometricEnabled, value: 'true'),
    ]);
  }

  /// Get stored user email
  Future<String?> getUserEmail() async {
    return await _storage.read(key: _keyEmail);
  }

  /// Get stored user password
  Future<String?> getUserPassword() async {
    return await _storage.read(key: _keyPassword);
  }

  /// Get stored user UID
  Future<String?> getUserUID() async {
    return await _storage.read(key: _keyUID);
  }

  /// Check if biometric login is enabled
  Future<bool> isBiometricEnabled() async {
    final enabled = await _storage.read(key: _keyBiometricEnabled);
    return enabled == 'true';
  }

  /// Get all stored credentials at once
  Future<Map<String, String?>> getAllCredentials() async {
    final results = await Future.wait([
      getUserEmail(),
      getUserPassword(),
      getUserUID(),
    ]);

    return {
      'email': results[0],
      'password': results[1],
      'uid': results[2],
    };
  }

  // ===== CREDENTIAL MANAGEMENT =====

  /// Update stored password (when user changes password)
  Future<void> updatePassword(String newPassword) async {
    await _storage.write(key: _keyPassword, value: newPassword);
  }

  /// Clear all stored credentials
  Future<void> clearCredentials() async {
    await Future.wait([
      _storage.delete(key: _keyEmail),
      _storage.delete(key: _keyPassword),
      _storage.delete(key: _keyUID),
      _storage.delete(key: _keyBiometricEnabled),
    ]);
  }

  /// Disable biometric login (keeps credentials for potential re-enrollment)
  Future<void> disableBiometric() async {
    await _storage.write(key: _keyBiometricEnabled, value: 'false');
  }

  /// Enable biometric login (if credentials already exist)
  Future<void> enableBiometric() async {
    await _storage.write(key: _keyBiometricEnabled, value: 'true');
  }

  // ===== UTILITY METHODS =====

  /// Check if user has enrolled credentials (but biometric might be disabled)
  Future<bool> hasEnrolledCredentials() async {
    final credentials = await getAllCredentials();
    return credentials['email'] != null &&
        credentials['password'] != null &&
        credentials['uid'] != null;
  }

  /// Check if biometric login is fully set up and enabled
  Future<bool> isBiometricLoginReady() async {
    final hasCredentials = await hasEnrolledCredentials();
    final isEnabled = await isBiometricEnabled();
    return hasCredentials && isEnabled;
  }

  /// Clear all stored data (use with caution)
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}

