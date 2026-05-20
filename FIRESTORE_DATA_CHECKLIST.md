# ✅ Firestore Data Checklist - Quick Reference

## 📊 What to Check When Things Don't Work

---

## 🔍 Supervisor Cannot Login or See Project

### Step 1: Check Firebase Authentication

```
Firebase Console → Authentication → Users

✅ Verify supervisor email exists:
   Email: supervisor@company.com
   UID: abc123xyz...           ← Copy this UID!
```

---

### Step 2: Check Firestore User Document

```
Firebase Console → Firestore → users → [paste UID here]

Document ID: abc123xyz...     ← MUST match Firebase Auth UID

Required Fields:
┌─────────────────────┬──────────────────────┬────────────────┐
│ Field Name          │ Expected Value       │ Your Value     │
├─────────────────────┼──────────────────────┼────────────────┤
│ uid                 │ abc123xyz...         │ ___________    │
│ email               │ supervisor@comp.com  │ ___________    │
│ name                │ John Manager         │ ___________    │
│ role                │ "supervisor"         │ ___________    │  ← Critical!
│ status              │ "approved"           │ ___________    │  ← Critical!
│ assignedProjectId   │ project_xyz123       │ ___________    │  ← Critical!
└─────────────────────┴──────────────────────┴────────────────┘
```

**Common Mistakes:**
- ❌ Document ID doesn't match Firebase Auth UID
- ❌ `role` is "employee" or "admin" instead of "supervisor"
- ❌ `status` is "pending" instead of "approved"
- ❌ `assignedProjectId` is missing, null, or empty string
- ❌ `assignedProjectId` doesn't match any actual project

---

### Step 3: Check Project Document

```
Firebase Console → Firestore → projects → [assignedProjectId]

Document ID: project_xyz123   ← MUST match supervisor's assignedProjectId

Required Fields:
┌─────────────────────┬──────────────────────┬────────────────┐
│ Field Name          │ Expected Value       │ Your Value     │
├─────────────────────┼──────────────────────┼────────────────┤
│ projectId           │ project_xyz123       │ ___________    │  ← Must match doc ID
│ name                │ Construction Site A  │ ___________    │
│ isActive            │ true                 │ ___________    │  ← Critical!
│ location            │ { address, lat, lng} │ ___________    │
└─────────────────────┴──────────────────────┴────────────────┘
```

**Common Mistakes:**
- ❌ Project doesn't exist
- ❌ `isActive` is false
- ❌ `projectId` field doesn't match document ID

---

## 🔍 Employee Cannot Login

### Step 1: Check Firestore User Document

```
Firebase Console → Firestore → users → [employee UID]

Required Fields:
┌─────────────────────┬──────────────────────┬────────────────┐
│ Field Name          │ Expected Value       │ Your Value     │
├─────────────────────┼──────────────────────┼────────────────┤
│ uid                 │ emp_uid_123          │ ___________    │
│ name                │ Mike Worker          │ ___________    │
│ role                │ "employee"           │ ___________    │  ← Critical!
│ status              │ "approved"           │ ___________    │  ← Critical!
│ systemGeneratedId   │ "0001"               │ ___________    │  ← Login ID
│ customId            │ "EMP001" (optional)  │ ___________    │
│ assignedProjectId   │ project_xyz123       │ ___________    │
│ supervisorId        │ supervisor_uid       │ ___________    │
└─────────────────────┴──────────────────────┴────────────────┘
```

**Common Mistakes:**
- ❌ `status` is "pending" (needs admin approval)
- ❌ `role` is not "employee"
- ❌ `systemGeneratedId` or `customId` is missing
- ❌ Using wrong ID to login (check which ID is set)

---

## 🔍 Employee Cannot Check-In

### Check All These:

```
1. Employee Document:
   □ status = "approved"
   □ assignedProjectId is set
   □ deviceInfo is set (after first login)

2. Project Document:
   □ isActive = true
   □ checkInMethods array has values (e.g., ["GPS", "NFC"])
   □ location object exists

3. Check-In Method:
   GPS:  □ Project has location with lat/lng
         □ Employee is within radius
   
   NFC:  □ Project has nfcTagIds array
         □ Tag ID matches one in array
   
   QR:   □ Project has qrCodes array
         □ QR code is valid
   
   Manual: □ Supervisor is logged in
           □ Employee is in supervisor's list
```

---

## 📋 Quick Validation Script

Copy this into your browser console while on Firebase Console:

```javascript
// Check Supervisor Data
const supervisorUid = 'PASTE_UID_HERE';
const db = firebase.firestore();

db.collection('users').doc(supervisorUid).get().then(doc => {
  if (!doc.exists) {
    console.error('❌ Supervisor document does NOT exist!');
    return;
  }
  
  const data = doc.data();
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('SUPERVISOR DATA:');
  console.log('  Name:', data.name);
  console.log('  Email:', data.email);
  console.log('  Role:', data.role, data.role === 'supervisor' ? '✅' : '❌');
  console.log('  Status:', data.status, data.status === 'approved' ? '✅' : '❌');
  console.log('  AssignedProjectId:', data.assignedProjectId, data.assignedProjectId ? '✅' : '❌');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  
  // Check project exists
  if (data.assignedProjectId) {
    db.collection('projects').doc(data.assignedProjectId).get().then(projectDoc => {
      if (!projectDoc.exists) {
        console.error('❌ Assigned project does NOT exist!');
        return;
      }
      
      const projectData = projectDoc.data();
      console.log('PROJECT DATA:');
      console.log('  Name:', projectData.name);
      console.log('  IsActive:', projectData.isActive, projectData.isActive ? '✅' : '❌');
      console.log('  ProjectId:', projectData.projectId);
    });
  }
});
```

