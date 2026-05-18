# 🔑 Complete Account Creation & Linking Guide

## 📋 Overview: 3 Types of Accounts

| Account Type | Created By | Created Where | Login Method | 
|--------------|-----------|---------------|--------------|
| **Admin** | Manual (Firebase Console) | Firebase Console | Email/Password |
| **Supervisor** | Admin | Web Dashboard | Email/Password |
| **Employee** | Supervisor | Mobile App | Employee ID/PIN |

---

## 🎯 PART 1: Creating Admin Account (Manual - Firebase Console)

### Why Manual?
The first admin must be created manually because there's no one to create it yet (chicken and egg problem).

### Step-by-Step:

#### **A. Create Firebase Auth Account**

1. **Open Firebase Console**
   - Go to: https://console.firebase.google.com
   - Select your project: `straights_psyroll`

2. **Navigate to Authentication**
   - Left sidebar → Click "Authentication"
   - Click "Users" tab
   - Click "Add user" button

3. **Fill Admin Credentials**
   ```
   Email: admin@company.com
   Password: admin123
   ```
   - Click "Add user"
   - ✅ User appears in list
   - **COPY THE UID** (e.g., `hG7kL2mN9pQ1rS3tU5vW7xY9z`)

#### **B. Create Firestore User Document**

4. **Navigate to Firestore Database**
   - Left sidebar → Click "Firestore Database"
   - Click "users" collection (or create it if doesn't exist)

5. **Add Document**
   - Click "Add document"
   - **Document ID:** Paste the UID you copied
   - Click "Add field" for each field below:

   | Field Name | Type | Value |
   |-----------|------|-------|
   | `uid` | string | `hG7kL2mN9pQ1rS3tU5vW7xY9z` (paste UID) |
   | `email` | string | `admin@company.com` |
   | `name` | string | `Admin User` |
   | `role` | string | `admin` |
   | `status` | string | `approved` |
   | `createdAt` | timestamp | Click clock icon → Now |
   | `updatedAt` | timestamp | Click clock icon → Now |

6. **Save Document**
   - Click "Save"
   - ✅ Document appears in users collection

#### **C. Verify & Test**

7. **Verify in Firestore**
   ```
   Collection: users
   Document ID: hG7kL2mN9pQ1rS3tU5vW7xY9z
   Fields:
     ✓ uid: matches Auth UID
     ✓ role: "admin" (lowercase)
     ✓ status: "approved" (lowercase)
   ```

8. **Test Login**
   - Run web dashboard
   - Login with: admin@company.com / admin123
   - ✅ Should access admin dashboard

---

## 🎯 PART 2: Creating Supervisor Account (Admin Dashboard)

### How It Works:
Admin uses the web dashboard to create supervisor accounts. This creates BOTH Firebase Auth AND Firestore document automatically.

### Step-by-Step in Web Dashboard:

#### **A. Navigate to Employee Management**

1. **Login to Admin Dashboard**
   - Email: admin@company.com
   - Password: admin123

2. **Go to Employees Section**
   - Click "Employees" in left sidebar
   - OR Click "Manage Employees" on dashboard

3. **Click "Add Employee" Button**
   - Top right corner: "+ Add Employee" button
   - Form opens (modal or new page)

#### **B. Fill Supervisor Form**

4. **Supervisor Information Form**

   ```
   ┌────────────────────────────────────────┐
   │  Add New Employee / Supervisor         │
   ├────────────────────────────────────────┤
   │                                        │
   │  Name: *                               │
   │  [John Supervisor              ]       │
   │                                        │
   │  Email: *                              │
   │  [supervisor1@company.com      ]       │
   │                                        │
   │  Password: *                           │
   │  [super123                     ]       │
   │                                        │
   │  Phone:                                │
   │  [+1234567890                  ]       │
   │                                        │
   │  Role: *                               │
   │  [▼ Supervisor  ]  ◄── SELECT THIS    │
   │     └─ Employee                        │
   │     └─ Supervisor ✓                   │
   │     └─ Admin                           │
   │                                        │
   │  Assign Project: *                     │
   │  [▼ Construction Site A ]              │
   │     └─ Construction Site A ✓           │
   │     └─ Renovation Project B           │
   │                                        │
   │  Status:                               │
   │  [▼ Approved  ]  ◄── AUTO-SET         │
   │     └─ Pending                         │
   │     └─ Approved ✓                     │
   │                                        │
   │  [Cancel]              [Add Employee]  │
   └────────────────────────────────────────┘
   ```

5. **Field Details:**

   | Field | Value | Notes |
   |-------|-------|-------|
   | **Name** | John Supervisor | Full name |
   | **Email** | supervisor1@company.com | Must be unique |
   | **Password** | super123 | Min 6 characters |
   | **Phone** | +1234567890 | Optional |
   | **Role** | Supervisor | IMPORTANT: Select "Supervisor" |
   | **Assign Project** | Construction Site A | Must have project first |
   | **Status** | Approved | Auto-set for supervisor |

6. **Click "Add Employee" Button**

#### **C. What Happens Behind the Scenes**

```
When you click "Add Employee":

1. Firebase Auth Account Created
   └─> Email: supervisor1@company.com
   └─> Password: super123
   └─> Returns UID: aB1cD2eF3gH4iJ5k

2. Firestore Document Created
   └─> Collection: users
   └─> Document ID: aB1cD2eF3gH4iJ5k
   └─> Fields:
       {
         uid: "aB1cD2eF3gH4iJ5k",
         email: "supervisor1@company.com",
         name: "John Supervisor",
         phone: "+1234567890",
         role: "supervisor",          ◄── KEY FIELD
         projectId: "xyz123abc456",   ◄── LINKS TO PROJECT
         status: "approved",
         createdAt: Timestamp,
         updatedAt: Timestamp
       }

3. Success Message Shown
   └─> "Supervisor added successfully!"
   └─> Returns to employee list

4. Supervisor Appears in List
   └─> Name: John Supervisor
   └─> Email: supervisor1@company.com
   └─> Role: Supervisor
   └─> Project: Construction Site A
   └─> Status: Approved
```

#### **D. Verify Supervisor Creation**

7. **Check in Web Dashboard**
   - Go to "Employees" page
   - Find "John Supervisor" in list
   - Verify:
     - ✅ Role: Supervisor
     - ✅ Status: Approved
     - ✅ Project: Construction Site A

8. **Check in Firebase Console** (Optional)
   - Authentication → Users tab
   - ✅ See: supervisor1@company.com
   - Firestore → users collection
   - ✅ See document with role: "supervisor"

---

## 🎯 PART 3: Creating Employee Account (Supervisor Mobile App)

### How It Works:
Supervisor uses mobile app to create employee accounts. This creates ONLY Firestore document (no Firebase Auth yet). Employee gets auto-generated ID and PIN.

### Step-by-Step in Mobile App:

#### **A. Supervisor Logs In**

1. **Open Mobile App**
   - Launch app on device/emulator

2. **Select Login**
   - Tap "Login" button on welcome screen

3. **Choose Login Method**
   ```
   ┌─────────────────────────────┐
   │    Login                    │
   ├─────────────────────────────┤
   │                             │
   │  [ Email/Password ]  ◄─ TAP │
   │                             │
   │  [ Employee ID/PIN ]        │
   │                             │
   └─────────────────────────────┘
   ```

4. **Enter Supervisor Credentials**
   ```
   Email: supervisor1@company.com
   Password: super123
   ```

5. **Tap "Login"**
   - App checks Firestore
   - Finds role: "supervisor"
   - ✅ Opens Supervisor Dashboard

#### **B. Navigate to Add Employee**

6. **Supervisor Dashboard**
   ```
   ┌─────────────────────────────────────┐
   │  Supervisor Dashboard               │
   ├─────────────────────────────────────┤
   │                                     │
   │  📊 Project: Construction Site A    │
   │                                     │
   │  ┌─────────────┐  ┌─────────────┐ │
   │  │ My Team     │  │ Attendance  │ │
   │  │ 0 Employees │  │ View        │ │
   │  └─────────────┘  └─────────────┘ │
   │                                     │
   │  ┌─────────────────────────────┐   │
   │  │  + Add Employee             │◄─ TAP
   │  └─────────────────────────────┘   │
   │                                     │
   │  📋 Recent Activity                 │
   │  └─ No employees yet                │
   │                                     │
   └─────────────────────────────────────┘
   ```

7. **Tap "+ Add Employee"**
   - Form screen opens

#### **C. Fill Employee Form**

8. **Employee Information Form**
   ```
   ┌─────────────────────────────────────┐
   │  ← Add New Employee                 │
   ├─────────────────────────────────────┤
   │                                     │
   │  Full Name: *                       │
   │  [Alice Worker               ]      │
   │                                     │
   │  Email: *                           │
   │  [alice@company.com          ]      │
   │                                     │
   │  Phone:                             │
   │  [+1234567891               ]      │
   │                                     │
   │  Position:                          │
   │  [Construction Worker        ]      │
   │                                     │
   │  Department:                        │
   │  [Construction               ]      │
   │                                     │
   │  Hire Date:                         │
   │  [2025-11-13                ]      │
   │                                     │
   │                                     │
   │  [Cancel]          [Add Employee]   │
   └─────────────────────────────────────┘
   ```

9. **Field Details:**

   | Field | Value | Notes |
   |-------|-------|-------|
   | **Name** | Alice Worker | Full name |
   | **Email** | alice@company.com | For future notifications |
   | **Phone** | +1234567891 | Optional |
   | **Position** | Construction Worker | Job title |
   | **Department** | Construction | Optional |
   | **Hire Date** | 2025-11-13 | Auto-filled to today |

   **NOTE:** No password field! Employee doesn't use email/password.

10. **Tap "Add Employee" Button**

#### **D. What Happens Behind the Scenes**

```
When you tap "Add Employee":

1. System Queries Existing Employees
   └─> Count employees in projectId: "xyz123abc456"
   └─> Result: 0 employees found
   └─> Next ID: 0001

2. Generate Employee ID
   └─> Format: 4 digits, zero-padded
   └─> First employee: 0001
   └─> Second employee: 0002
   └─> etc.

3. Generate PIN
   └─> Format: 4 digits, random
   └─> Example: 1234
   └─> OR sequential: 1000, 1001, 1002...

4. Create Firestore Document
   └─> Collection: users
   └─> Document ID: [auto-generated UID]
   └─> Fields:
       {
         uid: "newUid789xyz",
         employeeId: "0001",           ◄── AUTO-GENERATED
         pin: "1234",                  ◄── AUTO-GENERATED
         name: "Alice Worker",
         email: "alice@company.com",
         phone: "+1234567891",
         position: "Construction Worker",
         department: "Construction",
         role: "employee",             ◄── AUTO-SET
         projectId: "xyz123abc456",    ◄── SUPERVISOR'S PROJECT
         supervisorId: "aB1cD2eF3gH4iJ5k", ◄── SUPERVISOR UID
         status: "pending",            ◄── NEEDS APPROVAL
         deviceInfo: null,             ◄── Set on first login
         createdAt: Timestamp,
         updatedAt: Timestamp
       }

5. Show Success Dialog
   └─> Display employee credentials
```

#### **E. Success Confirmation**

11. **Employee Added Dialog**
    ```
    ┌─────────────────────────────────────┐
    │  ✅ Employee Added Successfully     │
    ├─────────────────────────────────────┤
    │                                     │
    │  Employee Details:                  │
    │                                     │
    │  Name: Alice Worker                 │
    │                                     │
    │  ┌─────────────────────────────┐   │
    │  │  Employee ID: 0001          │   │
    │  │  PIN: 1234                  │   │
    │  └─────────────────────────────┘   │
    │                                     │
    │  Status: Pending Approval           │
    │                                     │
    │  📝 Important:                      │
    │  1. Share ID and PIN with employee  │
    │  2. Wait for admin approval         │
    │  3. Employee can login after        │
    │     approval                        │
    │                                     │
    │  [ Copy Credentials ]  [ OK ]       │
    └─────────────────────────────────────┘
    ```

12. **What to Do Next:**
    - **Write down** or **screenshot** the ID and PIN
    - Share with the employee
    - Wait for admin approval
    - Employee can login once approved

#### **F. Verify Employee Creation**

13. **Check in Mobile App**
    - Go to "Employee List" or "My Team"
    - Find "Alice Worker"
    - Verify:
      - ✅ ID: 0001
      - ✅ Status: Pending Approval
      - ✅ Project: Construction Site A

14. **Check in Firebase Console** (Optional)
    - Firestore → users collection
    - Find document with employeeId: "0001"
    - Verify fields:
      - ✅ role: "employee"
      - ✅ projectId: matches supervisor's project
      - ✅ status: "pending"

---

## 🔗 PART 4: How Everything Links Together

### Database Relationships:

```
FIRESTORE STRUCTURE:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

projects/
├─ xyz123abc456/                    ← PROJECT DOCUMENT
   ├─ name: "Construction Site A"
   ├─ location: "Downtown"
   ├─ supervisorId: "aB1cD2eF3gH4iJ5k"  ← LINKS TO SUPERVISOR
   └─ status: "active"

users/
├─ hG7kL2mN9pQ1rS3tU5vW7xY9z/      ← ADMIN DOCUMENT
│  ├─ role: "admin"
│  ├─ email: "admin@company.com"
│  └─ ...
│
├─ aB1cD2eF3gH4iJ5k/               ← SUPERVISOR DOCUMENT
│  ├─ role: "supervisor"
│  ├─ email: "supervisor1@company.com"
│  ├─ projectId: "xyz123abc456"     ← LINKS TO PROJECT
│  └─ ...
│
└─ newUid789xyz/                    ← EMPLOYEE DOCUMENT
   ├─ role: "employee"
   ├─ employeeId: "0001"
   ├─ pin: "1234"
   ├─ projectId: "xyz123abc456"     ← LINKS TO PROJECT
   ├─ supervisorId: "aB1cD2eF3gH4iJ5k" ← LINKS TO SUPERVISOR
   ├─ status: "pending"
   └─ ...

attendance/
└─ attendance123/                   ← ATTENDANCE RECORD
   ├─ userId: "newUid789xyz"        ← LINKS TO EMPLOYEE
   ├─ projectId: "xyz123abc456"     ← LINKS TO PROJECT
   ├─ checkInTime: Timestamp
   └─ ...
```

### Visual Flow Diagram:

```
ADMIN creates PROJECT
    │
    ├─> projectId: xyz123abc456
    │   name: "Construction Site A"
    │
    ▼
ADMIN creates SUPERVISOR
    │
    ├─> uid: aB1cD2eF3gH4iJ5k
    │   role: "supervisor"
    │   projectId: xyz123abc456  ◄───┐
    │                                │ LINKED
    ▼                                │
SUPERVISOR adds EMPLOYEE              │
    │                                │
    ├─> uid: newUid789xyz            │
    │   role: "employee"             │
    │   employeeId: "0001"           │
    │   projectId: xyz123abc456  ◄───┘ SAME PROJECT
    │   supervisorId: aB1cD2eF3gH4iJ5k
    │   status: "pending"
    │
    ▼
ADMIN approves EMPLOYEE
    │
    └─> status: "pending" → "approved"
    
    ▼
EMPLOYEE logs in
    │
    └─> Queries Firestore for:
        employeeId == "0001"
        pin == "1234"
        role == "employee"
        
    ▼
EMPLOYEE checks in
    │
    └─> Creates attendance record:
        userId: newUid789xyz
        projectId: xyz123abc456  ◄─── SAME PROJECT
```

---

## 🎯 PART 5: Complete Linking Workflow

### Scenario: Full System Setup

#### **1. Admin Creates Project**
```
Web Dashboard → Projects → Add Project
└─> Creates: projects/xyz123abc456
    Name: "Construction Site A"
    ✅ Project ID: xyz123abc456
```

#### **2. Admin Creates Supervisor**
```
Web Dashboard → Employees → Add Employee
└─> Role: Supervisor
└─> Assign Project: Construction Site A  ◄─── LINKING HAPPENS
└─> Creates: users/aB1cD2eF3gH4iJ5k
    {
      role: "supervisor",
      projectId: "xyz123abc456"  ◄─── LINK TO PROJECT
    }
```

**HOW LINKING WORKS:**
- Admin selects project from dropdown
- System saves projectId in supervisor document
- Supervisor is now "assigned" to project

#### **3. Supervisor Logs In**
```
Mobile App → Login → Email/Password
└─> System reads: users/aB1cD2eF3gH4iJ5k
└─> Finds: projectId: "xyz123abc456"
└─> Loads project: projects/xyz123abc456
└─> Shows: "Project: Construction Site A"
```

**HOW LINKING SHOWS:**
- App reads supervisor's projectId
- Fetches project details from projects collection
- Displays project name in dashboard

#### **4. Supervisor Adds Employee**
```
Mobile App → Add Employee → Fill Form
└─> System reads supervisor's projectId: "xyz123abc456"
└─> Auto-assigns same project to employee
└─> Creates: users/newUid789xyz
    {
      role: "employee",
      projectId: "xyz123abc456",  ◄─── INHERITED FROM SUPERVISOR
      supervisorId: "aB1cD2eF3gH4iJ5k"  ◄─── LINK TO SUPERVISOR
    }
```

**HOW LINKING WORKS:**
- System gets supervisor's projectId
- Automatically assigns to new employee
- No need for employee to select project

#### **5. Admin Sees Employee**
```
Web Dashboard → Employees → Pending Approvals
└─> Queries: users where status == "pending"
└─> Finds: users/newUid789xyz
└─> Displays:
    Name: Alice Worker
    Project: Construction Site A  ◄─── READS FROM projectId
    Added By: John Supervisor     ◄─── READS FROM supervisorId
```

**HOW LINKING SHOWS:**
- Dashboard reads employee's projectId
- Looks up project name from projects collection
- Displays related information

#### **6. Admin Approves Employee**
```
Web Dashboard → Click "Approve" button
└─> Updates: users/newUid789xyz
    status: "pending" → "approved"
```

#### **7. Employee Logs In**
```
Mobile App → Login → ID/PIN
└─> Queries: users where employeeId == "0001"
└─> Finds: users/newUid789xyz
└─> Reads: projectId: "xyz123abc456"
└─> Loads: projects/xyz123abc456
└─> Shows: "Project: Construction Site A"
```

**HOW LINKING SHOWS:**
- App reads employee's projectId
- Fetches project details
- Displays in dashboard

#### **8. Employee Checks In**
```
Mobile App → Check In button
└─> Creates: attendance/attendance123
    {
      userId: "newUid789xyz",      ◄─── EMPLOYEE UID
      projectId: "xyz123abc456",   ◄─── FROM EMPLOYEE DOCUMENT
      checkInTime: Timestamp
    }
```

**HOW LINKING WORKS:**
- Reads employee's projectId
- Saves in attendance record
- Links attendance to both employee and project

#### **9. Supervisor Views Attendance**
```
Mobile App → Attendance → View Team
└─> Queries: attendance where projectId == "xyz123abc456"
└─> Finds: attendance/attendance123
└─> Joins with: users/newUid789xyz
└─> Displays:
    Employee: Alice Worker
    Check-in: 9:00 AM
    Project: Construction Site A
```

**HOW LINKING SHOWS:**
- Queries attendance by supervisor's projectId
- Gets all attendance for same project
- Joins with user data to show names

#### **10. Admin Exports Report**
```
Web Dashboard → Reports → Project Report
└─> Select: Construction Site A
└─> Queries: attendance where projectId == "xyz123abc456"
└─> Finds all attendance records
└─> Joins with: users collection
└─> Generates: PDF with employee names and hours
```

**HOW LINKING SHOWS:**
- Filters by projectId
- Gets all related attendance
- Joins with user data
- Creates comprehensive report

---

## 📊 Summary Table: Account Creation

| Step | Who | Where | Action | Creates Auth? | Creates Firestore? | Status |
|------|-----|-------|--------|---------------|-------------------|--------|
| 1 | You | Firebase Console | Create admin | ✅ Yes | ✅ Yes (manual) | approved |
| 2 | Admin | Web Dashboard | Create supervisor | ✅ Yes | ✅ Yes | approved |
| 3 | Supervisor | Mobile App | Add employee | ❌ No | ✅ Yes | pending |
| 4 | Admin | Web Dashboard | Approve employee | ❌ No | Updates only | approved |

---

## 🔑 Key Takeaways

### **Supervisor Creation:**
- ✅ Created by admin in web dashboard
- ✅ Has Firebase Auth account (email/password)
- ✅ Has Firestore document with role: "supervisor"
- ✅ Linked to project via projectId field
- ✅ Status is "approved" immediately

### **Employee Creation:**
- ✅ Created by supervisor in mobile app
- ❌ No Firebase Auth account initially
- ✅ Has Firestore document with role: "employee"
- ✅ Auto-generated employeeId and PIN
- ✅ Linked to project via projectId (inherited from supervisor)
- ✅ Linked to supervisor via supervisorId
- ⏳ Status is "pending" until admin approves

### **Linking Mechanism:**
- 📌 **projectId** field links everyone to a project
- 📌 **supervisorId** field links employees to supervisor
- 📌 **userId** field in attendance links to employee
- 📌 All queries filter by these IDs to show related data

---

## 🎯 Next Steps

1. **Test Account Creation:**
   - Follow Part 1: Create admin
   - Follow Part 2: Create supervisor
   - Follow Part 3: Create employee

2. **Verify Linking:**
   - Check Firestore: See matching projectId values
   - Check Dashboards: See project names displayed correctly
   - Test Attendance: Verify it shows in all related views

3. **Test Full Flow:**
   - Use checklist in `QUICK_START_CHECKLIST.md`
   - Follow workflow in `COMPLETE_WORKFLOW_GUIDE.md`

---

**Need more details?** Check the other guides:
- `COMPLETE_WORKFLOW_GUIDE.md` - Full system workflow
- `QUICK_START_CHECKLIST.md` - Step-by-step checklist
- `SYSTEM_FLOW_DIAGRAM.md` - Visual diagrams

