import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import '../constants/app_constants.dart';

/// Service for Firebase Storage file operations
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ============================================
  // DOCUMENT UPLOAD
  // ============================================

  /// Upload employee document (company-scoped path)
  /// Path: companies/{companyId}/documents/{userId}/{documentType}/{fileName}
  Future<String> uploadEmployeeDocument({
    required String companyId,
    required String userId,
    required File file,
    required String documentType,
  }) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final filePath =
          'companies/$companyId/${AppConstants.storageDocumentsPath}/$userId/$documentType/$fileName';

      final ref = _storage.ref().child(filePath);
      final uploadTask = ref.putFile(file);

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw 'Failed to upload document: $e';
    }
  }

  /// Upload document with progress callback (company-scoped path)
  /// Path: companies/{companyId}/documents/{userId}/{documentType}/{fileName}
  Future<String> uploadDocumentWithProgress({
    required String companyId,
    required String userId,
    required File file,
    required String documentType,
    required Function(double progress) onProgress,
  }) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final filePath =
          'companies/$companyId/${AppConstants.storageDocumentsPath}/$userId/$documentType/$fileName';

      final ref = _storage.ref().child(filePath);
      final uploadTask = ref.putFile(file);

      // Listen to progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw 'Failed to upload document: $e';
    }
  }

  // ============================================
  // PROFILE PHOTO UPLOAD
  // ============================================

  /// Upload profile photo
  Future<String> uploadProfilePhoto({
    required String userId,
    required File file,
  }) async {
    try {
      final fileName =
          'profile_${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}';
      final filePath =
          '${AppConstants.storageProfilePhotosPath}/$userId/$fileName';

      final ref = _storage.ref().child(filePath);
      final uploadTask = ref.putFile(file);

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw 'Failed to upload profile photo: $e';
    }
  }

  /// Upload file from bytes (for web/cross-platform)
  Future<String> uploadFileFromBytes({
    required List<int> bytes,
    required String fileName,
    required String storagePath,
  }) async {
    try {
      final filePath = '$storagePath/$fileName';
      final ref = _storage.ref().child(filePath);

      final uploadTask = ref.putData(
        bytes as dynamic,
        SettableMetadata(
          contentType: _getContentType(fileName),
        ),
      );

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      debugPrint(e.toString());
      throw 'Failed to upload file: $e';
    }
  }

  /// Get content type from file name
  String _getContentType(String fileName) {
    final ext = path.extension(fileName).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.svg':
        return 'image/svg+xml';
      case '.gif':
        return 'image/gif';
      case '.pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  // ============================================
  // FILE DELETION
  // ============================================

  /// Delete file by URL
  Future<void> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      throw 'Failed to delete file: $e';
    }
  }

  /// Delete all files in a folder
  Future<void> deleteFolder(String folderPath) async {
    try {
      final ref = _storage.ref().child(folderPath);
      final listResult = await ref.listAll();

      for (final item in listResult.items) {
        await item.delete();
      }

      // Recursively delete subfolders
      for (final prefix in listResult.prefixes) {
        await deleteFolder(prefix.fullPath);
      }
    } catch (e) {
      throw 'Failed to delete folder: $e';
    }
  }

  // ============================================
  // FILE INFORMATION
  // ============================================

  /// Get file metadata
  Future<FullMetadata> getFileMetadata(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      return await ref.getMetadata();
    } catch (e) {
      throw 'Failed to get file metadata: $e';
    }
  }

  /// Get file size
  Future<int> getFileSize(String fileUrl) async {
    try {
      final metadata = await getFileMetadata(fileUrl);
      return metadata.size ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // ============================================
  // FILE VALIDATION
  // ============================================

  /// Check if file size is within limit
  bool isFileSizeValid(File file) {
    final fileSize = file.lengthSync();
    return fileSize <= AppConstants.maxFileSizeBytes;
  }

  /// Check if file extension is allowed
  bool isFileExtensionValid(File file, List<String> allowedExtensions) {
    final extension =
        path.extension(file.path).toLowerCase().replaceAll('.', '');
    return allowedExtensions.contains(extension);
  }

  /// Validate image file
  bool isValidImageFile(File file) {
    return isFileSizeValid(file) &&
        isFileExtensionValid(file, AppConstants.allowedImageExtensions);
  }

  /// Validate document file
  bool isValidDocumentFile(File file) {
    return isFileSizeValid(file) &&
        (isFileExtensionValid(file, AppConstants.allowedImageExtensions) ||
            isFileExtensionValid(file, AppConstants.allowedDocumentExtensions));
  }

  // ============================================
  // UTILITIES
  // ============================================

  /// Get file name from URL
  String getFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      return segments.isNotEmpty ? segments.last : 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }

  /// Format file size
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
