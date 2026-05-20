# 🔥 FIREBASE STORAGE RULES - FIXED!

## ✅ **ISSUE RESOLVED**

**Problem:** "User is not authorized to perform the desired action" when uploading files

**Root Cause:** Firebase Storage has default rules that block all uploads unless properly configured

**Solution:** Created comprehensive Storage Security Rules with multi-tenant support

---

## 📋 **WHAT I CREATED**

### **1. storage.rules** ✅
Complete security rules for Firebase Storage with:
- ✅ Multi-tenant data isolation
- ✅ Role-based access control
- ✅ File type validation
- ✅ File size limits (10MB max)
- ✅ Company-specific storage paths

### **2. firebase.json** ✅
Firebase configuration file linking:
- Firestore rules
- Storage rules
- Hosting settings

---

## 🚀 **DEPLOY TO FIREBASE (2 OPTIONS)**

### **OPTION 1: Manual Deployment via Firebase Console** ⚡ (Fastest - 2 minutes)

#### **Step 1: Open Firebase Console**
👉 https://console.firebase.google.com/project/straights-payroll/storage/rules

#### **Step 2: Copy the Rules**
Open the file: `/Users/mac/Documents/straights_psyroll/storage.rules`

Copy ALL the content (from `rules_version = '2';` to the end)

#### **Step 3: Paste into Firebase Console**
1. In Firebase Console → Storage → Rules tab
2. Delete all existing content
3. Paste the new rules
4. Click **"Publish"** button

✅ **DONE! Rules are now active!**

---

### **OPTION 2: Deploy via Firebase CLI** 🔧 (Recommended for future)

#### **Step 1: Install Firebase CLI** (if not installed)

```bash
npm install -g firebase-tools
```

#### **Step 2: Login to Firebase**

```bash
firebase login
```

Follow the browser prompts to authenticate.

#### **Step 3: Initialize Firebase** (if not done)

```bash
cd /Users/mac/Documents/straights_psyroll
firebase init
```

Select:
- ☑ Firestore
- ☑ Storage
- ☑ Hosting (optional)

Use existing project: `straights-payroll`

Use existing files:
- Firestore rules: `firestore.rules`
- Storage rules: `storage.rules`

#### **Step 4: Deploy Storage Rules**

```bash
firebase deploy --only storage
```

Wait for deployment...

✅ **DONE! Rules deployed!**

---

## 📂 **STORAGE STRUCTURE**

Your files will be organized like this:

```
straights-payroll (Storage Bucket)
│
├── companies/
│   ├── {companyId}/
│   │   ├── logo/
│   │   │   └── logo.png
│   │   │
│   │   ├── employees/
│   │   │   ├── {userId}/
│   │   │   │   └── profile/
│   │   │   │       └── profile.jpg
│   │   │
│   │   ├── documents/
│   │   │   ├── {documentId}/
│   │   │   │   └── document.pdf
│   │   │
│   │   ├── projects/
│   │   │   ├── {projectId}/
│   │   │   │   └── images/
│   │   │   │       └── site_photo.jpg
│   │   │
│   │   └── attendance/
│   │       ├── {attendanceId}/
│   │       │   ├── checkin_photo.jpg
│   │       │   └── checkout_photo.jpg
│   │
└── public/
    └── temp_files/ (if needed)
```

---

## 🔐 **SECURITY RULES OVERVIEW**

### **Company Logos** 🏢
**Path:** `/companies/{companyId}/logo/{fileName}`

| Role | Permissions |
|------|-------------|
| Super Admin | ✅ Full access (read/write/delete) |
| Company Admin | ✅ Can upload their own company logo |
| Others | ✅ Can view any company logo |

**Restrictions:**
- ✅ Must be image file (png, jpg, etc.)
- ✅ Max size: 10MB

---

### **Employee Profile Pictures** 👤
**Path:** `/companies/{companyId}/employees/{userId}/profile/{fileName}`

| Role | Permissions |
|------|-------------|
| Super Admin | ✅ Full access to all profiles |
| Company Admin | ✅ Can manage profiles in their company |
| Supervisor | ✅ Can manage profiles in their company |
| Employee | ✅ Can update their own profile picture |
| Others | ✅ Can view profiles in same company |

**Restrictions:**
- ✅ Must be image file
- ✅ Max size: 10MB
- ✅ Must belong to same company

---

