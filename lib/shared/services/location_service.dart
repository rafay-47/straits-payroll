import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/attendance_model.dart';
import 'dart:math' show cos, sqrt, asin;

/// Service for GPS location and geocoding operations
class LocationService {
  // ============================================
  // LOCATION PERMISSIONS
  // ============================================

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check location permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Ensure location permission is granted
  Future<bool> ensurePermission() async {
    // Check if location service is enabled
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Location services are disabled. Please enable location services in settings.';
    }

    // Check permission
    LocationPermission permission = await checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Location permission denied. Please grant location access in settings.';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Location permission permanently denied. Please enable location access in device settings.';
    }

    return true;
  }

  // ============================================
  // GET LOCATION
  // ============================================

  /// Get current location with high accuracy
  Future<Position> getCurrentLocation() async {
    try {
      // Ensure permission first
      await ensurePermission();

      // Get current position with high accuracy
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 30),
      );

      return position;
    } catch (e) {
      throw 'Failed to get current location: $e';
    }
  }

  /// Get current location with custom settings
  Future<Position> getCurrentLocationWithSettings({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeLimit = const Duration(seconds: 30),
  }) async {
    try {
      await ensurePermission();

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        timeLimit: timeLimit,
      );
    } catch (e) {
      throw 'Failed to get location: $e';
    }
  }

  /// Get last known location (faster but may be outdated)
  Future<Position?> getLastKnownLocation() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      return null;
    }
  }

  // ============================================
  // LOCATION DATA CONVERSION
  // ============================================

  /// Get address from coordinates (reverse geocoding)
  Future<String> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      
      if (placemarks.isEmpty) {
        return 'Unknown location';
      }

      final place = placemarks.first;
      
      // Build address string
      final parts = <String>[];
      
      if (place.street?.isNotEmpty ?? false) parts.add(place.street!);
      if (place.subLocality?.isNotEmpty ?? false) parts.add(place.subLocality!);
      if (place.locality?.isNotEmpty ?? false) parts.add(place.locality!);
      if (place.administrativeArea?.isNotEmpty ?? false) parts.add(place.administrativeArea!);
      if (place.postalCode?.isNotEmpty ?? false) parts.add(place.postalCode!);
      if (place.country?.isNotEmpty ?? false) parts.add(place.country!);

      return parts.isNotEmpty ? parts.join(', ') : 'Unknown location';
    } catch (e) {
      return 'Location: $latitude, $longitude';
    }
  }

  /// Create LocationData from Position
  Future<LocationData> createLocationData(Position position) async {
    final address = await getAddressFromCoordinates(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    return LocationData(
      latitude: position.latitude,
      longitude: position.longitude,
      address: address,
      accuracy: position.accuracy,
    );
  }

  // ============================================
  // DISTANCE CALCULATIONS
  // ============================================

  /// Calculate distance between two coordinates (in meters)
  /// Uses Haversine formula for accuracy
  double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const earthRadius = 6371000.0; // Earth radius in meters

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2));

    final c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  /// Calculate distance using Geolocator utility
  double calculateDistanceSimple({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Convert radians to degrees
  double _toRadians(double degrees) {
    return degrees * (3.141592653589793 / 180.0);
  }

  /// Convert distance to human-readable format
  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)}m';
    } else {
      final km = meters / 1000;
      return '${km.toStringAsFixed(2)}km';
    }
  }

  // ============================================
  // LOCATION VALIDATION
  // ============================================

  /// Check if user is within project radius
  Future<bool> isWithinRadius({
    required double userLat,
    required double userLon,
    required double projectLat,
    required double projectLon,
    required double radiusMeters,
  }) async {
    final distance = calculateDistanceSimple(
      lat1: userLat,
      lon1: userLon,
      lat2: projectLat,
      lon2: projectLon,
    );

    return distance <= radiusMeters;
  }

  /// Validate location accuracy
  bool isAccuracyAcceptable(Position position, {double maxAccuracyMeters = 50}) {
    return position.accuracy <= maxAccuracyMeters;
  }

  /// Get location with validation
  Future<Map<String, dynamic>> getValidatedLocation({
    required double projectLat,
    required double projectLon,
    required double projectRadius,
    double maxAccuracyMeters = 50,
  }) async {
    try {
      // Get current position
      final position = await getCurrentLocation();

      // Check accuracy
      final isAccurate = isAccuracyAcceptable(position, maxAccuracyMeters: maxAccuracyMeters);

      // Calculate distance
      final distance = calculateDistanceSimple(
        lat1: position.latitude,
        lon1: position.longitude,
        lat2: projectLat,
        lon2: projectLon,
      );

      // Check if within radius
      final withinRadius = distance <= projectRadius;

      // Get address
      final address = await getAddressFromCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      return {
        'position': position,
        'distance': distance,
        'distanceFormatted': formatDistance(distance),
        'withinRadius': withinRadius,
        'isAccurate': isAccurate,
        'accuracy': position.accuracy,
        'address': address,
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
    } catch (e) {
      rethrow;
    }
  }

  // ============================================
  // LOCATION STREAMING
  // ============================================

  /// Stream location updates (useful for real-time tracking)
  Stream<Position> getLocationStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10, // Minimum distance (meters) before update
  }) {
    final locationSettings = LocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  // ============================================
  // LOCATION UTILITIES
  // ============================================

  /// Open device location settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Open app settings
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Get location permission status as string
  String getPermissionStatusString(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.denied:
        return 'Location permission denied';
      case LocationPermission.deniedForever:
        return 'Location permission permanently denied';
      case LocationPermission.whileInUse:
        return 'Location permission granted (while in use)';
      case LocationPermission.always:
        return 'Location permission granted (always)';
      default:
        return 'Unknown permission status';
    }
  }

  // Helper function for sin (using dart:math)
  double sin(double radians) {
    return radians - (radians * radians * radians) / 6 + 
           (radians * radians * radians * radians * radians) / 120;
  }
}

