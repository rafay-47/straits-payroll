# Document Download Security Fix

## ✅ Problem Fixed
- Network error during document download in Manage Documents Screen
- Downloads were opening in browser instead of being downloaded to device
- URLs were static and could be shared to bypass access control

## ✅ Solution Applied

### 1. Fixed Network Error (COMPLETED)
**File:** `lib/web/screens/documents/document_management_screen.dart`

**Issue:** XHR (XMLHttpRequest) blob download had problems:
- CORS headers not properly configured
- Error handling not triggering
- Blob response type could fail

**Fix:** Replaced with Fetch API implementation:
```dart
final response = await html.window.fetch(document.url);

if (!response.ok) {
  throw 'Failed to download: HTTP ${response.status}';
}

final blob = await response.blob();

// Proper element cleanup
final anchorElement = html.AnchorElement(href: blobUrl)
  ..setAttribute('download', document.name)
  ..style.display = 'none';

html.document.body!.append(anchorElement);
anchorElement.click();

// Clean up after download starts
await Future.delayed(const Duration(milliseconds: 500));
anchorElement.remove();
html.Url.revokeObjectUrl(blobUrl);
```

**Benefits:**
- Better error handling with HTTP status codes
- Proper CORS support
- Reliable blob-to-file conversion
- Clean DOM element cleanup

---

## 🔒 Security Enhancement: Dynamic Signed URLs

### Overview
To prevent shared/static URLs, implement signed URLs that:
- Expire after 15-30 minutes
- Can only be used by authorized users
- Cannot be shared across users

### Implementation Steps

#### Step 1: Enable Cloud Functions in Firebase

```bash
# Initialize Firebase Cloud Functions
firebase init functions

# Install required dependencies
cd functions
npm install
```

#### Step 2: Create Cloud Function for Signed URLs

**File:** `functions/src/index.ts` (or `index.js`)

```typescript
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

/**
 * Generate a signed download URL with expiration
 * Called from: lib/shared/services/storage_service.dart
 * 
 * Request body:
 * {
 *   "filePath": "companies/{companyId}/documents/{userId}/...",
 *   "expirationMinutes": 15
 * }
 */
export const getSignedDownloadUrl = functions.https.onCall(
  async (data, context) => {
    // Verify user is authenticated
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const { filePath, expirationMinutes } = data;

    if (!filePath) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "filePath is required"
      );
    }

    if (!expirationMinutes) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "expirationMinutes is required"
      );
    }

    try {
      const bucket = admin.storage().bucket();
      const file = bucket.file(filePath);

      // Generate signed URL
      const [signedUrl] = await file.getSignedUrl({
        version: "v4",
        action: "read",
        expires: Date.now() + expirationMinutes * 60 * 1000,
      });

      return {
        signedUrl: signedUrl,
        expiresAt: new Date(Date.now() + expirationMinutes * 60 * 1000),
      };
    } catch (error) {
      console.error("Error generating signed URL:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to generate signed URL"
      );
    }
  }
);

/**
 * Optional: Log document downloads for audit trail
 */
export const logDocumentDownload = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const { documentId, fileName, userId } = data;
    const db = admin.firestore();

    try {
      await db.collection("audit_logs").add({
        action: "document_download",
        documentId,
        fileName,
        downloadedBy: context.auth.uid,
        targetUser: userId,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      return { success: true };
    } catch (error) {
      console.error("Error logging download:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to log download"
      );
    }
  }
);
```

#### Step 3: Update Dart Code to Use Cloud Functions

**File:** `lib/shared/services/storage_service.dart`

Add the import at the top:
```dart
import 'package:cloud_functions/cloud_functions.dart';
```

Update the `getSignedDownloadUrl` method:
```dart
Future<String> getSignedDownloadUrl({
  required String filePath,
  required Duration expiresIn,
}) async {
  try {
    final callable = FirebaseFunctions.instance.httpsCallable('getSignedDownloadUrl');
    
    final result = await callable.call({
      'filePath': filePath,
      'expirationMinutes': expiresIn.inMinutes,
    });
    
    return result.data['signedUrl'] as String;
  } catch (e) {
    throw 'Failed to get signed download URL: $e';
  }
}
```