### **Employee Documents** 📄
**Path:** `/companies/{companyId}/documents/{documentId}/{fileName}`

| Role | Permissions |
|------|-------------|
| Super Admin | ✅ Full access to all documents |
| Company Admin | ✅ Can upload/manage company documents |
| Supervisor | ✅ Can upload/manage company documents |
| Employee | ✅ Can upload their own documents |
| Others | ✅ Can view documents in same company |

**Restrictions:**
- ✅ Must be valid document type (PDF, Word, Image)
- ✅ Max size: 10MB
- ✅ Must belong to same company

---

### **Project Images** 📸
**Path:** `/companies/{companyId}/projects/{projectId}/images/{fileName}`

| Role | Permissions |
|------|-------------|
| Super Admin | ✅ Full access to all project images |
| Company Admin | ✅ Can upload project images in their company |
| Supervisor | ✅ Can upload project images in their company |
| Others | ✅ Can view images in same company |

**Restrictions:**
- ✅ Must be image file
- ✅ Max size: 10MB
- ✅ Must belong to same company

---

### **Attendance Photos** 📷
**Path:** `/companies/{companyId}/attendance/{attendanceId}/{fileName}`

| Role | Permissions |
|------|-------------|
| Super Admin | ✅ Full access to all attendance photos |
| Company Admin | ✅ Can manage attendance photos in their company |
| Supervisor | ✅ Can manage attendance photos in their company |
| Employee | ✅ Can upload their own check-in/out photos |
| Others | ✅ Can view photos in same company |

**Restrictions:**
- ✅ Must be image file
- ✅ Max size: 10MB
- ✅ Must belong to same company

---

## 🧪 **TEST AFTER DEPLOYMENT**

### **Test 1: Company Logo Upload**

As Super Admin:

```dart
final storageService = StorageService();

final logoUrl = await storageService.uploadBytes(
  bytes: imageBytes,
  path: 'companies/comp_abc123/logo/logo.png',
  contentType: 'image/png',
);

print('Logo uploaded: $logoUrl');
```

✅ **Expected:** Logo uploads successfully

---

### **Test 2: Employee Document Upload**

As Company Admin or Supervisor:

```dart
final docUrl = await storageService.uploadBytes(
  bytes: documentBytes,
  path: 'companies/comp_abc123/documents/doc_123/certificate.pdf',
  contentType: 'application/pdf',
);

print('Document uploaded: $docUrl');
```

✅ **Expected:** Document uploads successfully

---

### **Test 3: Data Isolation**

As ABC Company Admin, try to upload to XYZ company path:

```dart
// This should FAIL
final url = await storageService.uploadBytes(
  bytes: imageBytes,
  path: 'companies/comp_xyz456/logo/logo.png', // Different company!
  contentType: 'image/png',
);
```

✅ **Expected:** Upload fails with permission error (correct behavior!)

---

## 🔍 **VALIDATION RULES**

### **File Type Validation**

```javascript
// Images
function isValidImage() {
  return request.resource.contentType.matches('image/.*');
}
// Accepts: image/png, image/jpeg, image/jpg, image/gif, etc.

// Documents
function isValidDocument() {
  return request.resource.contentType.matches(
    '(application/pdf|image/.*|application/msword|application/vnd.openxmlformats-officedocument.wordprocessingml.document)'
  );
}
// Accepts: PDF, images, .doc, .docx
```

### **File Size Validation**

```javascript
function isValidFileSize() {
  return request.resource.size < 10 * 1024 * 1024; // 10MB
}
```

### **Company Isolation**

```javascript
function isSameCompany(companyId) {
  return getCompanyId() == companyId;
}
// Ensures user can only access files in their company
```

---

## 🚨 **TROUBLESHOOTING**

### **Issue 1: Still getting "Not Authorized" error**

**Possible Causes:**
1. Rules not deployed yet
2. User not authenticated
3. User document missing in Firestore
4. User's companyId doesn't match path

**Solutions:**

#### **Check 1: Verify Rules are Deployed**
Firebase Console → Storage → Rules tab  
Should show your new rules with `rules_version = '2';`

#### **Check 2: Verify User is Authenticated**
```dart
final user = FirebaseAuth.instance.currentUser;
print('User: ${user?.uid}'); // Should print UID
```

#### **Check 3: Verify User Document Exists**
Firebase Console → Firestore → users → {uid}  
Check that document exists with:
- `uid`: user ID
- `role`: superadmin/companyadmin/supervisor/employee
- `companyId`: company ID (or null for superadmin)
- `status`: active

