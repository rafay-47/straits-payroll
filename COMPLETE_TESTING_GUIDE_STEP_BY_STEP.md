# 🧪 COMPLETE TESTING GUIDE - Step-by-Step

## 🎯 **OVERVIEW: How Everything Connects**

```
Super Admin → Creates Company → Company Admin → Creates Supervisor → Creates Employee
     (You)      (ABC Company)    (admin@abc.com)    (super@abc.com)    (ABC-0001)
```

---

## 📋 **STEP-BY-STEP TESTING GUIDE**

### **PHASE 1: CREATE SUPER ADMIN** ⭐

#### **Step 1.1: Create Firebase Auth Account**

1. Open Firebase Console: https://console.firebase.google.com
2. Go to your project: **straights-payroll**
3. Click **Authentication** → **Users** tab
4. Click **Add User**
5. Fill in:
   - Email: `superadmin@yourcompany.com`
   - Password: `SuperAdmin123!`
6. Click **Add User**
7. **COPY THE UID** (e.g., `sJkL9mNoPqRsT123456789`)

#### **Step 1.2: Create Firestore User Document**

1. In Firebase Console, go to **Firestore Database**
2. Click **users** collection (create if doesn't exist)
3. Click **Add Document**
4. Document ID: **Paste the UID from Step 1.1**
5. Add these fields:

```json
Field Name          | Type      | Value
--------------------|-----------|---------------------------
uid                 | string    | [same UID]
role                | string    | superadmin
companyId           | null      | null
name                | string    | Platform Owner
email               | string    | superadmin@yourcompany.com
status              | string    | active
createdAt           | string    | 2025-12-06T12:00:00.000Z
updatedAt           | string    | 2025-12-06T12:00:00.000Z
```

6. Click **Save**

✅ **Super Admin Created!**

---

### **PHASE 2: RUN THE APP & LOGIN AS SUPER ADMIN** ⭐

#### **Step 2.1: Start the Web App**

```bash
cd /Users/mac/Documents/straights_psyroll

flutter run -d chrome --web-browser-flag "--disable-web-security" --web-browser-flag "--user-data-dir=/tmp/chrome_dev_test"
```

Wait for the app to compile and open in Chrome.

#### **Step 2.2: Navigate to Super Admin Login**

In your app routing, navigate to super admin login screen.

**If you don't have routing setup yet**, temporarily update `lib/web/web_app.dart`:

```dart
import 'screens/auth/super_admin_login_screen.dart';

class WebApp extends StatelessWidget {
  const WebApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Straights Payroll - Admin',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // Temporarily start at super admin login
      home: const SuperAdminLoginScreen(),
      routes: {
        '/super-admin-login': (context) => const SuperAdminLoginScreen(),
        '/admin-login': (context) => const AdminLoginScreen(),
      },
    );
  }
}
```

#### **Step 2.3: Login as Super Admin**

On the login screen:
- Email: `superadmin@yourcompany.com`
- Password: `SuperAdmin123!`
- Click **Login as Super Admin**

✅ **You should now see the Super Admin Dashboard!**

You'll see:
- Platform statistics (0 companies at first)
- Empty company list
- "Create Company" button

---

### **PHASE 3: CREATE COMPANIES** ⭐

#### **Step 3.1: Create First Company (ABC Construction)**

1. Click **"Create Company"** button
2. Fill in the form:

```
Company Name:       ABC Construction
Company Code:       ABC
Contact Name:       John Administrator
Contact Email:      admin@abc.com
Contact Phone:      +1234567890 (optional)
Employee Limit:     50 (optional, leave empty for unlimited)
```

3. **Upload Logo** (optional):
   - Click "Upload Logo"
   - Select an image file
   - Wait for upload

4. Click **"Create Company"**

✅ **Company Created!**

You'll see a success message and the company appears in the list.

**Behind the scenes:**
- Company created in `companies` collection
- Company ID auto-generated
- Company code: ABC
- Employee ID prefix: ABC
- Employee counter: 0 (next employee will be ABC-0001)

#### **Step 3.2: Create Second Company (XYZ Builders)**

Click "Create Company" again:

```
Company Name:       XYZ Builders
Company Code:       XYZ
Contact Name:       Sarah Manager
Contact Email:      admin@xyz.com
Contact Phone:      +0987654321
```

Click **"Create Company"**

✅ **Second Company Created!**

Now you have:
- ABC Construction (code: ABC) → Employees will be ABC-0001, ABC-0002...
- XYZ Builders (code: XYZ) → Employees will be XYZ-0001, XYZ-0002...

#### **Step 3.3: View Company Details**

Click on **ABC Construction** in the list.

You'll see:
- Company information
- Statistics (0 users, 0 projects, 0 attendance)
- Settings (employee ID prefix, max check-ins, etc.)
- Actions (suspend/activate)

---

### **PHASE 4: CREATE COMPANY ADMIN** ⭐

Now create an admin for ABC Construction who can manage the company.

#### **Step 4.1: Get ABC Company ID**

In Firebase Console:
1. Go to **Firestore Database**
2. Click **companies** collection
3. Find **ABC Construction**
4. **COPY THE DOCUMENT ID** (e.g., `comp_abc123xyz`)

#### **Step 4.2: Create Firebase Auth for ABC Admin**

Firebase Console → Authentication → Add User:
- Email: `admin@abc.com`
- Password: `Admin123!`
- **COPY THE UID**

#### **Step 4.3: Create Firestore User Document**

Firestore → **users** collection → Add Document:

Document ID: [UID from Step 4.2]

```json
Field Name          | Type      | Value
--------------------|-----------|---------------------------
uid                 | string    | [UID from 4.2]
companyId           | string    | [ABC Company ID from 4.1]
role                | string    | companyadmin
name                | string    | John Administrator
email               | string    | admin@abc.com
phoneNumber         | string    | +1234567890
status              | string    | active
createdAt           | string    | 2025-12-06T12:00:00.000Z
updatedAt           | string    | 2025-12-06T12:00:00.000Z
```

✅ **ABC Company Admin Created!**

**Repeat for XYZ company** if you want to test multiple companies.

---

### **PHASE 5: TEST COMPANY ADMIN LOGIN** ⭐

#### **Step 5.1: Logout from Super Admin**

Click the logout button in the super admin dashboard.

#### **Step 5.2: Navigate to Company Admin Login**

The app should show the company admin login screen.

#### **Step 5.3: Login as ABC Company Admin**

On the login screen:
- **Company Code:** `ABC`
- **Email:** `admin@abc.com`
- **Password:** `Admin123!`
- Click **Login**

✅ **Logged in as ABC Company Admin!**

You should see:
- ABC Construction name/logo at the top
- Company dashboard
- Only ABC company data (no XYZ data visible)

---

### **PHASE 6: CREATE SUPERVISOR** ⭐

Now create a supervisor who will manage employees.

#### **Step 6.1: Create Firebase Auth for Supervisor**

Firebase Console → Authentication → Add User:
- Email: `supervisor@abc.com`
- Password: `Super123!`
- **COPY THE UID**

#### **Step 6.2: Create Firestore User Document**

Firestore → **users** collection → Add Document:

Document ID: [UID from Step 6.1]

```json
Field Name          | Type      | Value
--------------------|-----------|---------------------------
uid                 | string    | [UID from 6.1]
companyId           | string    | [ABC Company ID]
role                | string    | supervisor
name                | string    | Mike Supervisor
email               | string    | supervisor@abc.com
phoneNumber         | string    | +1234567891
status              | string    | active
assignedProjectId   | string    | [leave empty for now]
createdAt           | string    | 2025-12-06T12:00:00.000Z
updatedAt           | string    | 2025-12-06T12:00:00.000Z
```

✅ **Supervisor Created!**

---

### **PHASE 7: TEST SUPERVISOR LOGIN (MOBILE)** ⭐

#### **Step 7.1: Run Mobile App**

Open a new terminal:

```bash
cd /Users/mac/Documents/straights_psyroll

# Check available devices
flutter devices

# Run on device (example for Android emulator)
flutter run -d emulator-5554

# Or iOS simulator
flutter run -d "iPhone 15 Pro"
```

#### **Step 7.2: Login as Supervisor**

On the mobile app:
1. Select **"Supervisor"** or navigate to supervisor login
2. Fill in:
   - **Company Code:** `ABC`
   - **Email:** `supervisor@abc.com`
   - **Password:** `Super123!`
3. Click **Login**

✅ **Logged in as Supervisor!**

You should see the Supervisor Dashboard with ABC company branding.

---

### **PHASE 8: CREATE EMPLOYEES** ⭐

Now the supervisor creates employees.

#### **Step 8.1: Add First Employee**

In the Supervisor app:
1. Tap **"Add Employee"** or **"Manage Employees"**
2. Fill in the form:

```
Name:         Alice Worker
Email:        alice@abc.com
Phone:        +1234567892
Position:     Construction Worker
```

3. Tap **"Add Employee"**

🎉 **System automatically generates:**
- **Employee ID:** `ABC-0001`
- **Employee ID Number:** `0001`
- **Company ID:** [ABC company ID]
- **Status:** `pending` (needs approval)

The supervisor will see:
```
✅ Employee Created!
Employee ID: ABC-0001
Status: Pending Approval
```

#### **Step 8.2: Add Second Employee**

Repeat the process:
```
Name:         Bob Builder
Email:        bob@abc.com
Position:     Site Worker
```

🎉 **Employee ID auto-generated:**
- **Employee ID:** `ABC-0002`

#### **Step 8.3: Add Third Employee**

```
Name:         Carol Engineer
Email:        carol@abc.com
Position:     Engineer
```

🎉 **Employee ID auto-generated:**
- **Employee ID:** `ABC-0003`

✅ **You now have 3 employees in ABC company!**

---

### **PHASE 9: APPROVE EMPLOYEES (COMPANY ADMIN)** ⭐

#### **Step 9.1: Go Back to Web Dashboard**

Switch to your web browser (company admin dashboard).

#### **Step 9.2: View Pending Employees**

Navigate to **Employees** → **Pending Approvals**

You should see:
- Alice Worker (ABC-0001) - Pending
- Bob Builder (ABC-0002) - Pending
- Carol Engineer (ABC-0003) - Pending

#### **Step 9.3: Approve Employees**

For each employee:
1. Click **"Approve"** button
2. Confirm approval
3. Status changes to **"approved"**

✅ **Employees now approved and can login!**

---

### **PHASE 10: TEST EMPLOYEE LOGIN (MOBILE)** ⭐

#### **Step 10.1: Login as First Employee**

On the mobile app:
1. Go back to login screen (or logout supervisor)
2. Select **"Employee"** login
3. Fill in:
   - **Company Code:** `ABC`
   - **Employee ID:** `0001` (or `ABC-0001`)
4. Tap **Login**

✅ **Logged in as Alice (ABC-0001)!**

You should see:
- Employee Dashboard
- ABC Construction name/logo
- Employee ID: ABC-0001
- Assigned projects (if any)

#### **Step 10.2: Device Binding**

On first login, the system automatically:
- Registers the device (phone model, OS, device ID)
- Binds device to employee
- Employee can only login from this device now

You'll see a message: "Device registered successfully"

#### **Step 10.3: Test Check-In**

If you have a project created:
1. Tap **"Check In"** button
2. Select project
3. Choose check-in method (GPS/Manual)
4. Confirm

✅ **Checked In!**

The attendance record includes:
- Company ID: ABC
- Employee ID: ABC-0001
- Project ID
- Timestamp

---

### **PHASE 11: CREATE PROJECTS** ⭐

Go back to Company Admin (web) or Supervisor (mobile).

#### **Step 11.1: Create Project (Company Admin)**

In web dashboard:
1. Navigate to **Projects** → **Add Project**
2. Fill in:

```
Project Name:       Construction Site A
Location:           123 Main St, City
GPS Coordinates:    [Use map picker or enter manually]
Latitude:           40.7128
Longitude:          -74.0060
Radius:             200 (meters)
Check-in Methods:   ☑ GPS ☑ Manual
Status:             Active
Supervisor:         Mike Supervisor
```

3. Click **"Create Project"**

✅ **Project Created!**

The project is automatically linked to ABC company (companyId included).

---

### **PHASE 12: TEST DATA ISOLATION** ⭐

This is critical! Let's verify ABC cannot see XYZ data.

#### **Step 12.1: Create XYZ Company Admin**

Following the same steps as Phase 4:
1. Get XYZ company ID from Firestore
2. Create Firebase Auth user: `admin@xyz.com`
3. Create Firestore user document with XYZ companyId

#### **Step 12.2: Create XYZ Supervisor & Employees**

1. Create supervisor: `supervisor@xyz.com` (XYZ company)
2. Supervisor creates employees:
   - First employee gets: **XYZ-0001**
   - Second employee gets: **XYZ-0002**

#### **Step 12.3: Test Isolation**

**Test A: Login as ABC Admin**
- Company Code: ABC
- Login as admin@abc.com
- **Expected:** See only ABC employees (ABC-0001, ABC-0002, ABC-0003)
- **Expected:** Do NOT see XYZ employees

**Test B: Login as XYZ Admin**
- Company Code: XYZ
- Login as admin@xyz.com
- **Expected:** See only XYZ employees (XYZ-0001, XYZ-0002)
- **Expected:** Do NOT see ABC employees

**Test C: Login as Super Admin**
- Login as superadmin@yourcompany.com
- **Expected:** See ALL companies
- **Expected:** See ABC and XYZ in company list

✅ **Data Isolation Working!**

---

## 🎯 **COMPLETE FLOW DIAGRAM**

```
DAY 1: SETUP
─────────────

1. YOU (Super Admin)
   └─ Login to Super Admin Dashboard
      └─ Create Company: ABC Construction (Code: ABC)
      └─ Create Company: XYZ Builders (Code: XYZ)

2. ABC COMPANY SETUP
   └─ Create Company Admin: admin@abc.com
      └─ Login with: ABC + admin@abc.com
         └─ Create Supervisor: supervisor@abc.com
         └─ Create Project: "Construction Site A"

3. ABC SUPERVISOR
   └─ Login with: ABC + supervisor@abc.com (Mobile)
      └─ Create Employee #1 → ABC-0001 (auto-generated)
      └─ Create Employee #2 → ABC-0002 (auto-generated)
      └─ Create Employee #3 → ABC-0003 (auto-generated)

4. ABC COMPANY ADMIN
   └─ Approve Employees:
      ✓ Approve ABC-0001 (Alice)
      ✓ Approve ABC-0002 (Bob)
      ✓ Approve ABC-0003 (Carol)

5. ABC EMPLOYEE
   └─ Login with: ABC + 0001 (Mobile)
      └─ Device automatically registered
      └─ Check-in to "Construction Site A"
      └─ Work...
      └─ Check-out

DAY 2: VERIFY ISOLATION
────────────────────────

6. XYZ COMPANY SETUP (repeat steps 2-5 for XYZ)
   └─ Employees get: XYZ-0001, XYZ-0002, etc.

7. TEST ISOLATION
   └─ ABC admin cannot see XYZ data ✓
   └─ XYZ admin cannot see ABC data ✓
   └─ ABC employees see only ABC projects ✓
   └─ Super admin sees everything ✓
```

---

## 📝 **QUICK REFERENCE TABLE**

| User Type | Platform | Company Code | Email | Employee ID | Password |
|-----------|----------|--------------|-------|-------------|----------|
| **Super Admin** | Web | - | superadmin@yourcompany.com | - | SuperAdmin123! |
| **ABC Admin** | Web | ABC | admin@abc.com | - | Admin123! |
| **ABC Supervisor** | Mobile | ABC | supervisor@abc.com | - | Super123! |
| **ABC Employee 1** | Mobile | ABC | - | 0001 or ABC-0001 | - |
| **ABC Employee 2** | Mobile | ABC | - | 0002 or ABC-0002 | - |
| **XYZ Admin** | Web | XYZ | admin@xyz.com | - | Admin123! |
| **XYZ Supervisor** | Mobile | XYZ | supervisor@xyz.com | - | Super123! |
| **XYZ Employee 1** | Mobile | XYZ | - | 0001 or XYZ-0001 | - |

---

## 🎯 **EMPLOYEE LOGIN FLOW (DETAILED)**

### **Example: Alice (ABC-0001) Logging In**

#### **Step 1: Open Mobile App**

Employee opens the app on their phone.

#### **Step 2: Select Employee Login**

App shows role selection or employee login screen.

#### **Step 3: Enter Company Code**

```
Company Code: ABC
[Next]
```

**What happens:**
- App queries Firestore for company with code "ABC"
- Fetches company info (name, logo, settings)
- Shows company logo on screen
- Validates company is active

#### **Step 4: Enter Employee ID**

```
Employee ID: 0001
[Login]
```

**What happens:**
- App queries Firestore:
  ```javascript
  users
    .where('companyId', '==', 'abc_company_id')
    .where('employeeId', '==', 'ABC-0001')
    .where('role', '==', 'employee')
  ```
- Finds Alice's user document
- Checks status (must be 'approved' or 'active')
- Checks device binding

#### **Step 5: Device Binding (First Login)**

**First time login:**
- App gets device info (model, OS, ID)
- Saves to user document
- Device now registered

**Subsequent logins:**
- App checks if current device matches registered device
- If different → Show "Device Reset Request" option
- If same → Login successful

#### **Step 6: Dashboard Loaded**

Alice sees:
- Her employee ID: ABC-0001
- ABC Construction logo/name
- Assigned projects (only ABC projects)
- Check-in/out buttons
- Attendance history

---

## 🎯 **SUPERVISOR LOGIN FLOW (DETAILED)**

### **Example: Mike Supervisor Logging In**

#### **Step 1: Open Mobile App**

#### **Step 2: Select Supervisor Login**

#### **Step 3: Enter Company Code**

```
Company Code: ABC
```

App fetches ABC company info.

#### **Step 4: Enter Email & Password**

```
Email:    supervisor@abc.com
Password: Super123!
[Login]
```

**What happens:**
- App validates company code (ABC exists and active)
- Uses Firebase Auth to sign in
- Fetches user document from Firestore
- Validates user.companyId matches ABC company ID
- Validates user.role is 'supervisor'

#### **Step 5: Dashboard Loaded**

Supervisor sees:
- ABC Construction branding
- List of ABC employees only (ABC-0001, ABC-0002, ABC-0003)
- ABC projects only
- Options to:
  - Add new employees
  - Upload documents
  - Manual check-in
  - View attendance

---

## 🎯 **RELATIONSHIP DIAGRAM**

```
┌──────────────────────────────────────────────────────────┐
│  SUPER ADMIN (You)                                       │
│  Email: superadmin@yourcompany.com                       │
│  Access: ALL COMPANIES                                   │
└────────────────┬─────────────────────────────────────────┘
                 │
                 ├─────────────────────┬──────────────────┐
                 ▼                     ▼                  ▼
    ┌────────────────────┐  ┌────────────────┐  ┌────────────────┐
    │  ABC CONSTRUCTION  │  │  XYZ BUILDERS  │  │  TEST COMPANY  │
    │  Code: ABC         │  │  Code: XYZ     │  │  Code: TEST    │
    └────────┬───────────┘  └────────┬───────┘  └────────┬───────┘
             │                       │                   │
    ┌────────▼───────────┐  ┌────────▼───────┐  ┌───────▼────────┐
    │  Company Admin     │  │  Company Admin │  │  Company Admin │
    │  admin@abc.com     │  │  admin@xyz.com │  │  admin@test.com│
    └────────┬───────────┘  └────────┬───────┘  └────────┬───────┘
             │                       │                   │
    ┌────────▼───────────┐  ┌────────▼───────┐         │
    │  Supervisor        │  │  Supervisor    │         │
    │  super@abc.com     │  │  super@xyz.com │         │
    └────────┬───────────┘  └────────┬───────┘         │
             │                       │                   │
    ┌────────▼───────────┐  ┌────────▼───────┐  ┌───────▼────────┐
    │  Employees         │  │  Employees     │  │  Employees     │
    │  ABC-0001          │  │  XYZ-0001      │  │  TEST-0001     │
    │  ABC-0002          │  │  XYZ-0002      │  │  TEST-0002     │
    │  ABC-0003          │  │  XYZ-0003      │  │                │
    └────────────────────┘  └────────────────┘  └────────────────┘
         ↑                       ↑                     ↑
         └─ ABC Projects         └─ XYZ Projects      └─ TEST Projects
            ABC Attendance          XYZ Attendance        TEST Attendance
            
    ✗ Cannot access ←──────────────→ Cannot access
```

---

## 🧪 **TESTING SCENARIOS**

### **Scenario 1: Employee Check-In**

```
1. Login: ABC + ABC-0001 (Alice)
2. Dashboard shows: ABC projects only
3. Select: "Construction Site A"
4. Tap: "Check In"
5. System records:
   - companyId: ABC company ID
   - userId: Alice's UID
   - employeeId: ABC-0001
   - projectId: Site A
   - timestamp: now
6. Attendance saved with ABC company ID
```

### **Scenario 2: Supervisor Manual Check-In**

```
1. Login: ABC + supervisor@abc.com
2. Select: "Manual Check-In"
3. Choose employee: ABC-0002 (Bob)
4. Choose project: "Construction Site A"
5. Tap: "Check In"
6. System records attendance for Bob
7. Bob's status updates to "Checked In"
```

### **Scenario 3: Data Isolation Test**

```
1. Login as ABC admin (ABC + admin@abc.com)
2. Navigate to Employees
3. Expected: See ABC-0001, ABC-0002, ABC-0003
4. Expected: DO NOT see XYZ-0001, XYZ-0002

5. Logout
6. Login as XYZ admin (XYZ + admin@xyz.com)
7. Navigate to Employees
8. Expected: See XYZ-0001, XYZ-0002, XYZ-0003
9. Expected: DO NOT see ABC-0001, ABC-0002

10. Logout
11. Login as Super Admin
12. View companies
13. Expected: See both ABC and XYZ
14. Click ABC company
15. Expected: See ABC statistics and data
16. Click XYZ company
17. Expected: See XYZ statistics and data
```

---

## ⚡ **QUICK TEST SCRIPT**

### **Copy-Paste Testing Sequence:**

```bash
# Terminal 1: Start Web App
cd /Users/mac/Documents/straights_psyroll
flutter run -d chrome

# Terminal 2: Start Mobile App
cd /Users/mac/Documents/straights_psyroll
flutter run -d <your-device>
```

**Then follow:**

1. ✅ Create super admin in Firebase
2. ✅ Login to super admin dashboard
3. ✅ Create ABC company (code: ABC)
4. ✅ Create XYZ company (code: XYZ)
5. ✅ Create ABC admin (companyId: ABC)
6. ✅ Login as ABC admin (ABC + admin@abc.com)
7. ✅ Create ABC supervisor
8. ✅ Login as ABC supervisor (Mobile: ABC + supervisor@abc.com)
9. ✅ Create 3 employees → Get ABC-0001, ABC-0002, ABC-0003
10. ✅ Login as ABC admin → Approve employees
11. ✅ Login as ABC-0001 (Mobile: ABC + 0001)
12. ✅ Device registered automatically
13. ✅ View dashboard (only ABC projects)
14. ✅ Logout, login as XYZ admin
15. ✅ Verify cannot see ABC data
16. ✅ Login as super admin
17. ✅ Verify can see both ABC and XYZ

---

## 🔍 **TROUBLESHOOTING**

### **Issue 1: Cannot Login as Super Admin**
**Check:**
- User document exists in Firestore users collection
- role field = "superadmin" (lowercase)
- companyId field = null
- status field = "active"

### **Issue 2: Cannot Login as Company Admin**
**Check:**
- Company code exists in companies collection
- Company status = "active"
- User document has correct companyId
- User role = "companyadmin" or "supervisor"

### **Issue 3: Employee ID Not Auto-Generated**
**Check:**
- Company exists with companyCode
- Company settings has employeeIdPrefix
- Using companyService.getNextEmployeeId() method
- Company employeeIdCounter is updating

### **Issue 4: Can See Other Company's Data**
**Check:**
- Firestore rules deployed
- All queries include companyId filter
- User document has correct companyId
- Not logged in as super admin

### **Issue 5: Employee Cannot Login**
**Check:**
- Employee status = "approved" or "active"
- Employee document has companyId
- Employee document has employeeId (ABC-0001 format)
- Company code is correct
- Company is active

---

## 📊 **EXPECTED DATABASE STATE**

After complete testing, your Firestore should look like:

```
companies/
  comp_abc123/
    name: "ABC Construction"
    companyCode: "ABC"
    settings.employeeIdCounter: 3
    status: "active"
  
  comp_xyz456/
    name: "XYZ Builders"
    companyCode: "XYZ"
    settings.employeeIdCounter: 2
    status: "active"

users/
  uid_superadmin/
    role: "superadmin"
    companyId: null
  
  uid_abc_admin/
    role: "companyadmin"
    companyId: "comp_abc123"
    email: "admin@abc.com"
  
  uid_abc_supervisor/
    role: "supervisor"
    companyId: "comp_abc123"
    email: "supervisor@abc.com"
  
  uid_abc_emp1/
    role: "employee"
    companyId: "comp_abc123"
    employeeId: "ABC-0001"
    employeeIdNumber: "0001"
    status: "approved"
  
  uid_abc_emp2/
    role: "employee"
    companyId: "comp_abc123"
    employeeId: "ABC-0002"
    status: "approved"
  
  uid_xyz_admin/
    role: "companyadmin"
    companyId: "comp_xyz456"
    email: "admin@xyz.com"
  
  uid_xyz_emp1/
    role: "employee"
    companyId: "comp_xyz456"
    employeeId: "XYZ-0001"

projects/
  proj_abc1/
    companyId: "comp_abc123"
    name: "Construction Site A"
  
  proj_xyz1/
    companyId: "comp_xyz456"
    name: "Renovation Site B"

attendance/
  att_1/
    companyId: "comp_abc123"
    userId: "uid_abc_emp1"
    projectId: "proj_abc1"
  
  att_2/
    companyId: "comp_xyz456"
    userId: "uid_xyz_emp1"
    projectId: "proj_xyz1"
```

---

## ✅ **SUCCESS CRITERIA**

You know it's working when:

✅ Super admin can create companies
✅ Each company gets unique code (ABC, XYZ)
✅ Company admin can only see their company
✅ Employees get auto-generated IDs (ABC-0001)
✅ ABC employees cannot see XYZ projects
✅ XYZ employees cannot see ABC projects
✅ Super admin can see all companies
✅ All logins work correctly
✅ No linter errors
✅ No runtime errors

---

## 🎊 **YOU'RE READY!**

This guide shows you **exactly** how to test every aspect of the multi-tenant system!

Follow the steps in order, and you'll have a fully functional multi-tenant platform with:
- Multiple companies
- Complete data isolation
- Auto-generated employee IDs
- All roles working correctly

**Happy Testing!** 🚀

---

**Created:** December 6, 2025  
**Status:** Complete Testing Guide  
**Next:** Follow steps to test your platform!