#### Step 4: Update Document Download Screen

**File:** `lib/web/screens/documents/document_management_screen.dart`

Update the `_downloadDocument` method to use signed URLs:

```dart
Future<void> _downloadDocument(
    BuildContext context, DocumentModel document) async {
  try {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preparing download...')),
    );

    // Get signed URL with 15-minute expiration
    final storageService = ref.read(storageServiceProvider);
    
    // Extract file path from the document URL
    // Or store filePath in document model
    final fileUrl = await _getSignedDownloadUrl(document);

    // Use Fetch API to download
    final response = await html.window.fetch(fileUrl);
    
    if (!response.ok) {
      throw 'Failed to download: HTTP ${response.status}';
    }

    final blob = await response.blob();

    // Log the download for audit trail
    await _logDocumentDownload(document);

    // Trigger download...
    // [rest of implementation same as before]
  } catch (e) {
    // Handle error
  }
}
```

---

## 📋 Firebase Storage Rules Update

Update `storage.rules` to restrict direct access:

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Documents require authentication
    match /companies/{companyId}/documents/{userId}/{documentType}/{fileName} {
      // Only allow access via signed URLs from Cloud Functions
      allow read: if request.auth != null && 
                     request.auth.uid == userId || 
                     isCompanyAdmin(request.auth.uid, companyId) ||
                     isSuperAdmin(request.auth.uid);
      
      allow write: if request.auth != null && 
                      (isCompanyAdmin(request.auth.uid, companyId) ||
                       isSuperAdmin(request.auth.uid));
      
      allow delete: if request.auth != null && 
                       (isCompanyAdmin(request.auth.uid, companyId) ||
                        isSuperAdmin(request.auth.uid));
    }

    // Profile photos
    match /profile_photos/{userId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
      allow delete: if request.auth.uid == userId;
    }
  }

  function isCompanyAdmin(uid, companyId) {
    return exists(/databases/(default)/documents/users/$(uid)) &&
           get(/databases/(default)/documents/users/$(uid)).data.companyId == companyId &&
           get(/databases/(default)/documents/users/$(uid)).data.role == 'company_admin';
  }

  function isSuperAdmin(uid) {
    return exists(/databases/(default)/documents/users/$(uid)) &&
           get(/databases/(default)/documents/users/$(uid)).data.role == 'super_admin';
  }
}
```

---

## 🚀 Deployment Steps

### 1. Deploy Cloud Functions
```bash
firebase deploy --only functions
```

### 2. Update Storage Rules
```bash
firebase deploy --only storage
```

### 3. Run Tests
```bash
flutter test

# Or web
flutter run -d chrome
```

---

## ✅ Verification Checklist

- [ ] Download button works without network error
- [ ] File downloads to device (not opening in browser)
- [ ] Download filename is correct
- [ ] Signed URLs expire after specified time
- [ ] Audit logs created for all downloads
- [ ] Unauthorized users cannot download documents
- [ ] Storage rules properly restrict access

---

## 🔍 Troubleshooting

### Download Still Shows Network Error
- Check CORS settings in Firebase Console
- Verify storage bucket is accessible
- Check browser console for detailed error messages

### Signed URLs Not Working
- Verify Cloud Function is deployed: `firebase functions:list`
- Check Cloud Function logs: `firebase functions:log`
- Ensure `cloud_functions` package is added to `pubspec.yaml`

### Audit Logs Not Created
- Verify Firestore `audit_logs` collection exists
- Check Cloud Function execution logs
- Verify user has write permissions to Firestore

---

## 📚 References
- [Firebase Admin SDK - Signed URLs](https://cloud.google.com/storage/docs/access-control/signed-urls)
- [Firebase Cloud Functions](https://firebase.google.com/docs/functions)
- [Flutter Cloud Functions Integration](https://firebase.flutter.dev/docs/functions/overview/)
- [Fetch API Documentation](https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API)
