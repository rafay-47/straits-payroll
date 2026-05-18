import '../utils/timestamp_helper.dart';

/// Device information model for device binding security
class DeviceInfo {
  final String deviceId;
  final String deviceModel;
  final String? brand;
  final String? platform; // iOS, Android, etc.
  final String? osVersion; // Operating system version
  final DateTime registeredAt;
  final bool isActive;
  final int resetCount;
  final DateTime? lastResetAt;

  const DeviceInfo({
    required this.deviceId,
    required this.deviceModel,
    this.brand,
    this.platform,
    this.osVersion,
    required this.registeredAt,
    this.isActive = true,
    this.resetCount = 0,
    this.lastResetAt,
  });

  // Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'deviceModel': deviceModel,
      'brand': brand,
      'platform': platform,
      'osVersion': osVersion,
      'registeredAt': registeredAt.toIso8601String(),
      'isActive': isActive,
      'resetCount': resetCount,
      'lastResetAt': lastResetAt?.toIso8601String(),
    };
  }

  // Create from Firestore map
  factory DeviceInfo.fromMap(Map<String, dynamic> map) {
    return DeviceInfo(
      deviceId: map['deviceId'] as String,
      deviceModel: map['deviceModel'] as String,
      brand: map['brand'] as String?,
      platform: map['platform'] as String?,
      osVersion: map['osVersion'] as String?,
      registeredAt: TimestampHelper.parseDateTime(map['registeredAt']),
      isActive: map['isActive'] as bool? ?? true,
      resetCount: map['resetCount'] as int? ?? 0,
      lastResetAt: TimestampHelper.parseDateTimeNullable(map['lastResetAt']),
    );
  }

  // CopyWith method
  DeviceInfo copyWith({
    String? deviceId,
    String? deviceModel,
    String? brand,
    String? platform,
    String? osVersion,
    DateTime? registeredAt,
    bool? isActive,
    int? resetCount,
    DateTime? lastResetAt,
  }) {
    return DeviceInfo(
      deviceId: deviceId ?? this.deviceId,
      deviceModel: deviceModel ?? this.deviceModel,
      brand: brand ?? this.brand,
      platform: platform ?? this.platform,
      osVersion: osVersion ?? this.osVersion,
      registeredAt: registeredAt ?? this.registeredAt,
      isActive: isActive ?? this.isActive,
      resetCount: resetCount ?? this.resetCount,
      lastResetAt: lastResetAt ?? this.lastResetAt,
    );
  }

  @override
  String toString() {
    return 'DeviceInfo(deviceId: $deviceId, model: $deviceModel, brand: $brand)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeviceInfo && other.deviceId == deviceId;
  }

  @override
  int get hashCode => deviceId.hashCode;
}

