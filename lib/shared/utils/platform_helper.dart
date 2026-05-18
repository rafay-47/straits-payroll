import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Helper class for platform detection
class PlatformHelper {
  PlatformHelper._(); // Private constructor

  // ============================================
  // PLATFORM CHECKS
  // ============================================

  /// Check if running on web
  static bool get isWeb => kIsWeb;

  /// Check if running on mobile
  static bool get isMobile => !kIsWeb;

  /// Check if running on Android
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  /// Check if running on iOS
  static bool get isIOS => !kIsWeb && Platform.isIOS;

  /// Check if running on desktop
  static bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  /// Check if running on Windows
  static bool get isWindows => !kIsWeb && Platform.isWindows;

  /// Check if running on macOS
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;

  /// Check if running on Linux
  static bool get isLinux => !kIsWeb && Platform.isLinux;

  // ============================================
  // PLATFORM NAME
  // ============================================

  /// Get platform name as string
  static String get platformName {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  /// Get display platform name
  static String get platformDisplayName {
    if (kIsWeb) return 'Web';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }

  // ============================================
  // FEATURE SUPPORT
  // ============================================

  /// Check if biometric is supported
  static bool get supportsBiometric => isMobile;

  /// Check if NFC is supported
  static bool get supportsNFC => isMobile;

  /// Check if camera is supported
  static bool get supportsCamera => isMobile;

  /// Check if device binding is supported/required
  static bool get supportsDeviceBinding => isMobile;

  /// Check if GPS/location is supported
  static bool get supportsLocation => isMobile;

  // ============================================
  // ROUTING DECISIONS
  // ============================================

  /// Should show mobile app (Employee + Supervisor)
  static bool get shouldShowMobileApp => isMobile;

  /// Should show web dashboard (Admin)
  static bool get shouldShowWebDashboard => isWeb;

  // ============================================
  // DEVICE INFO
  // ============================================

  /// Get device type for logging/analytics
  static String get deviceType {
    if (isWeb) return 'web';
    if (isAndroid) return 'android_mobile';
    if (isIOS) return 'ios_mobile';
    if (isWindows) return 'windows_desktop';
    if (isMacOS) return 'macos_desktop';
    if (isLinux) return 'linux_desktop';
    return 'unknown';
  }

  // ============================================
  // PLATFORM-SPECIFIC CONFIGURATIONS
  // ============================================

  /// Get default font size based on platform
  static double get defaultFontSize {
    if (isWeb) return 14.0;
    if (isMobile) return 16.0;
    return 14.0;
  }

  /// Get default padding based on platform
  static double get defaultPadding {
    if (isWeb) return 16.0;
    if (isMobile) return 16.0;
    return 20.0;
  }

  /// Check if should use dense UI
  static bool get useDenseUI => isWeb;

  /// Check if should show back button
  static bool get showBackButton => isMobile;
}

