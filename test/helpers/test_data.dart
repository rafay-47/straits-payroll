import 'package:straights_psyroll/shared/models/attendance_model.dart';
import 'package:straights_psyroll/shared/models/device_info_model.dart';
import 'package:straights_psyroll/shared/models/project_model.dart';
import 'package:straights_psyroll/shared/models/user_model.dart';

/// Factory methods for creating test data objects.
class TestData {
  TestData._();

  // ── Users ──────────────────────────────────────────────────────────────

  static UserModel employee({
    String uid = 'emp_001',
    String companyId = 'comp_001',
    String name = 'John Doe',
    String? supervisorId = 'sup_001',
    String? assignedProjectId,
    String status = 'active',
  }) {
    return UserModel(
      uid: uid,
      companyId: companyId,
      role: 'employee',
      employeeId: 'ABC-0001',
      name: name,
      email: 'john@test.com',
      supervisorId: supervisorId,
      assignedProjectId: assignedProjectId,
      status: status,
    );
  }

  static UserModel supervisor({
    String uid = 'sup_001',
    String companyId = 'comp_001',
  }) {
    return UserModel(
      uid: uid,
      companyId: companyId,
      role: 'supervisor',
      name: 'Jane Supervisor',
      email: 'jane@test.com',
      status: 'active',
    );
  }

  // ── Projects ───────────────────────────────────────────────────────────

  static ProjectModel gpsProject({
    String projectId = 'proj_gps',
    String companyId = 'comp_001',
    double lat = 25.276987,
    double lon = 55.296249,
    double radius = 200.0,
  }) {
    return ProjectModel(
      projectId: projectId,
      companyId: companyId,
      name: 'GPS Project',
      checkInMethods: const ['gps'],
      location: ProjectLocation(
        latitude: lat,
        longitude: lon,
        address: '123 Test St, Dubai',
        radiusInMeters: radius,
      ),
      assignedEmployeeIds: const ['emp_001'],
    );
  }

  static ProjectModel nfcProject({
    String projectId = 'proj_nfc',
    String companyId = 'comp_001',
    String? nfcTagId = '04:A3:12:5B:6C:7D:8E',
  }) {
    return ProjectModel(
      projectId: projectId,
      companyId: companyId,
      name: 'NFC Project',
      checkInMethods: const ['nfc'],
      nfcTagId: nfcTagId,
      assignedEmployeeIds: const ['emp_001'],
    );
  }

  static ProjectModel qrProject({
    String projectId = 'proj_qr',
    String companyId = 'comp_001',
    String? qrCode = 'SP:proj_qr:QR Project',
  }) {
    return ProjectModel(
      projectId: projectId,
      companyId: companyId,
      name: 'QR Project',
      checkInMethods: const ['qr'],
      qrCode: qrCode,
      assignedEmployeeIds: const ['emp_001'],
    );
  }

  static ProjectModel manualProject({
    String projectId = 'proj_manual',
    String companyId = 'comp_001',
  }) {
    return ProjectModel(
      projectId: projectId,
      companyId: companyId,
      name: 'Manual Project',
      checkInMethods: const ['manual'],
      assignedEmployeeIds: const ['emp_001'],
    );
  }

  static ProjectModel allMethodsProject({
    String projectId = 'proj_all',
    String companyId = 'comp_001',
    String? nfcTagId = '04:A3:12:5B:6C:7D:8E',
    String? qrCode = 'SP:proj_all:All Methods',
  }) {
    return ProjectModel(
      projectId: projectId,
      companyId: companyId,
      name: 'All Methods Project',
      checkInMethods: const ['gps', 'nfc', 'qr', 'manual'],
      nfcTagId: nfcTagId,
      qrCode: qrCode,
      location: const ProjectLocation(
        latitude: 25.276987,
        longitude: 55.296249,
        address: '123 Test St, Dubai',
        radiusInMeters: 200.0,
      ),
      assignedEmployeeIds: const ['emp_001'],
    );
  }

  static ProjectModel noMethodsProject({
    String projectId = 'proj_none',
    String companyId = 'comp_001',
  }) {
    return ProjectModel(
      projectId: projectId,
      companyId: companyId,
      name: 'No Methods Project',
      checkInMethods: const [],
      assignedEmployeeIds: const ['emp_001'],
    );
  }

