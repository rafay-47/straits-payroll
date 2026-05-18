import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart';

/// Service for QR code operations
class QRService {
  // ============================================
  // QR CODE GENERATION
  // ============================================

  /// Generate QR code data for project
  String generateProjectQRCode({
    required String projectId,
    required String projectName,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'PROJECT:$projectId:$projectName:$timestamp';
  }

  /// Generate QR code widget
  Widget generateQRCodeWidget({
    required String data,
    double size = 200.0,
    Color foregroundColor = Colors.black,
    Color backgroundColor = Colors.white,
  }) {
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
      gapless: false,
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      errorStateBuilder: (context, error) {
        return Container(
          width: size,
          height: size,
          color: Colors.red.withOpacity(0.1),
          child: const Center(
            child: Text(
              'Error generating QR code',
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }

  // ============================================
  // QR CODE VALIDATION
  // ============================================

  /// Parse and validate QR code data
  Map<String, dynamic>? parseProjectQRCode(String qrData) {
    try {
      final parts = qrData.split(':');
      
      if (parts.length < 3 || parts[0] != 'PROJECT') {
        return null; // Invalid format
      }

      final projectId = parts[1];
      final projectName = parts[2];
      final timestamp = parts.length > 3 ? int.tryParse(parts[3]) : null;

      // Check if QR code is expired (valid for 24 hours)
      if (timestamp != null) {
        final qrTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final now = DateTime.now();
        final difference = now.difference(qrTime);

        if (difference.inHours > 24) {
          return {
            'valid': false,
            'error': 'QR code expired',
            'projectId': projectId,
            'projectName': projectName,
          };
        }
      }

      return {
        'valid': true,
        'projectId': projectId,
        'projectName': projectName,
        'timestamp': timestamp,
      };
    } catch (e) {
      return null;
    }
  }

  /// Check if QR code is valid
  bool isValidProjectQRCode(String qrData) {
    final parsed = parseProjectQRCode(qrData);
    return parsed != null && parsed['valid'] == true;
  }

  /// Get project ID from QR code
  String? getProjectIdFromQRCode(String qrData) {
    final parsed = parseProjectQRCode(qrData);
    return parsed?['projectId'];
  }

  // ============================================
  // QR CODE DISPLAY
  // ============================================

  /// Create a styled QR code with project info
  Widget createStyledProjectQRCode({
    required String projectId,
    required String projectName,
    double size = 250.0,
  }) {
    final qrData = generateProjectQRCode(
      projectId: projectId,
      projectName: projectName,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            projectName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          generateQRCodeWidget(
            data: qrData,
            size: size,
          ),
          const SizedBox(height: 16),
          Text(
            'Scan to check-in',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            'Valid for 24 hours',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // QR CODE ERROR CORRECTION
  // ============================================

  /// Get QR code with different error correction levels
  Widget generateQRCodeWithErrorCorrection({
    required String data,
    double size = 200.0,
    int errorCorrectLevel = QrErrorCorrectLevel.M,
  }) {
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
      gapless: false,
      errorCorrectionLevel: errorCorrectLevel,
    );
  }

  // ============================================
  // UTILITIES
  // ============================================

  /// Get QR code validity period in hours
  int getQRCodeValidityHours() {
    return 24; // QR codes valid for 24 hours
  }

  /// Check if QR code is expired
  bool isQRCodeExpired(String qrData) {
    final parsed = parseProjectQRCode(qrData);
    if (parsed == null) return true;
    return parsed['valid'] == false;
  }

  /// Get time remaining for QR code
  String getQRCodeTimeRemaining(String qrData) {
    try {
      final parsed = parseProjectQRCode(qrData);
      if (parsed == null || parsed['timestamp'] == null) {
        return 'Unknown';
      }

      final timestamp = parsed['timestamp'] as int;
      final qrTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final expiryTime = qrTime.add(const Duration(hours: 24));
      final now = DateTime.now();

      if (now.isAfter(expiryTime)) {
        return 'Expired';
      }

      final remaining = expiryTime.difference(now);
      final hours = remaining.inHours;
      final minutes = remaining.inMinutes % 60;

      return '${hours}h ${minutes}m remaining';
    } catch (e) {
      return 'Unknown';
    }
  }
}

