# Cloud Functions Setup for Signed Document URLs

## Quick Start

This guide sets up Firebase Cloud Functions to generate signed URLs with expiration for secure document downloads.

## Prerequisites

- Firebase CLI installed: `npm install -g firebase-tools`
- Node.js 18+ installed
- Firebase project initialized in your repository
- Admin access to Firebase Console

## Setup Steps

### 1. Initialize Cloud Functions (if not already done)

```bash
cd /path/to/straits-payroll
firebase init functions
```

When prompted, select:
- Language: **TypeScript** (recommended) or JavaScript
- Use ESLint: **Yes** (optional but recommended)
- Overwrite existing files: **No**

### 2. Install Dependencies

```bash
cd functions
npm install
# Already includes: firebase-admin, firebase-functions, etc.
```

### 3. Create the Signed URL Function

**File:** `functions/src/index.ts`

```typescript
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

const db = admin.firestore();
const bucket = admin.storage().bucket();

/**
 * Generate a signed download URL with 15-minute expiration
 * Only callable by authenticated users
 * 
 * Request:
 * {
 *   "filePath": "companies/companyId/documents/userId/...",
 *   "expirationMinutes": 15
 * }
 * 
 * Response:
 * {
 *   "signedUrl": "https://storage.googleapis.com/...",
 *   "expiresAt": "2024-01-01T12:15:00.000Z"
 * }
 */
export const getSignedDownloadUrl = functions.https.onCall(
  async (data, context) => {
    // Verify authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "You must be signed in to download documents"
      );
    }

    const { filePath, expirationMinutes = 15 } = data;

    // Validate input
    if (!filePath || typeof filePath !== "string") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "filePath is required and must be a string"
      );
    }

    if (!Number.isInteger(expirationMinutes) || expirationMinutes < 1) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "expirationMinutes must be a positive integer"
      );
    }

    if (expirationMinutes > 1440) { // 24 hours max
      throw new functions.https.HttpsError(
        "invalid-argument",
        "expirationMinutes cannot exceed 1440 (24 hours)"
      );
    }

    try {
      // Get the file
      const file = bucket.file(filePath);
      
      // Check if file exists
      const [exists] = await file.exists();
      if (!exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "Document not found"
        );
      }

      // Generate signed URL
      const expiresAtMs = Date.now() + expirationMinutes * 60 * 1000;
      const [signedUrl] = await file.getSignedUrl({
        version: "v4",
        action: "read",
        expires: expiresAtMs,
        // Optional: restrict to specific hosts
        // responseDisposition: 'attachment; filename="document.pdf"',
      });

      // Log for audit trail
      await logDocumentAccess({
        userId: context.auth.uid,
        filePath,
        action: "signed_url_generated",
        expiresAt: new Date(expiresAtMs),
      });

      return {
        signedUrl,
        expiresAt: new Date(expiresAtMs).toISOString(),
        expirationMinutes,
      };
    } catch (error) {
      functions.logger.error("Error generating signed URL:", error);
      
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      
      throw new functions.https.HttpsError(
        "internal",
        "Failed to generate signed URL"
      );
    }
  }
);

/**
 * Log document downloads for audit trail
 * Automatically called but can also be called directly
 */
export const logDocumentDownload = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "You must be signed in"
      );
    }

    const { documentId, fileName, filePath } = data;

    try {
      await logDocumentAccess({
        userId: context.auth.uid,
        filePath: filePath || "",
        action: "download",
        documentId,
        fileName,
      });

      return { success: true };
    } catch (error) {
      functions.logger.error("Error logging download:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to log download"
      );
    }
  }
);

/**
 * Helper function to log document access
 */
async function logDocumentAccess(data: any) {
  try {
    const auditLogsRef = db.collection("audit_logs");
    
    await auditLogsRef.add({
      ...data,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      userAgent: "",
      ipAddress: "",
    });
  } catch (error) {
    functions.logger.warn("Could not log document access:", error);
    // Don't throw - logging failure shouldn't break the operation
  }
}

/**
 * Optional: Clean up expired signed URLs (run periodically)
 * Can be called via Cloud Scheduler
 */
export const cleanupExpiredSessions = functions.pubsub
  .schedule("every 1 hours")
  .onRun(async (context) => {
    try {
      const twentyFourHoursAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
      
      const snapshot = await db
        .collection("audit_logs")
        .where("expiresAt", "<", twentyFourHoursAgo)
        .limit(100)
        .get();

      const batch = db.batch();
      snapshot.docs.forEach((doc) => {
        batch.delete(doc.ref);
      });

      await batch.commit();
      functions.logger.info(`Cleaned up ${snapshot.docs.length} expired logs`);
    } catch (error) {
      functions.logger.error("Cleanup error:", error);
    }
  });
```

### 4. Deploy Cloud Functions

```bash
# Deploy only functions
firebase deploy --only functions

# Or deploy everything
firebase deploy

# View logs
firebase functions:log

# List deployed functions
firebase functions:list
```

