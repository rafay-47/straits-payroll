import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../models/attendance_model.dart';
import '../models/device_info_model.dart';
import 'auth_provider.dart';

// ============================================
// SERVICE PROVIDERS
// ============================================

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

// ============================================
// ATTENDANCE PROVIDERS
// ============================================

/// Refresh trigger for attendance - increment to force refresh
final attendanceRefreshTriggerProvider = StateProvider<int>((ref) => 0);

/// Today's active attendance provider with manual refresh capability
final todayActiveAttendanceProvider = FutureProvider<AttendanceModel?>((ref) async {
  // Watch the trigger to auto-refresh when it changes
  final trigger = ref.watch(attendanceRefreshTriggerProvider);
  print('🔄 todayActiveAttendanceProvider rebuilding (trigger: $trigger)');
  
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.asData?.value;
  if (user == null) {
    print('❌ No user found in todayActiveAttendanceProvider');
    return null;
  }

  final firestoreService = ref.watch(firestoreServiceProvider);
  
  try {
    print('📞 Calling getTodayActiveAttendance for user: ${user.uid}');
    final result = await firestoreService.getTodayActiveAttendance(user.uid);
    print('✅ getTodayActiveAttendance returned: ${result != null ? "Attendance found" : "No attendance"}');
    return result;
  } catch (e) {
    print('❌ Error fetching today attendance: $e');
    return null;
  }
});

/// Attendance history provider
final attendanceHistoryProvider = FutureProvider<List<AttendanceModel>>((ref) async {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.asData?.value;
  if (user == null) return [];

  final firestoreService = ref.watch(firestoreServiceProvider);
  
  try {
    return await firestoreService.getAttendanceHistory(userId: user.uid);
  } catch (e) {
    print('Error fetching attendance history: $e');
    return [];
  }
});

/// Today's check-in count for project
final todayCheckInCountProvider = FutureProvider.family<int, String>(
  (ref, projectId) async {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.asData?.value;
    if (user == null) return 0;

    final firestoreService = ref.watch(firestoreServiceProvider);
    
    try {
      return await firestoreService.getTodayCheckInCount(
        userId: user.uid,
        projectId: projectId,
      );
    } catch (e) {
      return 0;
    }
  },
);

// ============================================
// ATTENDANCE CONTROLLER
// ============================================

/// Attendance state
class AttendanceState {
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final AttendanceModel? currentAttendance;

  const AttendanceState({
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.currentAttendance,
  });

  AttendanceState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    AttendanceModel? currentAttendance,
  }) {
    return AttendanceState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
      currentAttendance: currentAttendance ?? this.currentAttendance,
    );
  }
}

/// Attendance controller
class AttendanceController extends StateNotifier<AttendanceState> {
  final FirestoreService _firestoreService;
  final LocationService _locationService;
  final Ref _ref;

  AttendanceController(
    this._firestoreService,
    this._locationService,
    this._ref,
  ) : super(const AttendanceState());

