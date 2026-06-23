import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/pin_reset_request_model.dart';
import '../constants/app_constants.dart';
import 'auth_provider.dart';

const _uuid = Uuid();

// ============================================
// PIN RESET REQUEST PROVIDERS
// ============================================

/// Provider for user's PIN reset requests (real-time stream)
final userPinResetRequestsProvider =
    StreamProvider.autoDispose.family<List<PinResetRequestModel>, String>(
        (ref, userId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  try {
    return firestoreService.streamUserPinResetRequests(userId);
  } catch (e) {
    throw 'Failed to fetch PIN reset requests: $e';
  }
});

/// Provider for all PIN reset requests (admin/supervisor)
final allPinResetRequestsProvider =
    StreamProvider.autoDispose<List<PinResetRequestModel>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final currentUser = ref.watch(currentUserProvider).value;

  if (currentUser == null) {
    return Stream.value([]);
  }

  if (currentUser.companyId != null) {
    return firestoreService.streamAllPinResetRequestsForCompany(
      currentUser.companyId!,
    );
  }
  return Stream.value([]);
});

/// Provider for pending PIN reset requests
final pendingPinResetRequestsProvider =
    StreamProvider.autoDispose<List<PinResetRequestModel>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final currentUser = ref.watch(currentUserProvider).value;

  if (currentUser == null) {
    return Stream.value([]);
  }

  if (currentUser.companyId != null) {
    return firestoreService.streamPendingPinResetRequestsForCompany(
      currentUser.companyId!,
    );
  }
  return Stream.value([]);
});

// ============================================
// PIN RESET CONTROLLER
// ============================================

/// Controller for PIN reset operations
class PinResetController extends StateNotifier<AsyncValue<void>> {
  PinResetController(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  /// Request PIN reset
  Future<void> requestPinReset({
    required String userId,
    required String userName,
    String? employeeId,
    required String reason,
    String? additionalDetails,
    String? companyId,
  }) async {
    state = const AsyncValue.loading();

    try {
      final firestoreService = ref.read(firestoreServiceProvider);

      final resolvedCompanyId = companyId ??
          ref.read(currentUserProvider).value?.companyId;
      if (resolvedCompanyId == null) {
        throw 'User not found or company not set';
      }

      final request = PinResetRequestModel(
        requestId: _uuid.v4(),
        companyId: resolvedCompanyId,
        userId: userId,
        userName: userName,
        employeeId: employeeId,
        reason: reason,
        additionalDetails: additionalDetails,
        status: AppConstants.statusPending,
        requestedAt: DateTime.now(),
      );

      await firestoreService.createPinResetRequest(request);

      ref.invalidate(userPinResetRequestsProvider(userId));
      ref.invalidate(pendingPinResetRequestsProvider);

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Approve PIN reset request
  Future<void> approvePinResetRequest({
    required String userId,
    required String requestId,
    required String approvedBy,
    required String newPin,
  }) async {
    state = const AsyncValue.loading();

    try {
      final firestoreService = ref.read(firestoreServiceProvider);

      await firestoreService.approvePinResetRequest(
        userId: userId,
        requestId: requestId,
        approvedBy: approvedBy,
        newPin: newPin,
      );

      ref.invalidate(userPinResetRequestsProvider(userId));
      ref.invalidate(pendingPinResetRequestsProvider);
      ref.invalidate(allPinResetRequestsProvider);

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Reject PIN reset request
  Future<void> rejectPinResetRequest({
    required String userId,
    required String requestId,
    required String rejectedBy,
    String? rejectionReason,
  }) async {
    state = const AsyncValue.loading();

    try {
      final firestoreService = ref.read(firestoreServiceProvider);

      await firestoreService.rejectPinResetRequest(
        userId: userId,
        requestId: requestId,
        rejectedBy: rejectedBy,
        rejectionReason: rejectionReason,
      );

      ref.invalidate(userPinResetRequestsProvider(userId));
      ref.invalidate(pendingPinResetRequestsProvider);
      ref.invalidate(allPinResetRequestsProvider);

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

/// Provider for PinResetController
final pinResetControllerProvider =
    StateNotifierProvider<PinResetController, AsyncValue<void>>((ref) {
  return PinResetController(ref);
});
