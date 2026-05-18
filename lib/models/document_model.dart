import 'package:cloud_firestore/cloud_firestore.dart';

enum DocumentType {
  id,
  certificate,
  payslip,
  medical,
  other;

  String get displayName {
    switch (this) {
      case DocumentType.id:
        return 'ID Document';
      case DocumentType.certificate:
        return 'Certificate';
      case DocumentType.payslip:
        return 'Payslip';
      case DocumentType.medical:
        return 'Medical Record';
      case DocumentType.other:
        return 'Other';
    }
  }
}

class DocumentModel {
  final String id;
  final String userId;
  final String fileName;
  final String fileUrl;
  final DocumentType type;
  final double fileSizeInMB;
  final DateTime uploadedAt;
  final String? description;

  DocumentModel({
    required this.id,
    required this.userId,
    required this.fileName,
    required this.fileUrl,
    required this.type,
    required this.fileSizeInMB,
    required this.uploadedAt,
    this.description,
  });

  // Convert to Firestore (includes userId for backward compatibility)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'type': type.name,
      'fileSizeInMB': fileSizeInMB,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'description': description,
    };
  }

  // Convert to Firestore for subcollection (excludes userId)
  Map<String, dynamic> toMapForSubcollection() {
    return {
      'id': id,
      // userId is NOT included - it's implicit in the subcollection path
      'fileName': fileName,
      'fileUrl': fileUrl,
      'type': type.name,
      'fileSizeInMB': fileSizeInMB,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'description': description,
    };
  }

  // Create from Firestore (for backward compatibility with flat collections)
  factory DocumentModel.fromMap(Map<String, dynamic> map) {
    return DocumentModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      fileName: map['fileName'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      type: DocumentType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => DocumentType.other,
      ),
      fileSizeInMB: (map['fileSizeInMB'] ?? 0).toDouble(),
      uploadedAt: (map['uploadedAt'] as Timestamp).toDate(),
      description: map['description'],
    );
  }

  // Create from Firestore subcollection (userId passed separately)
  factory DocumentModel.fromMapWithUserId(Map<String, dynamic> map, String userId) {
    return DocumentModel(
      id: map['id'] ?? '',
      userId: userId, // userId comes from the subcollection path
      fileName: map['fileName'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      type: DocumentType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => DocumentType.other,
      ),
      fileSizeInMB: (map['fileSizeInMB'] ?? 0).toDouble(),
      uploadedAt: (map['uploadedAt'] as Timestamp).toDate(),
      description: map['description'],
    );
  }

  // Get file extension
  String get fileExtension {
    return fileName.split('.').last.toUpperCase();
  }

  // Format file size
  String get formattedFileSize {
    if (fileSizeInMB < 1) {
      return '${(fileSizeInMB * 1024).toStringAsFixed(0)} KB';
    }
    return '${fileSizeInMB.toStringAsFixed(2)} MB';
  }
}
