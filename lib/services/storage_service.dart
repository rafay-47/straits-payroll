import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload file to Firebase Storage
  Future<String> uploadFile({
    required File file,
    required String userId,
    required String folder, // 'documents' or 'profiles'
  }) async {
    try {
      // Generate unique filename
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final destination = '$folder/$userId/$fileName';

      // Create reference
      final ref = _storage.ref(destination);

      // Upload file
      final uploadTask = ref.putFile(file);

      // Wait for upload to complete
      final snapshot = await uploadTask.whenComplete(() {});

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint(e.toString());

      throw Exception('Failed to upload file: $e');
    }
  }

  // Upload profile image
  Future<String> uploadProfileImage(File file, String userId) async {
    return await uploadFile(
      file: file,
      userId: userId,
      folder: 'profiles',
    );
  }

  // Upload document
  Future<String> uploadDocument(File file, String userId) async {
    return await uploadFile(
      file: file,
      userId: userId,
      folder: 'documents',
    );
  }

  // Delete file from Firebase Storage
  Future<void> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  // Get file metadata
  Future<FullMetadata> getFileMetadata(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      return await ref.getMetadata();
    } catch (e) {
      throw Exception('Failed to get file metadata: $e');
    }
  }

  // Get file size in MB
  Future<double> getFileSizeInMB(File file) async {
    final bytes = await file.length();
    return bytes / (1024 * 1024);
  }

  // Check if file size is within limit (e.g., 10 MB)
  Future<bool> isFileSizeValid(File file, {double maxSizeMB = 10}) async {
    final sizeMB = await getFileSizeInMB(file);
    return sizeMB <= maxSizeMB;
  }
}
