import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/device_reset_request_model.dart';
import '../models/device_info_model.dart'; // This is DeviceInfo
import '../services/firestore_service.dart';
import '../services/device_service.dart';
import '../constants/app_constants.dart';
import 'auth_provider.dart';

/// Provider for FirestoreService instance
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

/// Provider for DeviceService instance
final deviceServiceProvider = Provider<DeviceService>((ref) {
  return DeviceService();
});

/// Provider for UUID generator
final uuidProvider = Provider<Uuid>((ref) {
  return const Uuid();
});

// ============================================
// DEVICE RESET REQUEST PROVIDERS
// ============================================

/// Provider for user's device reset requests
final userDeviceResetRequestsProvider = StreamProvider.autoDispose.family<List<DeviceResetRequestModel>, String>((ref, userId) async* {
  final firestoreService = ref.watch(firestoreServiceProvider);
  
  try {
    final requests = await firestoreService.getUserDeviceResetRequests(userId);
    yield requests;
  } catch (e) {
    throw 'Failed to fetch device reset requests: $e';
  }
});

/// Provider for all device reset requests (admin/supervisor)
final allDeviceResetRequestsProvider = StreamProvider.autoDispose<List<DeviceResetRequestModel>>((ref) async* {
  final firestoreService = ref.watch(firestoreServiceProvider);
  
  try {
    final requests = await firestoreService.getAllDeviceResetRequests();
    yield requests;
  } catch (e) {
    throw 'Failed to fetch all device reset requests: $e';
  }
});

/// Provider for pending device reset requests
final pendingDeviceResetRequestsProvider = StreamProvider.autoDispose<List<DeviceResetRequestModel>>((ref) async* {
  final firestoreService = ref.watch(firestoreServiceProvider);
  
  try {
    final requests = await firestoreService.getPendingDeviceResetRequests();
    yield requests;
  } catch (e) {
    throw 'Failed to fetch pending device reset requests: $e';
  }
});

/// Provider to check if user can request device reset
final canRequestDeviceResetProvider = FutureProvider.autoDispose.family<bool, String>((ref, userId) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  
  try {
    return await firestoreService.canRequestDeviceReset(
      userId,
      AppConstants.maxDeviceResetsPerMonth,
    );
  } catch (e) {
    throw 'Failed to check device reset eligibility: $e';
  }
});

// ============================================
// DEVICE RESET CONTROLLER
// ============================================

/// Controller for device reset operations
class DeviceResetController extends StateNotifier<AsyncValue<void>> {
  DeviceResetController(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  /// Request device reset
  Future<void> requestDeviceReset({
    required String userId,
    required String userName,
    required DeviceInfo currentDeviceInfo,
    required String reason,
  }) async {
    state = const AsyncValue.loading();

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final uuid = ref.read(uuidProvider);

      // Check if user can request reset
      final canRequest = await firestoreService.canRequestDeviceReset(
        userId,
        AppConstants.maxDeviceResetsPerMonth,
      );

      if (!canRequest) {
        throw 'Monthly device reset limit reached';
      }

      // Get companyId from current user
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null || currentUser.companyId == null) {
        throw 'User not found or company not set';
      }

      final request = DeviceResetRequestModel(
        requestId: uuid.v4(),
        companyId: currentUser.companyId!, // Add companyId
        userId: userId,
        userName: userName,
        deviceInfo: currentDeviceInfo,
        reason: reason,
        status: AppConstants.statusPending,
        requestedAt: DateTime.now(),
      );

      await firestoreService.createDeviceResetRequest(request);

      // Invalidate providers to refresh UI
      ref.invalidate(userDeviceResetRequestsProvider(userId));
      ref.invalidate(pendingDeviceResetRequestsProvider);

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Approve device reset request
  Future<void> approveDeviceResetRequest({
    required String userId,
    required String requestId,
    required String approvedBy,
  }) async {
    state = const AsyncValue.loading();

    try {
      final firestoreService = ref.read(firestoreServiceProvider);

      await firestoreService.approveDeviceResetRequest(
        userId: userId,
        requestId: requestId,
        approvedBy: approvedBy,
      );

      // Invalidate providers to refresh UI
      ref.invalidate(userDeviceResetRequestsProvider(userId));
      ref.invalidate(pendingDeviceResetRequestsProvider);
      ref.invalidate(allDeviceResetRequestsProvider);
      ref.invalidate(currentUserProvider);

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Reject device reset request
  Future<void> rejectDeviceResetRequest({
    required String userId,
    required String requestId,
    required String rejectedBy,
    String? rejectionReason,
  }) async {
    state = const AsyncValue.loading();

    try {
      final firestoreService = ref.read(firestoreServiceProvider);

      await firestoreService.rejectDeviceResetRequest(
        userId: userId,
        requestId: requestId,
        rejectedBy: rejectedBy,
        rejectionReason: rejectionReason,
      );

      // Invalidate providers to refresh UI
      ref.invalidate(userDeviceResetRequestsProvider(userId));
      ref.invalidate(pendingDeviceResetRequestsProvider);
      ref.invalidate(allDeviceResetRequestsProvider);

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

/// Provider for DeviceResetController
final deviceResetControllerProvider = StateNotifierProvider<DeviceResetController, AsyncValue<void>>((ref) {
  return DeviceResetController(ref);
});

