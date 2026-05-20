# 🔄 MIGRATION: Fix Company IDs from Random to Company Code

**Issue:** Existing companies have random IDs (e.g., `P8hGn53ZaxerCmXY8dwv`) instead of company code (e.g., `ABC`)

**Impact:** 
- Employee `companyId` = `"P8hGn53ZaxerCmXY8dwv"`
- Company document path = `companies/P8hGn53ZaxerCmXY8dwv`
- Hard to debug and manage

**Solution:** Migrate all data to use company code as ID

---

## 🎯 **MIGRATION STEPS**

### **STEP 1: Identify Affected Companies**

**In Firestore Console:**
```
1. Open: companies collection
2. Look for documents with random IDs:
   - P8hGn53ZaxerCmXY8dwv  ❌ Old format
   - 8Kx9mP2nQ4vR7wS1      ❌ Old format
   - ABC                   ✅ New format
   - XYZ                   ✅ New format
```

---

### **STEP 2: For Each Old Company, Do This:**

Let's say you have:
```
Company Document: companies/P8hGn53ZaxerCmXY8dwv
Data: {
  "id": "P8hGn53ZaxerCmXY8dwv",
  "companyCode": "ABC",
  "name": "ABC Corporation"
}
```

**Action A: Create New Company Document**
```
1. Copy the entire document data
2. Create new document at: companies/ABC  (use company code!)
3. Update the data:
   {
     "id": "ABC",  ← Changed from random ID
     "companyCode": "ABC",
     "name": "ABC Corporation",
     // ... keep all other fields
   }
```

**Action B: Update All Users**
```
Query: users
WHERE companyId = "P8hGn53ZaxerCmXY8dwv"

For each user found:
├─ Update field: companyId = "ABC"  (company code)
└─ Save
```

**Action C: Update All Projects**
```
Query: projects
WHERE companyId = "P8hGn53ZaxerCmXY8dwv"

For each project found:
├─ Update field: companyId = "ABC"
└─ Save
```

**Action D: Update All Attendance Records**
```
Query: users/{userId}/attendance
WHERE companyId = "P8hGn53ZaxerCmXY8dwv"

For each attendance found:
├─ Update field: companyId = "ABC"
└─ Save
```

**Action E: Delete Old Company Document**
```
Delete: companies/P8hGn53ZaxerCmXY8dwv
```

---

## 🛠️ **MANUAL FIRESTORE CONSOLE METHOD**

### **For Company: "ABC Corporation"**

**Current State:**
```
companies/P8hGn53ZaxerCmXY8dwv
{
  "id": "P8hGn53ZaxerCmXY8dwv",
  "companyCode": "ABC",
  "name": "ABC Corporation",
  "logo": "...",
  "status": "active",
  // ... other fields
}
```

**Step 1: Create New Company Document**
```
1. Go to Firestore Console
2. Select "companies" collection
3. Click "Add Document"
4. Document ID: ABC  (manual entry - use company code!)
5. Copy all fields from old document:
   - id: ABC  (change this!)
   - companyCode: ABC
   - name: ABC Corporation
   - logo: ...
   - status: active
   - ... (copy all other fields)
6. Save
```

**Result:**
```
companies/ABC  ✅ New document
{
  "id": "ABC",
  "companyCode": "ABC",
  "name": "ABC Corporation",
  // ... all other fields
}
```

**Step 2: Update All Users**
```
1. Go to "users" collection
2. Filter: companyId == "P8hGn53ZaxerCmXY8dwv"
3. For each user found:
   - Click on user document
   - Edit field: companyId
   - Change from: "P8hGn53ZaxerCmXY8dwv"
   - Change to: "ABC"
   - Save
4. Repeat for ALL users in this company
```

**Step 3: Update All Projects**
```
1. Go to "projects" collection
2. Filter: companyId == "P8hGn53ZaxerCmXY8dwv"
3. For each project:
   - Edit companyId to "ABC"
   - Save
```

**Step 4: Delete Old Company Document**
```
1. Go to "companies" collection
2. Find document: P8hGn53ZaxerCmXY8dwv
3. Delete it
```

---

## 🤖 **AUTOMATED SCRIPT METHOD**

Create this script to migrate automatically:

