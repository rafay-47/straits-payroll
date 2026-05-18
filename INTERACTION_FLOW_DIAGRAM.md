# 🔄 Complete System Interaction Flow Diagram

## Visual representation of how Admin, Supervisor, and Employee interact with the system

---

## 📊 System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     FIREBASE BACKEND                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐       │
│  │   Auth   │  │Firestore │  │ Storage  │  │  Rules   │       │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘       │
└─────────────────────────────────────────────────────────────────┘
                           ▲
                           │
                           │ (API Calls)
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
        │                  │                  │
┌───────▼────────┐  ┌─────▼──────┐  ┌───────▼────────┐
│  WEB DASHBOARD │  │ SUPERVISOR │  │  EMPLOYEE APP  │
│     (Admin)    │  │    MOBILE  │  │     MOBILE     │
│   [Browser]    │  │   [Phone]  │  │    [Phone]     │
└────────────────┘  └────────────┘  └────────────────┘
```

---

## 🎭 User Roles & Responsibilities

```
┌────────────────────────────────────────────────────────────────┐
│                        ADMIN (WEB)                              │
│  Creates & Manages:                                            │
│   ├─ Supervisor Accounts (Email + Password)                   │
│   ├─ Projects                                                  │
│   ├─ System Settings                                           │
│   ├─ Reports & Analytics                                       │
│   └─ Device Reset Approval (Optional)                         │
└────────────────────────────────────────────────────────────────┘
                             │
                             │ Assigns Projects
                             ▼
┌────────────────────────────────────────────────────────────────┐
│                    SUPERVISOR (MOBILE)                          │
│  Creates & Manages:                                            │
│   ├─ Employee Accounts (System/Custom ID)                     │
│   ├─ Employee Documents                                        │
│   ├─ Manual Check-in/out                                       │
│   ├─ Device Reset Approval                                     │
│   └─ Employee List & Details                                   │
└────────────────────────────────────────────────────────────────┘
                             │
                             │ Creates & Manages
                             ▼
┌────────────────────────────────────────────────────────────────┐
│                     EMPLOYEE (MOBILE)                           │
│  Can:                                                          │
│   ├─ Login (System ID / Custom ID)                            │
│   ├─ Check-in / Check-out                                      │
│   ├─ View Assigned Projects                                    │
│   ├─ View Attendance History                                   │
│   └─ Request Device Reset                                      │
└────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Complete Workflow Flow

### 1️⃣ Initial Setup Flow

```
┌──────────────────────────────────────────────────────────────────┐
│ STEP 1: Admin Setup                                             │
└──────────────────────────────────────────────────────────────────┘

    🌐 Admin Opens Web Dashboard
         │
         ├─→ 🔑 Login with admin@company.com
         │
         ├─→ 📋 Create Project
         │    ├─ Name: "Construction Site A"
         │    ├─ Location: GPS coordinates
         │    ├─ Check-in: GPS + NFC + QR
         │    └─ Status: Active
         │
         └─→ 👤 Create Supervisor Account
              ├─ Name: "John Manager"
              ├─ Email: john@company.com
              ├─ Password: [set password]
              ├─ Role: supervisor
              └─ Assign Project: "Construction Site A"

                     ✅ SUPERVISOR ACCOUNT READY
                     
                            ⬇️

┌──────────────────────────────────────────────────────────────────┐
│ STEP 2: Supervisor Setup                                        │
└──────────────────────────────────────────────────────────────────┘

    📱 Supervisor Opens Mobile App
         │
         ├─→ 🔑 Login with email + password
         │
         ├─→ 👤 Add Employee #1
         │    ├─ Name: "Mike Worker"
         │    ├─ Email: mike@company.com
         │    ├─ Custom ID: EMP001
         │    ├─ System ID: 0001 (auto-generated)
         │    └─ Project: "Construction Site A"
         │
         ├─→ 📄 Upload Documents for Mike
         │    ├─ ID Card (photo)
         │    └─ Contract (file)
         │
         └─→ 👤 Add Employee #2
              ├─ Name: "Sarah Builder"
              ├─ System ID: 0002 (auto-generated)
              └─ Project: "Construction Site A"

                     ✅ EMPLOYEES READY TO WORK
                     
                            ⬇️

┌──────────────────────────────────────────────────────────────────┐
│ STEP 3: Employee Setup (First Login)                            │
└──────────────────────────────────────────────────────────────────┘

    📱 Employee Opens Mobile App
         │
         ├─→ 🔑 Login with ID
         │    ├─ Mike: Enters "EMP001" or "0001"
         │    └─ Sarah: Enters "0002"
         │
         └─→ 📱 Device Auto-Registered
              ├─ Device Model: iPhone 14
              ├─ OS: iOS 17.1
              └─ Device ID: [unique]

                     ✅ READY FOR DAILY WORK
```