---

## 🎯 Common Scenarios & Fixes

### Scenario 1: "Admin created supervisor but they can't login"

**Checklist:**
```
1. □ Check Firebase Auth has user with that email
2. □ Check Firestore users collection has document with matching UID
3. □ Verify role = "supervisor"
4. □ Verify status = "approved"
5. □ Try password reset if needed
```

**Most Common Cause:** 
- Document ID doesn't match Firebase Auth UID
- Role field is wrong

---

### Scenario 2: "Supervisor can login but sees 'No project assigned'"

**Checklist:**
```
1. □ Check supervisor document has assignedProjectId field
2. □ Verify assignedProjectId is not null or empty
3. □ Check project with that ID exists in projects collection
4. □ Verify project isActive = true
5. □ Try pull-to-refresh in app
6. □ Try logout and login again
```

**Most Common Cause:**
- assignedProjectId field is missing
- Project doesn't exist
- Project ID mismatch

---

### Scenario 3: "Employee can't login with their ID"

**Checklist:**
```
1. □ Check employee document exists
2. □ Verify status = "approved" (not "pending")
3. □ Check systemGeneratedId or customId is set
4. □ Verify employee is using correct ID format (0001 not 1)
5. □ Check role = "employee"
```

**Most Common Cause:**
- Status is "pending" (admin needs to approve)
- Using wrong ID (custom vs system)
- Wrong ID format

---

## 🔧 Quick Fix Templates

### Fix 1: Add Missing assignedProjectId

```
1. Go to: Firestore → users → [supervisor doc]
2. Click "Add Field"
3. Field: assignedProjectId
4. Type: string
5. Value: [paste your project ID here]
6. Save
```

---

### Fix 2: Change Role to Supervisor

```
1. Go to: Firestore → users → [user doc]
2. Find field: role
3. Click to edit
4. Change value to: supervisor
5. Save
```

---

### Fix 3: Approve Pending Employee

```
1. Go to: Firestore → users → [employee doc]
2. Find field: status
3. Click to edit
4. Change from: pending
5. Change to: approved
6. Save
```

---

## 📊 Data Flow Verification

```
Admin Creates Supervisor
   ↓
✅ Firebase Auth user created
   ↓
✅ Firestore user document created
   ├─ role: "supervisor"
   ├─ status: "approved"
   └─ assignedProjectId: "xyz123"
   ↓
✅ Project exists with ID "xyz123"
   └─ isActive: true
   ↓
Supervisor can login and see project ✅

───────────────────────────────────────

Supervisor Creates Employee
   ↓
✅ Firestore user document created
   ├─ role: "employee"
   ├─ status: "approved"
   ├─ systemGeneratedId: "0001"
   ├─ assignedProjectId: "xyz123"
   └─ supervisorId: [supervisor UID]
   ↓
Employee can login with ID "0001" ✅
```

---

## 🎓 Field Definitions

| Field | Type | Purpose | Required For |
|-------|------|---------|--------------|
| `uid` | string | Unique user ID | All users |
| `role` | string | User type: "admin", "supervisor", "employee" | All users |
| `status` | string | Account status: "pending", "approved", "active", "suspended" | All users |
| `email` | string | User email (login for admin/supervisor) | Admin, Supervisor |
| `systemGeneratedId` | string | Auto-generated ID like "0001" (login for employee) | Employee |
| `customId` | string | Custom ID like "EMP001" (optional login for employee) | Employee (optional) |
| `assignedProjectId` | string | Project ID user is assigned to | Supervisor, Employee |
| `supervisorId` | string | UID of employee's supervisor | Employee |

---

## 🚨 Critical Rules

1. **Supervisor MUST have:**
   - `role` = "supervisor"
   - `status` = "approved"
   - `assignedProjectId` = valid project ID

2. **Employee MUST have:**
   - `role` = "employee"
   - `status` = "approved"
   - `systemGeneratedId` OR `customId` (for login)
   - `assignedProjectId` = valid project ID
   - `supervisorId` = valid supervisor UID

3. **Project MUST have:**
   - `isActive` = true
   - `projectId` = matches document ID
   - `location` object (for GPS check-in)

---

## 🎯 Quick Reference

**✅ Supervisor Login Success:**
- Firebase Auth exists
- Firestore doc exists with matching UID
- role = "supervisor"
- status = "approved"

**✅ Supervisor Sees Project:**
- assignedProjectId is set
- Project with that ID exists
- Project isActive = true

**✅ Employee Login Success:**
- Firestore doc exists
- role = "employee"
- status = "approved"
- systemGeneratedId or customId is set

---

**Need to verify your data?** → Follow this checklist step by step!

**Last Updated:** November 16, 2025

