# 🔐 COMPLETE LOGIN FLOW DIAGRAM - ALL ROLES

## 📊 **VISUAL OVERVIEW**

```
┌─────────────────────────────────────────────────────────────────┐
│                    THREE LOGIN TYPES                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1️⃣ COMPANY ADMIN (Web)                                        │
│     Company Code + Email + Password                             │
│                                                                 │
│  2️⃣ SUPERVISOR (Mobile/Web)                                     │
│     Company Code + Email + Password                             │
│                                                                 │
│  3️⃣ EMPLOYEE (Mobile Only)                                      │
│     Company Code + Employee ID + PIN                            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

# 🏢 **1. COMPANY ADMIN LOGIN FLOW**

## **Platform:** Web App (`/admin-login`)

### **📋 STEP-BY-STEP FLOW:**

```
┌─────────────────────────────────────────────────────────────┐
│ STEP 1: USER OPENS LOGIN PAGE                              │
│ URL: /admin-login                                           │
│ Screen: AdminLoginScreen                                    │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 2: USER ENTERS COMPANY CODE                           │
│ Field: Company Code                                          │
│ Input: "ABC"                                                 │
│                                                              │
│ Behind the scenes:                                           │
│ - Validates format (3-6 uppercase letters)                  │
│ - Queries Firestore: companies WHERE companyCode = "ABC"   │
│ - If found: Shows company name & logo                       │
│ - If not found: Shows error "Invalid company code"          │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 3: USER ENTERS EMAIL                                   │
│ Field: Email                                                 │
│ Input: "admin@abc.com"                                       │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 4: USER ENTERS PASSWORD                                │
│ Field: Password                                              │
│ Input: "Admin123!"                                           │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 5: USER CLICKS "LOGIN" BUTTON                         │
│ Action: _handleLogin()                                       │
│                                                              │
│ Calls: authService.signInWithCompany(                       │
│   companyCode: "ABC",                                        │
│   email: "admin@abc.com",                                    │
│   password: "Admin123!"                                      │
│ )                                                            │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 6: VALIDATE COMPANY CODE                              │
│ Query Firestore:                                             │
│   companies WHERE companyCode = "ABC"                        │
│                                                              │
│ Result:                                                      │
│   ✅ Found: comp_abc123                                      │
│   ✅ Status: active                                          │
│   ✅ Company Name: ABC Construction                          │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 7: FIREBASE AUTH SIGN IN                               │
│ Firebase Auth:                                               │
│   signInWithEmailAndPassword(                                │
│     email: "admin@abc.com",                                  │
│     password: "Admin123!"                                    │
│   )                                                          │
│                                                              │
│ Result:                                                      │
│   ✅ UID: user_xyz789                                        │
│   ✅ Credential returned                                      │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 8: FETCH USER DOCUMENT                                 │
│ Query Firestore:                                             │
│   users/user_xyz789                                           │
│                                                              │
│ Result:                                                      │
│   ✅ Document found                                           │
│   ✅ companyId: "comp_abc123"                                 │
│   ✅ role: "companyadmin"                                    │
│   ✅ status: "active"                                         │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 9: VALIDATE USER BELONGS TO COMPANY                   │
│ Check:                                                        │
│   user.companyId == company.id                               │
│                                                              │
│   "comp_abc123" == "comp_abc123" ✅                         │
│                                                              │
│ Check:                                                        │
│   user.role == "companyadmin" OR "supervisor" ✅            │
│                                                              │
│ Check:                                                        │
│   user.status == "active" ✅                                 │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 10: NAVIGATE TO DASHBOARD                             │
│ Route: AdminDashboardScreen                                 │
│                                                              │
│ Dashboard loads:                                             │
│ - Current user data                                          │
│ - Company projects (WHERE companyId = comp_abc123)          │
│ - Company employees (WHERE companyId = comp_abc123)         │
│ - Pending approvals                                          │
│                                                              │
│ ✅ LOGIN SUCCESSFUL!                                         │
└─────────────────────────────────────────────────────────────┘
```

---

## **📝 COMPANY ADMIN LOGIN CREDENTIALS:**

```
Platform:     Web Browser
URL:          /admin-login
─────────────────────────────────────
Company Code: ABC
Email:        admin@abc.com
Password:     Admin123!
─────────────────────────────────────
```

---

# 👔 **2. SUPERVISOR LOGIN FLOW**

## **Platform:** Mobile App OR Web App

### **📋 STEP-BY-STEP FLOW:**

```
┌─────────────────────────────────────────────────────────────┐
│ STEP 1: USER OPENS SUPERVISOR LOGIN                        │
│ Platform: Mobile App                                        │
│ Screen: SupervisorLoginScreen                              │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 2: USER ENTERS COMPANY CODE                          │
│ Field: Company Code                                          │
│ Input: "ABC"                                                 │
│                                                              │
│ Behind the scenes:                                          │
│ - Validates company code exists                             │
│ - Shows company name/logo                                    │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 3: USER ENTERS EMAIL                                  │
│ Field: Email                                                 │
│ Input: "supervisor@abc.com"                                 │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 4: USER ENTERS PASSWORD                               │
│ Field: Password                                              │
│ Input: "Super123!"                                           │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 5: USER CLICKS "LOGIN"                                │
│ Action: _handleLogin()                                       │
│                                                              │
│ Calls: authController.signInWithEmail(                     │
│   companyCode: "ABC",                                        │
│   email: "supervisor@abc.com",                              │
│   password: "Super123!"                                      │
│ )                                                            │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 6: VALIDATE COMPANY CODE                               │
│ Query Firestore:                                             │
│   companies WHERE companyCode = "ABC"                        │
│                                                              │
│ Result:                                                      │
│   ✅ Found: comp_abc123                                      │
│   ✅ Status: active                                          │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 7: FIREBASE AUTH SIGN IN                               │
│ Firebase Auth:                                               │
│   signInWithEmailAndPassword(                                │
│     email: "supervisor@abc.com",                             │
│     password: "Super123!"                                    │
│   )                                                          │
│                                                              │
│ Result:                                                      │
│   ✅ UID: user_super123                                      │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 8: FETCH USER DOCUMENT                                 │
│ Query Firestore:                                             │
│   users/user_super123                                         │
│                                                              │
│ Result:                                                      │
│   ✅ Document found                                           │
│   ✅ companyId: "comp_abc123"                                │
│   ✅ role: "supervisor"                                      │
│   ✅ status: "approved"                                      │
│   ✅ assignedProjectId: "proj_site_a"                        │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 9: VALIDATE USER DATA                                  │
│ Check:                                                        │
│   user.companyId matches company ✅                         │
│   user.role == "supervisor" ✅                              │
│   user.status == "approved" OR "active" ✅                  │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 10: WAIT FOR USER DATA TO LOAD                        │
│ StreamProvider: currentUserProvider                          │
│                                                              │
│ Waits up to 5 seconds for Firestore data to load           │
│ Checks every 500ms                                           │
│                                                              │
│ Result:                                                      │
│   ✅ User data loaded: UserModel                             │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 11: NAVIGATE TO SUPERVISOR DASHBOARD                  │
│ Route: SupervisorDashboardScreen                            │
│                                                              │
│ Dashboard loads:                                             │
│ - Assigned project details                                   │
│ - Project employees (WHERE assignedProjectId = proj_site_a) │
│ - Manual check-in options                                    │
│ - Employee management                                        │
│                                                              │
│ ✅ LOGIN SUCCESSFUL!                                         │
└─────────────────────────────────────────────────────────────┘
```

---

## **📝 SUPERVISOR LOGIN CREDENTIALS:**

```
Platform:     Mobile App (or Web)
─────────────────────────────────────
Company Code: ABC
Email:        supervisor@abc.com
Password:     Super123!
─────────────────────────────────────
```

---

# 👷 **3. EMPLOYEE LOGIN FLOW**

## **Platform:** Mobile App Only

### **📋 STEP-BY-STEP FLOW:**

```
┌─────────────────────────────────────────────────────────────┐
│ STEP 1: USER OPENS EMPLOYEE LOGIN                          │
│ Platform: Mobile App                                         │
│ Screen: EmployeeLoginScreen                                 │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 2: USER ENTERS COMPANY CODE                           │
│ Field: Company Code                                          │
│ Input: "ABC"                                                 │
│                                                              │
│ Behind the scenes:                                           │
│ - Validates company code exists                             │
│ - Shows company name/logo                                    │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 3: USER ENTERS EMPLOYEE ID                            │
│ Field: Employee ID                                          │
│ Input: "0001" OR "ABC-0001"                                  │
│                                                              │
│ Note: Can enter just number (0001) or full format (ABC-0001)│
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 4: USER CLICKS "NEXT" OR SUBMITS                      │
│ Action: _handleIdSubmit()                                    │
│                                                              │
│ Result:                                                      │
│   ✅ Shows PIN input field                                   │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 5: USER ENTERS PIN                                     │
│ Field: PIN (4 digits)                                        │
│ Input: "1234"                                                │
│                                                              │
│ Note: PIN is set by Company Admin after approving employee │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 6: USER CLICKS "LOGIN"                                │
│ Action: _handlePinLogin()                                    │
│                                                              │
│ Calls: authController.signInWithEmployeeId(                │
│   companyCode: "ABC",                                        │
│   employeeId: "0001",                                        │
│   password: "1234"                                           │
│ )                                                            │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 7: VALIDATE COMPANY CODE                               │
│ Query Firestore:                                             │
│   companies WHERE companyCode = "ABC"                        │
│                                                              │
│ Result:                                                      │
│   ✅ Found: comp_abc123                                      │
│   ✅ Gets company settings (employeeIdPrefix = "ABC")        │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 8: NORMALIZE EMPLOYEE ID                              │
│ Input: "0001" OR "ABC-0001"                                 │
│                                                              │
│ Logic:                                                        │
│   If input is just number:                                   │
│     Full ID = prefix + "-" + number                          │
│     Full ID = "ABC" + "-" + "0001" = "ABC-0001"            │
│                                                              │
│   If input already has prefix:                              │
│     Use as-is: "ABC-0001"                                    │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 9: QUERY EMPLOYEE IN FIRESTORE                        │
│ Query Firestore:                                             │
│   users WHERE                                                 │
│     companyId == "comp_abc123" AND                           │
│     employeeId == "ABC-0001" AND                            │
│     role == "employee"                                       │
│                                                              │
│ Result:                                                      │
│   ✅ Found: user_emp123                                      │
│   ✅ employeeId: "ABC-0001"                                  │
│   ✅ companyId: "comp_abc123"                                │
│   ✅ role: "employee"                                        │
│   ✅ status: "approved"                                      │
│   ✅ pin: "1234" (hashed)                                    │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 10: VALIDATE PIN                                       │
│ Compare:                                                      │
│   Input PIN: "1234"                                          │
│   Stored PIN (hashed): hash("1234")                          │
│                                                              │
│ Result:                                                      │
│   ✅ PIN matches                                              │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 11: CHECK EMPLOYEE STATUS                              │
│ Check:                                                        │
│   user.status == "approved" OR "active" ✅                 │
│                                                              │
│ If status == "pending":                                      │
│   ❌ Show error: "Account pending approval"                  │
│   ❌ Block login                                              │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 12: CHECK DEVICE BINDING                              │
│ Get current device info:                                      │
│   - Device ID: "device_xyz789"                               │
│   - Model: iPhone 12                                         │
│   - OS: iOS 15.0                                            │
│                                                              │
│ Check user document:                                         │
│   user.deviceInfo.deviceId == "device_xyz789"               │
│                                                              │
│ Result:                                                      │
│   ✅ First login: No device bound                            │
│   ✅ Same device: Device matches                             │
│   ❌ Different device: Show "Request Device Reset"           │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 13: BIND DEVICE (First Login)                         │
│ If first login OR device reset approved:                     │
│                                                              │
│ Update Firestore:                                            │
│   users/user_emp123                                          │
│   {                                                          │
│     deviceInfo: {                                            │
│       deviceId: "device_xyz789",                             │
│       model: "iPhone 12",                                    │
│       os: "iOS 15.0",                                        │
│       boundAt: now                                           │
│     }                                                        │
│   }                                                          │
│                                                              │
│ ✅ Device bound successfully                                 │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 14: SET USER IN AUTH STATE                            │
│ authController.state.user = UserModel                        │
│                                                              │
│ User data:                                                   │
│   - uid: user_emp123                                         │
│   - companyId: comp_abc123                                   │
│   - role: employee                                           │
│   - employeeId: ABC-0001                                     │
│   - name: Alice Worker                                       │
│   - status: approved                                         │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 15: NAVIGATE TO EMPLOYEE DASHBOARD                    │
│ Route: EmployeeDashboardScreen                               │
│                                                              │
│ Dashboard loads:                                             │
│ - Employee info (name, ID, photo)                           │
│ - Assigned projects (WHERE companyId = comp_abc123)         │
│ - Check-in/out buttons                                       │
│ - Attendance history                                         │
│ - Documents                                                   │
│                                                              │
│ ✅ LOGIN SUCCESSFUL!                                         │
└─────────────────────────────────────────────────────────────┘
```

---

## **📝 EMPLOYEE LOGIN CREDENTIALS:**

```
Platform:     Mobile App Only
─────────────────────────────────────
Company Code: ABC
Employee ID:  0001 (or ABC-0001)
PIN:          1234 (4 digits)
─────────────────────────────────────
```

---

# 🔄 **COMPLETE COMPARISON TABLE**

| Feature | Company Admin | Supervisor | Employee |
|---------|---------------|------------|----------|
| **Platform** | Web Only | Mobile/Web | Mobile Only |
| **Login URL** | `/admin-login` | Mobile App | Mobile App |
| **Company Code** | ✅ Required | ✅ Required | ✅ Required |
| **Email** | ✅ Required | ✅ Required | ❌ Not used |
| **Password** | ✅ Required | ✅ Required | ❌ Not used |
| **Employee ID** | ❌ Not used | ❌ Not used | ✅ Required |
| **PIN** | ❌ Not used | ❌ Not used | ✅ Required |
| **Firebase Auth** | ✅ Yes | ✅ Yes | ❌ No (Firestore only) |
| **Device Binding** | ❌ No | ❌ No | ✅ Yes |
| **Dashboard** | Admin Dashboard | Supervisor Dashboard | Employee Dashboard |
| **Can Create** | Projects, Supervisors, Employees | Employees | Nothing |
| **Can Approve** | Employees | Nothing | Nothing |
| **Can View** | All company data | Assigned project only | Own data only |

---

# 🎯 **QUICK LOGIN REFERENCE**

## **🏢 Company Admin Login:**

```
1. Open web browser
2. Go to: /admin-login
3. Enter:
   Company Code: ABC
   Email: admin@abc.com
   Password: Admin123!
