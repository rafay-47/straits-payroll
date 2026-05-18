import 'package:flutter_test/flutter_test.dart';
import 'package:straights_psyroll/shared/models/project_model.dart';
import '../helpers/test_data.dart';

void main() {
  group('ProjectModel check-in method support', () {
    test('GPS-only project supports only GPS', () {
      final project = TestData.gpsProject();
      expect(project.supportsGPS, isTrue);
      expect(project.supportsNFC, isFalse);
      expect(project.supportsQR, isFalse);
      expect(project.supportsManual, isFalse);
      expect(project.activeCheckInMethodsCount, 1);
    });

    test('NFC-only project supports only NFC', () {
      final project = TestData.nfcProject();
      expect(project.supportsNFC, isTrue);
      expect(project.supportsGPS, isFalse);
      expect(project.supportsQR, isFalse);
      expect(project.supportsManual, isFalse);
    });

    test('QR-only project supports only QR', () {
      final project = TestData.qrProject();
      expect(project.supportsQR, isTrue);
      expect(project.supportsGPS, isFalse);
      expect(project.supportsNFC, isFalse);
      expect(project.supportsManual, isFalse);
    });

    test('Manual-only project supports only manual', () {
      final project = TestData.manualProject();
      expect(project.supportsManual, isTrue);
      expect(project.supportsGPS, isFalse);
      expect(project.supportsNFC, isFalse);
      expect(project.supportsQR, isFalse);
    });

    test('All-methods project supports all methods', () {
      final project = TestData.allMethodsProject();
      expect(project.supportsGPS, isTrue);
      expect(project.supportsNFC, isTrue);
      expect(project.supportsQR, isTrue);
      expect(project.supportsManual, isTrue);
      expect(project.activeCheckInMethodsCount, 4);
    });

    test('No-methods project supports nothing', () {
      final project = TestData.noMethodsProject();
      expect(project.supportsGPS, isFalse);
      expect(project.supportsNFC, isFalse);
      expect(project.supportsQR, isFalse);
      expect(project.supportsManual, isFalse);
      expect(project.activeCheckInMethodsCount, 0);
    });

    test('default checkInMethods includes gps and manual', () {
      const project = ProjectModel(
        projectId: 'p1',
        companyId: 'c1',
        name: 'Default',
      );
      expect(project.supportsGPS, isTrue);
      expect(project.supportsManual, isTrue);
      expect(project.supportsNFC, isFalse);
      expect(project.supportsQR, isFalse);
    });
  });

  group('ProjectModel NFC tag configuration', () {
    test('NFC project stores tag ID', () {
      final project = TestData.nfcProject(nfcTagId: '04:A3:12:5B:6C:7D:8E');
      expect(project.nfcTagId, '04:A3:12:5B:6C:7D:8E');
    });

    test('NFC project can have null tag ID (setup mode)', () {
      final project = TestData.nfcProject(nfcTagId: null);
      expect(project.nfcTagId, isNull);
      expect(project.supportsNFC, isTrue);
    });

    test('nfcTagId round-trips through serialization', () {
      final project = TestData.nfcProject(nfcTagId: '04:A3:12:5B:6C:7D:8E');
      final restored = ProjectModel.fromMap(project.toMap());
      expect(restored.nfcTagId, '04:A3:12:5B:6C:7D:8E');
    });
  });

  group('ProjectModel QR code configuration', () {
    test('QR project stores QR code', () {
      final project = TestData.qrProject(qrCode: 'SP:proj_qr:QR Project');
      expect(project.qrCode, 'SP:proj_qr:QR Project');
    });

    test('QR project can have null QR code', () {
      final project = TestData.qrProject(qrCode: null);
      expect(project.qrCode, isNull);
      expect(project.supportsQR, isTrue);
    });

    test('qrCode round-trips through serialization', () {
      final project = TestData.qrProject(qrCode: 'SP:proj_qr:My Project');
      final restored = ProjectModel.fromMap(project.toMap());
      expect(restored.qrCode, 'SP:proj_qr:My Project');
    });
  });

  group('ProjectModel GPS location configuration', () {
    test('GPS project has location with radius', () {
      final project = TestData.gpsProject(radius: 200.0);
      expect(project.location, isNotNull);
      expect(project.location!.latitude, 25.276987);
      expect(project.location!.longitude, 55.296249);
      expect(project.location!.radiusInMeters, 200.0);
    });

    test('GPS project with no location configured', () {
      final project = TestData.gpsProjectNoLocation();
      expect(project.location, isNull);
      expect(project.supportsGPS, isTrue);
    });

    test('location round-trips through serialization', () {
      final project = TestData.gpsProject();
      final restored = ProjectModel.fromMap(project.toMap());
      expect(restored.location, isNotNull);
      expect(restored.location!.latitude, project.location!.latitude);
      expect(restored.location!.longitude, project.location!.longitude);
      expect(restored.location!.radiusInMeters, project.location!.radiusInMeters);
    });

    test('null location round-trips through serialization', () {
      final project = TestData.gpsProjectNoLocation();
      final restored = ProjectModel.fromMap(project.toMap());
      expect(restored.location, isNull);
    });
  });

  group('ProjectModel employee assignment', () {
    test('tracks assigned employee IDs', () {
      final project = TestData.gpsProject();
      expect(project.assignedEmployeeIds, contains('emp_001'));
    });

    test('defaults to empty employee list', () {
      const project = ProjectModel(
        projectId: 'p1',
        companyId: 'c1',
        name: 'Empty',
      );
      expect(project.assignedEmployeeIds, isEmpty);
    });

    test('assignedEmployeeIds round-trips through serialization', () {
      const project = ProjectModel(
        projectId: 'p1',
        companyId: 'c1',
        name: 'Multi',
        assignedEmployeeIds: ['emp_001', 'emp_002', 'emp_003'],
      );
      final restored = ProjectModel.fromMap(project.toMap());
      expect(restored.assignedEmployeeIds, ['emp_001', 'emp_002', 'emp_003']);
    });
  });

  group('ProjectModel max check-ins', () {
    test('defaults to 2 check-ins per day', () {
      const project = ProjectModel(
        projectId: 'p1',
        companyId: 'c1',
        name: 'Default',
      );
      expect(project.maxCheckInsPerDay, 2);
    });

    test('custom max check-ins per day', () {
      const project = ProjectModel(
        projectId: 'p1',
        companyId: 'c1',
        name: 'Custom',
        maxCheckInsPerDay: 5,
      );
      expect(project.maxCheckInsPerDay, 5);
    });

    test('maxCheckInsPerDay round-trips through serialization', () {
      const project = ProjectModel(
        projectId: 'p1',
        companyId: 'c1',
        name: 'Custom',
        maxCheckInsPerDay: 3,
      );
      final restored = ProjectModel.fromMap(project.toMap());
      expect(restored.maxCheckInsPerDay, 3);
    });
  });

  group('ProjectModel serialization with checkInMethods', () {
    test('checkInMethods serializes and deserializes', () {
      final project = TestData.allMethodsProject();
      final map = project.toMap();
      expect(map['checkInMethods'], ['gps', 'nfc', 'qr', 'manual']);

      final restored = ProjectModel.fromMap(map);
      expect(restored.checkInMethods, ['gps', 'nfc', 'qr', 'manual']);
    });

    test('missing checkInMethods defaults to gps and manual', () {
      final map = {
        'projectId': 'p1',
        'companyId': 'c1',
        'name': 'No Methods',
      };
      final project = ProjectModel.fromMap(map);
      expect(project.checkInMethods, ['gps', 'manual']);
    });
  });
}
