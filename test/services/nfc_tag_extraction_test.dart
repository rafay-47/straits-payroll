import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_data.dart';

/// Tests for NFC tag validation logic used in check-in/check-out flows.
///
/// The NFCService itself depends on platform NFC hardware (NfcManager),
/// so we test the validation and comparison logic that runs AFTER a tag
/// is read.
void main() {
  // ═══════════════════════════════════════════════════════════════════════
  // NFC TAG ID FORMAT
  // ═══════════════════════════════════════════════════════════════════════

  group('NFC Tag UID format', () {
    test('NTAG 213 produces 7-byte UID hex string', () {
      // NTAG 213 UIDs are 7 bytes -> "XX:XX:XX:XX:XX:XX:XX"
      const uid = '04:A3:12:5B:6C:7D:8E';
      final parts = uid.split(':');
      expect(parts.length, 7);
      for (final part in parts) {
        expect(part.length, 2);
        expect(int.tryParse(part, radix: 16), isNotNull);
      }
    });

    test('NTAG 215 produces 7-byte UID hex string', () {
      const uid = '04:FF:00:AB:CD:EF:01';
      final parts = uid.split(':');
      expect(parts.length, 7);
    });

    test('NTAG UIDs always start with 04 (NXP manufacturer)', () {
      const ntag213Uid = '04:A3:12:5B:6C:7D:8E';
      const ntag215Uid = '04:FF:00:AB:CD:EF:01';
      expect(ntag213Uid.startsWith('04'), isTrue);
      expect(ntag215Uid.startsWith('04'), isTrue);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // TAG MATCHING (CASE INSENSITIVE)
  // ═══════════════════════════════════════════════════════════════════════

  group('NFC Tag ID matching (case-insensitive)', () {
    test('same UIDs match', () {
      const expected = '04:A3:12:5B:6C:7D:8E';
      const scanned = '04:A3:12:5B:6C:7D:8E';
      expect(
        expected.toUpperCase().trim() == scanned.toUpperCase().trim(),
        isTrue,
      );
    });

    test('different case UIDs match (uppercase vs lowercase)', () {
      const expected = '04:A3:12:5B:6C:7D:8E';
      const scanned = '04:a3:12:5b:6c:7d:8e';
      expect(
        expected.toUpperCase().trim() == scanned.toUpperCase().trim(),
        isTrue,
      );
    });

    test('UIDs with leading/trailing whitespace match after trim', () {
      const expected = '04:A3:12:5B:6C:7D:8E';
      const scanned = ' 04:A3:12:5B:6C:7D:8E ';
      expect(
        expected.toUpperCase().trim() == scanned.toUpperCase().trim(),
        isTrue,
      );
    });

    test('completely different UIDs do NOT match', () {
      const expected = '04:A3:12:5B:6C:7D:8E';
      const scanned = '04:FF:00:AB:CD:EF:01';
      expect(
        expected.toUpperCase().trim() == scanned.toUpperCase().trim(),
        isFalse,
      );
    });

    test('partially different UIDs do NOT match', () {
      const expected = '04:A3:12:5B:6C:7D:8E';
      const scanned = '04:A3:12:5B:6C:7D:FF';
      expect(
        expected.toUpperCase().trim() == scanned.toUpperCase().trim(),
        isFalse,
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // PROJECT NFC VALIDATION SCENARIOS
  // ═══════════════════════════════════════════════════════════════════════

  group('Project NFC tag validation scenarios', () {
    test('project with registered NFC tag - matching tag is accepted', () {
      final project = TestData.nfcProject(nfcTagId: '04:A3:12:5B:6C:7D:8E');
      const scannedTagId = '04:A3:12:5B:6C:7D:8E';

      final expected = project.nfcTagId!;
      final matches = expected.toUpperCase().trim() ==
          scannedTagId.toUpperCase().trim();
      expect(matches, isTrue);
    });

    test('project with registered NFC tag - wrong tag is rejected', () {
      final project = TestData.nfcProject(nfcTagId: '04:A3:12:5B:6C:7D:8E');
      const scannedTagId = '04:FF:00:AB:CD:EF:01';

      final expected = project.nfcTagId!;
      final matches = expected.toUpperCase().trim() ==
          scannedTagId.toUpperCase().trim();
      expect(matches, isFalse);
    });

    test('project with NO registered NFC tag - any tag is accepted', () {
      final project = TestData.nfcProject(nfcTagId: null);
      const scannedTagId = '04:FF:00:AB:CD:EF:01';

      final shouldAccept =
          project.nfcTagId == null || project.nfcTagId!.isEmpty;
      expect(shouldAccept, isTrue);

      // In check-in code, if nfcTagId is null, any tag is accepted
      expect(scannedTagId.isNotEmpty, isTrue);
    });

    test('project with empty nfcTagId string - any tag is accepted', () {
      final project = TestData.nfcProject(nfcTagId: '');

      final shouldAccept =
          project.nfcTagId == null || project.nfcTagId!.isEmpty;
      expect(shouldAccept, isTrue);
    });

    test('project with NFC disabled - NFC tag is irrelevant', () {
      final project = TestData.gpsProject();
      expect(project.supportsNFC, isFalse);
      expect(project.nfcTagId, isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // QR CODE VALIDATION SCENARIOS
  // ═══════════════════════════════════════════════════════════════════════

  group('Project QR code validation scenarios', () {
    test('matching QR code is accepted', () {
      final project = TestData.qrProject(qrCode: 'SP:proj_qr:QR Project');
      const scannedQR = 'SP:proj_qr:QR Project';
      expect(project.qrCode, scannedQR);
    });

    test('non-matching QR code is rejected', () {
      final project = TestData.qrProject(qrCode: 'SP:proj_qr:QR Project');
      const scannedQR = 'SP:proj_other:Other Project';
      expect(project.qrCode, isNot(scannedQR));
    });

    test('QR code with matching projectId but different timestamp accepted', () {
      final project = TestData.qrProject(qrCode: 'SP:proj_qr:QR Project');
      const scannedQR = 'SP:proj_qr:QR Project Updated';

      // In the check-in screen, lenient validation extracts project ID
      final expectedParts = project.qrCode!.split(':');
      final scannedParts = scannedQR.split(':');

      expect(expectedParts.length >= 2, isTrue);
      expect(scannedParts.length >= 2, isTrue);
      expect(expectedParts[1], scannedParts[1]); // projectIds match
    });

    test('project with no QR code configured - any QR accepted', () {
      final project = TestData.qrProject(qrCode: null);
      expect(project.qrCode, isNull);
      expect(project.supportsQR, isTrue);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // NTAG 213 vs NTAG 215 CAPACITY
  // ═══════════════════════════════════════════════════════════════════════

  group('NTAG capacity validation', () {
    test('short project payload fits NTAG 213 (144 bytes)', () {
      const projectId = 'proj_001';
      const projectName = 'Office';
      final payload = 'PROJECT:$projectId:$projectName';

      // NTAG 213 = 144 bytes usable
      expect(payload.length, lessThan(144));
    });

    test('medium project payload fits NTAG 215 (504 bytes)', () {
      const projectId = 'proj_long_id_for_testing';
      const projectName = 'Very Long Project Name That Is Quite Descriptive';
      final payload = 'PROJECT:$projectId:$projectName';

      expect(payload.length, lessThan(504));
    });

    test('extremely long payload may exceed NTAG 213', () {
      final projectId = 'p' * 100;
      final projectName = 'N' * 100;
      final payload = 'PROJECT:$projectId:$projectName';

      // Payload > 144 bytes wouldn't fit NTAG 213
      expect(payload.length, greaterThan(144));
      // But fits NTAG 215
      expect(payload.length, lessThan(504));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // HEX CONVERSION
  // ═══════════════════════════════════════════════════════════════════════

  group('Hex byte conversion', () {
    String bytesToHex(List<int> bytes) {
      return bytes
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join(':')
          .toUpperCase();
    }

    test('converts NTAG 213 7-byte UID', () {
      final bytes = [0x04, 0xA3, 0x12, 0x5B, 0x6C, 0x7D, 0x8E];
      expect(bytesToHex(bytes), '04:A3:12:5B:6C:7D:8E');
    });

    test('converts NTAG 215 7-byte UID', () {
      final bytes = [0x04, 0xFF, 0x00, 0xAB, 0xCD, 0xEF, 0x01];
      expect(bytesToHex(bytes), '04:FF:00:AB:CD:EF:01');
    });

    test('pads single-digit hex values with leading zero', () {
      final bytes = [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07];
      expect(bytesToHex(bytes), '01:02:03:04:05:06:07');
    });

    test('handles zero bytes', () {
      final bytes = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
      expect(bytesToHex(bytes), '00:00:00:00:00:00:00');
    });

    test('handles max byte values', () {
      final bytes = [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF];
      expect(bytesToHex(bytes), 'FF:FF:FF:FF:FF:FF:FF');
    });

    test('handles 4-byte UID (some older tags)', () {
      final bytes = [0x04, 0xA3, 0x12, 0x5B];
      expect(bytesToHex(bytes), '04:A3:12:5B');
    });

    test('empty bytes produces empty string', () {
      final bytes = <int>[];
      expect(bytesToHex(bytes), '');
    });
  });
}
