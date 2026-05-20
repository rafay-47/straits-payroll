import 'device_info_model.dart';
import '../utils/timestamp_helper.dart';

/// Location data for check-in/check-out
class LocationData {
  final double latitude;
  final double longitude;
  final String address;
  final double? accuracy; // GPS accuracy in meters

  const LocationData({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.accuracy,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'accuracy': accuracy,
    };
  }

  factory LocationData.fromMap(Map<String, dynamic> map) {
    return LocationData(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      address: map['address'] as String,
      accuracy: (map['accuracy'] as num?)?.toDouble(),
    );
  }
}

/// Attendance model for check-in/check-out tracking
class AttendanceModel {
  final String attendanceId;
  final String companyId; // ⭐ NEW: Company reference for multi-tenancy
  final String userId;
  final String projectId;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String checkInMethod; // 'gps', 'nfc', 'qr', 'manual'
  final LocationData? checkInLocation; // Nullable: location may not be available for NFC/QR/Manual
  final LocationData? checkOutLocation;
  final DeviceInfo? deviceInfo; // Device used for check-in
  final String? verifiedBy; // Supervisor ID if manual check-in
  final String? notes; // Optional notes (for manual check-in)
  final double? workingHours; // Calculated working hours
  final String status; // 'checked_in', 'checked_out'
  final int sessionNumber; // 1 or 2 (for 2 check-ins per day)

  const AttendanceModel({
    required this.attendanceId,
    required this.companyId, // NEW: Required for multi-tenancy
    required this.userId,
    required this.projectId,
    required this.checkInTime,
    this.checkOutTime,
    required this.checkInMethod,
    this.checkInLocation,
    this.checkOutLocation,
    this.deviceInfo,
    this.verifiedBy,
    this.notes,
    this.workingHours,
    this.status = 'checked_in',
    this.sessionNumber = 1,
  });

  // Convenience getters
  bool get isCheckedIn => status == 'checked_in';
  bool get isCheckedOut => status == 'checked_out';
  bool get isManualCheckIn => checkInMethod == 'manual';
  bool get isGPSCheckIn => checkInMethod == 'gps';
  bool get isNFCCheckIn => checkInMethod == 'nfc';
  bool get isQRCheckIn => checkInMethod == 'qr';

  // Calculate working hours if checked out
  double? get calculatedWorkingHours {
    if (checkOutTime == null) return null;
    final duration = checkOutTime!.difference(checkInTime);
    return duration.inMinutes / 60.0; // Convert to hours with decimals
  }

  // Get formatted working hours (e.g., "8h 30m")
  String get formattedWorkingHours {
    final hours = workingHours ?? calculatedWorkingHours;
    if (hours == null) return '0h 0m';
    
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    return '${h}h ${m}m';
  }

  // Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'attendanceId': attendanceId,
      'companyId': companyId, // NEW
      'userId': userId,
      'projectId': projectId,
      'checkInTime': checkInTime.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'checkInMethod': checkInMethod,
      'checkInLocation': checkInLocation?.toMap(),
      'checkOutLocation': checkOutLocation?.toMap(),
      'deviceInfo': deviceInfo?.toMap(),
      'verifiedBy': verifiedBy,
      'notes': notes,
      'workingHours': workingHours ?? calculatedWorkingHours,
      'status': status,
      'sessionNumber': sessionNumber,
    };
  }

  // Create from Firestore map
  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    return AttendanceModel(
      attendanceId: map['attendanceId'] as String,
      companyId: map['companyId'] as String? ?? '', // NEW
      userId: map['userId'] as String,
      projectId: map['projectId'] as String,
      checkInTime: TimestampHelper.parseDateTime(map['checkInTime']),
      checkOutTime: TimestampHelper.parseDateTimeNullable(map['checkOutTime']),
      checkInMethod: map['checkInMethod'] as String,
      checkInLocation: map['checkInLocation'] != null
          ? LocationData.fromMap(map['checkInLocation'] as Map<String, dynamic>)
          : null,
      checkOutLocation: map['checkOutLocation'] != null
          ? LocationData.fromMap(map['checkOutLocation'] as Map<String, dynamic>)
          : null,
      deviceInfo: map['deviceInfo'] != null
          ? DeviceInfo.fromMap(map['deviceInfo'] as Map<String, dynamic>)
          : null,
      verifiedBy: map['verifiedBy'] as String?,
      notes: map['notes'] as String?,
      workingHours: (map['workingHours'] as num?)?.toDouble(),
      status: map['status'] as String? ?? 'checked_in',
      sessionNumber: map['sessionNumber'] as int? ?? 1,
    );
  }

  // CopyWith method
  AttendanceModel copyWith({
    String? attendanceId,
    String? companyId,
    String? userId,
    String? projectId,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    String? checkInMethod,
    LocationData? checkInLocation,
    LocationData? checkOutLocation,
    DeviceInfo? deviceInfo,
    String? verifiedBy,
    String? notes,
    double? workingHours,
    String? status,
    int? sessionNumber,
  }) {
    return AttendanceModel(
      attendanceId: attendanceId ?? this.attendanceId,
      companyId: companyId ?? this.companyId, // NEW
      userId: userId ?? this.userId,
      projectId: projectId ?? this.projectId,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      checkInMethod: checkInMethod ?? this.checkInMethod,
      checkInLocation: checkInLocation ?? this.checkInLocation,
      checkOutLocation: checkOutLocation ?? this.checkOutLocation,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      notes: notes ?? this.notes,
      workingHours: workingHours ?? this.workingHours,
      status: status ?? this.status,
      sessionNumber: sessionNumber ?? this.sessionNumber,
    );
  }

  @override
  String toString() {
    return 'AttendanceModel(id: $attendanceId, user: $userId, project: $projectId, method: $checkInMethod, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AttendanceModel && other.attendanceId == attendanceId;
  }

  @override
  int get hashCode => attendanceId.hashCode;
}