**File: `migrate_company_ids.dart`**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> migrateCompanyIds() async {
  final firestore = FirebaseFirestore.instance;
  
  print('🔄 Starting Company ID Migration...');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  
  // Get all companies
  final companiesSnapshot = await firestore.collection('companies').get();
  
  for (final companyDoc in companiesSnapshot.docs) {
    final companyData = companyDoc.data();
    final oldId = companyDoc.id;
    final companyCode = companyData['companyCode'] as String;
    
    // Check if ID is already the company code
    if (oldId == companyCode) {
      print('✅ Company $companyCode already migrated, skipping');
      continue;
    }
    
    print('');
    print('🏢 Migrating Company: ${companyData['name']}');
    print('   Old ID: $oldId');
    print('   New ID: $companyCode');
    
    // STEP 1: Create new company document with company code as ID
    print('   1️⃣ Creating new company document...');
    companyData['id'] = companyCode; // Update the id field
    await firestore.collection('companies').doc(companyCode).set(companyData);
    print('   ✅ New company document created at companies/$companyCode');
    
    // STEP 2: Update all users
    print('   2️⃣ Updating users...');
    final usersSnapshot = await firestore
        .collection('users')
        .where('companyId', isEqualTo: oldId)
        .get();
    
    for (final userDoc in usersSnapshot.docs) {
      await firestore.collection('users').doc(userDoc.id).update({
        'companyId': companyCode,
      });
    }
    print('   ✅ Updated ${usersSnapshot.docs.length} users');
    
    // STEP 3: Update all projects
    print('   3️⃣ Updating projects...');
    final projectsSnapshot = await firestore
        .collection('projects')
        .where('companyId', isEqualTo: oldId)
        .get();
    
    for (final projectDoc in projectsSnapshot.docs) {
      await firestore.collection('projects').doc(projectDoc.id).update({
        'companyId': companyCode,
      });
    }
    print('   ✅ Updated ${projectsSnapshot.docs.length} projects');
    
    // STEP 4: Update all attendance records
    print('   4️⃣ Updating attendance records...');
    final usersForAttendance = await firestore.collection('users').get();
    int attendanceCount = 0;
    
    for (final userDoc in usersForAttendance.docs) {
      final attendanceSnapshot = await firestore
          .collection('users')
          .doc(userDoc.id)
          .collection('attendance')
          .where('companyId', isEqualTo: oldId)
          .get();
      
      for (final attendanceDoc in attendanceSnapshot.docs) {
        await firestore
            .collection('users')
            .doc(userDoc.id)
            .collection('attendance')
            .doc(attendanceDoc.id)
            .update({'companyId': companyCode});
        attendanceCount++;
      }
    }
    print('   ✅ Updated $attendanceCount attendance records');
    
    // STEP 5: Delete old company document
    print('   5️⃣ Deleting old company document...');
    await firestore.collection('companies').doc(oldId).delete();
    print('   ✅ Old document deleted: companies/$oldId');
    
    print('   ✅ Migration complete for $companyCode');
    print('   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }
  
  print('');
  print('🎉 ALL COMPANIES MIGRATED SUCCESSFULLY!');
}
```

**To run this script:**

1. Create file: `lib/scripts/migrate_company_ids.dart`
2. Add a button in SuperAdmin dashboard to run it
3. Or run from terminal with Firebase Admin SDK

---

## ✅ **VERIFICATION AFTER MIGRATION**

### **Check 1: Company Documents**
```
Firestore → companies/

Before:
├── P8hGn53ZaxerCmXY8dwv  ❌
├── 8Kx9mP2nQ4vR7wS1      ❌

After:
├── ABC  ✅
├── XYZ  ✅
```

### **Check 2: User Documents**
```
Firestore → users/

Before:
{
  "uid": "user-123",
  "companyId": "P8hGn53ZaxerCmXY8dwv"  ❌
}

After:
{
  "uid": "user-123",
  "companyId": "ABC"  ✅
}
```

### **Check 3: Project Documents**
```
Firestore → projects/

Before:
{
  "projectId": "proj-456",
  "companyId": "P8hGn53ZaxerCmXY8dwv"  ❌
}

After:
{
  "projectId": "proj-456",
  "companyId": "ABC"  ✅
}
```

---

## 🎯 **QUICK FIX FOR YOUR CURRENT ISSUE**

**For immediate fix without full migration:**

1. **Find your company code:**
   ```
   Firestore → companies/P8hGn53ZaxerCmXY8dwv
   Look at: companyCode field
   Example: "ABC"
   ```

2. **Update all users manually:**
   ```
   Firestore → users/ (filter by companyId = P8hGn53ZaxerCmXY8dwv)
   Change companyId from: "P8hGn53ZaxerCmXY8dwv"
   Change companyId to: "ABC"
   ```

3. **Update getCompany calls:**
   - In code, when calling `getCompany()`, still use the old ID temporarily
   - OR migrate the company document as shown above

---

## 📊 **EXAMPLE: Complete Migration**

**Company: ABC Corporation**

**Before:**
```
companies/P8hGn53ZaxerCmXY8dwv
{
  "id": "P8hGn53ZaxerCmXY8dwv",
  "companyCode": "ABC",
  "name": "ABC Corporation"
}

users/supervisor-123
{
  "uid": "supervisor-123",
  "companyId": "P8hGn53ZaxerCmXY8dwv",  ❌
  "role": "supervisor"
}

users/employee-456
{
  "uid": "employee-456",
  "companyId": "P8hGn53ZaxerCmXY8dwv",  ❌
  "role": "employee",
  "status": "pending"
}

projects/project-789
{
  "projectId": "project-789",
  "companyId": "P8hGn53ZaxerCmXY8dwv",  ❌
  "name": "Construction Site"
}
```

**After:**
```
companies/ABC  ✅ Clean ID!
{
  "id": "ABC",
  "companyCode": "ABC",
  "name": "ABC Corporation"
}

users/supervisor-123
{
  "uid": "supervisor-123",
  "companyId": "ABC",  ✅
  "role": "supervisor"
}

users/employee-456
{
  "uid": "employee-456",
  "companyId": "ABC",  ✅
  "role": "employee",
  "status": "pending"
}

projects/project-789
{
  "projectId": "project-789",
  "companyId": "ABC",  ✅
  "name": "Construction Site"
}
```

---

## 🚀 **RECOMMENDED APPROACH**

**Option 1: Full Migration (Recommended)**
- Use the automated script
- Migrates all companies at once
- Clean database structure

**Option 2: Manual Migration (Safe)**
- Migrate one company at a time
- Verify after each migration
- Good for testing first

**Option 3: Quick Fix (Temporary)**
- Just update user `companyId` fields
- Keep old company document IDs for now
- Migrate properly later

---

**Which approach would you like to take? I can help you with any of these!** 🎯

