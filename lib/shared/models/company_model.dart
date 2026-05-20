import '../utils/timestamp_helper.dart';

/// Company model for multi-tenant system
class CompanyModel {
  final String id;
  final String name;
  final String companyCode; // Unique 3-6 char code (ABC, XYZ, etc.)
  final String? logo; // URL to company logo in Firebase Storage
  final String status; // 'active', 'suspended', 'inactive'
  
  // Additional company info (SA-3)
  final String? registrationNumber; // Business registration / tax ID
  final String? address; // Physical address
  final String? notes; // Free-form notes
  
  // SA-6: Allow super admin to view employees/supervisors for troubleshooting
  final bool allowSuperAdminView;
  
  // Primary Contact
  final CompanyContact primaryContact;
  
  // Settings
  final CompanySettings settings;
  
  // Subscription (for future billing)
  final CompanySubscription subscription;
  
  // Metadata
  final String createdBy; // Super admin user ID
  final DateTime createdAt;
  final DateTime updatedAt;

  const CompanyModel({
    required this.id,
    required this.name,
    required this.companyCode,
    this.logo,
    required this.status,
    this.registrationNumber,
    this.address,
    this.notes,
    this.allowSuperAdminView = true,
    required this.primaryContact,
    required this.settings,
    required this.subscription,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convenience getters
  bool get isActive => status == 'active';
  bool get isSuspended => status == 'suspended';
  bool get isInactive => status == 'inactive';

  // Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'companyCode': companyCode,
      'logo': logo,
      'status': status,
      'registrationNumber': registrationNumber,
      'address': address,
      'notes': notes,
      'allowSuperAdminView': allowSuperAdminView,
      'primaryContact': primaryContact.toMap(),
      'settings': settings.toMap(),
      'subscription': subscription.toMap(),
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from Firestore map
  factory CompanyModel.fromMap(Map<String, dynamic> map) {
    return CompanyModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      companyCode: map['companyCode'] as String? ?? '',
      logo: map['logo'] as String?,
      status: map['status'] as String? ?? 'active',
      registrationNumber: map['registrationNumber'] as String?,
      address: map['address'] as String?,
      notes: map['notes'] as String?,
      allowSuperAdminView: map['allowSuperAdminView'] as bool? ?? true,
      primaryContact: CompanyContact.fromMap(
        map['primaryContact'] as Map<String, dynamic>? ?? {},
      ),
      settings: CompanySettings.fromMap(
        map['settings'] as Map<String, dynamic>? ?? {},
      ),
      subscription: CompanySubscription.fromMap(
        map['subscription'] as Map<String, dynamic>? ?? {},
      ),
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: TimestampHelper.parseDateTime(map['createdAt']),
      updatedAt: TimestampHelper.parseDateTime(map['updatedAt']),
    );
  }

  // CopyWith method
  CompanyModel copyWith({
    String? id,
    String? name,
    String? companyCode,
    String? logo,
    String? status,
    String? registrationNumber,
    String? address,
    String? notes,
    bool? allowSuperAdminView,
    CompanyContact? primaryContact,
    CompanySettings? settings,
    CompanySubscription? subscription,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CompanyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      companyCode: companyCode ?? this.companyCode,
      logo: logo ?? this.logo,
      status: status ?? this.status,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      allowSuperAdminView: allowSuperAdminView ?? this.allowSuperAdminView,
      primaryContact: primaryContact ?? this.primaryContact,
      settings: settings ?? this.settings,
      subscription: subscription ?? this.subscription,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'CompanyModel(id: $id, name: $name, code: $companyCode, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CompanyModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Company contact information
class CompanyContact {
  final String name;
  final String email;
  final String? phone;

  const CompanyContact({
    required this.name,
    required this.email,
    this.phone,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
    };
  }

  factory CompanyContact.fromMap(Map<String, dynamic> map) {
    return CompanyContact(
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String?,
    );
  }

  CompanyContact copyWith({
    String? name,
    String? email,
    String? phone,
  }) {
    return CompanyContact(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }
}

/// Company settings
class CompanySettings {
  final String employeeIdPrefix; // ABC, XYZ, etc.
  final int employeeIdCounter; // Next number to use (0, 1, 2...)
  final int maxCheckInsPerDay; // Default: 2
  final int maxDeviceResetsPerMonth; // Default: 1
  final List<String> allowedCheckInMethods; // ['gps', 'nfc', 'qr', 'manual']
  final int geofenceRadius; // In meters, default: 200
  final WorkingHours workingHours;
  final String timezone; // e.g., 'America/New_York'

  const CompanySettings({
    required this.employeeIdPrefix,
    this.employeeIdCounter = 0,
    this.maxCheckInsPerDay = 2,
    this.maxDeviceResetsPerMonth = 1,
    this.allowedCheckInMethods = const ['gps', 'nfc', 'qr', 'manual'],
    this.geofenceRadius = 200,
    required this.workingHours,
    this.timezone = 'UTC',
  });

  Map<String, dynamic> toMap() {
    return {
      'employeeIdPrefix': employeeIdPrefix,
      'employeeIdCounter': employeeIdCounter,
      'maxCheckInsPerDay': maxCheckInsPerDay,
      'maxDeviceResetsPerMonth': maxDeviceResetsPerMonth,
      'allowedCheckInMethods': allowedCheckInMethods,
      'geofenceRadius': geofenceRadius,
      'workingHours': workingHours.toMap(),
      'timezone': timezone,
    };
  }

  factory CompanySettings.fromMap(Map<String, dynamic> map) {
    return CompanySettings(
      employeeIdPrefix: map['employeeIdPrefix'] as String? ?? '',
      employeeIdCounter: map['employeeIdCounter'] as int? ?? 0,
      maxCheckInsPerDay: map['maxCheckInsPerDay'] as int? ?? 2,
      maxDeviceResetsPerMonth: map['maxDeviceResetsPerMonth'] as int? ?? 1,
      allowedCheckInMethods: map['allowedCheckInMethods'] != null
          ? List<String>.from(map['allowedCheckInMethods'] as List)
          : ['gps', 'nfc', 'qr', 'manual'],
      geofenceRadius: map['geofenceRadius'] as int? ?? 200,
      workingHours: WorkingHours.fromMap(
        map['workingHours'] as Map<String, dynamic>? ?? {},
      ),
      timezone: map['timezone'] as String? ?? 'UTC',
    );
  }

  CompanySettings copyWith({
    String? employeeIdPrefix,
    int? employeeIdCounter,
    int? maxCheckInsPerDay,
    int? maxDeviceResetsPerMonth,
    List<String>? allowedCheckInMethods,
    int? geofenceRadius,
    WorkingHours? workingHours,
    String? timezone,
  }) {
    return CompanySettings(
      employeeIdPrefix: employeeIdPrefix ?? this.employeeIdPrefix,
      employeeIdCounter: employeeIdCounter ?? this.employeeIdCounter,
      maxCheckInsPerDay: maxCheckInsPerDay ?? this.maxCheckInsPerDay,
      maxDeviceResetsPerMonth: maxDeviceResetsPerMonth ?? this.maxDeviceResetsPerMonth,
      allowedCheckInMethods: allowedCheckInMethods ?? this.allowedCheckInMethods,
      geofenceRadius: geofenceRadius ?? this.geofenceRadius,
      workingHours: workingHours ?? this.workingHours,
      timezone: timezone ?? this.timezone,
    );
  }
}

/// Working hours
class WorkingHours {
  final String start; // e.g., '09:00'
  final String end; // e.g., '17:00'

  const WorkingHours({
    this.start = '09:00',
    this.end = '17:00',
  });

  Map<String, dynamic> toMap() {
    return {
      'start': start,
      'end': end,
    };
  }

  factory WorkingHours.fromMap(Map<String, dynamic> map) {
    return WorkingHours(
      start: map['start'] as String? ?? '09:00',
      end: map['end'] as String? ?? '17:00',
    );
  }

  WorkingHours copyWith({
    String? start,
    String? end,
  }) {
    return WorkingHours(
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }
}

/// Company subscription (for future billing)
class CompanySubscription {
  final String plan; // 'free', 'basic', 'premium', 'enterprise'
  final String status; // 'trial', 'active', 'suspended', 'cancelled'
  final int? employeeLimit; // null = unlimited
  final DateTime? startDate;
  final DateTime? endDate;

  const CompanySubscription({
    this.plan = 'free',
    this.status = 'trial',
    this.employeeLimit,
    this.startDate,
    this.endDate,
  });

  bool get isActive => status == 'active' || status == 'trial';
  bool get isSuspended => status == 'suspended';
  bool get isCancelled => status == 'cancelled';
  bool get hasEmployeeLimit => employeeLimit != null;

  Map<String, dynamic> toMap() {
    return {
      'plan': plan,
      'status': status,
      'employeeLimit': employeeLimit,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
    };
  }

  factory CompanySubscription.fromMap(Map<String, dynamic> map) {
    return CompanySubscription(
      plan: map['plan'] as String? ?? 'free',
      status: map['status'] as String? ?? 'trial',
      employeeLimit: map['employeeLimit'] as int?,
      startDate: TimestampHelper.parseDateTimeNullable(map['startDate']),
      endDate: TimestampHelper.parseDateTimeNullable(map['endDate']),
    );
  }

  CompanySubscription copyWith({
    String? plan,
    String? status,
    int? employeeLimit,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return CompanySubscription(
      plan: plan ?? this.plan,
      status: status ?? this.status,
      employeeLimit: employeeLimit ?? this.employeeLimit,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}