  static ProjectModel gpsProjectNoLocation({
    String projectId = 'proj_gps_noloc',
    String companyId = 'comp_001',
  }) {
    return ProjectModel(
      projectId: projectId,
      companyId: companyId,
      name: 'GPS No Location',
      checkInMethods: const ['gps'],
      location: null,
      assignedEmployeeIds: const ['emp_001'],
    );
  }

  // ── Attendance ─────────────────────────────────────────────────────────

  static AttendanceModel checkedInAttendance({
    String attendanceId = 'att_001',
    String companyId = 'comp_001',
    String userId = 'emp_001',
    String projectId = 'proj_gps',
    String method = 'gps',
    DateTime? checkInTime,
    int sessionNumber = 1,
  }) {
    return AttendanceModel(
      attendanceId: attendanceId,
      companyId: companyId,
      userId: userId,
      projectId: projectId,
      checkInTime: checkInTime ?? DateTime.now(),
      checkInMethod: method,
      checkInLocation: const LocationData(
        latitude: 25.276987,
        longitude: 55.296249,
        address: '123 Test St, Dubai',
        accuracy: 10.0,
      ),
      status: 'checked_in',
      sessionNumber: sessionNumber,
    );
  }

  static AttendanceModel checkedOutAttendance({
    String attendanceId = 'att_001',
    String companyId = 'comp_001',
    String userId = 'emp_001',
    String projectId = 'proj_gps',
    String method = 'gps',
    double workingHours = 8.0,
  }) {
    final checkIn = DateTime.now().subtract(Duration(hours: workingHours.toInt()));
    return AttendanceModel(
      attendanceId: attendanceId,
      companyId: companyId,
      userId: userId,
      projectId: projectId,
      checkInTime: checkIn,
      checkOutTime: DateTime.now(),
      checkInMethod: method,
      checkInLocation: const LocationData(
        latitude: 25.276987,
        longitude: 55.296249,
        address: '123 Test St, Dubai',
        accuracy: 10.0,
      ),
      status: 'checked_out',
      workingHours: workingHours,
      sessionNumber: 1,
    );
  }

  // ── Device Info ────────────────────────────────────────────────────────

  static DeviceInfo deviceInfo({
    String deviceId = 'device_001',
    String deviceModel = 'iPhone 15 Pro',
    String brand = 'Apple',
  }) {
    return DeviceInfo(
      deviceId: deviceId,
      deviceModel: deviceModel,
      brand: brand,
      platform: 'iOS',
      osVersion: '17.4',
      registeredAt: DateTime(2024, 1, 1),
    );
  }

  // ── Location Data ──────────────────────────────────────────────────────

  static LocationData locationData({
    double lat = 25.276987,
    double lon = 55.296249,
    String address = '123 Test St, Dubai',
    double accuracy = 10.0,
  }) {
    return LocationData(
      latitude: lat,
      longitude: lon,
      address: address,
      accuracy: accuracy,
    );
  }

  // ── Attendance Maps (for Firestore simulation) ─────────────────────────

  static Map<String, dynamic> attendanceMap({
    String attendanceId = 'att_001',
    String companyId = 'comp_001',
    String userId = 'emp_001',
    String projectId = 'proj_gps',
    String method = 'gps',
    String status = 'checked_in',
    DateTime? checkInTime,
  }) {
    return {
      'attendanceId': attendanceId,
      'companyId': companyId,
      'userId': userId,
      'projectId': projectId,
      'checkInTime': (checkInTime ?? DateTime.now()).toIso8601String(),
      'checkOutTime': null,
      'checkInMethod': method,
      'checkInLocation': {
        'latitude': 25.276987,
        'longitude': 55.296249,
        'address': '123 Test St, Dubai',
        'accuracy': 10.0,
      },
      'checkOutLocation': null,
      'deviceInfo': null,
      'verifiedBy': null,
      'notes': null,
      'workingHours': null,
      'status': status,
      'sessionNumber': 1,
    };
  }
}
