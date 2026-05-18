# 📊 Complete Testing Flow Diagram

**Visual guide for testing all functionalities**

---

## 🎯 Complete User Journey Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    PHASE 1: SETUP                                │
│                    (Super Admin + Admin)                        │
└─────────────────────────────────────────────────────────────────┘

┌──────────────┐
│ Super Admin │
│   (Web)     │
└──────┬───────┘
       │
       │ 1. Login
       │    Email: superadmin@test.com
       │    Password: SuperAdmin123!
       │
       ▼
┌─────────────────────────────────────┐
│ Super Admin Dashboard               │
│ ├─ View Companies                   │
│ ├─ View Statistics                  │
│ └─ Create Company                   │
└──────┬──────────────────────────────┘
       │
       │ 2. Create Company
       │    Name: "Test Construction Co."
       │    Code: "TCC"
       │    Contact: admin@testco.com
       │
       ▼
┌─────────────────────────────────────┐
│ Company Created                     │
│ ✅ Company Admin Auto-Created       │
│    Email: admin@testco.com          │
│    Password: [auto-generated]       │
└──────┬──────────────────────────────┘
       │
       │ 3. Login as Admin
       │    Company Code: TCC
       │    Email: admin@testco.com
       │    Password: [from above]
       │
       ▼
┌─────────────────────────────────────┐
│ Admin Dashboard (Web)               │
│ ├─ Manage Projects                  │
│ ├─ Manage Employees                 │
│ ├─ Manage Documents                 │
│ └─ View Reports                     │
└──────┬──────────────────────────────┘
       │
       │ 4. Create Supervisor
       │    Name: "Supervisor Smith"
       │    Email: supervisor@testco.com
       │    Password: Supervisor123!
       │
       ▼
┌─────────────────────────────────────┐
│ Supervisor Created                  │
│ ✅ Status: Active                   │
└──────┬──────────────────────────────┘
       │
       │ 5. Create Project
       │    Name: "Construction Site A"
       │    Location: [address + GPS]
       │    Supervisor: Supervisor Smith
       │    Methods:
       │      ☑ GPS
       │      ☑ NFC → Tag ID: 04:AA:BB:CC
       │      ☑ QR → Generate QR Code
       │      ☑ Manual
       │
       ▼
┌─────────────────────────────────────┐
│ Project Created                     │
│ ✅ NFC Tag ID: 04:AA:BB:CC          │
│ ✅ QR Code Generated                │
│ ✅ Supervisor Assigned              │
└──────┬──────────────────────────────┘
       │
       │ 6. Create Employee
       │    Name: "John Employee"
       │    Email: employee@testco.com
       │    Employee ID: TCC-0001
       │    PIN: 1234 (save this!)
       │    Supervisor: Supervisor Smith
       │    Projects: Construction Site A
       │
       ▼
┌─────────────────────────────────────┐
│ Employee Created                    │
│ ✅ Status: Pending                  │
│ ✅ Employee ID: TCC-0001            │
│ ✅ PIN: 1234                        │
└──────┬──────────────────────────────┘
       │
       │ 7. Approve Employee
       │
       ▼
┌─────────────────────────────────────┐
│ Employee Approved                   │
│ ✅ Status: Active                   │
│ ✅ Can now log in                   │
└─────────────────────────────────────┘
```

---

```
┌─────────────────────────────────────────────────────────────────┐
│                    PHASE 2: SUPERVISOR ACTIONS                  │
│                         (Mobile App)                            │
└─────────────────────────────────────────────────────────────────┘

┌──────────────┐
│ Supervisor   │
│  (Mobile)    │
└──────┬───────┘
       │
       │ 1. Login
       │    Company Code: TCC
       │    Email: supervisor@testco.com
       │    Password: Supervisor123!
       │
       ▼
┌─────────────────────────────────────┐
│ Supervisor Dashboard               │
│ ├─ Assigned Project: Site A        │
│ ├─ Add Employee                     │
│ ├─ My Employees                     │
│ ├─ Upload Document                  │
│ ├─ Manual Check-In                  │
│ └─ Device Reset Approvals           │
└──────┬──────────────────────────────┘
       │
       │ 2. View Assigned Project
       │
       ▼
┌─────────────────────────────────────┐
│ Project Details                    │
│ ✅ Construction Site A              │
│ ✅ Location: 456 Construction Ave   │
│ ✅ Status: Active                   │
└──────┬──────────────────────────────┘
       │
       │ 3. Upload Document (Optional)
       │    Employee: John Employee
       │    Type: ID Proof
       │    File: [select file]
       │
       ▼
