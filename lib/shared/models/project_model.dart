import '../utils/timestamp_helper.dart';
import '../constants/app_constants.dart';

/// Project location with GPS coordinates and radius
class ProjectLocation {
  final double latitude;
  final double longitude;
  final String address;
  final double radiusInMeters; // Check-in radius (e.g., 200m)

  const ProjectLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.radiusInMeters = 200.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'radiusInMeters': radiusInMeters,
    };
  }

  factory ProjectLocation.fromMap(Map<String, dynamic> map) {
    return ProjectLocation(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      address: map['address'] as String,
      radiusInMeters: (map['radiusInMeters'] as num?)?.toDouble() ?? 200.0,
    );
  }
}

/// Project model with location and check-in configuration
class ProjectModel {
  final String projectId;
  final String companyId; // ⭐ NEW: Company reference for multi-tenancy
  final String name;
  final String? description;
  final String? employerId; // DEPRECATED: use companyId instead
  final String? supervisorId;
  final List<String> assignedEmployeeIds; // List of employee UIDs assigned to this project
  final ProjectLocation? location;
  final List<String> checkInMethods; // ['gps', 'nfc', 'qr', 'manual']
  final String checkInRequirement; // 'any_one' | 'all_enabled'
  final String? nfcTagId; // NFC tag ID if NFC is enabled
  final String? qrCode; // Legacy single QR code data
  final List<String> qrCodes; // Multiple active QR codes
  final int maxCheckInsPerDay; // Default: 2
  final int maxCheckOutsPerDay; // Default: 2
  final bool requireCheckOutBeforeNewCheckIn; // Default: true
  final bool isActive;
  final String? createdBy; // Admin user ID
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProjectModel({
    required this.projectId,
    required this.companyId, // NEW: Required for multi-tenancy
    required this.name,
    this.description,
    this.employerId,
    this.supervisorId,
    this.assignedEmployeeIds = const [],
    this.location,
    this.checkInMethods = const ['gps', 'manual'],
    this.checkInRequirement = AppConstants.checkInRequirementAnyOne,
    this.nfcTagId,
    this.qrCode,
    this.qrCodes = const [],
    this.maxCheckInsPerDay = 2,
    this.maxCheckOutsPerDay = 2,
    this.requireCheckOutBeforeNewCheckIn = true,
    this.isActive = true,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  // Convenience getters
  bool get supportsGPS => checkInMethods.contains('gps');
  bool get supportsNFC => checkInMethods.contains('nfc');
  bool get supportsQR => checkInMethods.contains('qr');
  bool get supportsManual => checkInMethods.contains('manual');
  int get activeCheckInMethodsCount => checkInMethods.length;
  bool get requiresAllMethods =>
      checkInRequirement == AppConstants.checkInRequirementAllEnabled;

  // Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'companyId': companyId, // NEW
      'name': name,
      'description': description,
      'employerId': employerId,
      'supervisorId': supervisorId,
      'assignedEmployeeIds': assignedEmployeeIds,
      'location': location?.toMap(),
      'checkInMethods': checkInMethods,
      'checkInRequirement': checkInRequirement,
      'nfcTagId': nfcTagId,
      'qrCode': qrCode,
      'qrCodes': qrCodes,
      'maxCheckInsPerDay': maxCheckInsPerDay,
      'maxCheckOutsPerDay': maxCheckOutsPerDay,
      'requireCheckOutBeforeNewCheckIn': requireCheckOutBeforeNewCheckIn,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Create from Firestore map
  factory ProjectModel.fromMap(Map<String, dynamic> map) {
    return ProjectModel(
      projectId: map['projectId'] as String? ?? '',
      companyId: map['companyId'] as String? ?? '', // NEW
      name: map['name'] as String? ?? 'Unnamed Project',
      description: map['description'] as String?,
      employerId: map['employerId'] as String?,
      supervisorId: map['supervisorId'] as String?,
      assignedEmployeeIds: List<String>.from(map['assignedEmployeeIds'] as List? ?? []),
      location: map['location'] != null 
          ? ProjectLocation.fromMap(map['location'] as Map<String, dynamic>)
          : null,
      checkInMethods: map['checkInMethods'] != null
          ? List<String>.from(map['checkInMethods'] as List)
          : ['gps', 'manual'],
      checkInRequirement: map['checkInRequirement'] as String? ??
          AppConstants.checkInRequirementAnyOne,
      nfcTagId: map['nfcTagId'] as String?,
      qrCode: map['qrCode'] as String?,
      qrCodes: map['qrCodes'] != null
          ? List<String>.from(map['qrCodes'] as List)
          : (map['qrCode'] != null ? [map['qrCode'] as String] : const []),
      maxCheckInsPerDay: map['maxCheckInsPerDay'] as int? ?? 2,
      maxCheckOutsPerDay: map['maxCheckOutsPerDay'] as int? ?? 2,
      requireCheckOutBeforeNewCheckIn: map['requireCheckOutBeforeNewCheckIn'] as bool? ?? true,
      isActive: map['isActive'] as bool? ?? true,
      createdBy: map['createdBy'] as String?,
      createdAt: map['createdAt'] != null 
          ? TimestampHelper.parseDateTime(map['createdAt'])
          : null,
      updatedAt: TimestampHelper.parseDateTimeNullable(map['updatedAt']),
    );
  }

  // CopyWith method
  ProjectModel copyWith({
    String? projectId,
    String? companyId,
    String? name,
    String? description,
    String? employerId,
    String? supervisorId,
    List<String>? assignedEmployeeIds,
    ProjectLocation? location,
    List<String>? checkInMethods,
    String? checkInRequirement,
    String? nfcTagId,
    String? qrCode,
    List<String>? qrCodes,
    int? maxCheckInsPerDay,
    int? maxCheckOutsPerDay,
    bool? requireCheckOutBeforeNewCheckIn,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProjectModel(
      projectId: projectId ?? this.projectId,
      companyId: companyId ?? this.companyId, // NEW
      name: name ?? this.name,
      description: description ?? this.description,
      employerId: employerId ?? this.employerId,
      supervisorId: supervisorId ?? this.supervisorId,
      assignedEmployeeIds: assignedEmployeeIds ?? this.assignedEmployeeIds,
      location: location ?? this.location,
      checkInMethods: checkInMethods ?? this.checkInMethods,
      checkInRequirement: checkInRequirement ?? this.checkInRequirement,
      nfcTagId: nfcTagId ?? this.nfcTagId,
      qrCode: qrCode ?? this.qrCode,
      qrCodes: qrCodes ?? this.qrCodes,
      maxCheckInsPerDay: maxCheckInsPerDay ?? this.maxCheckInsPerDay,
      maxCheckOutsPerDay: maxCheckOutsPerDay ?? this.maxCheckOutsPerDay,
      requireCheckOutBeforeNewCheckIn: requireCheckOutBeforeNewCheckIn ?? this.requireCheckOutBeforeNewCheckIn,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ProjectModel(id: $projectId, name: $name, supervisor: $supervisorId, active: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProjectModel && other.projectId == projectId;
  }

  @override
  int get hashCode => projectId.hashCode;
}

