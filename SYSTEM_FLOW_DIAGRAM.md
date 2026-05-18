# System Flow Diagram

## 📊 Complete System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    FIREBASE BACKEND                          │
│  ┌────────────┐  ┌──────────────┐  ┌──────────────┐        │
│  │    Auth    │  │  Firestore   │  │   Storage    │        │
│  │            │  │              │  │              │        │
│  │ • Users    │  │ • users      │  │ • Documents  │        │
│  │ • Tokens   │  │ • projects   │  │ • Photos     │        │
│  │            │  │ • attendance │  │ • Files      │        │
│  └────────────┘  └──────────────┘  └──────────────┘        │
└─────────────────────────────────────────────────────────────┘
         │                    │                    │
         └────────────────────┼────────────────────┘
                              │
         ┌────────────────────┼────────────────────┐
         │                    │                    │
         ▼                    ▼                    ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  WEB DASHBOARD  │  │  MOBILE - SUP   │  │  MOBILE - EMP   │
│     (ADMIN)     │  │   (SUPERVISOR)  │  │   (EMPLOYEE)    │
│                 │  │                 │  │                 │
│ • Projects      │  │ • Add Employee  │  │ • Check In/Out  │
│ • Employees     │  │ • View Team     │  │ • View Hours    │
│ • Approval      │  │ • Attendance    │  │ • Documents     │
│ • Reports       │  │ • Monitor       │  │ • Profile       │
│ • Settings      │  │                 │  │                 │
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

---

## 🔄 Data Flow Sequence

```
SETUP PHASE:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. ADMIN creates PROJECT
   └─> Firestore: projects/{projectId}
   
2. ADMIN creates SUPERVISOR
   └─> Firebase Auth: user account
   └─> Firestore: users/{supervisorId}
       ├─ role: "supervisor"
       ├─ projectId: [assigned project]
       └─ status: "approved"

3. SUPERVISOR adds EMPLOYEE
   └─> Firebase Auth: NOT created yet
   └─> Firestore: users/{employeeId}
       ├─ employeeId: "0001" (auto-generated)
       ├─ pin: "1234" (auto-generated)
       ├─ role: "employee"
       ├─ projectId: [supervisor's project]
       └─ status: "pending"

4. ADMIN approves EMPLOYEE
   └─> Firestore: users/{employeeId}
       └─ status: "pending" → "approved"


DAILY OPERATIONS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
5. EMPLOYEE checks in
   └─> Firestore: attendance/{attendanceId}
       ├─ userId: [employee uid]
       ├─ projectId: [project uid]
       ├─ checkInTime: [timestamp]
       ├─ checkInMethod: "gps"
       └─ status: "checked_in"

6. EMPLOYEE checks out
   └─> Firestore: attendance/{attendanceId}
       ├─ checkOutTime: [timestamp]
       ├─ totalHours: [calculated]
       └─ status: "checked_out"

7. SUPERVISOR views attendance
   └─> Read: attendance collection
       └─ Filter: projectId == supervisor's project

8. ADMIN exports report
   └─> Read: attendance collection
       └─ Filter: date range
       └─> Generate PDF/CSV
```

---

## 🔐 Authentication & Role Flow

```
LOGIN PROCESS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ADMIN:
┌─────────────┐
│ Email/Pass  │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Firebase    │
│ Auth        │
└──────┬──────┘
       │
       ▼
┌─────────────┐      role == "admin" ?
│ Firestore   │────────────────┐
│ users/{uid} │                │
└─────────────┘                │
                               ▼
                      ┌──────────────────┐
                      │ Admin Dashboard  │
                      └──────────────────┘

SUPERVISOR:
┌─────────────┐
│ Email/Pass  │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Firebase    │
│ Auth        │
└──────┬──────┘
       │
       ▼
┌─────────────┐      role == "supervisor" ?
│ Firestore   │────────────────┐
│ users/{uid} │                │
└─────────────┘                │
                               ▼
                      ┌──────────────────────┐
                      │ Supervisor Dashboard │
                      └──────────────────────┘

EMPLOYEE:
┌─────────────┐
│  ID / PIN   │
└──────┬──────┘
       │
       ▼
┌─────────────┐      Search: employeeId == ID
│ Firestore   │      AND pin == PIN
│ users/{uid} │      AND role == "employee"
└──────┬──────┘
       │
       ▼
┌─────────────┐      PIN matches?
│ Verify PIN  │──────────────┐
└─────────────┘              │
                             ▼
                    ┌──────────────────────┐
                    │ Employee Dashboard   │
                    └──────────────────────┘
```

---

## 📱 App Navigation Flow

```
MOBILE APP STRUCTURE:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

                    ┌──────────────┐
                    │  App Start   │
                    └──────┬───────┘
                           │
                           ▼
                    ┌──────────────┐
                    │ Login Screen │
                    └──────┬───────┘
                           │
            ┌──────────────┼──────────────┐
            │                             │
            ▼                             ▼
    ┌───────────────┐           ┌────────────────┐
    │ Email/Pass    │           │   ID / PIN     │
    │ Login         │           │   Login        │
    └───────┬───────┘           └────────┬───────┘
            │                            │
            │                            │
    role == "supervisor"?        role == "employee"?
            │                            │
            ▼                            ▼
    ┌───────────────────┐       ┌───────────────────┐
    │ SUPERVISOR        │       │ EMPLOYEE          │
    │ DASHBOARD         │       │ DASHBOARD         │
    │                   │       │                   │
    │ • My Project      │       │ • Check In/Out    │
    │ • Add Employee    │       │ • Attendance      │
    │ • Employee List   │       │ • Profile         │
    │ • Attendance      │       │ • Work Hours      │
    │ • Profile         │       │ • Documents       │
    └───────────────────┘       └───────────────────┘
```

