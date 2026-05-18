# 🏢 EMPLOYEE-COMPANY RELATIONSHIP GUIDE

**Complete explanation of how employees are linked to specific companies**

---

## 📊 **RELATIONSHIP STRUCTURE**

### **Database Schema:**

```
companies/ABC
{
  "id": "ABC",
  "companyCode": "ABC",
  "name": "ABC Corporation"
}
     ↓ (1 company has many users)
     
users/employee-uid-1
{
  "uid": "employee-uid-1",
  "companyId": "ABC",  ← Links to company!
  "role": "employee",
  "employeeId": "ABC-0001"
}

users/supervisor-uid-2
{
  "uid": "supervisor-uid-2",
  "companyId": "ABC",  ← Same company!
  "role": "supervisor"
}

users/admin-uid-3
{
  "uid": "admin-uid-3",
  "companyId": "ABC",  ← Same company!
  "role": "companyadmin"
}
```

---

## 🔄 **COMPLETE FLOW: COMPANY TO EMPLOYEE**

### **STEP 1: Super Admin Creates Company**

**Who:** Super Admin (platform owner)  
**Where:** Web Dashboard → Create Company Screen

```
Super Admin Dashboard
├─ Click "Create Company"
├─ Fill in:
│   ├─ Company Name: "ABC Corporation"
│   ├─ Company Code: "ABC"  ← Unique identifier
│   ├─ Admin Email: admin@abc.com
│   └─ Admin Password: ********
└─ Click "Create"
```

**Firestore Result:**

```javascript
// Path: companies/ABC
{
  "id": "ABC",  ← Company document ID
  "companyCode": "ABC",
  "name": "ABC Corporation",
  "status": "active",
  "createdAt": "2025-12-14T..."
}

// Path: users/admin-uid
{
  "uid": "admin-uid",
  "companyId": "ABC",  ← ✅ Linked to company!
  "role": "companyadmin",
  "email": "admin@abc.com",
  "name": "Admin Name"
}
```

---

### **STEP 2: Company Admin Creates Supervisor**

**Who:** Company Admin  
**Where:** Web Dashboard → Employee Management

```
Admin Dashboard (ABC Corporation)
├─ Navigate to "Manage Employees"
├─ Click "Add Employee/User"
├─ Select role: "Supervisor"
├─ Fill in:
│   ├─ Name: John Smith
│   ├─ Email: john@abc.com
│   ├─ Password: ********
│   └─ Assign to Project: Construction Site
└─ Click "Create"
```

**Code Execution:**

**File:** `lib/web/screens/employees/add_employee_dialog.dart`

```dart
// Get current admin's companyId
final currentUser = ref.read(currentUserProvider).value;
final companyId = currentUser.companyId;  // "ABC"

// Create supervisor with same companyId
final newUser = UserModel(
  uid: userUid,
  companyId: companyId,  // ✅ "ABC" from admin
  role: 'supervisor',
  email: 'john@abc.com',
  name: 'John Smith',
  assignedProjectId: selectedProjectId,
  status: 'approved',
);

await firestoreService.createUser(newUser);
```

**Firestore Result:**

```javascript
// Path: users/supervisor-uid
{
  "uid": "supervisor-uid",
  "companyId": "ABC",  ← ✅ Same as admin!
  "role": "supervisor",
  "email": "john@abc.com",
  "name": "John Smith",
  "assignedProjectId": "project-123"
}
```

---

### **STEP 3: Supervisor Creates Employee**

**Who:** Supervisor  
**Where:** Mobile App → Add Employee

```
Supervisor Mobile App (John Smith)
├─ Login with email/password
├─ Navigate to "Add Employee"
├─ Fill in:
│   ├─ Name: Mike Johnson
│   ├─ Email: mike@abc.com
│   └─ Phone: +1234567890
└─ Click "Add Employee"
```

**Code Execution:**

**File:** `lib/mobile/screens/supervisor/add_employee_screen.dart`