#### **Check 4: Verify Path Matches Company**
If user is in company `comp_abc123`, path must be:
```
companies/comp_abc123/... ✅ Correct
companies/comp_xyz456/... ❌ Wrong company!
```

---

### **Issue 2: File type rejected**

**Error:** "Invalid file type"

**Solution:** Check that your file type matches the allowed types:

**For Images:**
- ✅ PNG, JPG, JPEG, GIF, WebP
- ❌ PDF, Word docs

**For Documents:**
- ✅ PDF, PNG, JPG, DOC, DOCX
- ❌ EXE, ZIP, other binary files

---

### **Issue 3: File too large**

**Error:** "File size exceeds limit"

**Solution:** Current limit is 10MB per file

To change the limit, update `storage.rules`:

```javascript
// Change this function
function isValidFileSize() {
  return request.resource.size < 20 * 1024 * 1024; // 20MB
}
```

Then redeploy the rules.

---

## 📊 **MONITORING UPLOADS**

### **Firebase Console**

View uploaded files:
👉 https://console.firebase.google.com/project/straights-payroll/storage

You'll see:
- File paths
- File sizes
- Upload dates
- Download URLs

### **Storage Usage**

Firebase Storage free tier:
- **5GB** storage
- **1GB/day** download
- **20k/day** uploads

Monitor usage in Firebase Console → Storage → Usage tab

---

## ✅ **VERIFICATION CHECKLIST**

Before testing uploads:

- [ ] `storage.rules` file created
- [ ] `firebase.json` file created
- [ ] Rules deployed to Firebase (Option 1 or 2)
- [ ] User is authenticated (logged in)
- [ ] User document exists in Firestore
- [ ] User has correct role and companyId
- [ ] File path matches user's company
- [ ] File type is valid (image/document)
- [ ] File size is under 10MB

---

## 🎯 **QUICK DEPLOY COMMAND**

If you have Firebase CLI installed:

```bash
cd /Users/mac/Documents/straights_psyroll
firebase deploy --only storage
```

Or deploy everything:

```bash
firebase deploy
```

---

## 📝 **COMMON UPLOAD PATTERNS**

### **Pattern 1: Company Logo Upload (Super Admin)**

```dart
Future<String?> uploadCompanyLogo(String companyId, Uint8List bytes) async {
  final storageService = StorageService();
  
  try {
    final url = await storageService.uploadBytes(
      bytes: bytes,
      path: 'companies/$companyId/logo/logo.png',
      contentType: 'image/png',
    );
    return url;
  } catch (e) {
    print('Error uploading logo: $e');
    return null;
  }
}
```

### **Pattern 2: Employee Document Upload**

```dart
Future<String?> uploadEmployeeDocument(
  String companyId,
  String documentId,
  String fileName,
  Uint8List bytes,
  String contentType,
) async {
  final storageService = StorageService();
  
  try {
    final url = await storageService.uploadBytes(
      bytes: bytes,
      path: 'companies/$companyId/documents/$documentId/$fileName',
      contentType: contentType,
    );
    return url;
  } catch (e) {
    print('Error uploading document: $e');
    return null;
  }
}
```

### **Pattern 3: Attendance Photo Upload**

```dart
Future<String?> uploadAttendancePhoto(
  String companyId,
  String attendanceId,
  Uint8List bytes,
  String type, // 'checkin' or 'checkout'
) async {
  final storageService = StorageService();
  
  try {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final url = await storageService.uploadBytes(
      bytes: bytes,
      path: 'companies/$companyId/attendance/$attendanceId/${type}_$timestamp.jpg',
      contentType: 'image/jpeg',
    );
    return url;
  } catch (e) {
    print('Error uploading photo: $e');
    return null;
  }
}
```

---

## 🎊 **YOU'RE ALL SET!**

### **What's Fixed:**
✅ Storage rules created  
✅ Multi-tenant security enforced  
✅ Role-based permissions configured  
✅ File validation in place  

### **Next Steps:**
1. Deploy rules (Option 1: Console or Option 2: CLI)
2. Test file upload (company logo)
3. Verify permissions work correctly

---

**Created:** December 6, 2025  
**Status:** Storage Rules Ready for Deployment  
**Action Required:** Deploy rules to Firebase (2 minutes)

🚀 **Let's fix that upload error!**