  /// Check in to project
  Future<bool> checkIn({
    required String userId,
    required String projectId,
    required String checkInMethod,
    DeviceInfo? deviceInfo,
    String? verifiedBy,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      print('');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🔵 CHECK-IN STARTED');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('User ID: $userId');
      print('Project ID: $projectId');
      print('Method: $checkInMethod');
      
      // CRITICAL FIX: Auto-checkout any existing checked-in records first
      print('🔍 Checking for existing active check-ins...');
      final existingAttendance = await _firestoreService.getTodayActiveAttendance(userId);
      
      if (existingAttendance != null && existingAttendance.status == 'checked_in') {
        print('⚠️ Found existing checked-in record: ${existingAttendance.attendanceId}');
        print('   Auto-checking out old record before new check-in...');
        
        // Auto-checkout the old record
        final now = DateTime.now();
        final autoCheckoutUpdates = {
          'checkOutTime': now.toIso8601String(),
          'status': 'checked_out',
          'checkOutMethod': 'auto',
          'notes': (existingAttendance.notes ?? '') + 
                   ' | Auto checked-out at ${now.toIso8601String()} (new session started)',
          'workingHours': now.difference(existingAttendance.checkInTime).inMinutes / 60.0,
        };
        
        try {
          await _firestoreService.updateAttendance(
            userId: userId,
            attendanceId: existingAttendance.attendanceId,
            updates: autoCheckoutUpdates,
          );
          print('✅ Old record auto-checked-out successfully');
        } catch (e) {
          print('⚠️ Auto-checkout of old record failed (non-blocking): $e');
        }
      } else {
        print('✅ No existing active check-ins found - proceeding with new check-in');
      }
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      // Get current location (required for GPS, best-effort for other methods)
      LocationData? locationData;
      try {
        final position = await _locationService.getCurrentLocation();
        locationData = await _locationService.createLocationData(position);
      } catch (e) {
        if (checkInMethod == AppConstants.checkInMethodGPS) {
          // GPS check-in REQUIRES location - rethrow
          rethrow;
        }
        // For NFC/QR/Manual: location is nice-to-have, don't block check-in
        print('Location unavailable for $checkInMethod check-in (non-blocking): $e');
      }

      // Get current user for companyId
      final currentUser = _ref.read(currentUserProvider).value;
      if (currentUser == null || currentUser.companyId == null) {
        throw 'User not found or company not set';
      }

      // Get current session number
      final todayCount = await _firestoreService.getTodayCheckInCount(
        userId: userId,
        projectId: projectId,
      );

      // Create attendance record
      final attendance = AttendanceModel(
        attendanceId: 'att_${DateTime.now().millisecondsSinceEpoch}',
        companyId: currentUser.companyId!, // Add companyId
        userId: userId,
        projectId: projectId,
        checkInTime: DateTime.now(),
        checkInMethod: checkInMethod,
        checkInLocation: locationData,
        deviceInfo: deviceInfo,
        verifiedBy: verifiedBy,
        notes: notes,
        status: 'checked_in',
        sessionNumber: todayCount + 1,
      );

      await _firestoreService.createAttendance(attendance);
      
      print('✅ Attendance created successfully: ${attendance.attendanceId}');
      print('   User ID: $userId');
      print('   Project ID: $projectId');
      print('   Check-in Time: ${attendance.checkInTime.toIso8601String()}');
      print('   Status: ${attendance.status}');

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Checked in successfully',
        currentAttendance: attendance,
      );

      // Wait a moment for Firestore write to be fully committed
      await Future.delayed(const Duration(milliseconds: 500));

      // Refresh providers - invalidate triggers rebuild
      _ref.invalidate(todayActiveAttendanceProvider);
      _ref.invalidate(attendanceHistoryProvider);

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Check out from project
  Future<bool> checkOut({
    required String userId,
    required String attendanceId,
    String? checkOutMethod, // 'gps', 'nfc', 'qr', 'manual'
    String? notes, // Optional notes (e.g., NFC tag ID, QR code)
  }) async {
    print('');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔵 ATTENDANCE CONTROLLER: checkOut()');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('User ID: $userId');
    print('Attendance ID: $attendanceId');
    print('Check-out Method: $checkOutMethod');
    
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Get current location (best-effort - don't block check-out if unavailable)
      LocationData? locationData;
      try {
        final position = await _locationService.getCurrentLocation();
        locationData = await _locationService.createLocationData(position);
      } catch (e) {
        print('Location unavailable for check-out (non-blocking): $e');
      }

      // Get current attendance from Firestore
      final currentAttendance = await _firestoreService.getAttendanceById(userId, attendanceId);
      
      if (currentAttendance == null) {
        throw 'No active check-in found for ID: $attendanceId';
      }

      // Calculate working hours
      final checkOutTime = DateTime.now();
      final duration = checkOutTime.difference(currentAttendance.checkInTime);
      final workingHours = duration.inMinutes / 60.0;

      // Prepare update data
      final updates = <String, dynamic>{
        'checkOutTime': checkOutTime.toIso8601String(),
        if (locationData != null) 'checkOutLocation': locationData.toMap(),
        'workingHours': workingHours,
        'status': 'checked_out',
      };

      // Add check-out method if provided
      if (checkOutMethod != null) {
        updates['checkOutMethod'] = checkOutMethod;
      }

      // Add notes if provided (e.g., NFC tag ID, QR code)
      if (notes != null && notes.isNotEmpty) {
        final existingNotes = currentAttendance.notes ?? '';
        updates['notes'] = existingNotes.isEmpty
            ? 'Check-out: $notes'
            : '$existingNotes | Check-out: $notes';
      }

      // Update attendance
      print('💾 Updating attendance record...');
      print('   Attendance ID: $attendanceId');
      print('   New status: checked_out');
      print('   Check-out time: ${DateTime.now().toIso8601String()}');
      
      await _firestoreService.updateAttendance(
        userId: userId,
        attendanceId: attendanceId,
        updates: updates,
      );
      
      print('✅ Attendance updated in Firestore');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Checked out successfully',
        currentAttendance: null,
      );

      // Wait for Firestore write to propagate
      await Future.delayed(const Duration(milliseconds: 500));

      // Refresh providers
      _ref.invalidate(todayActiveAttendanceProvider);
      _ref.invalidate(attendanceHistoryProvider);

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Manual check-in by supervisor
  Future<bool> manualCheckIn({
    required String employeeId,
    required String projectId,
    required String supervisorId,
    required String reason,
    String? notes,
    DeviceInfo? deviceInfo,
  }) async {
    return await checkIn(
      userId: employeeId,
      projectId: projectId,
      checkInMethod: 'manual',
      deviceInfo: deviceInfo,
      verifiedBy: supervisorId,
      notes: notes ?? reason,
    );
  }

  /// Clear messages
  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }

  /// Set current attendance
  void setCurrentAttendance(AttendanceModel? attendance) {
    state = state.copyWith(currentAttendance: attendance);
  }
}

/// Attendance controller provider
final attendanceControllerProvider =
    StateNotifierProvider<AttendanceController, AttendanceState>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final locationService = ref.watch(locationServiceProvider);
  return AttendanceController(firestoreService, locationService, ref);
});