```dart
// Get supervisor's companyId
final currentUser = ref.read(currentUserProvider).value;
final supervisorCompanyId = currentUser.companyId;  // "ABC"

// Get company details
final companyDoc = await companyService.getCompany(supervisorCompanyId);
final companyCode = companyDoc.companyCode;  // "ABC"

// Create employee with supervisor's companyId
final newEmployee = UserModel(
  uid: uid,
  companyId: companyCode,  // ✅ "ABC" from supervisor
  role: 'employee',
  employeeId: 'ABC-0001',  // Generated with company code
  name: 'Mike Johnson',
  email: 'mike@abc.com',
  supervisorId: currentUser.uid,
  status: 'pending',  // Needs admin approval
);

await firestoreService.createUser(newEmployee);
```

**Firestore Result:**

```javascript
// Path: users/employee-uid
{
  "uid": "employee-uid",
  "companyId": "ABC",  ← ✅ Same as supervisor and admin!
  "role": "employee",
  "employeeId": "ABC-0001",
  "name": "Mike Johnson",
  "supervisorId": "supervisor-uid",
  "status": "pending"
}
```

---

### **STEP 4: Admin Approves Employee**

**Who:** Company Admin  
**Where:** Web Dashboard → Pending Approvals

```
Admin Dashboard
├─ See "Pending Approvals: 1"
├─ Click "Manage Employees" or "View Pending"
├─ See: Mike Johnson (ABC-0001)
├─ Click "Approve"
├─ Set PIN: 1234
└─ Confirm
```

**Code Execution:**

**File:** `lib/shared/services/firestore_service.dart`

```dart
// Get admin's companyId
final adminDoc = await firestore.collection('users').doc(adminUid).get();
final adminCompanyId = adminDoc.data()['companyId'];  // "ABC"

// Query pending employees for THIS company only
final snapshot = await firestore
    .collection('users')
    .where('role', isEqualTo: 'employee')
    .where('companyId', isEqualTo: adminCompanyId)  // ✅ Filter by company
    .where('status', isEqualTo: 'pending')
    .get();

// Admin approves
await firestore.collection('users').doc(employeeUid).update({
  'status': 'approved',
  'pin': '1234',
  'approvedBy': adminUid,
  'approvedAt': DateTime.now().toIso8601String(),
});
```

---

## 🎯 **KEY RELATIONSHIP FIELDS**

### **UserModel Fields:**

```dart
class UserModel {
  final String uid;              // Unique user ID
  final String? companyId;       // ✅ Company link!
  final String role;             // 'superadmin' | 'companyadmin' | 'supervisor' | 'employee'
  final String? supervisorId;    // For employees: their supervisor
  final String? assignedProjectId; // For supervisors/employees
  
  // Employee-specific
  final String? employeeId;      // ABC-0001 (includes company code)
  final String status;           // 'pending' | 'approved' | 'active'
}
```

### **Relationship Hierarchy:**

```
Company (ABC)
    ↓ companyId
    ├─ Admin (companyId: "ABC")
    │   └─ Creates →
    │
    ├─ Supervisor (companyId: "ABC")
    │   ├─ Manages projects for company
    │   └─ Creates →
    │
    └─ Employees (companyId: "ABC")
        ├─ Employee 1: ABC-0001
        ├─ Employee 2: ABC-0002
        └─ Employee 3: ABC-0003
```

---

## 🔒 **DATA ISOLATION (MULTI-TENANCY)**

### **How It Ensures Company Separation:**

**Company A (companyId: "ABC"):**
```javascript
users/admin-a:       { companyId: "ABC" }
users/supervisor-a:  { companyId: "ABC" }
users/employee-a1:   { companyId: "ABC" }
users/employee-a2:   { companyId: "ABC" }
```

**Company B (companyId: "XYZ"):**
```javascript
users/admin-b:       { companyId: "XYZ" }
users/supervisor-b:  { companyId: "XYZ" }
users/employee-b1:   { companyId: "XYZ" }
users/employee-b2:   { companyId: "XYZ" }
```

**Queries Are Filtered:**

