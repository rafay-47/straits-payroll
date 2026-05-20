import 'device_info_model.dart';
import '../utils/timestamp_helper.dart';

/// Device reset request model for employee device change
class DeviceResetRequestModel {
  final String requestId;
  final String companyId; // ⭐ NEW: Company reference for multi-tenancy
  final String userId; // Employee requesting reset
  final String userName; // Employee name for display
  final String reason; // Selected reason
  final String? additionalDetails; // Optional details
  final DeviceInfo oldDeviceInfo; // Current/old device
  final DeviceInfo currentDeviceInfo; // Alias for oldDeviceInfo
  final DeviceInfo? newDeviceInfo; // New device (after approval)
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime requestedAt;
  final String? reviewedBy; // Admin/Supervisor who reviewed
  final String? approvedBy; // Admin/Supervisor who approved
  final String? rejectedBy; // Admin/Supervisor who rejected
  final DateTime? reviewedAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final String? rejectionReason;

  DeviceResetRequestModel({
    required this.requestId,
    required this.companyId, // NEW
    required this.userId,
    required this.userName,
    required this.reason,
    this.additionalDetails,
    required DeviceInfo deviceInfo,
    this.newDeviceInfo,
    this.status = 'pending',
    required this.requestedAt,
    this.reviewedBy,
    this.approvedBy,
    this.rejectedBy,
    this.reviewedAt,
    this.approvedAt,
    this.rejectedAt,
    this.rejectionReason,
  })  : oldDeviceInfo = deviceInfo,
        currentDeviceInfo = deviceInfo;

  // Convenience getters
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get hasBeenReviewed => reviewedAt != null;

  // Predefined reasons
  static const List<String> availableReasons = [
    'Lost/stolen phone',
    'Upgraded to new phone',
    'Phone damaged',
    'Other',
  ];

  // Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'companyId': companyId, // NEW
      'userId': userId,
      'userName': userName,
      'reason': reason,
      'additionalDetails': additionalDetails,
      'oldDeviceInfo': oldDeviceInfo.toMap(),
      'newDeviceInfo': newDeviceInfo?.toMap(),
      'status': status,
      'requestedAt': requestedAt.toIso8601String(),
      'reviewedBy': reviewedBy,
      'approvedBy': approvedBy,
      'rejectedBy': rejectedBy,
      'reviewedAt': reviewedAt?.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
      'rejectedAt': rejectedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
    };
  }

  // Create from Firestore map
  factory DeviceResetRequestModel.fromMap(Map<String, dynamic> map) {
    return DeviceResetRequestModel(
      requestId: map['requestId'] as String,
      companyId: map['companyId'] as String? ?? '', // NEW
      userId: map['userId'] as String,
      userName: map['userName'] as String? ?? 'Unknown User',
      reason: map['reason'] as String,
      additionalDetails: map['additionalDetails'] as String?,
      deviceInfo: DeviceInfo.fromMap(map['oldDeviceInfo'] as Map<String, dynamic>),
      newDeviceInfo: map['newDeviceInfo'] != null
          ? DeviceInfo.fromMap(map['newDeviceInfo'] as Map<String, dynamic>)
          : null,
      status: map['status'] as String? ?? 'pending',
      requestedAt: TimestampHelper.parseDateTime(map['requestedAt']),
      reviewedBy: map['reviewedBy'] as String?,
      approvedBy: map['approvedBy'] as String?,
      rejectedBy: map['rejectedBy'] as String?,
      reviewedAt: TimestampHelper.parseDateTimeNullable(map['reviewedAt']),
      approvedAt: TimestampHelper.parseDateTimeNullable(map['approvedAt']),
      rejectedAt: TimestampHelper.parseDateTimeNullable(map['rejectedAt']),
      rejectionReason: map['rejectionReason'] as String?,
    );
  }

  // CopyWith method
  DeviceResetRequestModel copyWith({
    String? requestId,
    String? companyId,
    String? userId,
    String? userName,
    String? reason,
    String? additionalDetails,
    DeviceInfo? deviceInfo,
    DeviceInfo? newDeviceInfo,
    String? status,
    DateTime? requestedAt,
    String? reviewedBy,
    String? approvedBy,
    String? rejectedBy,
    DateTime? reviewedAt,
    DateTime? approvedAt,
    DateTime? rejectedAt,
    String? rejectionReason,
  }) {
    return DeviceResetRequestModel(
      requestId: requestId ?? this.requestId,
      companyId: companyId ?? this.companyId, // NEW
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      reason: reason ?? this.reason,
      additionalDetails: additionalDetails ?? this.additionalDetails,
      deviceInfo: deviceInfo ?? this.oldDeviceInfo,
      newDeviceInfo: newDeviceInfo ?? this.newDeviceInfo,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      approvedBy: approvedBy ?? this.approvedBy,
      rejectedBy: rejectedBy ?? this.rejectedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  @override
  String toString() {
    return 'DeviceResetRequestModel(id: $requestId, user: $userId, reason: $reason, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeviceResetRequestModel && other.requestId == requestId;
  }

  @override
  int get hashCode => requestId.hashCode;
}