---

### 2️⃣ Daily Work Flow

```
┌──────────────────────────────────────────────────────────────────┐
│ MORNING: Check-In                                                │
└──────────────────────────────────────────────────────────────────┘

    SCENARIO A: Employee with Smartphone (Mike)
    ────────────────────────────────────────────
    
    📱 Mike arrives at construction site (8:00 AM)
         │
         ├─→ Opens Employee App
         │
         ├─→ Tap "Check In" button
         │
         ├─→ 📍 GPS Check
         │    └─ ✅ Within project radius
         │
         ├─→ Select Project: "Construction Site A"
         │
         └─→ Confirm
              │
              └─→ ✅ CHECKED IN: 8:00 AM
                   ├─ Timestamp: 2025-11-16 08:00:00
                   ├─ Location: [GPS coords]
                   ├─ Method: GPS
                   └─ Device: Mike's iPhone
    
    
    SCENARIO B: Employee without Smartphone (Sarah)
    ────────────────────────────────────────────────
    
    📱 Supervisor's phone (John)
         │
         ├─→ Opens Supervisor App
         │
         ├─→ Tap "Manual Check-in"
         │
         ├─→ Select Employee: Sarah (0002)
         │
         ├─→ Select Project: "Construction Site A"
         │
         ├─→ Action: Check-in
         │
         └─→ Submit
              │
              └─→ ✅ CHECKED IN: 8:05 AM
                   ├─ Timestamp: 2025-11-16 08:05:00
                   ├─ Method: Manual
                   └─ By: Supervisor John


┌──────────────────────────────────────────────────────────────────┐
│ DURING WORK: Activities                                          │
└──────────────────────────────────────────────────────────────────┘

    📊 Admin (Web Dashboard)
         │
         └─→ Views Real-Time Attendance
              ├─ Mike: Checked In (8:00 AM)
              ├─ Sarah: Checked In (8:05 AM)
              └─ Total: 2 employees on site

    📱 Supervisor (Mobile)
         │
         ├─→ Views Employee List
         │    └─ All employees and their status
         │
         └─→ Uploads additional documents
              └─ Sarah's bank statement

    📱 Employee (Mobile)
         │
         └─→ Views Dashboard
              ├─ Status: Checked In
              ├─ Time: 4h 30m
              └─ Project: Construction Site A


┌──────────────────────────────────────────────────────────────────┐
│ EVENING: Check-Out                                               │
└──────────────────────────────────────────────────────────────────┘

    SCENARIO A: Mike (with smartphone)
    ───────────────────────────────────
    
    📱 Mike finishes work (5:00 PM)
         │
         ├─→ Opens Employee App
         │
         ├─→ Tap "Check Out" button
         │
         ├─→ Confirm
         │
         └─→ ✅ CHECKED OUT: 5:00 PM
              ├─ Timestamp: 2025-11-16 17:00:00
              ├─ Total Hours: 9h 0m
              └─ Status: Completed
    
    
    SCENARIO B: Sarah (without smartphone)
    ───────────────────────────────────────
    
    📱 Supervisor John's phone
         │
         ├─→ Opens Supervisor App
         │
         ├─→ Tap "Manual Check-in"
         │
         ├─→ Select Employee: Sarah
         │
         ├─→ Action: Check-out
         │
         └─→ Submit
              │
              └─→ ✅ CHECKED OUT: 5:10 PM
                   ├─ Total Hours: 9h 5m
                   └─ By: Supervisor John
```

