# Subcollection Migration Guide

This guide will help you migrate your Firestore database from flat collections to subcollections.

## 🎯 What Changed

### Before (Flat Collections):
```
attendance (Collection)
  ├── doc1 { userId: "abc123", checkInTime: ..., ... }
  ├── doc2 { userId: "abc123", checkInTime: ..., ... }
  └── doc3 { userId: "def456", checkInTime: ..., ... }

documents (Collection)
  ├── doc1 { userId: "abc123", fileName: ..., ... }
  └── doc2 { userId: "def456", fileName: ..., ... }
```

### After (Subcollections):
```
users
  ├── abc123
  │   ├── attendance (Subcollection)
  │   │   ├── doc1 { checkInTime: ..., ... } // No userId field!
  │   │   └── doc2 { checkInTime: ..., ... }
  │   └── documents (Subcollection)
  │       └── doc1 { fileName: ..., ... } // No userId field!
  └── def456
      ├── attendance (Subcollection)
      │   └── doc3 { checkInTime: ..., ... }
      └── documents (Subcollection)
          └── doc2 { fileName: ..., ... }
```

## ✅ Code Changes Summary

### 1. Firestore Service (`lib/services/firestore_service.dart`)
- ✅ Updated collection references to use subcollections
- ✅ Modified all methods to use subcollection paths
- ✅ Added `userId` parameter to `checkOut()` and `deleteDocument()`

### 2. Models
- ✅ `AttendanceModel`: Added `toMapForSubcollection()` and `fromMapWithUserId()`
- ✅ `DocumentModel`: Added `toMapForSubcollection()` and `fromMapWithUserId()`

### 3. Providers
- ✅ `attendance_provider.dart`: Updated `checkOut()` to pass `userId`
- ✅ `document_provider.dart`: Updated `deleteDocument()` to pass `userId`

### 4. Security Rules
- ✅ Created `firestore.rules` with subcollection-aware rules

## 📋 Migration Steps

### Option 1: Fresh Database (Recommended for Development)

If you're in development and can afford to start fresh:

1. **Delete existing data** from Firebase Console:
   - Go to Firestore Database
   - Delete `attendance` collection
   - Delete `documents` collection
   - Keep `users` collection

2. **Deploy security rules**:
   ```bash
   firebase deploy --only firestore:rules
   ```

3. **Test the app** - New data will automatically use subcollections

### Option 2: Migrate Existing Data (Production)

If you have existing data that needs to be preserved:

#### Step 1: Backup Your Database

```bash
# Using gcloud CLI
gcloud firestore export gs://YOUR_BUCKET_NAME/firestore-backup
```

Or manually export from Firebase Console.

#### Step 2: Create Migration Script

Create a file `migrate_to_subcollections.dart` in your project:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  // Initialize Firebase
  await Firebase.initializeApp();
  final firestore = FirebaseFirestore.instance;
  
  print('🚀 Starting migration to subcollections...\n');
  
  // =========================================
  // Migrate Attendance Collection
  // =========================================
  print('📦 Migrating attendance records...');
  final attendanceDocs = await firestore.collection('attendance').get();
  int attendanceCount = 0;
  
  for (var doc in attendanceDocs.docs) {
    try {
      final data = doc.data();
      final userId = data['userId'];
      
      if (userId == null || userId.isEmpty) {
        print('⚠️  Skipping attendance ${doc.id} - no userId');
        continue;
      }
      
      // Create a copy without userId field
      final Map<String, dynamic> newData = Map.from(data);
      newData.remove('userId');
      
      // Write to subcollection
      await firestore
        .collection('users')
        .doc(userId)
        .collection('attendance')
        .doc(doc.id)
        .set(newData);
      
      attendanceCount++;
      
      if (attendanceCount % 10 == 0) {
        print('   Migrated $attendanceCount attendance records...');
      }
    } catch (e) {
      print('❌ Error migrating attendance ${doc.id}: $e');
    }
  }
  
  print('✅ Migrated $attendanceCount attendance records\n');
  
  // =========================================
  // Migrate Documents Collection
  // =========================================
  print('📦 Migrating document records...');
  final documentDocs = await firestore.collection('documents').get();
  int documentCount = 0;
  
  for (var doc in documentDocs.docs) {
    try {
      final data = doc.data();
      final userId = data['userId'];
      
      if (userId == null || userId.isEmpty) {
        print('⚠️  Skipping document ${doc.id} - no userId');
        continue;
      }
      
      // Create a copy without userId field
      final Map<String, dynamic> newData = Map.from(data);
      newData.remove('userId');
      
      // Write to subcollection
      await firestore
        .collection('users')
        .doc(userId)
        .collection('documents')
        .doc(doc.id)
        .set(newData);
      
      documentCount++;
      
      if (documentCount % 10 == 0) {
        print('   Migrated $documentCount document records...');
      }
    } catch (e) {
      print('❌ Error migrating document ${doc.id}: $e');
    }
  }
  
  print('✅ Migrated $documentCount document records\n');
  
  // =========================================
  // Summary
  // =========================================
  print('🎉 Migration complete!');
  print('   - Attendance records: $attendanceCount');
  print('   - Document records: $documentCount');
  print('\n⚠️  IMPORTANT: Verify the migration before deleting old collections!');
  print('   Run the app and check that all data is displaying correctly.');
  print('\n📝 To delete old collections after verification:');
  print('   - Go to Firebase Console');
  print('   - Manually delete "attendance" collection');
  print('   - Manually delete "documents" collection');
}
```

#### Step 3: Run Migration Script

```bash
# Create a temporary Flutter app to run the migration
flutter create migration_tool
cd migration_tool