4. Click "Login"
5. ✅ See Admin Dashboard
```

## **👔 Supervisor Login:**

```
1. Open mobile app
2. Select "Supervisor" login
3. Enter:
   Company Code: ABC
   Email: supervisor@abc.com
   Password: Super123!
4. Click "Login"
5. ✅ See Supervisor Dashboard
```

## **👷 Employee Login:**

```
1. Open mobile app
2. Select "Employee" login
3. Enter:
   Company Code: ABC
   Employee ID: 0001
4. Click "Next"
5. Enter PIN: 1234
6. Click "Login"
7. ✅ See Employee Dashboard
```

---

# 🔐 **SECURITY CHECKS (All Logins)**

## **Common Validations:**

```
✅ Company Code exists
✅ Company is active (not suspended)
✅ User belongs to company (companyId matches)
✅ User status is active/approved
✅ Role matches login type
```

## **Role-Specific Checks:**

### **Company Admin:**
```
✅ Role == "companyadmin"
✅ Has Firebase Auth account
✅ Can access all company data
```

### **Supervisor:**
```
✅ Role == "supervisor"
✅ Has Firebase Auth account
✅ Status == "approved" OR "active"
✅ Can access assigned project only
```

### **Employee:**
```
✅ Role == "employee"
✅ Status == "approved" (not pending)
✅ PIN matches
✅ Device matches (or first login/reset approved)
✅ No Firebase Auth account needed
```

---

# 📊 **DATA ISOLATION**

## **All Logins Filter by Company:**

```
Company Admin (ABC):
  ↓
  Sees: ABC projects, ABC employees, ABC attendance
  ❌ Cannot see: XYZ data

Supervisor (ABC):
  ↓
  Sees: Assigned ABC project, ABC employees in project
  ❌ Cannot see: Other projects, XYZ data

Employee (ABC):
  ↓
  Sees: Own attendance, assigned ABC projects
  ❌ Cannot see: Other employees, XYZ data
```

---

# ✅ **SUMMARY**

**Three login types, each with different:**
- ✅ Credentials (Email+Password vs ID+PIN)
- ✅ Platform (Web vs Mobile)
- ✅ Authentication method (Firebase Auth vs Firestore)
- ✅ Dashboard features
- ✅ Permissions

**But all share:**
- ✅ Company Code requirement
- ✅ Company validation
- ✅ Data isolation by companyId
- ✅ Security checks

**That's the complete login flow for all roles!** 🎉






