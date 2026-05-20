import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/biometric_service.dart';
import '../models/attendance_model.dart';
import 'auth_provider.dart';

// Location Service Provider
final locationServiceProvider =
    Provider<LocationService>((ref) => LocationService());

// Biometric Service Provider
final biometricServiceProvider =
    Provider<BiometricService>((ref) => BiometricService());

// Today's Attendance Provider (most recent check-in)
final todayAttendanceProvider = FutureProvider.autoDispose
    .family<AttendanceModel?, String>((ref, userId) async {
  return await ref.watch(firestoreServiceProvider).getTodayAttendance(userId);
});

// Today's Total Working Hours Provider (all sessions combined)
final todayTotalWorkingHoursProvider = FutureProvider.autoDispose
    .family<Duration, String>((ref, userId) async {
  return await ref.watch(firestoreServiceProvider).getTodayTotalWorkingHours(userId);
});

// Attendance History Provider
final attendanceHistoryProvider = FutureProvider.autoDispose
    .family<List<AttendanceModel>, String>((ref, userId) async {
  return await ref.watch(firestoreServiceProvider).getAttendanceHistory(userId);
});

// Weekly Stats Provider
final weeklyStatsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, userId) async {
  return await ref.watch(firestoreServiceProvider).getWeeklyStats(userId);
});

// Attendance Controller
class AttendanceController extends StateNotifier<AsyncValue<void>> {
  final FirestoreService _firestoreService;
  final LocationService _locationService;
  final BiometricService _biometricService;
  final String userId;

  AttendanceController(
    this._firestoreService,
    this._locationService,
    this._biometricService,
    this.userId,
  ) : super(const AsyncValue.data(null));

  // Check in with biometric authentication
  Future<void> checkIn() async {
    state = const AsyncValue.loading();
    try {
      // Authenticate with biometrics
      final authenticated = await _biometricService.authenticate(
        reason: 'Authenticate to check in',
      );

      if (!authenticated) {
        state = const AsyncValue.data(null);
        throw Exception('Biometric authentication failed');
      }

      // Get location (optional - won't fail if location unavailable)
      Map<String, dynamic>? locationData;
      try {
        locationData = await _locationService.getCurrentLocationWithAddress();
      } catch (e) {
        // Location failed, but continue with check-in
        print('Location unavailable: $e');
        locationData = null;
      }

      // Create attendance record
      final attendance = AttendanceModel(
        id: '', // Will be set by Firestore
        userId: userId,
        checkInTime: DateTime.now(),
        checkInLocation: locationData?['address'],
        checkInLatitude: locationData?['latitude'],
        checkInLongitude: locationData?['longitude'],
        isCheckedIn: true,
      );

      await _firestoreService.checkIn(attendance);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow; // Rethrow so the UI can catch it
    }
  }

  // Check out
  Future<void> checkOut(String attendanceId) async {
    state = const AsyncValue.loading();
    try {
      // Authenticate with biometrics
      final authenticated = await _biometricService.authenticate(
        reason: 'Authenticate to check out',
      );

      if (!authenticated) {
        state = const AsyncValue.data(null);
        throw Exception('Biometric authentication failed');
      }

      // Get location (optional - won't fail if location unavailable)
      Map<String, dynamic>? locationData;
      try {
        locationData = await _locationService.getCurrentLocationWithAddress();
      } catch (e) {
        // Location failed, but continue with check-out
        print('Location unavailable: $e');
        locationData = null;
      }

      await _firestoreService.checkOut(
        userId, // Pass userId for subcollection path
        attendanceId,
        DateTime.now(),
        location: locationData?['address'],
        latitude: locationData?['latitude'],
        longitude: locationData?['longitude'],
      );

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow; // Rethrow so the UI can catch it
    }
  }

  // Check if biometric is available
  Future<bool> isBiometricAvailable() async {
    return await _biometricService.canCheckBiometrics();
  }
}

// Attendance Controller Provider
final attendanceControllerProvider = StateNotifierProvider.autoDispose
    .family<AttendanceController, AsyncValue<void>, String>((ref, userId) {
  return AttendanceController(
    ref.watch(firestoreServiceProvider),
    ref.watch(locationServiceProvider),
    ref.watch(biometricServiceProvider),
    userId,
  );
});