```
WEB DASHBOARD STRUCTURE:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

            ┌──────────────────┐
            │ Admin Login      │
            │ (Email/Password) │
            └────────┬─────────┘
                     │
                     ▼
            ┌────────────────────────┐
            │   ADMIN DASHBOARD      │
            │   ┌──────────────────┐ │
            │   │   Navigation     │ │
            │   └──────────────────┘ │
            └────────┬───────────────┘
                     │
     ┌───────────────┼───────────────┐
     │               │               │
     ▼               ▼               ▼
┌──────────┐  ┌──────────┐  ┌──────────┐
│ Projects │  │ Employee │  │ Reports  │
│          │  │ Manage   │  │          │
│ • List   │  │          │  │ • Daily  │
│ • Create │  │ • List   │  │ • Weekly │
│ • Edit   │  │ • Add    │  │ • Monthly│
│ • Delete │  │ • Approve│  │ • Export │
└──────────┘  │ • Assign │  └──────────┘
              └──────────┘
                   │
     ┌─────────────┼─────────────┐
     │                           │
     ▼                           ▼
┌──────────┐              ┌──────────┐
│Pending   │              │ Active   │
│Approval  │              │ List     │
└──────────┘              └──────────┘
```

---

## 🔄 Employee ID & PIN Generation

```
WHEN SUPERVISOR ADDS EMPLOYEE:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Supervisor fills form
   ├─ Name: "John Doe"
   ├─ Email: "john@example.com"
   ├─ Phone: "+1234567890"
   └─ Position: "Worker"

2. System queries Firestore:
   └─> Count existing employees in project
       └─ Result: 0 employees found

3. System auto-generates:
   ├─ Employee ID: 0001 (format: 4 digits, padded)
   └─ PIN: 1234 (format: 4 digits, random)

4. System creates Firestore document:
   └─> users/{newEmployeeUid}
       ├─ uid: [auto-generated Firebase UID]
       ├─ employeeId: "0001"
       ├─ pin: "1234"
       ├─ name: "John Doe"
       ├─ email: "john@example.com"
       ├─ role: "employee"
       ├─ projectId: [supervisor's project]
       └─ status: "pending"

5. Supervisor sees confirmation:
   ┌─────────────────────────────┐
   │ Employee Added Successfully │
   │                             │
   │ Employee ID: 0001           │
   │ PIN: 1234                   │
   │                             │
   │ Status: Pending Approval    │
   │                             │
   │ Share these credentials     │
   │ with the employee           │
   └─────────────────────────────┘
```

---

## ⏱️ Check-In/Out Process

```
EMPLOYEE CHECK-IN FLOW:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Employee Dashboard
       │
       ▼
┌──────────────┐
│ Check In Btn │
└──────┬───────┘
       │
       ▼
┌──────────────────┐
│ Select Method:   │
│ • GPS            │◄── Easiest for testing
│ • QR Code        │
│ • Geofence       │
└──────┬───────────┘
       │
       ▼ (GPS selected)
┌──────────────────┐
│ Get GPS Location │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ Create Record:   │
│ checkInTime      │
│ location         │
│ method: "gps"    │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ Update UI:       │
│ Status: Checked  │
│ Timer: Started   │
└──────────────────┘

EMPLOYEE CHECK-OUT FLOW:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Employee Dashboard
       │
       ▼
┌──────────────┐
│ Check Out    │
│ Button       │
└──────┬───────┘
       │
       ▼
┌──────────────────┐
│ Get Current      │
│ Attendance       │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ Update Record:   │
│ checkOutTime     │
│ totalHours       │
│ status: complete │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ Show Summary:    │
│ Work Time: 8h    │
│ Break: 1h        │
│ Total: 7h        │
└──────────────────┘
```

---

## 📊 Real-Time Data Sync

```
FIRESTORE REAL-TIME UPDATES:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Employee checks in
       │
       ▼
┌─────────────────┐
│ Firestore       │
│ attendance      │
│ collection      │
└────┬───────┬────┘
     │       │
     │       │
     ▼       ▼
┌─────────┐ ┌──────────┐
│Supervisor│ │  Admin   │
│  App    │ │ Dashboard│
└─────────┘ └──────────┘
     │            │
     ▼            ▼
Real-time    Real-time
update       update
shows        shows
"Checked In" attendance
             record
```

---

## 🎯 Testing Flow Summary

```
START
  │
  ├─ 1. Create Admin User (Firebase Console)
  │     │
  ├─ 2. Login to Web Dashboard
  │     │
  ├─ 3. Create Project
  │     │
  ├─ 4. Create Supervisor (assign to project)
  │     │
  ├─ 5. Supervisor logs in (Mobile App)
  │     │
  ├─ 6. Supervisor adds Employee
  │     │    (Gets ID: 0001, PIN: 1234)
  │     │
  ├─ 7. Admin approves Employee (Web Dashboard)
  │     │
  ├─ 8. Employee logs in (Mobile App)
  │     │    (Uses ID: 0001, PIN: 1234)
  │     │
  ├─ 9. Employee checks in
  │     │
  └─ 10. Verify in all interfaces
         ├─ Employee App: Shows "Checked In"
         ├─ Supervisor App: See employee status
         └─ Admin Dashboard: See attendance record
END ✓
```

---

**See detailed steps in:** `COMPLETE_WORKFLOW_GUIDE.md`  
**Quick checklist in:** `QUICK_START_CHECKLIST.md`