## Configuration

### Environment Variables (Optional)

Create `.env.local` in the `functions` directory:

```env
SIGNED_URL_EXPIRATION_MINUTES=15
SIGNED_URL_MAX_EXPIRATION_MINUTES=1440
```

Then update the function to use these:

```typescript
const DEFAULT_EXPIRATION = 15;
const MAX_EXPIRATION = 1440;

export const getSignedDownloadUrl = functions.https.onCall(
  async (data, context) => {
    const expirationMinutes = data.expirationMinutes || DEFAULT_EXPIRATION;
    
    if (expirationMinutes > MAX_EXPIRATION) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        `Expiration cannot exceed ${MAX_EXPIRATION} minutes`
      );
    }
    // ... rest of function
  }
);
```

## Usage in Flutter

### In Document Management Screen

```dart
import 'package:cloud_functions/cloud_functions.dart';

Future<void> _downloadDocument(
    BuildContext context, DocumentModel document) async {
  try {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating download link...')),
    );

    // Get signed URL with 15-minute expiration
    final signedUrl = await _getSignedDownloadUrl(document);

    // Download using the signed URL
    final response = await html.window.fetch(signedUrl);
    
    if (!response.ok) {
      throw 'Download failed: HTTP ${response.status}';
    }

    final blob = await response.blob();
    final blobUrl = html.Url.createObjectUrlFromBlob(blob);
    
    // Trigger download
    final anchorElement = html.AnchorElement(href: blobUrl)
      ..setAttribute('download', document.name)
      ..style.display = 'none';
    
    html.document.body!.append(anchorElement);
    anchorElement.click();
    
    await Future.delayed(const Duration(milliseconds: 500));
    anchorElement.remove();
    html.Url.revokeObjectUrl(blobUrl);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${document.name} downloaded')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    }
  }
}

Future<String> _getSignedDownloadUrl(DocumentModel document) async {
  try {
    final storageService = ref.read(storageServiceProvider);
    
    // Extract file path from URL or use stored path
    final filePath = _extractFilePathFromUrl(document.url);
    
    return await storageService.getSignedDownloadUrl(
      filePath: filePath,
      expiresIn: const Duration(minutes: 15),
    );
  } catch (e) {
    print('Error getting signed URL: $e');
    // Fallback to regular URL
    return document.url;
  }
}

String _extractFilePathFromUrl(String fileUrl) {
  // Extract path from Firebase Storage URL
  // Format: https://firebasestorage.googleapis.com/v0/b/{bucket}/o/{path}?...
  try {
    final uri = Uri.parse(fileUrl);
    final pathParts = uri.pathSegments;
    if (pathParts.length >= 4 && pathParts[2] == 'o') {
      return Uri.decodeComponent(pathParts[3]);
    }
  } catch (e) {
    print('Error parsing file path: $e');
  }
  return '';
}
```

## Testing

### Test the Cloud Function Locally

```bash
firebase emulators:start --only functions

# In another terminal, call the function:
curl -X POST http://localhost:5001/{PROJECT_ID}/us-central1/getSignedDownloadUrl \
  -H "Content-Type: application/json" \
  -d '{"filePath":"companies/test/documents/user1/id_proof/file.pdf","expirationMinutes":15}'
```

### In Flutter Tests

```dart
void main() {
  group('Document Download Security', () {
    test('should generate signed URL with expiration', () async {
      final storageService = StorageService();
      
      final url = await storageService.getSignedDownloadUrl(
        filePath: 'companies/test/documents/user1/id_proof/test.pdf',
        expiresIn: const Duration(minutes: 15),
      );
      
      expect(url, isNotEmpty);
      expect(url, contains('access_token'));
      expect(url, contains('X-Goog-Expires'));
    });
  });
}
```

## Troubleshooting

### "Cloud Function not found" Error

1. Check deployment: `firebase functions:list`
2. Verify function name matches: `getSignedDownloadUrl`
3. Re-deploy: `firebase deploy --only functions`

### CORS Issues

Update `functions/.firebaserc` to ensure correct region configuration.

### Permission Denied Errors

Check Firebase Storage Rules in Console:
- Ensure authenticated users can read documents
- Verify company-scoped access rules

### URLs Not Expiring

Verify Cloud Function is being called, not using cached regular URLs.

## Security Best Practices

1. **Always verify authentication** before generating signed URLs
2. **Log all document access** for audit trails
3. **Use short expiration times** (15-30 minutes recommended)
4. **Restrict URL generation** to authorized users only
5. **Monitor Cloud Function usage** for abuse patterns

## References

- [Firebase Admin SDK - Signed URLs](https://cloud.google.com/storage/docs/access-control/signed-urls)
- [Firebase Cloud Functions - Security](https://firebase.google.com/docs/functions/tips/retries)
- [Google Cloud Storage - Signed URLs](https://cloud.google.com/storage/docs/access-control/signed-urls)
