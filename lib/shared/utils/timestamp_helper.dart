import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper class for handling Firestore Timestamp conversions
class TimestampHelper {
  /// Convert Timestamp or String to DateTime
  /// Handles both Firestore Timestamp objects and ISO8601 strings
  static DateTime parseDateTime(dynamic value) {
    if (value == null) {
      return DateTime.now();
    } else if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    } else if (value is DateTime) {
      return value;
    } else {
      return DateTime.now();
    }
  }

  /// Convert Timestamp or String to DateTime (nullable version)
  /// Returns null if value is null
  static DateTime? parseDateTimeNullable(dynamic value) {
    if (value == null) {
      return null;
    } else if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    } else if (value is DateTime) {
      return value;
    } else {
      return null;
    }
  }
}