---

### 3️⃣ Device Reset Flow

```
┌──────────────────────────────────────────────────────────────────┐
│ SCENARIO: Employee Lost Phone                                    │
└──────────────────────────────────────────────────────────────────┘

    📅 DAY 1: Phone Lost
    ─────────────────────
    
    😟 Mike loses his iPhone
         │
         └─→ ❌ Can't check-in
    
    📱 Supervisor John
         │
         └─→ Does manual check-in/out for Mike temporarily
    
    
    📅 DAY 2: Got New Phone
    ───────────────────────
    
    📱 Mike's New Phone
         │
         ├─→ Installs Employee App
         │
         ├─→ Try to login with "EMP001"
         │
         └─→ ❌ ERROR: "Device mismatch"
              │
              └─→ Option shown: "Request Device Reset"
    
    
    📱 Mike: Submit Device Reset Request
         │
         ├─→ Reason: "Device Lost"
         ├─→ Notes: "Lost phone, using new iPhone"
         │
         └─→ ✅ REQUEST SUBMITTED
              │
              └─→ Status: Pending
                       ⬇️
    
    📱 Supervisor John: Receives Notification
         │
         ├─→ Opens "Device Reset Approvals"
         │
         ├─→ Reviews Mike's request
         │    ├─ Employee: Mike Worker
         │    ├─ Old Device: iPhone 14
         │    ├─ Reason: Device Lost
         │    └─ Reset Count: 1/1 (this month)
         │
         └─→ Tap "Approve"
              │
              └─→ ✅ REQUEST APPROVED
                       ⬇️
    
    📱 Mike: Notification Received
         │
         ├─→ Opens Employee App
         │
         ├─→ Login with "EMP001"
         │
         └─→ ✅ LOGIN SUCCESSFUL
              ├─ Old device unbound
              ├─ New device registered
              └─ Can now check-in normally
```

---

## 🔄 Data Flow Diagram

```
┌────────────────────────────────────────────────────────────────┐
│                    DATA CREATION FLOW                           │
└────────────────────────────────────────────────────────────────┘

┌─────────────┐
│    ADMIN    │
└──────┬──────┘
       │
       ├─→ Creates Project ──────────┐
       │                             │
       ├─→ Creates Supervisor ───┐   │
       │                         │   │
       │                         ▼   ▼
       │                  ┌──────────────┐
       │                  │  FIRESTORE   │
       │                  │   /projects  │
       │                  │   /users     │
       │                  └──────────────┘
       │                         ▲   ▲
┌──────▼────────┐                │   │
│  SUPERVISOR   │                │   │
└──────┬────────┘                │   │
       │                         │   │
       ├─→ Creates Employee ─────┤   │
       │                         │   │
       ├─→ Uploads Documents ────┼───┘
       │                         │
       └─→ Manual Check-in ──────┘
                                 ▲
┌──────────────┐                 │
│   EMPLOYEE   │                 │
└──────┬───────┘                 │
       │                         │
       ├─→ Registers Device ─────┤
       │                         │
       ├─→ Check-in/out ─────────┤
       │                         │
       └─→ Device Reset Request ─┘
```

---

## 🔐 Authentication Flow

