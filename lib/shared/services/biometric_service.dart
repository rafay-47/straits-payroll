import 'package:local_auth/local_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

/// Service for biometric authentication operations
class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  // ============================================
  // BIOMETRIC AVAILABILITY
  // ============================================

  /// Check if biometric authentication is available on device
  Future<bool> isBiometricAvailable() async {
    if (kIsWeb) return false;

    try {
      return await _localAuth.canCheckBiometrics;
    } on PlatformException catch (e) {
      print('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Check if device supports biometric authentication
  Future<bool> isDeviceSupported() async {
    if (kIsWeb) return false;

    try {
      return await _localAuth.isDeviceSupported();
    } on PlatformException catch (e) {
      print('Error checking device support: $e');
      return false;
    }
  }

  /// Get list of available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    if (kIsWeb) return [];

    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      print('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Check if Face ID is available (iOS)
  Future<bool> isFaceIDAvailable() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.face);
  }

  /// Check if Touch ID/Fingerprint is available
  Future<bool> isFingerprintAvailable() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.fingerprint);
  }

  /// Check if any biometric is enrolled
  Future<bool> isBiometricEnrolled() async {
    final isAvailable = await isBiometricAvailable();
    if (!isAvailable) return false;

    final biometrics = await getAvailableBiometrics();
    return biometrics.isNotEmpty;
  }

  // ============================================
  // AUTHENTICATION
  // ============================================

  /// Authenticate with biometric
  Future<bool> authenticate({
    required String reason,
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    if (kIsWeb) {
      throw 'Biometric authentication is not supported on web';
    }

    try {
      // Check if biometric is available
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        throw 'Biometric authentication is not available on this device';
      }

      // Check if biometrics are enrolled
      final isEnrolled = await isBiometricEnrolled();
      if (!isEnrolled) {
        throw 'No biometrics enrolled. Please set up Face ID or Fingerprint in device settings';
      }

      // Authenticate
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: true,
        ),
      );

      return authenticated;
    } on PlatformException catch (e) {
      throw _handlePlatformException(e);
    } catch (e) {
      rethrow;
    }
  }

  /// Authenticate with fallback to PIN/Password
  Future<bool> authenticateWithFallback({
    required String reason,
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    if (kIsWeb) {
      throw 'Biometric authentication is not supported on web';
    }

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: false, // Allow device PIN/Password fallback
        ),
      );

      return authenticated;
    } on PlatformException catch (e) {
      throw _handlePlatformException(e);
    } catch (e) {
      rethrow;
    }
  }

  // ============================================
  // BIOMETRIC TYPE DETECTION
  // ============================================

  /// Get biometric type name for display
  Future<String> getBiometricTypeName() async {
    if (kIsWeb) return 'Biometric';

    try {
      final biometrics = await getAvailableBiometrics();

      if (biometrics.isEmpty) {
        return 'Biometric';
      }

      if (biometrics.contains(BiometricType.face)) {
        return 'Face ID';
      }

      if (biometrics.contains(BiometricType.fingerprint)) {
        return 'Fingerprint';
      }

      if (biometrics.contains(BiometricType.iris)) {
        return 'Iris';
      }

      return 'Biometric';
    } catch (e) {
      return 'Biometric';
    }
  }

  /// Check if specific biometric type is available
  Future<bool> isBiometricTypeAvailable(BiometricType type) async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(type);
  }

  // ============================================
  // ERROR HANDLING
  // ============================================

  /// Handle platform-specific biometric errors
  String _handlePlatformException(PlatformException e) {
    switch (e.code) {
      case 'NotAvailable':
        return 'Biometric authentication is not available on this device';
      case 'NotEnrolled':
        return 'No biometrics enrolled. Please set up Face ID or Fingerprint in device settings';
      case 'PasscodeNotSet':
        return 'Device passcode not set. Please set up device passcode first';
      case 'LockedOut':
        return 'Biometric authentication locked due to too many failed attempts. Please use device passcode';
      case 'PermanentlyLockedOut':
        return 'Biometric authentication permanently locked. Please use device passcode';
      case 'OtherOperatingSystem':
        return 'Biometric authentication is not supported on this device';
      default:
        return e.message ?? 'Biometric authentication failed';
    }
  }

  // ============================================
  // CANCELLATION
  // ============================================

  /// Stop authentication (if supported)
  Future<void> stopAuthentication() async {
    if (kIsWeb) return;

    try {
      await _localAuth.stopAuthentication();
    } on PlatformException catch (e) {
      print('Error stopping authentication: $e');
    }
  }

  // ============================================
  // UTILITIES
  // ============================================

  /// Get user-friendly error message
  String getErrorMessage(dynamic error) {
    if (error is PlatformException) {
      return _handlePlatformException(error);
    }
    return error.toString();
  }

  /// Check if biometric authentication is supported and enrolled
  Future<bool> canUseBiometric() async {
    if (kIsWeb) return false;

    try {
      final isSupported = await isDeviceSupported();
      if (!isSupported) return false;

      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) return false;

      final isEnrolled = await isBiometricEnrolled();
      return isEnrolled;
    } catch (e) {
      return false;
    }
  }

  /// Get biometric icon name for UI
  Future<String> getBiometricIconName() async {
    if (await isFaceIDAvailable()) {
      return 'face';
    } else if (await isFingerprintAvailable()) {
      return 'fingerprint';
    }
    return 'security';
  }

  /// Check if device supports biometric (static)
  static bool get isSupported => !kIsWeb;
}

