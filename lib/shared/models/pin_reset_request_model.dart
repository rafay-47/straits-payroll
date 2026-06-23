import '../utils/timestamp_helper.dart';

/// PIN reset request model for employee PIN reset
class PinResetRequestModel {
  final String requestId;
  final String companyId;
  final String userId;
  final String userName;
  final String? employeeId;
  final String reason;
  final String? additionalDetails;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime requestedAt;
  final String? reviewedBy;
  final String? approvedBy;
  final String? rejectedBy;
  final DateTime? reviewedAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final String? rejectionReason;
  final String? newPin; // Set by admin/supervisor on approval

  PinResetRequestModel({
    required this.requestId,
    required this.companyId,
    required this.userId,
    required this.userName,
    this.employeeId,
    required this.reason,
    this.additionalDetails,
    this.status = 'pending',
    required this.requestedAt,
    this.reviewedBy,
    this.approvedBy,
    this.rejectedBy,
    this.reviewedAt,
    this.approvedAt,
    this.rejectedAt,
    this.rejectionReason,
    this.newPin,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  static const List<String> availableReasons = [
    'Forgot PIN',
    'PIN not working',
    'Security concern',
    'Other',
  ];

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'companyId': companyId,
      'userId': userId,
      'userName': userName,
      'employeeId': employeeId,
      'reason': reason,
      'additionalDetails': additionalDetails,
      'status': status,
      'requestedAt': requestedAt.toIso8601String(),
      'reviewedBy': reviewedBy,
      'approvedBy': approvedBy,
      'rejectedBy': rejectedBy,
      'reviewedAt': reviewedAt?.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
      'rejectedAt': rejectedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'newPin': newPin,
    };
  }

  factory PinResetRequestModel.fromMap(Map<String, dynamic> map) {
    return PinResetRequestModel(
      requestId: map['requestId'] as String,
      companyId: map['companyId'] as String? ?? '',
      userId: map['userId'] as String,
      userName: map['userName'] as String? ?? 'Unknown',
      employeeId: map['employeeId'] as String?,
      reason: map['reason'] as String? ?? '',
      additionalDetails: map['additionalDetails'] as String?,
      status: map['status'] as String? ?? 'pending',
      requestedAt: TimestampHelper.parseDateTime(map['requestedAt']),
      reviewedBy: map['reviewedBy'] as String?,
      approvedBy: map['approvedBy'] as String?,
      rejectedBy: map['rejectedBy'] as String?,
      reviewedAt: TimestampHelper.parseDateTimeNullable(map['reviewedAt']),
      approvedAt: TimestampHelper.parseDateTimeNullable(map['approvedAt']),
      rejectedAt: TimestampHelper.parseDateTimeNullable(map['rejectedAt']),
      rejectionReason: map['rejectionReason'] as String?,
      newPin: map['newPin'] as String?,
    );
  }

  PinResetRequestModel copyWith({
    String? requestId,
    String? companyId,
    String? userId,
    String? userName,
    String? employeeId,
    String? reason,
    String? additionalDetails,
    String? status,
    DateTime? requestedAt,
    String? reviewedBy,
    String? approvedBy,
    String? rejectedBy,
    DateTime? reviewedAt,
    DateTime? approvedAt,
    DateTime? rejectedAt,
    String? rejectionReason,
    String? newPin,
  }) {
    return PinResetRequestModel(
      requestId: requestId ?? this.requestId,
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      employeeId: employeeId ?? this.employeeId,
      reason: reason ?? this.reason,
      additionalDetails: additionalDetails ?? this.additionalDetails,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      approvedBy: approvedBy ?? this.approvedBy,
      rejectedBy: rejectedBy ?? this.rejectedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      newPin: newPin ?? this.newPin,
    );
  }

  @override
  String toString() {
    return 'PinResetRequestModel(id: $requestId, user: $userId, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PinResetRequestModel && other.requestId == requestId;
  }

  @override
  int get hashCode => requestId.hashCode;
}
