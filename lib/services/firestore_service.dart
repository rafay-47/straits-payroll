import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/attendance_model.dart';
import '../models/document_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collections
  CollectionReference get _usersCollection => _db.collection('users');
  
  // Subcollection references (requires userId)
  CollectionReference _attendanceCollection(String userId) =>
      _db.collection('users').doc(userId).collection('attendance');
  
  CollectionReference _documentsCollection(String userId) =>
      _db.collection('users').doc(userId).collection('documents');

  // ===== USER OPERATIONS =====

  // Create user profile
  Future<void> createUserProfile(UserModel user) async {
    await _usersCollection.doc(user.uid).set(user.toMap());
  }

  // Get user profile
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  // Update user profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _usersCollection.doc(uid).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Stream user profile
  Stream<UserModel?> streamUserProfile(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  // ===== ATTENDANCE OPERATIONS =====

  // Check in
  Future<String> checkIn(AttendanceModel attendance) async {
    final docRef = await _attendanceCollection(attendance.userId).add(attendance.toMapForSubcollection());
    await _attendanceCollection(attendance.userId).doc(docRef.id).update({'id': docRef.id});
    return docRef.id;
  }

  // Check out
  Future<void> checkOut(String userId, String attendanceId, DateTime checkOutTime,
      {String? location, double? latitude, double? longitude}) async {
    await _attendanceCollection(userId).doc(attendanceId).update({
      'checkOutTime': Timestamp.fromDate(checkOutTime),
      'checkOutLocation': location,
      'checkOutLatitude': latitude,
      'checkOutLongitude': longitude,
      'isCheckedIn': false,
    });
  }

  // Get today's attendance (most recent check-in for status)
  Future<AttendanceModel?> getTodayAttendance(String userId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    // Use GetOptions to force fetch from server (bypass cache)
    final query = await _attendanceCollection(userId)
        .where('checkInTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('checkInTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('checkInTime', descending: true)
        .limit(1)
        .get(const GetOptions(source: Source.server));

    if (query.docs.isNotEmpty) {
      return AttendanceModel.fromMapWithUserId(
          query.docs.first.data() as Map<String, dynamic>, userId);
    }
    return null;
  }

  // Get all today's attendance records for total hours calculation
  Future<List<AttendanceModel>> getAllTodayAttendance(String userId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final query = await _attendanceCollection(userId)
        .where('checkInTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('checkInTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('checkInTime', descending: true)
        .get(const GetOptions(source: Source.server));

    return query.docs
        .map((doc) => AttendanceModel.fromMapWithUserId(doc.data() as Map<String, dynamic>, userId))
        .toList();
  }

  // Calculate total working hours for today
  Future<Duration> getTodayTotalWorkingHours(String userId) async {
    final allTodayAttendance = await getAllTodayAttendance(userId);
    
    Duration totalHours = Duration.zero;
    for (var attendance in allTodayAttendance) {
      if (attendance.workingHours != null) {
        totalHours += attendance.workingHours!;
      }
    }
    
    return totalHours;
  }

  // Get attendance history
  Future<List<AttendanceModel>> getAttendanceHistory(String userId,
      {int limit = 30}) async {
    final query = await _attendanceCollection(userId)
        .orderBy('checkInTime', descending: true)
        .limit(limit)
        .get();

    return query.docs
        .map((doc) =>
            AttendanceModel.fromMapWithUserId(doc.data() as Map<String, dynamic>, userId))
        .toList();
  }

  // Get attendance stats (last 7 days)
  Future<Map<String, dynamic>> getWeeklyStats(String userId) async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    final query = await _attendanceCollection(userId)
        .where('checkInTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
        .orderBy('checkInTime', descending: true)
        .get();

    // Group attendance by unique dates
    Map<String, List<AttendanceModel>> attendanceByDate = {};
    
    for (var doc in query.docs) {
      final attendance =
          AttendanceModel.fromMapWithUserId(doc.data() as Map<String, dynamic>, userId);
      
      // Get date string (YYYY-MM-DD) to group by day
      final dateKey = DateTime(
        attendance.checkInTime.year,
        attendance.checkInTime.month,
        attendance.checkInTime.day,
      ).toString().split(' ')[0];
      
      if (!attendanceByDate.containsKey(dateKey)) {
        attendanceByDate[dateKey] = [];
      }
      attendanceByDate[dateKey]!.add(attendance);
    }

    // Count unique days worked
    int totalDays = attendanceByDate.length;
    
    // Calculate total working hours and days with checkout
    Duration totalWorkingTime = Duration.zero;
    int daysWithCheckout = 0;
    
    for (var dayAttendances in attendanceByDate.values) {
      // For each day, sum up all working hours from all check-ins/outs
      Duration dayWorkingTime = Duration.zero;
      bool hasCheckout = false;
      
      for (var attendance in dayAttendances) {
        if (attendance.workingHours != null) {
          dayWorkingTime += attendance.workingHours!;
          hasCheckout = true;
        }
      }
      
      totalWorkingTime += dayWorkingTime;
      if (hasCheckout) {
        daysWithCheckout++;
      }
    }

    // Calculate average hours per day (only for days actually worked)
    double averageHoursPerDay = totalDays > 0 
        ? totalWorkingTime.inMinutes / totalDays / 60.0 
        : 0;

    return {
      'totalDays': totalDays,  // Unique days worked
      'checkedOutDays': daysWithCheckout,  // Days with at least one checkout
      'totalWorkingHours': totalWorkingTime.inHours,  // Total hours
      'totalWorkingMinutes': totalWorkingTime.inMinutes,  // For more accurate display
      'averageHoursPerDay': averageHoursPerDay,  // Average hours per unique day
    };
  }

  // ===== DOCUMENT OPERATIONS =====

  // Upload document metadata
  Future<String> uploadDocumentMetadata(DocumentModel document) async {
    final docRef = await _documentsCollection(document.userId).add(document.toMapForSubcollection());
    await _documentsCollection(document.userId).doc(docRef.id).update({'id': docRef.id});
    return docRef.id;
  }

  // Get user documents
  Future<List<DocumentModel>> getUserDocuments(String userId) async {
    final query = await _documentsCollection(userId)
        .orderBy('uploadedAt', descending: true)
        .get();

    return query.docs
        .map((doc) => DocumentModel.fromMapWithUserId(doc.data() as Map<String, dynamic>, userId))
        .toList();
  }

  // Delete document metadata
  Future<void> deleteDocument(String userId, String documentId) async {
    await _documentsCollection(userId).doc(documentId).delete();
  }

  // Stream user documents
  Stream<List<DocumentModel>> streamUserDocuments(String userId) {
    return _documentsCollection(userId)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                DocumentModel.fromMapWithUserId(doc.data() as Map<String, dynamic>, userId))
            .toList());
  }
}