┌─────────────────────────────────────┐
│ Document Uploaded                  │
│ ✅ Status: Pending                  │
│ ✅ Waiting for Admin Approval       │
└─────────────────────────────────────┘
```

---

```
┌─────────────────────────────────────────────────────────────────┐
│                    PHASE 3: EMPLOYEE CHECK-IN                   │
│                         (Mobile App)                            │
└─────────────────────────────────────────────────────────────────┘

┌──────────────┐
│ Employee     │
│  (Mobile)    │
└──────┬───────┘
       │
       │ 1. Login
       │    Company Code: TCC
       │    Employee ID: TCC-0001
       │    PIN: 1234
       │
       ▼
┌─────────────────────────────────────┐
│ Employee Dashboard                 │
│ ├─ Welcome: John Employee           │
│ ├─ Status: Not Checked In          │
│ ├─ Assigned Projects: Site A       │
│ └─ Quick Actions                    │
└──────┬──────────────────────────────┘
       │
       │ 2. Tap "Check In"
       │
       ▼
┌─────────────────────────────────────┐
│ Check-In Screen                    │
│ ├─ Select Project: Site A          │
│ └─ Check-In Methods:               │
│      📍 GPS Check-in                │
│      📱 NFC Check-in                │
│      📷 QR Check-in                 │
│      ✏️ Manual Check-in             │
└──────┬──────────────────────────────┘
       │
       ├─ Option A: GPS Check-In ────────┐
       │                                  │
       │  3a. Tap "GPS Check-in"         │
       │  4a. Grant location permission  │
       │  5a. System validates location  │
       │  6a. ✅ Check-in successful     │
       │                                  │
       ├─ Option B: NFC Check-In ────────┤
       │                                  │
       │  3b. Tap "NFC Check-in"        │
       │  4b. Hold phone near NFC tag    │
       │  5b. System reads tag ID        │
       │  6b. Validate: Tag = 04:AA:BB:CC│
       │  7b. ✅ Check-in successful    │
       │                                  │
       ├─ Option C: QR Check-In ─────────┤
       │                                  │
       │  3c. Tap "QR Check-in"         │
       │  4c. QR Scanner opens           │
       │  5c. Scan QR code               │
       │  6c. System validates QR        │
       │  7c. ✅ Check-in successful    │
       │                                  │
       └──────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│ Check-In Successful                 │
│ ✅ Status: Checked In               │
│ ✅ Project: Construction Site A     │
│ ✅ Method: [GPS/NFC/QR]             │
│ ✅ Time: [timestamp]                 │
└─────────────────────────────────────┘
```

---

```
┌─────────────────────────────────────────────────────────────────┐
│                    PHASE 4: EMPLOYEE CHECK-OUT                  │
│                         (Mobile App)                            │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────┐
│ Employee Dashboard                 │
│ ✅ Status: Checked In               │
│ ✅ Project: Construction Site A     │
│ └─ [Check Out Button]               │
└──────┬──────────────────────────────┘
       │
       │ 1. Tap "Check Out"
       │
       ▼
┌─────────────────────────────────────┐
│ Method Selection Dialog             │
│ ├─ 📍 GPS Location                  │
│ ├─ 📱 NFC Tag                       │
│ ├─ 📷 QR Code                       │
│ └─ ✏️ Manual                        │
└──────┬──────────────────────────────┘
       │
       ├─ Option A: NFC Check-Out ───────┐
       │                                  │
       │  2a. Select "NFC Tag"           │
       │  3a. Hold phone near NFC tag    │
       │  4a. System reads tag ID        │
       │  5a. Validate: Tag = 04:AA:BB:CC │
       │  6a. ✅ Check-out successful     │
       │                                  │
       ├─ Option B: QR Check-Out ─────────┤
       │                                  │
       │  2b. Select "QR Code"          │
       │  3b. QR Scanner opens           │
       │  4b. Scan QR code               │
       │  5b. System validates QR        │
       │  6b. ✅ Check-out successful    │
       │                                  │
       └──────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│ Check-Out Successful                │
