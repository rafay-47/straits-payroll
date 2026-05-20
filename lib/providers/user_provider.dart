import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import 'auth_provider.dart';

// Storage Service Provider
final storageServiceProvider =
    Provider<StorageService>((ref) => StorageService());

// User Profile Controller
class UserProfileController extends StateNotifier<AsyncValue<void>> {
  final FirestoreService _firestoreService;
  final StorageService _storageService;
  final String userId;

  UserProfileController(
    this._firestoreService,
    this._storageService,
    this.userId,
  ) : super(const AsyncValue.data(null));

  // Complete user profile
  Future<void> completeProfile({
    required String name,
    required String phone,
    required String designation,
    File? profileImage,
  }) async {
    state = const AsyncValue.loading();
    try {
      String? profileImageUrl;

      // Upload profile image if provided
      if (profileImage != null) {
        profileImageUrl = await _storageService.uploadProfileImage(
          profileImage,
          userId,
        );
      }

      // Update user profile
      await _firestoreService.updateUserProfile(userId, {
        'name': name,
        'phone': phone,
        'designation': designation,
        'profileImageUrl': profileImageUrl,
        'isProfileComplete': true,
      });

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Update profile
  Future<void> updateProfile({
    String? name,
    String? phone,
    String? designation,
    File? profileImage,
  }) async {
    state = const AsyncValue.loading();
    try {
      final Map<String, dynamic> updates = {};

      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (designation != null) updates['designation'] = designation;

      // Upload new profile image if provided
      if (profileImage != null) {
        final profileImageUrl = await _storageService.uploadProfileImage(
          profileImage,
          userId,
        );
        updates['profileImageUrl'] = profileImageUrl;
      }

      if (updates.isNotEmpty) {
        await _firestoreService.updateUserProfile(userId, updates);
      }

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// User Profile Controller Provider
final userProfileControllerProvider = StateNotifierProvider.autoDispose
    .family<UserProfileController, AsyncValue<void>, String>((ref, userId) {
  return UserProfileController(
    ref.watch(firestoreServiceProvider),
    ref.watch(storageServiceProvider),
    userId,
  );
});
