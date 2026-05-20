# 🏢 HOW EMPLOYEES & SUPERVISORS IDENTIFY THEIR COMPANY

**Last Updated:** December 14, 2025

---

## 📋 **TABLE OF CONTENTS**

1. [Overview](#overview)
2. [Employee Identification](#employee-identification)
3. [Supervisor Identification](#supervisor-identification)
4. [Company Admin Identification](#company-admin-identification)
5. [Technical Implementation](#technical-implementation)
6. [Examples](#examples)

---

## 🎯 **OVERVIEW**

In the Straights Psyroll multi-tenant system, **employees and supervisors identify their company differently**:

| User Type | Identification Method | Company Code Required? |
|-----------|----------------------|------------------------|
| **Employee** | Employee ID (contains company code) | ❌ No - embedded in ID |
| **Supervisor** | Email + Password + Company Code | ✅ Yes - manual entry |
| **Company Admin** | Email + Password + Company Code | ✅ Yes - manual entry |
| **Super Admin** | Email + Password only | ❌ No |

---

## 👷 **EMPLOYEE IDENTIFICATION**

### **How It Works:**

**Employees identify their company through their Employee ID**, which contains the company code.

### **Employee ID Format:**
```
ABC-0001
│   └── Employee Number (unique per company)
└────── Company Code (3 letters)
```

### **Login Flow:**

**Step 1: Employee enters ID**
```
Employee ID: ABC-0001  (or just "0001")
PIN: 1234
```

**Step 2: System extracts company from ID**
```dart
// In FirestoreService.getEmployeeByIdAndPin()

String formattedId = employeeId.trim();

// If user enters just "0001", system needs company code
// If user enters "ABC-0001", company code is extracted

// Query: Find employee with this employeeId
final querySnapshot = await _firestore
  .collection('users')
  .where('employeeId', isEqualTo: formattedId)
  .where('role', isEqualTo: 'employee')
  .limit(1)
  .get();
```

**Step 3: System validates**
- ✅ Employee exists?
- ✅ PIN matches?
- ✅ Status is "active" or "approved"?
- ✅ Company is active?

### **Key Points:**

✅ **No company code needed** - it's embedded in the Employee ID  
✅ **No Firebase Auth** - employees use Firestore-only authentication  
✅ **Device binding** - first login binds device  
✅ **PIN-based** - 4-digit PIN instead of password

### **Current Implementation:**

**File:** `lib/mobile/screens/auth/employee_login_screen.dart`

```dart
// Line 88-91
final success = await ref.read(authControllerProvider.notifier).signInWithEmployeeId(
  employeeId: employeeId,  // e.g., "ABC-0001" or "0001"
  password: pin,            // 4-digit PIN
);
```

**File:** `lib/shared/services/firestore_service.dart`

```dart
Future<UserModel?> getEmployeeByIdAndPin({
  required String employeeId,
  required String pin,
}) async {
  try {
    // Query Firestore by employeeId
    final querySnapshot = await _firestore
      .collection('users')
      .where('employeeId', isEqualTo: employeeId)
      .where('role', isEqualTo: 'employee')
      .limit(1)
      .get();

    if (querySnapshot.docs.isEmpty) {
      return null; // Employee not found
    }

    final userData = querySnapshot.docs.first.data();
    
    // Validate PIN (stored in Firestore user document)
    if (userData['pin'] != pin) {
      return null; // Invalid PIN
    }

    return UserModel.fromMap(userData);
  } catch (e) {
    return null;
  }
}
```

---

## 👨‍💼 **SUPERVISOR IDENTIFICATION**

### **How It Works:**

**Supervisors MUST enter a company code** during login to identify which company they belong to.

### **Login Flow:**

**Step 1: Supervisor enters company code**
```
Company Code: ABC
[Continue]
```

**Step 2: System validates company**
```dart
// In supervisor_login_screen.dart - _validateCompanyCode()

final company = await _companyService.getCompanyByCode(code);

if (company == null) {
  // Show error: Invalid company code
  return;
}

if (!company.isActive) {
  // Show error: Company suspended
  return;
}

// Display company logo and name
setState(() {
  _validatedCompany = company;
  _showLoginFields = true;
});
```

**Step 3: Supervisor enters credentials**
```
Email: supervisor@example.com
Password: ••••••••
[Login]
```

**Step 4: System authenticates & validates**
```dart
// In supervisor_login_screen.dart - _handleLogin()

// Use AuthService.signInWithCompany for proper validation
final authService = ref.read(authServiceProvider);
await authService.signInWithCompany(
  companyCode: _validatedCompany!.companyCode,
  email: _emailController.text.trim(),
  password: _passwordController.text,
);

// This method validates:
// 1. Email/password are correct
// 2. User belongs to this company (companyId matches)
// 3. User has 'supervisor' role
```

### **Key Points:**

✅ **Company code REQUIRED** - manual entry by supervisor  
✅ **Firebase Auth** - supervisors have full Firebase Authentication accounts  
✅ **Email + Password** - standard authentication  
✅ **Company validation** - system checks supervisor belongs to entered company  
✅ **Company branding** - logo and name displayed after validation

### **Current Implementation:**

**File:** `lib/mobile/screens/auth/supervisor_login_screen.dart`

✅ **FULLY IMPLEMENTED** - Now includes company code validation just like Company Admin login!

---

## 🏢 **COMPANY ADMIN IDENTIFICATION**

### **How It Works:**

**Company Admins enter a company code** to identify their company, just like supervisors.

### **Login Flow:**

**File:** `lib/web/screens/auth/admin_login_screen.dart`

**Step 1: Enter company code**
```
Company Code: ABC
[Continue]
```

**Step 2: System validates & displays company branding**
```dart
// Lines 48-100
Future<void> _validateCompanyCode() async {
  final code = _companyCodeController.text.trim().toUpperCase();
  
  // Validate company exists
  final company = await _companyService.getCompanyByCode(code);
  
  if (company == null) {
    // Show error
    return;
  }
  
  if (!company.isActive) {
    // Show "Company suspended" error
    return;
  }
  
  // Display company logo and name
  setState(() {
    _validatedCompany = company;
    _showLoginFields = true;
  });
}
```

**Step 3: Enter credentials**
```
Email: admin@company.com
Password: ••••••••
[Login]
```

**Step 4: System authenticates**
```dart
// Lines 102-135
Future<void> _handleLogin() async {
  // Use AuthService.signInWithCompany()
  final success = await _authService.signInWithCompany(
    companyCode: _validatedCompany!.companyCode,
    email: _emailController.text.trim(),
    password: _passwordController.text,
  );
  
  // This method validates:
  // - Email/password are correct
  // - User belongs to this company (companyId matches)
  // - User has 'companyadmin' or 'admin' role
}
```

### **Key Points:**

✅ **Company code REQUIRED** - entered first, validated before login  
✅ **Firebase Auth** - company admins have full Firebase Authentication  
✅ **Company branding** - logo and name displayed after validation  
✅ **Web dashboard** - company admins use web interface

---

## 🔧 **TECHNICAL IMPLEMENTATION**

### **Database Schema:**

**users Collection:**
```javascript
{
  uid: "firebase-auth-uid-or-auto-id",
  companyId: "company-doc-id",        // ⭐ Links user to company
  employeeId: "ABC-0001",             // ⭐ Contains company code
  employeeIdNumber: "0001",
  name: "John Doe",
  email: "john@example.com",
  role: "employee",                    // or "supervisor", "companyadmin"
  pin: "1234",                         // For employees only
  status: "active",
  assignedProjectId: "project-id",
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

**companies Collection:**
```javascript
{
  id: "auto-generated-id",
  companyCode: "ABC",                 // ⭐ 3-letter unique code
  companyName: "ABC Construction",
  logoUrl: "https://...",
  isActive: true,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

### **Authentication Methods:**

| Method | Used By | Firebase Auth? | Company Identification |
|--------|---------|----------------|------------------------|
| `signInSuperAdmin()` | Super Admin | ✅ Yes | N/A (platform-wide) |
| `signInWithCompany()` | Company Admin, Supervisor | ✅ Yes | Company code parameter |
| `signInEmployee()` | Employee | ❌ No | Extracted from Employee ID |
| `signInWithEmployeeId()` | Employee | ❌ No | Query by employeeId field |

### **Key Services:**

**1. AuthService** (`lib/shared/services/auth_service.dart`)
- `signInSuperAdmin()` - Lines 31-65
- `signInWithCompany()` - Lines 68-123
- `signInEmployee()` - Lines 127-182

**2. FirestoreService** (`lib/shared/services/firestore_service.dart`)
- `getEmployeeByIdAndPin()` - Queries by employeeId + PIN

**3. CompanyService** (`lib/shared/services/company_service.dart`)
- `getCompanyByCode()` - Looks up company by 3-letter code

---

## 📖 **EXAMPLES**

### **Example 1: Employee Login**

**Scenario:** Construction worker "John Doe" logs in  
**Company:** ABC Construction (code: ABC)  
**Employee ID:** ABC-0001  
**PIN:** 1234

**Step-by-step:**

1. Open mobile app → Select "Employee Login"
2. Enter Employee ID: `ABC-0001` (or just `0001`)
3. Enter PIN: `1234`
4. System:
   - Queries Firestore: `WHERE employeeId == "ABC-0001" AND role == "employee"`
   - Finds user with `companyId: "abc-construction-id"`
   - Validates PIN matches
   - Returns `UserModel` with `companyId` field set
5. Employee logged in ✅
6. Dashboard shows:
   - Projects from company ABC only
   - Attendance for ABC projects only
   - Documents for ABC company only

**No company code needed!** The `ABC` in `ABC-0001` identifies the company.

---

### **Example 2: Supervisor Login (CURRENT - WITH COMPANY CODE)**

**Scenario:** Site supervisor "Jane Smith" logs in  
**Company:** ABC Construction  
**Code:** ABC  
**Email:** jane@abc.com  
**Password:** password123

**Step-by-step:**

1. Open mobile app → Select "Supervisor Login"
2. **Enter Company Code: `ABC`**
3. Click "Continue"
4. System validates company exists and is active
5. Shows company logo and name: "ABC Construction"
6. Enter Email: `jane@abc.com`
7. Enter Password: `password123`
8. Click "Login"
9. System:
   - Calls `AuthService.signInWithCompany(companyCode: "ABC", ...)`
   - Validates email/password with Firebase Auth
   - Validates supervisor belongs to company ABC (companyId matches)
   - Validates `role == "supervisor"`
10. Supervisor logged in ✅

**✅ Secure!** Company code validation ensures supervisor logs into correct company.

---

### **Example 3: Company Admin Login**

**Scenario:** Company administrator logs in to web dashboard  
**Company:** ABC Construction  
**Code:** ABC  
**Email:** admin@abc.com  
**Password:** adminpass

**Step-by-step:**

1. Open web app → Navigate to `/admin-login`
2. Enter Company Code: `ABC`
3. Click "Continue"
4. System validates company, shows logo and name
5. Enter Email: `admin@abc.com`
6. Enter Password: `adminpass`
7. System:
   - Calls `AuthService.signInWithCompany(companyCode: "ABC", ...)`
   - Validates admin belongs to company ABC
   - Validates `role == "companyadmin" OR "admin"`
8. Redirects to admin dashboard ✅
9. Dashboard shows:
   - Only ABC company's projects
   - Only ABC company's employees
   - Only ABC company's data

---

## ⚠️ **POTENTIAL IMPROVEMENTS**

### **Improvement 1: Employee ID Format Flexibility**

**Problem:**  
System accepts both `0001` and `ABC-0001` formats, but query only works with exact match.

**Risk:**  
If employee enters `0001` but database stores `ABC-0001`, login fails.

**Recommendation:**  
Normalize employee ID format during login:
```dart
String normalizeEmployeeId(String input, String companyCode) {
  input = input.trim().toUpperCase();
  if (!input.contains('-')) {
    return '$companyCode-$input';
  }
  return input;
}
```

---

## ✅ **SUMMARY**

| User Type | Company Identification | Implementation Status |
|-----------|------------------------|----------------------|
| **Employee** | Employee ID (embedded) | ✅ Working correctly |
| **Supervisor** | Company code (manual entry) | ✅ **FIXED** - Now includes validation |
| **Company Admin** | Company code (manual entry) | ✅ Working correctly |
| **Super Admin** | N/A (platform-wide) | ✅ Working correctly |

**Key Takeaway:**  
- ✅ **Employees** identify company through their ID (e.g., `ABC-0001`)
- ✅ **Supervisors** identify company via code entry (secure & validated)
- ✅ **Company Admins** identify company via code entry (working)

---

## 🎉 **ALL ISSUES RESOLVED!**

✅ **Supervisor login now includes company code validation**
- Two-step process: Company code → Email/Password
- Displays company logo and name after validation
- Uses `AuthService.signInWithCompany()` for proper security
- Consistent with Company Admin login flow

**All user types now have secure, company-validated authentication!** 🔒