│ ✅ Status: Checked Out              │
│ ✅ Working Hours: [calculated]      │
│ ✅ Method: [NFC/QR]                 │
│ ✅ Check-out Time: [timestamp]       │
└─────────────────────────────────────┘
```

---

## 🔒 Validation Flow Diagrams

### NFC Validation Flow:

```
Employee Taps NFC Check-In
         │
         ▼
    Read NFC Tag
         │
         ▼
    Extract Tag ID
         │
         ▼
    ┌─────────────────┐
    │ Project.nfcTagId│
    │   is set?       │
    └────┬────────────┘
         │
    ┌────┴────┐
    │         │
   NO        YES
    │         │
    │         ▼
    │    Tag ID matches?
    │         │
    │    ┌────┴────┐
    │    │         │
    │   YES       NO
    │    │         │
    │    │         ▼
    │    │    ❌ FAIL
    │    │    Error: "NFC tag does not match"
    │    │
    ▼    ▼
✅ SUCCESS
Check-in recorded
```

### QR Validation Flow:

```
Employee Taps QR Check-In
         │
         ▼
    Open QR Scanner
         │
         ▼
    Scan QR Code
         │
         ▼
    ┌─────────────────┐
    │ Project.qrCode  │
    │   is set?       │
    └────┬────────────┘
         │
    ┌────┴────┐
    │         │
   NO        YES
    │         │
    │         ▼
    │    QR Code matches?
    │         │
    │    ┌────┴────┐
    │    │         │
    │   YES       NO
    │    │         │
    │    │         ▼
    │    │    ❌ FAIL
    │    │    Error: "QR code does not match"
    │    │
    ▼    ▼
✅ SUCCESS
Check-in recorded
```

---

## 📱 Screen-by-Screen Flow

### Web Admin Screens:

```
Super Admin Login
    ↓
Super Admin Dashboard
    ├─ Create Company
    └─ View Companies
        ↓
    Company Details
        └─ View Stats

Admin Login
    ↓
Admin Dashboard
    ├─ Manage Projects
    │   ├─ Add Project
    │   │   ├─ Basic Info
    │   │   ├─ Location
    │   │   ├─ NFC Config (Tag ID)
    │   │   └─ QR Config (Generate)
    │   └─ Edit Project
    ├─ Manage Employees
    │   ├─ Create Supervisor
    │   ├─ Create Employee
    │   └─ Approve Employee
    ├─ Manage Documents
    ├─ View Reports
    └─ Device Reset Requests
```

### Mobile Supervisor Screens:

```
Role Selection
    ↓
Supervisor Login
    ↓
Supervisor Dashboard
    ├─ Assigned Project
    ├─ Add Employee
    ├─ My Employees
    ├─ Upload Document
    ├─ Manual Check-In
    └─ Device Reset Approvals
```

### Mobile Employee Screens:

```
Role Selection
    ↓
Employee Login
    ├─ Enter Company Code
    ├─ Enter Employee ID
    └─ Enter PIN
    ↓
Employee Dashboard
    ├─ Today's Status
    ├─ Quick Actions
    │   ├─ Check In
    │   ├─ Attendance
    │   └─ Device Reset
    └─ Assigned Projects
        ↓
    Check-In Screen
        ├─ Select Project
        └─ Select Method
            ├─ GPS Check-In
            ├─ NFC Check-In
            │   └─ NFC Scanner
            ├─ QR Check-In
            │   └─ QR Scanner
            └─ Manual Check-In
        ↓
    Check-Out Flow
        ├─ Method Selection
        └─ Validation
            ├─ NFC Validation
            └─ QR Validation
```

---

## 🎯 Testing Priority

### Must Test (Critical):
1. ✅ **NFC Check-In** - Tag validation works
2. ✅ **NFC Check-Out** - Tag validation works
3. ✅ **QR Check-In** - Code validation works
4. ✅ **QR Check-Out** - Code validation works
5. ✅ **NFC Validation** - Wrong tag rejected
6. ✅ **QR Validation** - Wrong code rejected

### Should Test (Important):
7. ✅ GPS Check-In
8. ✅ Employee Approval Flow
9. ✅ Project Assignment
10. ✅ Document Upload

### Nice to Test (Optional):
11. ✅ Manual Check-In
12. ✅ Device Reset
13. ✅ Reports

---

## 📝 Test Data Checklist

Before testing, ensure you have:

- [ ] Super Admin credentials
- [ ] Company Code (e.g., "TCC")
- [ ] Admin email & password
- [ ] Supervisor email & password
- [ ] Employee ID & PIN
- [ ] NFC Tag (physical tag or phone)
- [ ] NFC Tag ID (if configuring specific tag)
- [ ] QR Code (generated from admin dashboard)
- [ ] Project GPS coordinates
- [ ] Test location (for GPS testing)

---

**Follow the complete testing guide for detailed step-by-step instructions!**
