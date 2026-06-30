import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/device_reset_request_model.dart';
import '../models/device_info_model.dart'; // This is DeviceInfo
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/device_service.dart';
import '../services/company_service.dart';
import '../models/company_model.dart';
import '../constants/app_constants.dart';
import 'auth_provider.dart';

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

/// Provider for user's device reset requests (real-time stream)
final userDeviceResetRequestsProvider = StreamProvider.autoDispose.family<List<DeviceResetRequestModel>, String>((ref, userId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  
  try {
    return firestoreService.streamUserDeviceResetRequests(userId);
  } catch (e) {
    throw 'Failed to fetch device reset requests: $e';
  }
});

/// Provider for all device reset requests (admin/supervisor)
/// Real-time stream of device reset requests for the current company
final allDeviceResetRequestsProvider = StreamProvider.autoDispose<List<DeviceResetRequestModel>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final currentUser = ref.watch(currentUserProvider).value;

  if (currentUser == null) {
    return Stream.value([]);
  }

  // Stream pending requests for the current company
  if (currentUser.companyId != null) {
    return firestoreService.streamPendingDeviceResetRequestsForCompany(
      currentUser.companyId!,
    );
  }
  return Stream.value([]);
});

/// Provider for pending device reset requests
final pendingDeviceResetRequestsProvider = StreamProvider.autoDispose<List<DeviceResetRequestModel>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final currentUser = ref.watch(currentUserProvider).value;

  if (currentUser == null) {
    return Stream.value([]);
  }

  // Stream pending requests for the current company
  if (currentUser.companyId != null) {
    return firestoreService.streamPendingDeviceResetRequestsForCompany(
      currentUser.companyId!,
    );
  }
  return Stream.value([]);
});

/// Provider for company settings of the current user
final currentUserCompanySettingsProvider = FutureProvider.autoDispose<CompanySettings?>((ref) async {
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser == null || currentUser.companyId == null) {
    return null;
  }
  final companyService = CompanyService();
  final company = await companyService.getCompany(currentUser.companyId!);
  return company?.settings;
});

/// Provider to check if user can request device reset
final canRequestDeviceResetProvider = FutureProvider.autoDispose.family<bool, String>((ref, userId) async {
  final firestoreService = ref.watch(firestoreServiceProvider);

  try {
    // Get user document to get their company ID
    final user = await firestoreService.getUser(userId);
    if (user == null || user.companyId == null) {
      return false;
    }

    // Get company settings
    final companyService = CompanyService();
    final company = await companyService.getCompany(user.companyId!);
    final limit = company?.settings.maxDeviceResetsPerMonth ?? AppConstants.maxDeviceResetsPerMonth;

    return await firestoreService.canRequestDeviceReset(
      userId,
      limit,
    );
  } catch (e) {
    throw 'Failed to check device reset eligibility: $e';
  }
});

/// Real-time stream of employees in the current admin's company that
/// currently have a device bound. Drives the "Active Devices" tab on
/// the device reset management screen and powers proactive resets.
final boundDevicesForCompanyProvider =
    StreamProvider.autoDispose<List<UserModel>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final currentUser = ref.watch(currentUserProvider).value;

  if (currentUser == null || currentUser.companyId == null) {
    return Stream.value([]);
  }
  return firestoreService.streamBoundDevicesForCompany(currentUser.companyId!);
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
      final userDoc = await firestoreService.getUser(userId);
      if (userDoc == null || userDoc.companyId == null) {
        throw 'User or company not found';
      }

      final companyService = CompanyService();
      final company = await companyService.getCompany(userDoc.companyId!);
      final limit = company?.settings.maxDeviceResetsPerMonth ?? AppConstants.maxDeviceResetsPerMonth;

      final canRequest = await firestoreService.canRequestDeviceReset(
        userId,
        limit,
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

  /// Admin-initiated device reset (proactive, no pending request).
  /// Clears the employee's device binding so they can register a new
  /// device on their next login.
  Future<void> adminResetEmployeeDevice({
    required String userId,
    required String adminId,
  }) async {
    state = const AsyncValue.loading();

    try {
      final firestoreService = ref.read(firestoreServiceProvider);

      await firestoreService.adminResetEmployeeDevice(
        userId: userId,
        adminId: adminId,
      );

      // Invalidate providers to refresh UI across the app.
      ref.invalidate(userDeviceResetRequestsProvider(userId));
      ref.invalidate(pendingDeviceResetRequestsProvider);
      ref.invalidate(allDeviceResetRequestsProvider);
      ref.invalidate(currentUserProvider);
      ref.invalidate(boundDevicesForCompanyProvider);

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