```
┌────────────────────────────────────────────────────────────────┐
│                   AUTHENTICATION METHODS                        │
└────────────────────────────────────────────────────────────────┘

┌─────────────┐
│    ADMIN    │───────────────────────────────────────┐
└─────────────┘                                       │
                                                      │
  Login Method:                                       │
  ├─ Email: admin@company.com                        │
  └─ Password: [set during setup]                    │
                                                      │
                                                      ▼
                                            ┌──────────────────┐
┌─────────────┐                             │  FIREBASE AUTH   │
│ SUPERVISOR  │────────────────────────────▶│                  │
└─────────────┘                             │  Email/Password  │
                                            └──────────────────┘
  Login Method:                                       ▲
  ├─ Email: supervisor@company.com                   │
  └─ Password: [set by admin]                        │
                                                      │
                                                      │
┌─────────────┐                                       │
│  EMPLOYEE   │───────────────────────────────────────┘
└─────────────┘
                                            (No Firebase Auth)
  Login Method:
  ├─ System ID: 0001, 0002, 0003...
  └─ Custom ID: EMP001, EMP002...
  
  Verification:
  ├─ Check Firestore for user document
  ├─ Validate device binding
  └─ Verify account status = "approved"
```

---

## 📊 Check-in Methods Comparison

```
┌────────────────────────────────────────────────────────────────┐
│              CHECK-IN METHODS FLOW COMPARISON                   │
└────────────────────────────────────────────────────────────────┘

METHOD 1: GPS Check-In
──────────────────────
Employee App → GPS Service → Validate Location → Firestore
                    │
                    ├─→ ✅ Within radius → Check-in allowed
                    └─→ ❌ Outside radius → Check-in denied


METHOD 2: NFC Check-In
──────────────────────
Employee App → NFC Scanner → Read Tag → Validate Tag ID → Firestore
                                  │
                                  ├─→ ✅ Valid tag → Check-in allowed
                                  └─→ ❌ Invalid tag → Check-in denied


METHOD 3: QR Code Check-In
──────────────────────────
Employee App → Camera → Scan QR → Decode Data → Validate → Firestore
                            │
                            ├─→ ✅ Valid code → Check-in allowed
                            └─→ ❌ Invalid code → Check-in denied


METHOD 4: Manual Check-In
─────────────────────────
Supervisor App → Select Employee → Select Project → Submit → Firestore
                                                        │
                                                        └─→ ✅ Always allowed
```

---

## 📱 Screen Navigation Flow

### Employee App Navigation

```
Login Screen
    │
    └─→ Employee Dashboard
         ├─→ Check-In Screen
         │    ├─→ GPS Check-in
         │    ├─→ NFC Check-in
         │    └─→ QR Check-in
         │
         ├─→ Device Reset Request Screen
         │    ├─→ Submit Request Form
         │    └─→ View Request History
         │
         └─→ Profile Screen (future)
```

### Supervisor App Navigation

```
Login Screen
    │
    └─→ Supervisor Dashboard
         ├─→ Add Employee Screen
         │    └─→ Employee Form
         │
         ├─→ Employee List Screen
         │    └─→ Employee Details Screen
         │         ├─→ Edit Employee
         │         └─→ Delete Employee
         │
         ├─→ Manual Check-in Screen
         │    ├─→ Select Employee
         │    ├─→ Select Project
         │    └─→ Submit Check-in/out
         │
         ├─→ Upload Document Screen
         │    ├─→ Select Employee
         │    ├─→ Choose File/Photo
         │    └─→ Upload
         │
         ├─→ Device Reset Approvals Screen
         │    └─→ Request Details
         │         ├─→ Approve
         │         └─→ Reject
         │
         └─→ Profile Screen (future)
```

### Admin Web Dashboard Navigation

```
Login Screen
    │
    └─→ Admin Dashboard
         ├─→ Projects Management
         │    ├─→ Create Project
         │    ├─→ Edit Project
         │    └─→ View Project Details
         │
         ├─→ Employee Management
         │    ├─→ Add Supervisor/Employee
         │    ├─→ View All Users
         │    └─→ Edit/Delete Users
         │
         ├─→ Attendance Reports
         │    ├─→ Daily Report
         │    ├─→ Weekly Report
         │    └─→ Export (PDF/CSV)
         │
         ├─→ Device Reset Management
         │    ├─→ View All Requests
         │    ├─→ Approve/Reject
         │    └─→ Reset History
         │
         └─→ System Settings
              ├─→ Check-in Settings
              ├─→ Device Settings
              └─→ Notification Settings
```

