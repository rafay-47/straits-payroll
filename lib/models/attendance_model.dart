import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String id;
  final String userId;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String? checkInLocation;
  final String? checkOutLocation;
  final double? checkInLatitude;
  final double? checkInLongitude;
  final double? checkOutLatitude;
  final double? checkOutLongitude;
  final bool isCheckedIn;
  final String? notes;

  AttendanceModel({
    required this.id,
    required this.userId,
    required this.checkInTime,
    this.checkOutTime,
    this.checkInLocation,
    this.checkOutLocation,
    this.checkInLatitude,
    this.checkInLongitude,
    this.checkOutLatitude,
    this.checkOutLongitude,
    this.isCheckedIn = true,
    this.notes,
  });

  // Calculate working hours
  Duration? get workingHours {
    if (checkOutTime == null) return null;
    return checkOutTime!.difference(checkInTime);
  }

  // Format working hours as string
  String? get workingHoursFormatted {
    final hours = workingHours;
    if (hours == null) return null;
    
    final h = hours.inHours;
    final m = hours.inMinutes.remainder(60);
    return '${h}h ${m}m';
  }

  // Convert to Firestore (includes userId for backward compatibility)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'checkInTime': Timestamp.fromDate(checkInTime),
      'checkOutTime': checkOutTime != null 
          ? Timestamp.fromDate(checkOutTime!) 
          : null,
      'checkInLocation': checkInLocation,
      'checkOutLocation': checkOutLocation,
      'checkInLatitude': checkInLatitude,
      'checkInLongitude': checkInLongitude,
      'checkOutLatitude': checkOutLatitude,
      'checkOutLongitude': checkOutLongitude,
      'isCheckedIn': isCheckedIn,
      'notes': notes,
    };
  }

  // Convert to Firestore for subcollection (excludes userId)
  Map<String, dynamic> toMapForSubcollection() {
    return {
      'id': id,
      // userId is NOT included - it's implicit in the subcollection path
      'checkInTime': Timestamp.fromDate(checkInTime),
      'checkOutTime': checkOutTime != null 
          ? Timestamp.fromDate(checkOutTime!) 
          : null,
      'checkInLocation': checkInLocation,
      'checkOutLocation': checkOutLocation,
      'checkInLatitude': checkInLatitude,
      'checkInLongitude': checkInLongitude,
      'checkOutLatitude': checkOutLatitude,
      'checkOutLongitude': checkOutLongitude,
      'isCheckedIn': isCheckedIn,
      'notes': notes,
    };
  }

  // Create from Firestore (for backward compatibility with flat collections)
  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    return AttendanceModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      checkInTime: (map['checkInTime'] as Timestamp).toDate(),
      checkOutTime: map['checkOutTime'] != null
          ? (map['checkOutTime'] as Timestamp).toDate()
          : null,
      checkInLocation: map['checkInLocation'],
      checkOutLocation: map['checkOutLocation'],
      checkInLatitude: map['checkInLatitude']?.toDouble(),
      checkInLongitude: map['checkInLongitude']?.toDouble(),
      checkOutLatitude: map['checkOutLatitude']?.toDouble(),
      checkOutLongitude: map['checkOutLongitude']?.toDouble(),
      isCheckedIn: map['isCheckedIn'] ?? true,
      notes: map['notes'],
    );
  }

  // Create from Firestore subcollection (userId passed separately)
  factory AttendanceModel.fromMapWithUserId(Map<String, dynamic> map, String userId) {
    return AttendanceModel(
      id: map['id'] ?? '',
      userId: userId, // userId comes from the subcollection path
      checkInTime: (map['checkInTime'] as Timestamp).toDate(),
      checkOutTime: map['checkOutTime'] != null
          ? (map['checkOutTime'] as Timestamp).toDate()
          : null,
      checkInLocation: map['checkInLocation'],
      checkOutLocation: map['checkOutLocation'],
      checkInLatitude: map['checkInLatitude']?.toDouble(),
      checkInLongitude: map['checkInLongitude']?.toDouble(),
      checkOutLatitude: map['checkOutLatitude']?.toDouble(),
      checkOutLongitude: map['checkOutLongitude']?.toDouble(),
      isCheckedIn: map['isCheckedIn'] ?? true,
      notes: map['notes'],
    );
  }

  // Copy with method
  AttendanceModel copyWith({
    String? id,
    String? userId,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    String? checkInLocation,
    String? checkOutLocation,
    double? checkInLatitude,
    double? checkInLongitude,
    double? checkOutLatitude,
    double? checkOutLongitude,
    bool? isCheckedIn,
    String? notes,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      checkInLocation: checkInLocation ?? this.checkInLocation,
      checkOutLocation: checkOutLocation ?? this.checkOutLocation,
      checkInLatitude: checkInLatitude ?? this.checkInLatitude,
      checkInLongitude: checkInLongitude ?? this.checkInLongitude,
      checkOutLatitude: checkOutLatitude ?? this.checkOutLatitude,
      checkOutLongitude: checkOutLongitude ?? this.checkOutLongitude,
      isCheckedIn: isCheckedIn ?? this.isCheckedIn,
      notes: notes ?? this.notes,
    );
  }
}