# Copy firebase config files
cp -r ../android/app/google-services.json android/app/
cp -r ../ios/Runner/GoogleService-Info.plist ios/Runner/

# Add dependencies to pubspec.yaml
# - cloud_firestore
# - firebase_core

# Copy the migration script to lib/main.dart
# Then run it
flutter run -d chrome
# or
flutter run -d macos
```

#### Step 4: Verify Migration

1. Open your app
2. Check that all attendance records are visible
3. Check that all documents are visible
4. Test check-in/check-out functionality
5. Test document upload/delete functionality

#### Step 5: Deploy Security Rules

```bash
firebase deploy --only firestore:rules
```

#### Step 6: Clean Up Old Collections (After Verification)

**⚠️ ONLY DO THIS AFTER VERIFYING EVERYTHING WORKS!**

1. Go to Firebase Console
2. Navigate to Firestore Database
3. Delete the old `attendance` collection
4. Delete the old `documents` collection

## 🧪 Testing Checklist

After migration, verify the following:

### Attendance
- [ ] Check-in creates record in `users/{userId}/attendance/`
- [ ] Check-out updates the correct record
- [ ] Today's attendance displays correctly
- [ ] Weekly stats calculate correctly
- [ ] Attendance history shows all records

### Documents
- [ ] Document upload creates record in `users/{userId}/documents/`
- [ ] Documents list shows all uploaded files
- [ ] Document deletion removes the correct file
- [ ] Document stream updates in real-time

### Security
- [ ] Users can only see their own data
- [ ] Users cannot access other users' attendance or documents
- [ ] Unauthenticated users cannot access any data

## 🔥 Firebase Console Commands

### Deploy Security Rules
```bash
firebase deploy --only firestore:rules
```

### View Current Rules
```bash
firebase firestore:rules:get
```

### Export Data (Backup)
```bash
gcloud firestore export gs://YOUR_BUCKET_NAME/firestore-backup
```

### Import Data (Restore)
```bash
gcloud firestore import gs://YOUR_BUCKET_NAME/firestore-backup/backup-folder
```

## 🆘 Troubleshooting

### Issue: "Missing or insufficient permissions"
**Solution**: Ensure you've deployed the new security rules:
```bash
firebase deploy --only firestore:rules
```

### Issue: "Document not found" errors
**Solution**: Check that data was migrated correctly. Verify the subcollection paths in Firebase Console.

### Issue: Old data still showing
**Solution**: Clear app cache or force refresh:
```dart
// Use GetOptions to force server fetch
.get(const GetOptions(source: Source.server))
```

### Issue: Duplicate data appearing
**Solution**: You might have both old (flat) and new (subcollection) data. Delete old collections after verification.

## 📚 References

- [Firestore Database Hierarchy](./FIRESTORE_DATABASE_HIERARCHY.md)
- [Firestore Security Rules](./firestore.rules)
- [Firebase Documentation](https://firebase.google.com/docs/firestore)

## 🎓 Key Concepts

### Why Subcollections?

1. **Data Isolation**: Each user's data is naturally isolated
2. **Better Security**: Rules automatically scope to user context
3. **Cleaner Queries**: No need to filter by userId
4. **Simpler Indexes**: Only single-field indexes needed
5. **Easier Deletion**: Delete user = cascade delete possible

### Path Structure

**Flat Collection**:
```
attendance/{docId}
```

**Subcollection**:
```
users/{userId}/attendance/{docId}
```

The userId is **implicit in the path**, not stored as a field!

---

**Last Updated**: November 3, 2025
**Migration Status**: ✅ Ready for deployment

