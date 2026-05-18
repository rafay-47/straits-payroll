import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:device_info_plus/device_info_plus.dart';
import '../models/device_info_model.dart';

/// Service for device information and binding
class DeviceService {
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  // ============================================
  // GET DEVICE INFORMATION
  // ============================================

  /// Get complete device information
  Future<DeviceInfo?> getDeviceInfo() async {
    try {
      // Skip device binding on web
      if (kIsWeb) {
        return DeviceInfo(
          deviceId: 'web-device-${DateTime.now().millisecondsSinceEpoch}',
          deviceModel: 'Web Browser',
          brand: 'Browser',
          registeredAt: DateTime.now(),
          isActive: true,
        );
      }

      // Get platform-specific device info with unique ID
      if (Platform.isAndroid) {
        return await _getAndroidDeviceInfo();
      } else if (Platform.isIOS) {
        return await _getIOSDeviceInfo();
      }

      return null;
    } catch (e) {
      throw 'Failed to get device information: $e';
    }
  }

  /// Get Android device information
  Future<DeviceInfo> _getAndroidDeviceInfo() async {
    final androidInfo = await _deviceInfoPlugin.androidInfo;
    // Use Android ID as unique device identifier
    final deviceId = androidInfo.id;
    
    return DeviceInfo(
      deviceId: deviceId,
      deviceModel: androidInfo.model,
      brand: androidInfo.brand,
      registeredAt: DateTime.now(),
      isActive: true,
    );
  }

  /// Get iOS device information
  Future<DeviceInfo> _getIOSDeviceInfo() async {
    final iosInfo = await _deviceInfoPlugin.iosInfo;
    // Use identifierForVendor as unique device identifier
    final deviceId = iosInfo.identifierForVendor ?? 'ios-${DateTime.now().millisecondsSinceEpoch}';
    
    return DeviceInfo(
      deviceId: deviceId,
      deviceModel: iosInfo.model,
      brand: 'Apple',
      registeredAt: DateTime.now(),
      isActive: true,
    );
  }

  // ============================================
  // DEVICE VERIFICATION
  // ============================================

  /// Verify if current device matches registered device
  Future<bool> verifyDevice(DeviceInfo? registeredDevice) async {
    try {
      // Skip verification on web
      if (kIsWeb) return true;

      // No registered device means not bound yet
      if (registeredDevice == null) return false;

      // Get current device ID
      String? currentDeviceId;
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        currentDeviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        currentDeviceId = iosInfo.identifierForVendor;
      }
      
      if (currentDeviceId == null) return false;

      // Compare device IDs
      return currentDeviceId == registeredDevice.deviceId;
    } catch (e) {
      // If we can't verify, assume false for security
      return false;
    }
  }

  /// Check if device binding is required (returns false on web)
  bool isDeviceBindingRequired() {
    return !kIsWeb; // Only required for mobile
  }

  // ============================================
  // DEVICE DETAILS
  // ============================================

  /// Get device model name
  Future<String> getDeviceModel() async {
    try {
      if (kIsWeb) return 'Web Browser';

      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        return androidInfo.model;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        return iosInfo.model;
      }

      return 'Unknown Device';
    } catch (e) {
      return 'Unknown Device';
    }
  }

  /// Get device brand/manufacturer
  Future<String> getDeviceBrand() async {
    try {
      if (kIsWeb) return 'Browser';

      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        return androidInfo.brand;
      } else if (Platform.isIOS) {
        return 'Apple';
      }

      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Get OS version
  Future<String> getOSVersion() async {
    try {
      if (kIsWeb) return 'Web';

      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        return 'Android ${androidInfo.version.release}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        return 'iOS ${iosInfo.systemVersion}';
      }

      return 'Unknown OS';
    } catch (e) {
      return 'Unknown OS';
    }
  }

  /// Get device display name (for UI)
  Future<String> getDeviceDisplayName() async {
    try {
      if (kIsWeb) return 'Web Browser';

      final brand = await getDeviceBrand();
      final model = await getDeviceModel();
      
      return '$brand $model';
    } catch (e) {
      return 'Unknown Device';
    }
  }

  // ============================================
  // DEVICE CAPABILITIES
  // ============================================

  /// Check if device supports NFC
  bool get supportsNFC {
    if (kIsWeb) return false;
    // Most modern Android devices support NFC, iOS 7+ supports it
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Check if device has camera
  Future<bool> hasCamera() async {
    // Assume all mobile devices have cameras
    return !kIsWeb;
  }

  /// Check if device supports biometric authentication
  Future<bool> supportsBiometric() async {
    // Would need local_auth package to check properly
    // For now, assume modern devices support it
    return !kIsWeb;
  }

  // ============================================
  // DEVICE RESET VALIDATION
  // ============================================

  /// Check if device reset is allowed (monthly limit)
  bool canRequestDeviceReset({
    required int currentResetCount,
    required DateTime? lastResetAt,
    required int maxResetsPerMonth,
  }) {
    // Check monthly limit
    if (currentResetCount >= maxResetsPerMonth) {
      // Check if a month has passed since last reset
      if (lastResetAt != null) {
        final now = DateTime.now();
        final monthsSinceReset = (now.year - lastResetAt.year) * 12 + 
                                 (now.month - lastResetAt.month);
        
        // If less than a month, can't reset
        if (monthsSinceReset < 1) {
          return false;
        }
      } else {
        // No last reset date but limit reached, don't allow
        return false;
      }
    }

    return true;
  }

  /// Get days until next allowed reset
  int getDaysUntilNextReset({
    required DateTime? lastResetAt,
  }) {
    if (lastResetAt == null) return 0;

    final now = DateTime.now();
    final nextAllowedReset = DateTime(
      lastResetAt.year,
      lastResetAt.month + 1,
      lastResetAt.day,
    );

    if (now.isAfter(nextAllowedReset)) {
      return 0; // Can reset now
    }

    return nextAllowedReset.difference(now).inDays;
  }

  // ============================================
  // PLATFORM DETECTION
  // ============================================

  /// Get current platform
  String get platform {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  /// Check if running on mobile
  bool get isMobile => !kIsWeb;

  /// Check if running on web
  bool get isWeb => kIsWeb;

  /// Check if running on Android
  bool get isAndroid => !kIsWeb && Platform.isAndroid;

  /// Check if running on iOS
  bool get isIOS => !kIsWeb && Platform.isIOS;

  /// Get device ID for comparison
  Future<String> getDeviceId() async {
    if (kIsWeb) {
      return 'web_device';
    }

    try {
      String? deviceId;
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        deviceId = iosInfo.identifierForVendor;
      }
      return deviceId ?? 'unknown_device';
    } catch (e) {
      return 'unknown_device';
    }
  }
}

