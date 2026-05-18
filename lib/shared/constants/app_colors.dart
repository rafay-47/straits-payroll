import 'package:flutter/material.dart';

/// Application color constants aligned with the refreshed gray & blue theme.
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // Primary & Accent Colors
  static const Color primary = Color(0xFF55A1D3); // Accent blue
  static const Color primaryDark = Color(0xFF2F6D91);
  static const Color primaryLight = Color(0xFF8EC1E0);
  static const Color accent = primary;

  // Secondary Colors (kept for API compatibility, mapped to accent family)
  static const Color secondary = Color(0xFF55A1D3);
  static const Color secondaryDark = Color(0xFF2F6D91);
  static const Color secondaryLight = Color(0xFFA7D7ED);

  // Status Colors
  static const Color success = Color(0xFF10B981); // Green
  static const Color error = Color(0xFFEF4444); // Red
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color info = Color(0xFF55A1D3); // Accent blue

  // Role-specific Colors
  static const Color employeeColor = Color(0xFF55A1D3); // Accent blue
  static const Color supervisorColor = Color(0xFF55A1D3); // Purple
  static const Color adminColor = Color(0xFF8D8E8D); // Mid gray

  // Text Colors
  static const Color textPrimary = Color(0xFF202020); // Dark text
  static const Color textSecondary = Color(0xFF383838);
  static const Color textTertiary = Color(0xFF4F4F4F);
  static const Color textLight = Color(0xFF6F6F6F);
  static const Color textWhite = Color(0xFFFAFAFA);

  // Background Colors
  static const Color backgroundWhite = Color(0xFFD5D5D5); // Primary background
  static const Color backgroundLight = backgroundWhite;
  static const Color backgroundGray = Color(0xFF8D8E8D); // Secondary background
  static const Color backgroundDark = Color(0xFF111827);

  // Card & Surface Colors
  static const Color cardBackground = Color(0xFFE2E2E2);
  static const Color surfaceLight = Color(0xFFFAFAFA); // Divider / panel fill
  static const Color surfaceDark = Color(0xFFBEBEBE);

  // Border & Divider Colors
  static const Color borderLight = Color(0xFFFAFAFA);
  static const Color borderMedium = Color(0xFFE2E2E2);
  static const Color borderDark = Color(0xFFB3B3B3);
  static const Color divider = Color(0xFFFAFAFA);

  // Ancillary UI Colors
  static const Color cardShadow = Color(0x1A000000);

  // Check-in Method Colors
  static const Color gpsColor = Color(0xFF55A1D3); // Accent blue
  static const Color nfcColor = Color(0xFF8B5CF6); // Purple
  static const Color qrColor = Color(0xFFF59E0B); // Amber
  static const Color manualColor = Color(0xFF6B7280); // Gray

  // Status Badge Colors
  static const Color pendingColor = Color(0xFFF59E0B); // Amber
  static const Color approvedColor = Color(0xFF10B981); // Green
  static const Color rejectedColor = Color(0xFFEF4444); // Red
  static const Color activeColor = Color(0xFF10B981); // Green
  static const Color suspendedColor = Color(0xFF6B7280); // Gray

  // Attendance Status Colors
  static const Color checkedInColor = Color(0xFF10B981); // Green
  static const Color checkedOutColor = Color(0xFF6B7280); // Gray
  static const Color notCheckedInColor = Color(0xFFEF4444); // Red

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFD5D5D5), Color(0xFF8D8E8D)],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  // Shadow Colors
  static Color shadowLight = Colors.black.withOpacity(0.08);
  static Color shadowMedium = Colors.black.withOpacity(0.16);
  static Color shadowDark = Colors.black.withOpacity(0.24);
}
