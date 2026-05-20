import '../utils/timestamp_helper.dart';

/// Document model for employee documents
class DocumentModel {
  final String documentId;
  final String companyId; // ⭐ NEW: Company reference for multi-tenancy
  final String userId; // Employee user ID
  final String type; // 'id_proof', 'bank_statement', 'contract', 'other'
  final String name; // File name
  final String url; // Firebase Storage URL
  final int? fileSizeBytes;
  final String? mimeType;
  final String uploadedBy; // Supervisor/Admin user ID
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime uploadedAt;
  final String? rejectionReason;

  const DocumentModel({
    required this.documentId,
    required this.companyId, // NEW
    required this.userId,
    required this.type,
    required this.name,
    required this.url,
    this.fileSizeBytes,
    this.mimeType,
    required this.uploadedBy,
    this.status = 'approved',
    required this.uploadedAt,
    this.rejectionReason,
  });

  // Convenience getters
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isIDProof => type == 'id_proof';
  bool get isBankStatement => type == 'bank_statement';
  bool get isContract => type == 'contract';

  // Get file size in human-readable format
  String get fileSizeFormatted {
    if (fileSizeBytes == null) return 'Unknown size';
    final kb = fileSizeBytes! / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }

  // Get display name for document type
  String get typeDisplayName {
    switch (type) {
      case 'id_proof':
        return 'ID Proof';
      case 'bank_statement':
        return 'Bank Statement';
      case 'contract':
        return 'Employment Contract';
      default:
        return 'Other Document';
    }
  }

  // Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'documentId': documentId,
      'companyId': companyId, // NEW
      'userId': userId,
      'type': type,
      'name': name,
      'url': url,
      'fileSizeBytes': fileSizeBytes,
      'mimeType': mimeType,
      'uploadedBy': uploadedBy,
      'status': status,
      'uploadedAt': uploadedAt.toIso8601String(),
      'rejectionReason': rejectionReason,
    };
  }

  // Create from Firestore map
  factory DocumentModel.fromMap(Map<String, dynamic> map) {
    return DocumentModel(
      documentId: map['documentId'] as String,
      companyId: map['companyId'] as String? ?? '', // NEW
      userId: map['userId'] as String,
      type: map['type'] as String,
      name: map['name'] as String,
      url: map['url'] as String,
      fileSizeBytes: map['fileSizeBytes'] as int?,
      mimeType: map['mimeType'] as String?,
      uploadedBy: map['uploadedBy'] as String,
      status: map['status'] as String? ?? 'approved',
      uploadedAt: TimestampHelper.parseDateTime(map['uploadedAt']),
      rejectionReason: map['rejectionReason'] as String?,
    );
  }

  // CopyWith method
  DocumentModel copyWith({
    String? documentId,
    String? companyId,
    String? userId,
    String? type,
    String? name,
    String? url,
    int? fileSizeBytes,
    String? mimeType,
    String? uploadedBy,
    String? status,
    DateTime? uploadedAt,
    String? rejectionReason,
  }) {
    return DocumentModel(
      documentId: documentId ?? this.documentId,
      companyId: companyId ?? this.companyId, // NEW
      userId: userId ?? this.userId,
      type: type ?? this.type,
      name: name ?? this.name,
      url: url ?? this.url,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      mimeType: mimeType ?? this.mimeType,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      status: status ?? this.status,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  @override
  String toString() {
    return 'DocumentModel(id: $documentId, type: $type, name: $name, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DocumentModel && other.documentId == documentId;
  }

  @override
  int get hashCode => documentId.hashCode;
}

