import 'package:flutter_test/flutter_test.dart';
import 'package:straights_psyroll/shared/models/attendance_model.dart';
import '../helpers/test_data.dart';

void main() {
  group('LocationData', () {
    test('toMap produces correct structure', () {
      const loc = LocationData(
        latitude: 25.276987,
        longitude: 55.296249,
        address: '123 Test St',
        accuracy: 10.5,
      );

      final map = loc.toMap();
      expect(map['latitude'], 25.276987);
      expect(map['longitude'], 55.296249);
      expect(map['address'], '123 Test St');
      expect(map['accuracy'], 10.5);
    });

    test('fromMap round-trips correctly', () {
      const original = LocationData(
        latitude: -33.8688,
        longitude: 151.2093,
        address: 'Sydney, Australia',
        accuracy: 5.0,
      );

      final restored = LocationData.fromMap(original.toMap());
      expect(restored.latitude, original.latitude);
      expect(restored.longitude, original.longitude);
      expect(restored.address, original.address);
      expect(restored.accuracy, original.accuracy);
    });

    test('fromMap handles null accuracy', () {
      final map = {
        'latitude': 0.0,
        'longitude': 0.0,
        'address': 'Origin',
      };

      final loc = LocationData.fromMap(map);
      expect(loc.accuracy, isNull);
    });

    test('fromMap handles int coordinates', () {
      final map = {
        'latitude': 25,
        'longitude': 55,
        'address': 'Rounded',
        'accuracy': 10,
      };

      final loc = LocationData.fromMap(map);
      expect(loc.latitude, 25.0);
      expect(loc.longitude, 55.0);
      expect(loc.accuracy, 10.0);
    });
  });

  group('AttendanceModel', () {
    group('creation and defaults', () {
      test('creates with all required fields', () {
        final att = TestData.checkedInAttendance();
        expect(att.attendanceId, 'att_001');
        expect(att.companyId, 'comp_001');
        expect(att.userId, 'emp_001');
        expect(att.projectId, 'proj_gps');
        expect(att.checkInMethod, 'gps');
        expect(att.status, 'checked_in');
        expect(att.sessionNumber, 1);
      });

      test('defaults status to checked_in', () {
        final att = AttendanceModel(
          attendanceId: 'test',
          companyId: 'c',
          userId: 'u',
          projectId: 'p',
          checkInTime: DateTime.now(),
          checkInMethod: 'gps',
        );
        expect(att.status, 'checked_in');
        expect(att.sessionNumber, 1);
      });

      test('checkInLocation can be null', () {
        final att = AttendanceModel(
          attendanceId: 'test',
          companyId: 'c',
          userId: 'u',
          projectId: 'p',
          checkInTime: DateTime.now(),
          checkInMethod: 'nfc',
          checkInLocation: null,
        );
        expect(att.checkInLocation, isNull);
      });
    });

    group('convenience getters', () {
      test('isCheckedIn returns true for checked_in status', () {
        final att = TestData.checkedInAttendance();
        expect(att.isCheckedIn, isTrue);
        expect(att.isCheckedOut, isFalse);
      });

      test('isCheckedOut returns true for checked_out status', () {
        final att = TestData.checkedOutAttendance();
        expect(att.isCheckedOut, isTrue);
        expect(att.isCheckedIn, isFalse);
      });

      test('isGPSCheckIn', () {
        final att = TestData.checkedInAttendance(method: 'gps');
        expect(att.isGPSCheckIn, isTrue);
        expect(att.isNFCCheckIn, isFalse);
        expect(att.isQRCheckIn, isFalse);
        expect(att.isManualCheckIn, isFalse);
      });

      test('isNFCCheckIn', () {
        final att = TestData.checkedInAttendance(method: 'nfc');
        expect(att.isNFCCheckIn, isTrue);
        expect(att.isGPSCheckIn, isFalse);
      });

      test('isQRCheckIn', () {
        final att = TestData.checkedInAttendance(method: 'qr');
        expect(att.isQRCheckIn, isTrue);
      });

      test('isManualCheckIn', () {
        final att = TestData.checkedInAttendance(method: 'manual');
        expect(att.isManualCheckIn, isTrue);
      });
    });

    group('working hours calculation', () {
      test('calculatedWorkingHours returns null when not checked out', () {
        final att = TestData.checkedInAttendance();
        expect(att.calculatedWorkingHours, isNull);
      });

      test('calculatedWorkingHours computes correctly', () {
        final checkIn = DateTime(2024, 1, 1, 9, 0);
        final checkOut = DateTime(2024, 1, 1, 17, 30);
        final att = AttendanceModel(
          attendanceId: 'att',
          companyId: 'c',
          userId: 'u',
          projectId: 'p',
          checkInTime: checkIn,
          checkOutTime: checkOut,
          checkInMethod: 'gps',
          status: 'checked_out',
        );
        expect(att.calculatedWorkingHours, 8.5);
      });

      test('formattedWorkingHours shows 0h 0m when null', () {
        final att = TestData.checkedInAttendance();
        expect(att.formattedWorkingHours, '0h 0m');
      });

      test('formattedWorkingHours formats correctly', () {
        final att = TestData.checkedOutAttendance(workingHours: 8.5);
        expect(att.formattedWorkingHours, '8h 30m');
      });

      test('formattedWorkingHours uses stored value over calculated', () {
        final att = AttendanceModel(
          attendanceId: 'att',
          companyId: 'c',
          userId: 'u',
          projectId: 'p',
          checkInTime: DateTime(2024, 1, 1, 9, 0),
          checkOutTime: DateTime(2024, 1, 1, 17, 0),
          checkInMethod: 'gps',
          status: 'checked_out',
          workingHours: 7.5,
        );
        expect(att.formattedWorkingHours, '7h 30m');
      });
    });

    group('serialization', () {
      test('toMap includes all fields', () {
        final att = TestData.checkedInAttendance();
        final map = att.toMap();

        expect(map['attendanceId'], att.attendanceId);
        expect(map['companyId'], att.companyId);
        expect(map['userId'], att.userId);
        expect(map['projectId'], att.projectId);
        expect(map['checkInMethod'], att.checkInMethod);
        expect(map['status'], att.status);
        expect(map['sessionNumber'], att.sessionNumber);
        expect(map['checkInTime'], isA<String>());
      });

      test('toMap handles null checkInLocation', () {
        final att = AttendanceModel(
          attendanceId: 'test',
          companyId: 'c',
          userId: 'u',
          projectId: 'p',
          checkInTime: DateTime.now(),
          checkInMethod: 'nfc',
          checkInLocation: null,
        );
        final map = att.toMap();
        expect(map['checkInLocation'], isNull);
      });

      test('fromMap round-trips correctly', () {
        final original = TestData.checkedInAttendance();
        final restored = AttendanceModel.fromMap(original.toMap());

        expect(restored.attendanceId, original.attendanceId);
        expect(restored.companyId, original.companyId);
        expect(restored.userId, original.userId);
        expect(restored.projectId, original.projectId);
        expect(restored.checkInMethod, original.checkInMethod);
        expect(restored.status, original.status);
        expect(restored.sessionNumber, original.sessionNumber);
      });

      test('fromMap handles null checkInLocation', () {
        final map = TestData.attendanceMap();
        map['checkInLocation'] = null;

        final att = AttendanceModel.fromMap(map);
        expect(att.checkInLocation, isNull);
      });

      test('fromMap handles missing companyId gracefully', () {
        final map = TestData.attendanceMap();
        map.remove('companyId');

        final att = AttendanceModel.fromMap(map);
        expect(att.companyId, '');
      });

      test('fromMap handles missing status gracefully', () {
        final map = TestData.attendanceMap();
        map.remove('status');

        final att = AttendanceModel.fromMap(map);
        expect(att.status, 'checked_in');
      });

      test('fromMap parses deviceInfo when present', () {
        final map = TestData.attendanceMap();
        map['deviceInfo'] = TestData.deviceInfo().toMap();

        final att = AttendanceModel.fromMap(map);
        expect(att.deviceInfo, isNotNull);
        expect(att.deviceInfo!.deviceId, 'device_001');
      });
    });

    group('copyWith', () {
      test('copies with new status', () {
        final att = TestData.checkedInAttendance();
        final updated = att.copyWith(status: 'checked_out');

        expect(updated.status, 'checked_out');
        expect(updated.attendanceId, att.attendanceId);
        expect(updated.userId, att.userId);
      });

      test('copies with new checkOutTime and workingHours', () {
        final att = TestData.checkedInAttendance();
        final now = DateTime.now();
        final updated = att.copyWith(
          checkOutTime: now,
          workingHours: 8.0,
          status: 'checked_out',
        );

        expect(updated.checkOutTime, now);
        expect(updated.workingHours, 8.0);
        expect(updated.status, 'checked_out');
      });
    });

    group('equality', () {
      test('equal when attendanceId matches', () {
        final a = TestData.checkedInAttendance(attendanceId: 'same_id');
        final b = TestData.checkedInAttendance(attendanceId: 'same_id', method: 'nfc');
        expect(a, equals(b));
      });

      test('not equal when attendanceId differs', () {
        final a = TestData.checkedInAttendance(attendanceId: 'id_a');
        final b = TestData.checkedInAttendance(attendanceId: 'id_b');
        expect(a, isNot(equals(b)));
      });
    });
  });
}
