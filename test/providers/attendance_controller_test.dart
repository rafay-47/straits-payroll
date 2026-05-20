import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:straights_psyroll/shared/constants/app_constants.dart';
import 'package:straights_psyroll/shared/models/attendance_model.dart';
import 'package:straights_psyroll/shared/models/user_model.dart';
import 'package:straights_psyroll/shared/providers/attendance_provider.dart';
import 'package:straights_psyroll/shared/providers/auth_provider.dart';
import '../helpers/mocks.dart';
import '../helpers/test_data.dart';

void main() {
  late MockFirestoreService mockFirestore;
  late MockLocationService mockLocation;
  late MockRef mockRef;
  late AttendanceController controller;

  final testEmployee = TestData.employee();
  final testPosition = FakePosition();
  final testLocationData = TestData.locationData();

  setUpAll(() {
    registerFallbackValue(FakeAttendanceModel());
    registerFallbackValue(FakePosition());
  });

  setUp(() {
    mockFirestore = MockFirestoreService();
    mockLocation = MockLocationService();
    mockRef = MockRef();

    // Stub ref.read for currentUserProvider -> returns the test employee
    when(() => mockRef.read<AsyncValue<UserModel?>>(currentUserProvider))
        .thenReturn(AsyncData(testEmployee));

    // Stub ref.invalidate (called after check-in/out to refresh providers)
    when(() => mockRef.invalidate(todayActiveAttendanceProvider)).thenReturn(null);
    when(() => mockRef.invalidate(attendanceHistoryProvider)).thenReturn(null);

    controller = AttendanceController(mockFirestore, mockLocation, mockRef);
  });

  void stubLocationSuccess() {
    when(() => mockLocation.getCurrentLocation())
        .thenAnswer((_) async => testPosition);
    when(() => mockLocation.createLocationData(any()))
        .thenAnswer((_) async => testLocationData);
  }

  void stubLocationFailure([String message = 'Location permission denied']) {
    when(() => mockLocation.getCurrentLocation()).thenThrow(message);
  }

  void stubNoExistingAttendance(String userId) {
    when(() => mockFirestore.getTodayActiveAttendance(userId))
        .thenAnswer((_) async => null);
  }

  void stubExistingActiveAttendance(String userId) {
    when(() => mockFirestore.getTodayActiveAttendance(userId))
        .thenAnswer((_) async => TestData.checkedInAttendance(userId: userId));
    when(() => mockFirestore.updateAttendance(
          userId: any(named: 'userId'),
          attendanceId: any(named: 'attendanceId'),
          updates: any(named: 'updates'),
        )).thenAnswer((_) async {});
  }

  void stubCheckInCount(String userId, String projectId, int count) {
    when(() => mockFirestore.getTodayCheckInCount(
          userId: userId,
          projectId: projectId,
        )).thenAnswer((_) async => count);
  }

  void stubCreateAttendance() {
    when(() => mockFirestore.createAttendance(any()))
        .thenAnswer((_) async {});
  }

  // ═══════════════════════════════════════════════════════════════════════
  // GPS CHECK-IN TESTS
  // ═══════════════════════════════════════════════════════════════════════

  group('GPS Check-In', () {
    test('succeeds with valid location within radius', () async {
      stubLocationSuccess();
      stubNoExistingAttendance('emp_001');
      stubCheckInCount('emp_001', 'proj_gps', 0);
      stubCreateAttendance();

      final result = await controller.checkIn(
        userId: 'emp_001',
        projectId: 'proj_gps',
        checkInMethod: AppConstants.checkInMethodGPS,
        deviceInfo: TestData.deviceInfo(),
      );

      expect(result, isTrue);
      expect(controller.state.isLoading, isFalse);
      expect(controller.state.successMessage, 'Checked in successfully');
      expect(controller.state.currentAttendance, isNotNull);
      expect(controller.state.currentAttendance!.checkInMethod, 'gps');
      verify(() => mockFirestore.createAttendance(any())).called(1);
    });

    test('fails when location permission denied', () async {
      stubLocationFailure('Location permission denied');
      stubNoExistingAttendance('emp_001');
      stubCheckInCount('emp_001', 'proj_gps', 0);

      final result = await controller.checkIn(
        userId: 'emp_001',
        projectId: 'proj_gps',
        checkInMethod: AppConstants.checkInMethodGPS,
      );

      expect(result, isFalse);
      expect(controller.state.error, contains('Location permission denied'));
      verifyNever(() => mockFirestore.createAttendance(any()));
    });

    test('fails when location services are disabled', () async {
      stubLocationFailure('Location services are disabled');
      stubNoExistingAttendance('emp_001');
      stubCheckInCount('emp_001', 'proj_gps', 0);

      final result = await controller.checkIn(
        userId: 'emp_001',
        projectId: 'proj_gps',
        checkInMethod: AppConstants.checkInMethodGPS,
      );

      expect(result, isFalse);
      expect(controller.state.error, contains('Location services are disabled'));
    });

    test('stores location data in attendance record', () async {
      stubLocationSuccess();
      stubNoExistingAttendance('emp_001');
      stubCheckInCount('emp_001', 'proj_gps', 0);
      stubCreateAttendance();

      await controller.checkIn(
        userId: 'emp_001',
        projectId: 'proj_gps',
        checkInMethod: AppConstants.checkInMethodGPS,
      );

      final captured =
          verify(() => mockFirestore.createAttendance(captureAny())).captured;
      final attendance = captured.first as AttendanceModel;
      expect(attendance.checkInLocation, isNotNull);
      expect(attendance.checkInLocation!.latitude, 25.276987);
      expect(attendance.checkInLocation!.longitude, 55.296249);
    });

    test('records device info when provided', () async {
      stubLocationSuccess();
      stubNoExistingAttendance('emp_001');
      stubCheckInCount('emp_001', 'proj_gps', 0);
      stubCreateAttendance();

      await controller.checkIn(
        userId: 'emp_001',
        projectId: 'proj_gps',
        checkInMethod: AppConstants.checkInMethodGPS,
        deviceInfo: TestData.deviceInfo(),
      );

      final captured =
          verify(() => mockFirestore.createAttendance(captureAny())).captured;
      final attendance = captured.first as AttendanceModel;
      expect(attendance.deviceInfo, isNotNull);
      expect(attendance.deviceInfo!.deviceId, 'device_001');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // NFC CHECK-IN TESTS
  // ═══════════════════════════════════════════════════════════════════════

  group('NFC Check-In', () {
    test('succeeds with location available', () async {
      stubLocationSuccess();
      stubNoExistingAttendance('emp_001');
      stubCheckInCount('emp_001', 'proj_nfc', 0);
      stubCreateAttendance();

      final result = await controller.checkIn(
        userId: 'emp_001',
        projectId: 'proj_nfc',
        checkInMethod: AppConstants.checkInMethodNFC,
        notes: 'NFC Tag: 04:A3:12:5B:6C:7D:8E',
      );

      expect(result, isTrue);
      final captured =
          verify(() => mockFirestore.createAttendance(captureAny())).captured;
      final attendance = captured.first as AttendanceModel;
      expect(attendance.checkInMethod, 'nfc');
      expect(attendance.notes, contains('NFC Tag'));
      expect(attendance.checkInLocation, isNotNull);
    });

    test('succeeds WITHOUT location (permission denied)', () async {
      stubLocationFailure('Location permission denied');
      stubNoExistingAttendance('emp_001');
      stubCheckInCount('emp_001', 'proj_nfc', 0);
      stubCreateAttendance();

      final result = await controller.checkIn(
        userId: 'emp_001',
        projectId: 'proj_nfc',
        checkInMethod: AppConstants.checkInMethodNFC,
        notes: 'NFC Tag: 04:A3:12:5B:6C:7D:8E',
      );

      expect(result, isTrue);
      expect(controller.state.error, isNull);

      final captured =
          verify(() => mockFirestore.createAttendance(captureAny())).captured;
      final attendance = captured.first as AttendanceModel;
      expect(attendance.checkInMethod, 'nfc');
      expect(attendance.checkInLocation, isNull);
    });

    test('records NFC tag ID in notes', () async {
      stubLocationSuccess();
      stubNoExistingAttendance('emp_001');
      stubCheckInCount('emp_001', 'proj_nfc', 0);
      stubCreateAttendance();

      await controller.checkIn(
        userId: 'emp_001',
        projectId: 'proj_nfc',
        checkInMethod: AppConstants.checkInMethodNFC,
        notes: 'NFC Tag: 04:A3:12:5B:6C:7D:8E',
      );

      final captured =
          verify(() => mockFirestore.createAttendance(captureAny())).captured;
      final attendance = captured.first as AttendanceModel;
      expect(attendance.notes, 'NFC Tag: 04:A3:12:5B:6C:7D:8E');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // QR CODE CHECK-IN TESTS
  // ═══════════════════════════════════════════════════════════════════════

  group('QR Code Check-In', () {
    test('succeeds with location available', () async {
      stubLocationSuccess();
      stubNoExistingAttendance('emp_001');
      stubCheckInCount('emp_001', 'proj_qr', 0);
      stubCreateAttendance();

      final result = await controller.checkIn(
        userId: 'emp_001',
        projectId: 'proj_qr',
        checkInMethod: AppConstants.checkInMethodQR,
        notes: 'QR Code: SP:proj_qr:QR Project',
      );

      expect(result, isTrue);
      final captured =
          verify(() => mockFirestore.createAttendance(captureAny())).captured;
      final attendance = captured.first as AttendanceModel;
      expect(attendance.checkInMethod, 'qr');
      expect(attendance.notes, contains('QR Code'));
    });

    test('succeeds WITHOUT location (permission denied)', () async {
      stubLocationFailure('Location permission denied');
      stubNoExistingAttendance('emp_001');
      stubCheckInCount('emp_001', 'proj_qr', 0);
      stubCreateAttendance();

      final result = await controller.checkIn(
        userId: 'emp_001',
        projectId: 'proj_qr',
        checkInMethod: AppConstants.checkInMethodQR,
        notes: 'QR Code: SP:proj_qr:QR Project',
      );

      expect(result, isTrue);

      final captured =
          verify(() => mockFirestore.createAttendance(captureAny())).captured;
      final attendance = captured.first as AttendanceModel;
      expect(attendance.checkInLocation, isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // MANUAL CHECK-IN TESTS
  // ═══════════════════════════════════════════════════════════════════════

  group('Manual Check-In', () {
    test('succeeds with location available', () async {
      stubLocationSuccess();
      stubNoExistingAttendance('emp_001');
      stubCheckInCount('emp_001', 'proj_manual', 0);
      stubCreateAttendance();

      final result = await controller.checkIn(
        userId: 'emp_001',
        projectId: 'proj_manual',
        checkInMethod: AppConstants.checkInMethodManual,
        notes: 'Manual check-in - requires supervisor approval',
      );

      expect(result, isTrue);
      final captured =
          verify(() => mockFirestore.createAttendance(captureAny())).captured;
      final attendance = captured.first as AttendanceModel;
      expect(attendance.checkInMethod, 'manual');
    });

    test('succeeds WITHOUT location (permission denied)', () async {
      stubLocationFailure();
      stubNoExistingAttendance('emp_001');
      stubCheckInCount('emp_001', 'proj_manual', 0);
      stubCreateAttendance();

      final result = await controller.checkIn(
        userId: 'emp_001',
        projectId: 'proj_manual',
        checkInMethod: AppConstants.checkInMethodManual,
      );

      expect(result, isTrue);

      final captured =
          verify(() => mockFirestore.createAttendance(captureAny())).captured;
      final attendance = captured.first as AttendanceModel;
      expect(attendance.checkInLocation, isNull);
    });

    test('manualCheckIn helper delegates correctly', () async {
      stubLocationSuccess();
      stubNoExistingAttendance('emp_001');
      stubCheckInCount('emp_001', 'proj_manual', 0);
      stubCreateAttendance();

      final result = await controller.manualCheckIn(
        employeeId: 'emp_001',
        projectId: 'proj_manual',
        supervisorId: 'sup_001',
        reason: 'Forgot NFC tag',
      );

      expect(result, isTrue);
      final captured =
          verify(() => mockFirestore.createAttendance(captureAny())).captured;
      final attendance = captured.first as AttendanceModel;
      expect(attendance.checkInMethod, 'manual');
      expect(attendance.verifiedBy, 'sup_001');
      expect(attendance.notes, 'Forgot NFC tag');
    });

    test('manualCheckIn uses notes over reason if provided', () async {
      stubLocationSuccess();
      stubNoExistingAttendance('emp_001');
      stubCheckInCount('emp_001', 'proj_manual', 0);
      stubCreateAttendance();

      await controller.manualCheckIn(
        employeeId: 'emp_001',
        projectId: 'proj_manual',
        supervisorId: 'sup_001',
        reason: 'Reason text',
        notes: 'Custom note',
      );

      final captured =
          verify(() => mockFirestore.createAttendance(captureAny())).captured;
      final attendance = captured.first as AttendanceModel;
      expect(attendance.notes, 'Custom note');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // AUTO-CHECKOUT OF EXISTING SESSIONS
  // ═══════════════════════════════════════════════════════════════════════

  group('Auto-checkout of existing sessions', () {
    test('auto-checks out existing active attendance before new check-in',
        () async {
      stubLocationSuccess();
      stubExistingActiveAttendance('emp_001');
      stubCheckInCount('emp_001', 'proj_gps', 0);
      stubCreateAttendance();

      final result = await controller.checkIn(
        userId: 'emp_001',
        projectId: 'proj_gps',
        checkInMethod: AppConstants.checkInMethodGPS,
      );

      expect(result, isTrue);

      verify(() => mockFirestore.updateAttendance(
            userId: 'emp_001',
            attendanceId: 'att_001',
            updates: any(named: 'updates'),
          )).called(1);

      verify(() => mockFirestore.createAttendance(any())).called(1);
    });

    test('skips auto-checkout when no existing attendance', () async {
      stubLocationSuccess();
      stubNoExistingAttendance('emp_001');
      stubCheckInCount('emp_001', 'proj_gps', 0);
      stubCreateAttendance();

      await controller.checkIn(
        userId: 'emp_001',
        projectId: 'proj_gps',
        checkInMethod: AppConstants.checkInMethodGPS,
      );

      verifyNever(() => mockFirestore.updateAttendance(
            userId: any(named: 'userId'),
            attendanceId: any(named: 'attendanceId'),
            updates: any(named: 'updates'),
          ));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // SESSION NUMBERING
  // ═══════════════════════════════════════════════════════════════════════

  group('Session numbering', () {
    test('first check-in of the day is session 1', () async {
      stubLocationSuccess();
      stubNoExistingAttendance('emp_001');
      stubCheckInCount('emp_001', 'proj_gps', 0);
      stubCreateAttendance();

      await controller.checkIn(
        userId: 'emp_001',
        projectId: 'proj_gps',
        checkInMethod: AppConstants.checkInMethodGPS,
      );

      final captured =
          verify(() => mockFirestore.createAttendance(captureAny())).captured;
      final attendance = captured.first as AttendanceModel;
      expect(attendance.sessionNumber, 1);
    });

    test('second check-in of the day is session 2', () async {
      stubLocationSuccess();
      stubNoExistingAttendance('emp_001');
      stubCheckInCount('emp_001', 'proj_gps', 1);
      stubCreateAttendance();

      await controller.checkIn(
        userId: 'emp_001',
        projectId: 'proj_gps',
        checkInMethod: AppConstants.checkInMethodGPS,
      );

      final captured =
          verify(() => mockFirestore.createAttendance(captureAny())).captured;
      final attendance = captured.first as AttendanceModel;
      expect(attendance.sessionNumber, 2);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // COMPANY ID ASSIGNMENT
  // ═══════════════════════════════════════════════════════════════════════

  group('Company ID assignment', () {
    test('attendance record includes companyId from current user', () async {
      stubLocationSuccess();
      stubNoExistingAttendance('emp_001');
      stubCheckInCount('emp_001', 'proj_gps', 0);
      stubCreateAttendance();

      await controller.checkIn(
        userId: 'emp_001',
        projectId: 'proj_gps',
        checkInMethod: AppConstants.checkInMethodGPS,
      );

      final captured =
          verify(() => mockFirestore.createAttendance(captureAny())).captured;
      final attendance = captured.first as AttendanceModel;
      expect(attendance.companyId, 'comp_001');
    });

    test('check-in fails when user has no companyId', () async {
      final userNoCompany = UserModel(
        uid: 'emp_no_company',
        companyId: null,
        role: 'employee',
        name: 'No Company',
        email: 'nocompany@test.com',
      );

      when(() => mockRef.read<AsyncValue<UserModel?>>(currentUserProvider))
          .thenReturn(AsyncData(userNoCompany));

      stubLocationSuccess();
      when(() => mockFirestore.getTodayActiveAttendance('emp_no_company'))
          .thenAnswer((_) async => null);
      when(() => mockFirestore.getTodayCheckInCount(
            userId: 'emp_no_company',
            projectId: 'proj_gps',
          )).thenAnswer((_) async => 0);

      final result = await controller.checkIn(
        userId: 'emp_no_company',
        projectId: 'proj_gps',
        checkInMethod: AppConstants.checkInMethodGPS,
      );

      expect(result, isFalse);
      expect(controller.state.error,
          contains('User not found or company not set'));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // CHECK-OUT TESTS
  // ═══════════════════════════════════════════════════════════════════════

  group('Check-Out', () {
    void stubCheckOutDeps() {
      when(() => mockFirestore.getAttendanceById('emp_001', 'att_001'))
          .thenAnswer((_) async => TestData.checkedInAttendance());
      when(() => mockFirestore.updateAttendance(
            userId: any(named: 'userId'),
            attendanceId: any(named: 'attendanceId'),
            updates: any(named: 'updates'),
          )).thenAnswer((_) async {});
    }

    test('successful check-out with location', () async {
      stubLocationSuccess();
      stubCheckOutDeps();

      final result = await controller.checkOut(
        userId: 'emp_001',
        attendanceId: 'att_001',
        checkOutMethod: AppConstants.checkInMethodGPS,
      );

      expect(result, isTrue);
      expect(controller.state.successMessage, 'Checked out successfully');

      final captured = verify(() => mockFirestore.updateAttendance(
            userId: 'emp_001',
            attendanceId: 'att_001',
            updates: captureAny(named: 'updates'),
          )).captured;

      final updates = captured.first as Map<String, dynamic>;
      expect(updates['status'], 'checked_out');
      expect(updates['checkOutMethod'], AppConstants.checkInMethodGPS);
      expect(updates.containsKey('checkOutTime'), isTrue);
      expect(updates.containsKey('workingHours'), isTrue);
      expect(updates.containsKey('checkOutLocation'), isTrue);
    });

    test('check-out succeeds when location unavailable', () async {
      stubLocationFailure();
      stubCheckOutDeps();

      final result = await controller.checkOut(
        userId: 'emp_001',
        attendanceId: 'att_001',
        checkOutMethod: AppConstants.checkInMethodNFC,
      );

      expect(result, isTrue);

      final captured = verify(() => mockFirestore.updateAttendance(
            userId: 'emp_001',
            attendanceId: 'att_001',
            updates: captureAny(named: 'updates'),
          )).captured;

      final updates = captured.first as Map<String, dynamic>;
      expect(updates['status'], 'checked_out');
      expect(updates.containsKey('checkOutLocation'), isFalse);
    });

    test('check-out fails when attendance not found', () async {
      stubLocationSuccess();
      when(() => mockFirestore.getAttendanceById('emp_001', 'att_missing'))
          .thenAnswer((_) async => null);

      final result = await controller.checkOut(
        userId: 'emp_001',
        attendanceId: 'att_missing',
      );

      expect(result, isFalse);
      expect(controller.state.error, contains('No active check-in found'));
    });

    test('check-out appends notes to existing notes', () async {
      stubLocationSuccess();
      final existingAtt =
          TestData.checkedInAttendance().copyWith(notes: 'Check-in note');
      when(() => mockFirestore.getAttendanceById('emp_001', 'att_001'))
          .thenAnswer((_) async => existingAtt);
      when(() => mockFirestore.updateAttendance(
            userId: any(named: 'userId'),
            attendanceId: any(named: 'attendanceId'),
            updates: any(named: 'updates'),
          )).thenAnswer((_) async {});

      await controller.checkOut(
        userId: 'emp_001',
        attendanceId: 'att_001',
        notes: 'NFC Tag: 04:AB',
      );

      final captured = verify(() => mockFirestore.updateAttendance(
            userId: any(named: 'userId'),
            attendanceId: any(named: 'attendanceId'),
            updates: captureAny(named: 'updates'),
          )).captured;

      final updates = captured.first as Map<String, dynamic>;
      expect(updates['notes'], 'Check-in note | Check-out: NFC Tag: 04:AB');
    });

    test('check-out calculates working hours', () async {
      stubLocationSuccess();
      final twoHoursAgo =
          DateTime.now().subtract(const Duration(hours: 2));
      final existingAtt =
          TestData.checkedInAttendance(checkInTime: twoHoursAgo);
      when(() => mockFirestore.getAttendanceById('emp_001', 'att_001'))
          .thenAnswer((_) async => existingAtt);
      when(() => mockFirestore.updateAttendance(
            userId: any(named: 'userId'),
            attendanceId: any(named: 'attendanceId'),
            updates: any(named: 'updates'),
          )).thenAnswer((_) async {});

      await controller.checkOut(
        userId: 'emp_001',
        attendanceId: 'att_001',
      );

      final captured = verify(() => mockFirestore.updateAttendance(
            userId: any(named: 'userId'),
            attendanceId: any(named: 'attendanceId'),
            updates: captureAny(named: 'updates'),
          )).captured;

      final updates = captured.first as Map<String, dynamic>;
      final workingHours = updates['workingHours'] as double;
      expect(workingHours, closeTo(2.0, 0.1));
    });

    test('check-out via NFC records method', () async {
      stubLocationSuccess();
      stubCheckOutDeps();

      await controller.checkOut(
        userId: 'emp_001',
        attendanceId: 'att_001',
        checkOutMethod: AppConstants.checkInMethodNFC,
        notes: 'NFC Tag: 04:A3:12:5B:6C:7D:8E',
      );

      final captured = verify(() => mockFirestore.updateAttendance(
            userId: any(named: 'userId'),
            attendanceId: any(named: 'attendanceId'),
            updates: captureAny(named: 'updates'),
          )).captured;

      final updates = captured.first as Map<String, dynamic>;
      expect(updates['checkOutMethod'], 'nfc');
    });

    test('check-out via QR records method', () async {
      stubLocationSuccess();
      stubCheckOutDeps();

      await controller.checkOut(
        userId: 'emp_001',
        attendanceId: 'att_001',
        checkOutMethod: AppConstants.checkInMethodQR,
        notes: 'QR Code: SP:proj_gps:Test',
      );

      final captured = verify(() => mockFirestore.updateAttendance(
            userId: any(named: 'userId'),
            attendanceId: any(named: 'attendanceId'),
            updates: captureAny(named: 'updates'),
          )).captured;

      final updates = captured.first as Map<String, dynamic>;
      expect(updates['checkOutMethod'], 'qr');
    });

    test('check-out via manual records method', () async {
      stubLocationSuccess();
      stubCheckOutDeps();

      await controller.checkOut(
        userId: 'emp_001',
        attendanceId: 'att_001',
        checkOutMethod: AppConstants.checkInMethodManual,
      );

      final captured = verify(() => mockFirestore.updateAttendance(
            userId: any(named: 'userId'),
            attendanceId: any(named: 'attendanceId'),
            updates: captureAny(named: 'updates'),
          )).captured;

      final updates = captured.first as Map<String, dynamic>;
      expect(updates['checkOutMethod'], 'manual');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // STATE MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════

  group('AttendanceController state management', () {
    test('initial state is not loading', () {
      expect(controller.state.isLoading, isFalse);
      expect(controller.state.error, isNull);
      expect(controller.state.successMessage, isNull);
      expect(controller.state.currentAttendance, isNull);
    });

    test('clearMessages resets error and successMessage', () async {
      stubLocationSuccess();
      stubNoExistingAttendance('emp_001');
      stubCheckInCount('emp_001', 'proj_gps', 0);
      stubCreateAttendance();

      await controller.checkIn(
        userId: 'emp_001',
        projectId: 'proj_gps',
        checkInMethod: AppConstants.checkInMethodGPS,
      );

      expect(controller.state.successMessage, isNotNull);

      controller.clearMessages();
      expect(controller.state.error, isNull);
      expect(controller.state.successMessage, isNull);
    });

    test('setCurrentAttendance updates state', () {
      final att = TestData.checkedInAttendance();
      controller.setCurrentAttendance(att);
      expect(controller.state.currentAttendance, att);
    });

    test('error state is set on Firestore failure', () async {
      stubLocationSuccess();
      stubNoExistingAttendance('emp_001');
      stubCheckInCount('emp_001', 'proj_gps', 0);
      when(() => mockFirestore.createAttendance(any()))
          .thenThrow('Firestore write failed');

      final result = await controller.checkIn(
        userId: 'emp_001',
        projectId: 'proj_gps',
        checkInMethod: AppConstants.checkInMethodGPS,
      );

      expect(result, isFalse);
      expect(controller.state.error, contains('Firestore write failed'));
      expect(controller.state.isLoading, isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // CROSS-METHOD LOCATION BEHAVIOR
  // ═══════════════════════════════════════════════════════════════════════

  group('Location behavior varies by method', () {
    for (final method in [
      AppConstants.checkInMethodNFC,
      AppConstants.checkInMethodQR,
      AppConstants.checkInMethodManual,
    ]) {
      test('$method check-in succeeds without location', () async {
        stubLocationFailure('Permission denied');
        stubNoExistingAttendance('emp_001');
        stubCheckInCount('emp_001', 'proj_all', 0);
        stubCreateAttendance();

        final result = await controller.checkIn(
          userId: 'emp_001',
          projectId: 'proj_all',
          checkInMethod: method,
        );

        expect(result, isTrue,
            reason: '$method should succeed without location');
      });
    }

    test('GPS check-in FAILS without location', () async {
      stubLocationFailure('Permission denied');
      stubNoExistingAttendance('emp_001');
      stubCheckInCount('emp_001', 'proj_gps', 0);

      final result = await controller.checkIn(
        userId: 'emp_001',
        projectId: 'proj_gps',
        checkInMethod: AppConstants.checkInMethodGPS,
      );

      expect(result, isFalse, reason: 'GPS must require location');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ATTENDANCE ID GENERATION
  // ═══════════════════════════════════════════════════════════════════════

  group('Attendance ID generation', () {
    test('attendance ID starts with att_ prefix', () async {
      stubLocationSuccess();
      stubNoExistingAttendance('emp_001');
      stubCheckInCount('emp_001', 'proj_gps', 0);
      stubCreateAttendance();

      await controller.checkIn(
        userId: 'emp_001',
        projectId: 'proj_gps',
        checkInMethod: AppConstants.checkInMethodGPS,
      );

      final captured =
          verify(() => mockFirestore.createAttendance(captureAny())).captured;
      final attendance = captured.first as AttendanceModel;
      expect(attendance.attendanceId, startsWith('att_'));
    });

    test('attendance IDs are unique across check-ins', () async {
      stubLocationSuccess();
      stubNoExistingAttendance('emp_001');
      stubCheckInCount('emp_001', 'proj_gps', 0);
      stubCreateAttendance();

      await controller.checkIn(
        userId: 'emp_001',
        projectId: 'proj_gps',
        checkInMethod: AppConstants.checkInMethodGPS,
      );

      // Capture first attendance ID
      final captured1 =
          verify(() => mockFirestore.createAttendance(captureAny())).captured;
      final id1 = (captured1.first as AttendanceModel).attendanceId;

      // Small delay so millisecondsSinceEpoch differs
      await Future.delayed(const Duration(milliseconds: 5));

      // Reset stubs for second check-in
      reset(mockFirestore);
      stubNoExistingAttendance('emp_001');
      stubCheckInCount('emp_001', 'proj_gps', 1);
      stubCreateAttendance();

      await controller.checkIn(
        userId: 'emp_001',
        projectId: 'proj_gps',
        checkInMethod: AppConstants.checkInMethodGPS,
      );

      final captured2 =
          verify(() => mockFirestore.createAttendance(captureAny())).captured;
      final id2 = (captured2.first as AttendanceModel).attendanceId;

      expect(id1, isNot(equals(id2)));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ATTENDANCE STATE copyWith
  // ═══════════════════════════════════════════════════════════════════════

  group('AttendanceState', () {
    test('copyWith preserves existing values', () {
      final att = TestData.checkedInAttendance();
      const state = AttendanceState(isLoading: true);
      final updated = state.copyWith(currentAttendance: att);

      expect(updated.isLoading, isTrue);
      expect(updated.currentAttendance, att);
    });

    test('copyWith clears error and successMessage', () {
      const state = AttendanceState(
        error: 'some error',
        successMessage: 'success',
      );
      final updated = state.copyWith();

      expect(updated.error, isNull);
      expect(updated.successMessage, isNull);
    });
  });
}
