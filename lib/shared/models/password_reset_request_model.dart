import '../utils/timestamp_helper.dart';

/// Password reset request that requires role-based approval before reset email is sent.
class PasswordResetRequestModel {
  final String requestId;
  final String requesterUserId;
  final String requesterName;
  final String requesterEmail;
  final String requesterRole; // 'companyadmin' | 'admin' | 'supervisor'
  final String? companyId;
  final String pendingApproverRole; // 'superadmin' | 'companyadmin'
  final String status; // 'pending' | 'approved' | 'rejected'
  final DateTime requestedAt;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime? emailSentAt;
  final String? rejectionReason;

  const PasswordResetRequestModel({
    required this.requestId,
    required this.requesterUserId,
    required this.requesterName,
    required this.requesterEmail,
    required this.requesterRole,
    required this.companyId,
    required this.pendingApproverRole,
    this.status = 'pending',
    required this.requestedAt,
    this.approvedBy,
    this.approvedAt,
    this.emailSentAt,
    this.rejectionReason,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'requesterUserId': requesterUserId,
      'requesterName': requesterName,
      'requesterEmail': requesterEmail,
      'requesterRole': requesterRole,
      'companyId': companyId,
      'pendingApproverRole': pendingApproverRole,
      'status': status,
      'requestedAt': requestedAt.toIso8601String(),
      'approvedBy': approvedBy,
      'approvedAt': approvedAt?.toIso8601String(),
      'emailSentAt': emailSentAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
    };
  }

  factory PasswordResetRequestModel.fromMap(Map<String, dynamic> map) {
    return PasswordResetRequestModel(
      requestId: map['requestId'] as String? ?? '',
      requesterUserId: map['requesterUserId'] as String? ?? '',
      requesterName: map['requesterName'] as String? ?? 'Unknown',
      requesterEmail: map['requesterEmail'] as String? ?? '',
      requesterRole: map['requesterRole'] as String? ?? '',
      companyId: map['companyId'] as String?,
      pendingApproverRole: map['pendingApproverRole'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      requestedAt: TimestampHelper.parseDateTime(map['requestedAt']),
      approvedBy: map['approvedBy'] as String?,
      approvedAt: TimestampHelper.parseDateTimeNullable(map['approvedAt']),
      emailSentAt: TimestampHelper.parseDateTimeNullable(map['emailSentAt']),
      rejectionReason: map['rejectionReason'] as String?,
    );
  }
}

