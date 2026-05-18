import 'device_info_model.dart';
import '../utils/timestamp_helper.dart';

/// User model supporting four roles: superadmin, companyadmin, supervisor, employee
class UserModel {
  final String uid;
  final String? companyId; // ⭐ NEW: Company reference (null for superadmin)
  final String role; // 'superadmin', 'companyadmin', 'supervisor', 'employee'
  final String? employeeId; // Full format: 'ABC-0001' (for employees only)
  final String? employeeIdNumber; // Number only: '0001' (for sorting/display)
  final String? systemGeneratedId; // DEPRECATED: use employeeId instead
  final String? customId; // DEPRECATED: use employeeId instead
  final String name;
  final String email;
  final String? phoneNumber;
  final String? position; // Job title/position (e.g., "Construction Worker")
  final String? assignedProjectId; // Legacy single-project field
  final List<String> assignedProjectIds; // Multi-project assignment
  final String? supervisorId; // For employees - their supervisor's ID
  final String? employerId; // DEPRECATED: use companyId instead
  final DeviceInfo? deviceInfo; // For employees - device binding
  final bool biometricEnabled;
  final String status; // 'pending', 'approved', 'active', 'suspended'
  final String? approvedBy; // Admin user ID who approved
  final DateTime? approvedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.uid,
    this.companyId, // NEW: null for superadmin, required for others
    required this.role,
    this.employeeId,
    this.employeeIdNumber,
    this.systemGeneratedId,
    this.customId,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.position,
    this.assignedProjectId,
    this.assignedProjectIds = const [],
    this.supervisorId,
    this.employerId,
    this.deviceInfo,
    this.biometricEnabled = false,
    this.status = 'pending',
    this.approvedBy,
    this.approvedAt,
    this.createdAt,
    this.updatedAt,
  });

  // Convenience getters
  bool get isSuperAdmin => role == 'superadmin';
  bool get isCompanyAdmin => role == 'companyadmin';
  bool get isEmployee => role == 'employee';
  bool get isSupervisor => role == 'supervisor';
  bool get isAdmin => role == 'admin' || role == 'companyadmin'; // Backward compatibility
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved' || status == 'active';
  bool get isActive => status == 'active';
  bool get isSuspended => status == 'suspended';
  bool get hasDeviceBound => deviceInfo != null;
  String? get primaryAssignedProjectId =>
      assignedProjectIds.isNotEmpty ? assignedProjectIds.first : assignedProjectId;

  // Get display ID (employeeId is now the full format: ABC-0001)
  String? get displayId => employeeId ?? customId ?? systemGeneratedId;

  // Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'companyId': companyId, // NEW
      'role': role,
      'employeeId': employeeId,
      'employeeIdNumber': employeeIdNumber, // NEW
      'systemGeneratedId': systemGeneratedId,
      'customId': customId,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'position': position,
      'assignedProjectId': assignedProjectId,
      'assignedProjectIds': assignedProjectIds,
      'supervisorId': supervisorId,
      'employerId': employerId,
      'deviceInfo': deviceInfo?.toMap(),
      'biometricEnabled': biometricEnabled,
      'status': status,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Create from Firestore map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    // Provide defaults for required fields to handle null values
    return UserModel(
      uid: map['uid'] as String? ?? '',
      companyId: map['companyId'] as String?, // NEW
      role: map['role'] as String? ?? 'employee',
      employeeId: map['employeeId'] as String?,
      employeeIdNumber: map['employeeIdNumber'] as String?, // NEW
      systemGeneratedId: map['systemGeneratedId'] as String?,
      customId: map['customId'] as String?,
      name: map['name'] as String? ?? 'Unknown',
      email: map['email'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String?,
      position: map['position'] as String?,
      assignedProjectId: map['assignedProjectId'] as String?,
      assignedProjectIds: List<String>.from(map['assignedProjectIds'] as List? ?? []),
      supervisorId: map['supervisorId'] as String?,
      employerId: map['employerId'] as String?,
      deviceInfo: map['deviceInfo'] != null
          ? DeviceInfo.fromMap(map['deviceInfo'] as Map<String, dynamic>)
          : null,
      biometricEnabled: map['biometricEnabled'] as bool? ?? false,
      status: map['status'] as String? ?? 'pending',
      approvedBy: map['approvedBy'] as String?,
      approvedAt: TimestampHelper.parseDateTimeNullable(map['approvedAt']),
      createdAt: map['createdAt'] != null 
          ? TimestampHelper.parseDateTime(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? TimestampHelper.parseDateTime(map['updatedAt'])
          : DateTime.now(),
    );
  }

  // CopyWith method
  UserModel copyWith({
    String? uid,
    String? companyId,
    String? role,
    String? employeeId,
    String? employeeIdNumber,
    String? systemGeneratedId,
    String? customId,
    String? name,
    String? email,
    String? phoneNumber,
    String? position,
    String? assignedProjectId,
    List<String>? assignedProjectIds,
    String? supervisorId,
    String? employerId,
    DeviceInfo? deviceInfo,
    bool? biometricEnabled,
    String? status,
    String? approvedBy,
    DateTime? approvedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      companyId: companyId ?? this.companyId, // NEW
      role: role ?? this.role,
      employeeId: employeeId ?? this.employeeId,
      employeeIdNumber: employeeIdNumber ?? this.employeeIdNumber, // NEW
      systemGeneratedId: systemGeneratedId ?? this.systemGeneratedId,
      customId: customId ?? this.customId,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      position: position ?? this.position,
      assignedProjectId: assignedProjectId ?? this.assignedProjectId,
      assignedProjectIds: assignedProjectIds ?? this.assignedProjectIds,
      supervisorId: supervisorId ?? this.supervisorId,
      employerId: employerId ?? this.employerId,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, role: $role, name: $name, employeeId: $displayId, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}

