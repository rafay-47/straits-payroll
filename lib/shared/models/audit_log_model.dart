import '../utils/timestamp_helper.dart';

/// Audit log model for tracking system actions
class AuditLogModel {
  final String logId;
  final String? companyId; // ⭐ NEW: null for super admin actions, company ID for company-specific actions
  final String userId; // Who performed the action
  final String action; // 'create_project', 'approve_employee', 'reset_device', etc.
  final String entityType; // 'user', 'project', 'attendance', 'device', 'company'
  final String entityId; // ID of the affected entity
  final Map<String, dynamic>? details; // Action-specific details
  final DateTime timestamp;
  final String? ipAddress;
  final String platform; // 'mobile', 'web'

  const AuditLogModel({
    required this.logId,
    this.companyId, // NEW: null for super admin actions
    required this.userId,
    required this.action,
    required this.entityType,
    required this.entityId,
    this.details,
    required this.timestamp,
    this.ipAddress,
    this.platform = 'mobile',
  });

  // Predefined actions
  static const String actionCreateCompany = 'create_company'; // NEW
  static const String actionUpdateCompany = 'update_company'; // NEW
  static const String actionSuspendCompany = 'suspend_company'; // NEW
  static const String actionDeleteCompany = 'delete_company'; // NEW
  static const String actionViewCompanyData = 'view_company_data'; // NEW
  static const String actionCreateProject = 'create_project';
  static const String actionUpdateProject = 'update_project';
  static const String actionDeleteProject = 'delete_project';
  static const String actionApproveEmployee = 'approve_employee';
  static const String actionRejectEmployee = 'reject_employee';
  static const String actionSuspendEmployee = 'suspend_employee';
  static const String actionActivateEmployee = 'activate_employee';
  static const String actionAssignCustomId = 'assign_custom_id';
  static const String actionApproveDeviceReset = 'approve_device_reset';
  static const String actionRejectDeviceReset = 'reject_device_reset';
  static const String actionAssignToProject = 'assign_to_project';
  static const String actionRemoveFromProject = 'remove_from_project';
  static const String actionManualCheckIn = 'manual_check_in';
  static const String actionManualCheckOut = 'manual_check_out';
  static const String actionUploadDocument = 'upload_document';
  static const String actionDeleteDocument = 'delete_document';
  static const String actionUpdateSettings = 'update_settings';

  // Get human-readable action name
  String get actionDisplayName {
    switch (action) {
      case actionCreateCompany:
        return 'Created Company';
      case actionUpdateCompany:
        return 'Updated Company';
      case actionSuspendCompany:
        return 'Suspended Company';
      case actionDeleteCompany:
        return 'Deleted Company';
      case actionViewCompanyData:
        return 'Viewed Company Data';
      case actionCreateProject:
        return 'Created Project';
      case actionUpdateProject:
        return 'Updated Project';
      case actionDeleteProject:
        return 'Deleted Project';
      case actionApproveEmployee:
        return 'Approved Employee';
      case actionRejectEmployee:
        return 'Rejected Employee';
      case actionSuspendEmployee:
        return 'Suspended Employee';
      case actionActivateEmployee:
        return 'Activated Employee';
      case actionAssignCustomId:
        return 'Assigned Custom ID';
      case actionApproveDeviceReset:
        return 'Approved Device Reset';
      case actionRejectDeviceReset:
        return 'Rejected Device Reset';
      case actionAssignToProject:
        return 'Assigned to Project';
      case actionRemoveFromProject:
        return 'Removed from Project';
      case actionManualCheckIn:
        return 'Manual Check-In';
      case actionManualCheckOut:
        return 'Manual Check-Out';
      case actionUploadDocument:
        return 'Uploaded Document';
      case actionDeleteDocument:
        return 'Deleted Document';
      case actionUpdateSettings:
        return 'Updated Settings';
      default:
        return action;
    }
  }

  // Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'logId': logId,
      'companyId': companyId, // NEW
      'userId': userId,
      'action': action,
      'entityType': entityType,
      'entityId': entityId,
      'details': details,
      'timestamp': timestamp.toIso8601String(),
      'ipAddress': ipAddress,
      'platform': platform,
    };
  }

  // Create from Firestore map
  factory AuditLogModel.fromMap(Map<String, dynamic> map) {
    return AuditLogModel(
      logId: map['logId'] as String,
      companyId: map['companyId'] as String?, // NEW
      userId: map['userId'] as String,
      action: map['action'] as String,
      entityType: map['entityType'] as String,
      entityId: map['entityId'] as String,
      details: map['details'] as Map<String, dynamic>?,
      timestamp: TimestampHelper.parseDateTime(map['timestamp']),
      ipAddress: map['ipAddress'] as String?,
      platform: map['platform'] as String? ?? 'mobile',
    );
  }

  @override
  String toString() {
    return 'AuditLogModel(id: $logId, action: $action, entity: $entityType/$entityId, time: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuditLogModel && other.logId == logId;
  }

  @override
  int get hashCode => logId.hashCode;
}