```dart
// Admin A queries employees
await firestore
    .collection('users')
    .where('role', isEqualTo: 'employee')
    .where('companyId', isEqualTo: 'ABC')  // ✅ Only ABC employees
    .get();

// Result: [employee-a1, employee-a2]  ✅
// Does NOT include: [employee-b1, employee-b2]  ✅
```

---

## 📝 **CODE IMPLEMENTATION**

### **1. Creating Employee with Company Link**

**File:** `lib/mobile/screens/supervisor/add_employee_screen.dart`

```dart
Future<void> _handleAddEmployee() async {
  final currentUser = ref.read(currentUserProvider).value;
  
  // Get supervisor's company
  final supervisorCompanyId = currentUser.companyId;  // "ABC"
  
  // Get company document
  final companyDoc = await companyService.getCompany(supervisorCompanyId);
  final companyCode = companyDoc.companyCode;  // "ABC"
  
  // Create employee with company link
  final newEmployee = UserModel(
    uid: uid,
    companyId: companyCode,  // ✅ Links to company
    role: 'employee',
    employeeId: '$companyCode-$nextNumber',  // ABC-0001
    name: name,
    email: email,
    supervisorId: currentUser.uid,
    status: 'pending',
  );
  
  await firestoreService.createUser(newEmployee);
}
```

---

### **2. Fetching Company-Specific Employees**

**File:** `lib/shared/services/firestore_service.dart`

```dart
Future<List<UserModel>> getPendingEmployees() async {
  // Get current user (admin)
  final currentUser = FirebaseAuth.instance.currentUser;
  final userDoc = await firestore.collection('users').doc(currentUser.uid).get();
  
  // Get admin's companyId
  final userData = userDoc.data()!;
  final companyId = userData['companyId'] as String;  // "ABC"
  
  // Query only THIS company's pending employees
  final snapshot = await firestore
      .collection('users')
      .where('role', isEqualTo: 'employee')
      .where('companyId', isEqualTo: companyId)  // ✅ Filter by company
      .where('status', isEqualTo: 'pending')
      .get();
  
  return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
}
```

---

### **3. Fetching Company-Specific Projects**

**File:** `lib/shared/services/firestore_service.dart`

```dart
Future<List<ProjectModel>> getEmployeeProjects(String employeeId) async {
  // Get employee's companyId
  final employeeDoc = await firestore.collection('users').doc(employeeId).get();
  final employeeData = employeeDoc.data()!;
  final companyId = employeeData['companyId'] as String;  // "ABC"
  
  // Get projects for THIS company only
  final projectsSnapshot = await firestore
      .collection('projects')
      .where('isActive', isEqualTo: true)
      .where('companyId', isEqualTo: companyId)  // ✅ Filter by company
      .get();
  
  // Further filter by assigned employees
  final assignedProjects = projectsSnapshot.docs.where((doc) {
    final assignedEmployeeIds = doc.data()['assignedEmployeeIds'] as List;
    return assignedEmployeeIds.contains(employeeId);
  }).toList();
  
  return assignedProjects;
}
```

---

## 🎯 **SUMMARY**

### **How Employee Gets CompanyId:**

```
1. Super Admin creates company "ABC"
   └─ Creates company admin with companyId: "ABC"

2. Company Admin creates supervisor
   └─ Supervisor gets admin's companyId: "ABC"

3. Supervisor creates employee
   └─ Employee gets supervisor's companyId: "ABC"

Result: All users have companyId: "ABC"  ✅
```

### **How It's Used:**

```
1. Data Filtering:
   - Admin queries: WHERE companyId = "ABC"
   - Only sees ABC employees  ✅

2. Employee ID Format:
   - Employee ID includes company code
   - ABC-0001, ABC-0002, ABC-0003  ✅

3. Multi-Tenancy:
   - Company A cannot see Company B data
   - Complete isolation  ✅
```

### **Key Fields:**

- **`companyId`** - Links user to company
- **`employeeId`** - Includes company code (ABC-0001)
- **`supervisorId`** - Links employee to supervisor
- **`assignedProjectId`** - Links to company project

---

**🎉 Every employee is linked to their company through the `companyId` field, ensuring complete data isolation and multi-tenancy!**