---

## 🎯 Integration Points

```
┌────────────────────────────────────────────────────────────────┐
│           SYSTEM INTEGRATION OVERVIEW                           │
└────────────────────────────────────────────────────────────────┘

┌──────────────┐      API Calls      ┌──────────────┐
│  Mobile Apps │◄────────────────────►│   Firebase   │
└──────────────┘                      │   Services   │
       │                              └──────────────┘
       │                                     ▲
       │                                     │
       ├─→ GPS Service                      │
       │    (Location)                      │
       │                                     │
       ├─→ NFC Reader                       │
       │    (Tag Scan)                      │
       │                                     │
       ├─→ Camera                            │
       │    (QR Scan)                       │
       │                                     │
       └─→ Device Info                      │
            (Platform)                      │
                                            │
┌──────────────┐      API Calls            │
│ Web Dashboard│◄───────────────────────────┘
└──────────────┘
```

---

## 📋 State Management Flow

```
┌────────────────────────────────────────────────────────────────┐
│                  RIVERPOD STATE FLOW                            │
└────────────────────────────────────────────────────────────────┘

┌─────────────────┐
│   UI Widgets    │
└────────┬────────┘
         │ ref.watch()
         ▼
┌─────────────────┐
│   Providers     │ ◄───┐
│  (Riverpod)     │     │ notifyListeners()
└────────┬────────┘     │
         │ call         │
         ▼              │
┌─────────────────┐     │
│   Controllers   │─────┘
│   (Logic)       │
└────────┬────────┘
         │ execute
         ▼
┌─────────────────┐
│    Services     │
│ (Firebase API)  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│    Firestore    │
│    Storage      │
└─────────────────┘

Example Flow:
──────────────
User Taps "Check In" Button
   ↓
Widget calls ref.read(attendanceController.notifier).checkIn()
   ↓
Controller validates and calls FirestoreService.createAttendance()
   ↓
Service writes to Firestore
   ↓
Firestore updates
   ↓
Provider notifies listeners
   ↓
UI automatically updates with new state
```

---

## 🔄 Real-Time Updates

```
┌────────────────────────────────────────────────────────────────┐
│              REAL-TIME DATA SYNCHRONIZATION                     │
└────────────────────────────────────────────────────────────────┘

SCENARIO: Employee checks in
────────────────────────────

📱 Employee App                  📱 Supervisor App         🌐 Admin Dashboard
     │                                │                          │
     │ Tap "Check In"                 │                          │
     │                                │                          │
     ├─→ Submit to Firestore          │                          │
     │         │                      │                          │
     │         └─→ Firestore ◄────────┼──── Stream Listener ────┤
     │              Updates           │                          │
     │                │               │                          │
     │                └───────────────┼─→ New Data Received      │
     │                                │                          │
     │                                └─→ UI Auto-Updates        │
     │                                     (Show Mike checked in)│
     │                                                            │
     └─→ UI Updates                                              │
         (Show checked in status)                                │
                                                                  │
                                                                  └─→ Dashboard
                                                                      Auto-Updates
                                                                      (Show real-time
                                                                       attendance)

All three platforms see the update within 1-2 seconds!
```

---

## 🎓 Summary

This interaction flow shows:

1. **Admin** → Creates foundation (projects, supervisors)
2. **Supervisor** → Manages employees (creates accounts, uploads docs, approves resets)
3. **Employee** → Uses system (check-in/out, view status, request resets)

All interactions flow through **Firebase** as the central hub, ensuring:
- ✅ Real-time synchronization
- ✅ Data consistency
- ✅ Secure access control
- ✅ Scalable architecture

---

**Related Documents:**
- [Mobile App Interaction Guide](MOBILE_APP_INTERACTION_GUIDE.md)
- [Complete Workflow Guide](COMPLETE_WORKFLOW_GUIDE.md)
- [Account Creation Guide](ACCOUNT_CREATION_GUIDE.md)

**Last Updated:** November 16, 2025

