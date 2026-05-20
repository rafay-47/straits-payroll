# 🧪 Practical Testing Guide - Step by Step

## Overview
This guide provides **exact step-by-step instructions** to test your Straights Psyroll app from scratch.

---

## 📋 Prerequisites Checklist

Before starting, ensure:
- [ ] Flutter is installed: `flutter --version`
- [ ] Project dependencies installed: `flutter pub get`
- [ ] Firebase project created
- [ ] Firebase configured in the app

---

## 🔥 Part 1: Firebase Setup & Test Data Creation

### Step 1: Create Firebase Project

1. **Open Firebase Console**
   - Go to: https://console.firebase.google.com/
   - Click "Add project"

2. **Project Setup**
   - Project name: `straights-psyroll-test`
   - Disable Google Analytics (for testing)
   - Click "Create Project"
   - Wait for project creation
   - Click "Continue"

### Step 2: Enable Firebase Services

#### A. Enable Authentication

1. **Navigate to Authentication**
   - In left sidebar, click "Authentication"
   - Click "Get Started"

2. **Enable Email/Password**
   - Click "Sign-in method" tab
   - Click "Email/Password"
   - Toggle "Enable" ON
   - Click "Save"

#### B. Create Firestore Database

1. **Navigate to Firestore**
   - In left sidebar, click "Firestore Database"
   - Click "Create database"

2. **Security Rules**
   - Select "Start in test mode" (for now)
   - Click "Next"

3. **Location**
   - Choose location closest to you (e.g., us-central)
   - Click "Enable"
   - Wait for database creation

#### C. Enable Storage

1. **Navigate to Storage**
   - In left sidebar, click "Storage"
   - Click "Get started"

2. **Security Rules**
   - Start in test mode
   - Click "Next"

3. **Location**
   - Use same location as Firestore
   - Click "Done"

### Step 3: Configure App with Firebase

#### For Web Testing (Easiest)

1. **Add Web App to Firebase**
   - In Project Overview, click "</>" (Web icon)
   - App nickname: `Straits Payroll`
   - Check "Also set up Firebase Hosting"
   - Click "Register app"

2. **Copy Configuration**
   - Copy the `firebaseConfig` object shown
   - It looks like:
   ```javascript
   apiKey: "AIzaSy...",
   authDomain: "straights-psyroll-test.firebaseapp.com",
   projectId: "straights-psyroll-test",
   storageBucket: "straights-psyroll-test.appspot.com",
   messagingSenderId: "123456789",
   appId: "1:123456789:web:abc123"
   ```

3. **Update Your App**
   - Open: `lib/main.dart`
   - Find line ~15-21 (the `FirebaseOptions` for web)
   - Replace with your actual values:
   ```dart
   options: kIsWeb
       ? const FirebaseOptions(
           apiKey: "YOUR_ACTUAL_API_KEY",
           authDomain: "straights-psyroll-test.firebaseapp.com",
           projectId: "straights-psyroll-test",
           storageBucket: "straights-psyroll-test.appspot.com",
           messagingSenderId: "YOUR_ACTUAL_SENDER_ID",
           appId: "YOUR_ACTUAL_APP_ID",
         )
       : null,
   ```

### Step 4: Create Test Users in Firebase

#### A. Create Admin User

1. **Go to Authentication**
   - Firebase Console → Authentication → Users tab
   - Click "Add user"

2. **Add Admin Details**
   - Email: `admin@test.com`
   - Password: `Admin@123`
   - Click "Add user"
   - **Copy the User UID** (you'll need it next)
   - Example UID: `ABC123xyz789`

3. **Create Admin Profile in Firestore**
   - Go to Firestore Database
   - Click "Start collection"
   - Collection ID: `users`
   - Click "Next"

4. **Add Admin Document**
   - Document ID: (paste the User UID you copied)
   - Add fields (click "Add field" for each):

   ```
   Field Name: uid
   Field Type: string
   Value: ABC123xyz789 (your actual UID)

   Field Name: name
   Field Type: string
   Value: Admin User

   Field Name: email
   Field Type: string
   Value: admin@test.com

   Field Name: role
   Field Type: string
   Value: admin

   Field Name: status
   Field Type: string
   Value: active

   Field Name: biometricEnabled
   Field Type: boolean
   Value: false

   Field Name: createdAt
   Field Type: timestamp
   Value: (click "now")

   Field Name: updatedAt
   Field Type: timestamp
   Value: (click "now")
   ```

5. Click "Save"

#### B. Create Supervisor User

1. **Add User in Authentication**
   - Authentication → Users → Add user
   - Email: `supervisor@test.com`
   - Password: `Super@123`
   - Click "Add user"
   - **Copy the User UID**

2. **Add Supervisor Document in Firestore**
   - Firestore → users collection
   - Click "Add document"
   - Document ID: (paste Supervisor UID)
   - Add fields:

   ```
   uid: [supervisor-uid]
   name: Test Supervisor
   email: supervisor@test.com
   role: supervisor
   status: active
   biometricEnabled: false
   createdAt: (timestamp - now)
   updatedAt: (timestamp - now)
   ```

3. Click "Save"

### Step 5: Create Test Project

1. **Create Projects Collection**
   - Firestore Database
   - Click "Start collection" (or if users collection exists, add new collection)
   - Collection ID: `projects`

2. **Add Test Project Document**
   - Document ID: `project-001` (or auto-ID)
   - Add fields:

   ```
   projectId: project-001
   name: Test Project Site A
   description: Test project for development and testing
   
   location: (Map type)
     └─ address: 123 Test Street, San Francisco, CA
     └─ latitude: 37.7749
     └─ longitude: -122.4194
     └─ radiusInMeters: 10000
   
   checkInMethods: (Array type)
     └─ 0: gps
     └─ 1: manual
   
   nfcTagId: (leave empty or null)
   qrCodeData: (leave empty or null)
   
   assignedEmployeeIds: (Array type - leave empty for now)
     (we'll add employees after they're created)
   
   isActive: true
   
   createdBy: [admin-uid-you-copied-earlier]
   
   createdAt: (timestamp - now)
   updatedAt: (timestamp - now)
   ```

3. Click "Save"

**Important Note about Location**: The `radiusInMeters: 10000` (10km) is very large so GPS check-in will work from anywhere during testing. For production, use 200-500 meters.

### Step 6: Create System Settings (Optional but Recommended)

1. **Create Collection**
   - Firestore → Start collection
   - Collection ID: `systemSettings`

2. **Add Settings Document**
   - Document ID: `general`
   - Add fields:

   ```
   maxCheckInsPerDay: 2
   maxCheckOutsPerDay: 2
   maxDeviceResetsPerMonth: 1
   defaultCheckInRadiusMeters: 200
   ```

3. Click "Save"

---

## 🧪 Part 2: Testing Flow - Complete Walkthrough

### 🌐 PHASE 1: Test Admin Web Dashboard

#### Step 1: Run the Web App

```bash
# In terminal, navigate to project
cd /Users/mac/Documents/straights_psyroll

# Run on Chrome
flutter run -d chrome
```

**Expected Result**: App opens in Chrome browser at `http://localhost:XXXXX`

#### Step 2: Admin Login

1. **You should see**: Admin Login Screen
   - Email field
   - Password field
   - Login button

2. **Enter Credentials**:
   - Email: `admin@test.com`
   - Password: `Admin@123`
   - Click "Login"

3. **Expected Result**: 
   - Success message or navigation
   - Admin Dashboard loads
   - You see statistics (may be 0 if no data yet)

#### Step 3: Verify Admin Dashboard

**What You Should See**:
- 📊 **Statistics Cards** at top:
  - Total Employees: 0 (we haven't added any yet)
  - Active Projects: 1 (the test project)
  - Total Check-ins Today: 0

- 🎯 **Quick Action Cards**:
  - Manage Projects
  - Approve Employees
  - Manage Documents
  - View Reports
  - Device Requests
  - System Settings (might be a button)

#### Step 4: Verify Project Management

1. **Click "Manage Projects"** card/button
2. **Expected Result**:
   - Data table showing projects
   - You should see "Test Project Site A"
   - Columns: Name, Location, Methods, Status, Actions

3. **Test Creating a Project** (Optional):
   - Click "Create Project" button
   - Fill in form:
     - Name: "Downtown Office"
     - Description: "Main office location"
     - Address: "456 Main St"
     - Latitude: 37.7849
     - Longitude: -122.4094
     - Radius: 200
     - Check-in methods: Select GPS and Manual
   - Click "Save"
   - **Verify**: New project appears in table

4. **Go Back to Dashboard** (use back button or navigation)

---

### 📱 PHASE 2: Test Supervisor Mobile App

#### Step 1: Run Mobile App

**Option A - Android Emulator**:
```bash
# Open Android Studio → AVD Manager → Start Emulator
# Then in terminal:
flutter run

# Or specify device:
flutter run -d emulator-5554
```

**Option B - iOS Simulator (Mac only)**:
```bash
# Open Simulator
open -a Simulator

# Run app
flutter run
```

**Option C - Physical Device**:
```bash
# Connect device via USB
# Enable USB debugging (Android) or trust computer (iOS)
flutter run
```

#### Step 2: Role Selection

1. **You should see**: Role Selection Screen with 2 options
   - "Employee" button
   - "Supervisor" button

2. **Tap "Supervisor"**

#### Step 3: Supervisor Login

1. **You should see**: Login Screen
   - Email field
   - Password field
   - Login button

2. **Enter Credentials**:
   - Email: `supervisor@test.com`
   - Password: `Super@123`
   - Tap "Login"

3. **Expected Result**: Supervisor Dashboard loads

#### Step 4: Supervisor Dashboard Overview

**What You Should See**:
- 👤 **Header**: "Welcome, Test Supervisor" (or similar)
- 📊 **Statistics** (if implemented):
  - Total Employees: 0
  - Active Projects: 1
  - Today's Attendance: 0

- 🎯 **Quick Action Buttons** (5 buttons in grid):
  1. "Add Employee" 👤
  2. "My Employees" 👥
  3. "Upload Document" 📄
  4. "Manual Check-In" ✓
  5. "Device Reset Approvals" 📱

- 📋 **Active Projects Section**:
  - Shows "Test Project Site A"
  - Location information
  - Status: Active

#### Step 5: Add First Employee

1. **Tap "Add Employee"** button

2. **You should see**: Add Employee Form

3. **Fill in Employee Details**:
   - Name: `John Doe`
   - Email: `john.doe@test.com`
   - Phone: `+1234567890`

4. **Tap "Submit"** or "Add Employee"

5. **Expected Result**: 
   - Success dialog appears showing:
     - Employee ID: **0001**
     - Default PIN: **1234**
   - ⚠️ **IMPORTANT**: Note down this ID and PIN!

6. **Tap "OK"** on dialog

7. **Form should reset** or navigate back to dashboard

#### Step 6: Verify Employee in List

1. **Tap "My Employees"** from dashboard

2. **You should see**: Employee List Screen
   - Shows John Doe
   - System ID: 0001
   - Status: Pending (yellow/orange indicator)
   - Email and phone visible

3. **Tap on "John Doe"** card

4. **You should see**: Employee Details Screen
   - Name, email, phone
   - System Generated ID: 0001
   - Status: Pending
   - No device info yet (not logged in yet)
   - No custom ID yet (admin hasn't approved)

5. **Go back** to Employee List
6. **Go back** to Dashboard

#### Step 7: Add Second Employee (Optional)

Repeat Step 5 with:
- Name: `Jane Smith`
- Email: `jane.smith@test.com`
- Phone: `+1234567891`

Expected ID: **0002**
Expected PIN: **1234**

---

### 🌐 PHASE 3: Approve Employee (Switch to Web)

#### Step 1: Go Back to Admin Web Dashboard

**If you closed the web app, restart it**:
```bash
flutter run -d chrome
```

Login as admin again if needed.

#### Step 2: Navigate to Employee Approval

1. **From Dashboard**, click "Approve Employees" card

2. **You should see**: Employee Approval Screen
   - Data table with pending employees
   - Shows: John Doe (ID: 0001, Status: Pending)
   - Shows: Jane Smith if you added her

3. **For John Doe**, you should see action buttons:
   - ✓ Approve icon
   - ✗ Reject icon
   - ℹ️ View details icon

#### Step 3: Approve John Doe

1. **Click the "Approve" button** (✓ icon) for John Doe

2. **Approval Dialog appears**:
   - Shows employee details
   - Option to assign Custom ID (optional)
   - Example: `EMP001` or leave blank

3. **Assign Custom ID** (optional):
   - Enter: `EMP001`

4. **Click "Approve"**

5. **Expected Result**:
   - Success message
   - John Doe disappears from pending list (or status changes to Approved)

6. **Repeat for Jane Smith** if you added her
   - Custom ID: `EMP002`

---

### 📱 PHASE 4: Test Employee Mobile App

#### Step 1: Restart or Keep Running Mobile App

If still running from Phase 2, tap back button until you reach Role Selection.
Or restart: `flutter run` (on mobile device/emulator)

#### Step 2: Employee Login

1. **Tap "Employee"** on Role Selection Screen

2. **You should see**: Employee Login Screen
   - ID field (for System ID or Custom ID)
   - PIN field (6 digits)
   - Login button

3. **Enter Credentials** (use John Doe's credentials):
   - ID: `0001` (or `EMP001` if you assigned custom ID)
   - PIN: `123456` (6 digits, so `1234` becomes `001234` or try `123456`)
   
   **⚠️ Important**: The PIN might be 4 digits or 6 digits. Try:
   - `1234` then tap Submit (if 4-digit)
   - `123456` if 6-digit field

4. **Tap "Login"**

5. **First Login - Device Binding**:
   - App captures device information
   - Device is bound to this employee
   - This prevents login from other devices

6. **Expected Result**: 
   - Login successful
   - **Optional**: Biometric setup prompt (Skip for now)
   - Navigate to Employee Dashboard

#### Step 3: Employee Dashboard Overview

**What You Should See**:

**Header Section**:
- "Welcome, John Doe"
- Employee ID: 0001 (or EMP001)

**Today's Status Card** (at top):
- Check-ins Today: 0/2
- Check-outs Today: 0/2
- Working Hours: 0h 0m
- Status: Not Checked In (or similar)

**Quick Actions** (3 buttons):
1. "Check In" (green button)
2. "Attendance" (blue/info button)
3. "Device Reset" (orange/warning button)

**Assigned Projects Section**:
- Shows "Test Project Site A"
- Location: 123 Test Street...
- Status: Active
- Distance: (may show if location enabled)

#### Step 4: Perform Check-In (GPS Method)

1. **Tap "Check In"** button

2. **You should see**: Check-In Screen
   - Select Project dropdown/list
   - Project: Test Project Site A
   - Check-in methods available (GPS, Manual)

3. **Select Check-In Method**: 
   - Tap "GPS Location" (usually default)

4. **Location Permission**:
   - If first time, app requests location permission
   - **Tap "Allow" or "Allow While Using App"**

5. **GPS Check-In Process**:
   - App gets your current location
   - Validates if within project radius (10km - set large for testing)
   - Shows loading indicator

6. **Expected Result - Success**:
   - ✅ Success message: "Checked in successfully!"
   - Button changes to "Check Out"
   - Shows check-in time
   - Shows location captured
   - Working hours timer starts (0h 0m)

7. **Dashboard Updates**:
   - Tap back button to go to dashboard
   - Today's Status now shows:
     - Check-ins Today: 1/2
     - Status: Checked In
     - Check-in time visible

**If Check-In Fails (Out of Range)**:
- You'll see error: "Outside project radius"
- **Solution for Testing**: 
  - Go to Firebase Console → Firestore
  - Edit project document
  - Change `location.radiusInMeters` to `100000` (100km)
  - Try again

#### Step 5: Wait and Check Out

**Simulate Working Time**:
- Wait 2-3 minutes (or just proceed immediately for testing)

**Check Out Process**:
1. **Tap "Check Out"** button (was "Check In", now changed)

2. **You should see**: Check-Out Confirmation
   - Shows check-in time
   - Shows current time
   - Calculated working duration

3. **Tap "Check Out"** to confirm

4. **Expected Result**:
   - ✅ Success message: "Checked out successfully!"
   - Working hours calculated (e.g., "0h 2m")
   - Button changes back to "Check In"
   - Attendance record created

5. **Dashboard Updates**:
   - Today's Status shows:
     - Check-ins Today: 1/2
     - Check-outs Today: 1/2
     - Working Hours: 0h 2m (or actual time)
     - Status: Checked Out

---

### 🌐 PHASE 5: Verify Data in Admin Dashboard (Web)

#### Step 1: Go to Admin Web Dashboard

Switch to your browser with admin dashboard.

#### Step 2: Check Dashboard Statistics

**Statistics should now show**:
- Total Employees: 2 (John Doe, Jane Smith)
- Total Check-ins Today: 1
- Recent activity may show John's check-in

#### Step 3: View Reports

1. **Click "View Reports"** from dashboard

2. **Select "Attendance Report"** tab

3. **Set Date Range**:
   - From: Today's date
   - To: Today's date

4. **Click "Generate Report"** or "Load Data"

5. **You should see**:
   - Table with attendance records
   - John Doe's check-in and check-out
   - Project: Test Project Site A
   - Check-in time, Check-out time
   - Working hours: 0h 2m (or actual)
   - Location: GPS coordinates
   - Check-in method: GPS

6. **Test Export**:
   - Click "Export PDF"
   - PDF should download with attendance data
   - Click "Export CSV"
   - CSV file should download

---

## 🔄 Complete Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     FIREBASE SETUP                           │
│  1. Create Project                                          │
│  2. Enable Auth, Firestore, Storage                        │
│  3. Create Admin user (admin@test.com)                     │
│  4. Create Supervisor user (supervisor@test.com)           │
│  5. Create Test Project in Firestore                       │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│              PHASE 1: TEST WEB ADMIN                         │
│  1. Run: flutter run -d chrome                             │
│  2. Login as admin@test.com                                │
│  3. View Dashboard - verify project shows                  │
│  4. Check Project Management - see test project            │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│           PHASE 2: TEST MOBILE SUPERVISOR                    │
│  1. Run: flutter run (on emulator/device)                  │
│  2. Select "Supervisor" role                               │
│  3. Login as supervisor@test.com                           │
│  4. Add Employee (John Doe) - Get ID: 0001, PIN: 1234    │
│  5. Verify in "My Employees" - Status: Pending            │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│        PHASE 3: APPROVE EMPLOYEE (Back to Web)              │
│  1. Admin Dashboard → Employee Approval                     │
│  2. See John Doe (Pending)                                 │
│  3. Approve John Doe (optional: assign custom ID EMP001)  │
│  4. Status changes to Approved                             │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│            PHASE 4: TEST MOBILE EMPLOYEE                     │
│  1. Mobile App → Select "Employee" role                    │
│  2. Login: ID=0001 (or EMP001), PIN=1234                  │
│  3. First login = Device Binding                           │
│  4. Dashboard - see assigned projects                      │
│  5. Check In - GPS method - allow location                │
│  6. Wait (or proceed immediately)                          │
│  7. Check Out - see working hours calculated               │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│       PHASE 5: VERIFY IN ADMIN DASHBOARD (Web)              │
│  1. Admin Dashboard - see updated statistics              │
│  2. Reports → Attendance Report                            │
│  3. See John Doe's check-in/out record                    │
│  4. Export PDF/CSV - verify download works                │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔗 How Everything Links Together

### Data Flow

```
1. SUPERVISOR CREATES EMPLOYEE
   Mobile Supervisor App
   ↓
   Firebase Auth (creates user account)
   ↓
   Firestore → users/[uid] (status: pending)
   ↓
   System auto-generates ID (0001, 0002...)

2. ADMIN APPROVES EMPLOYEE
   Web Admin Dashboard
   ↓
   Reads from: Firestore → users collection (where status=pending)
   ↓
   Updates: Firestore → users/[uid] (status: active, customId: EMP001)
   ↓
   Employee can now login

3. EMPLOYEE LOGS IN
   Mobile Employee App
   ↓
   Firebase Auth (sign in with email converted from ID)
   ↓
   Reads: Firestore → users/[uid]
   ↓
   Verifies: role=employee, status=active
   ↓
   First login: Captures device info
   ↓
   Updates: Firestore → users/[uid] (deviceInfo: {...})

4. EMPLOYEE CHECKS IN
   Mobile Employee App
   ↓
   Reads: Firestore → projects (assigned projects)
   ↓
   GPS: Gets current location
   ↓
   Validates: Within project radius?
   ↓
   Creates: Firestore → users/[uid]/attendance/[attendanceId]
   ↓
   Real-time update to: Dashboard

5. EMPLOYEE CHECKS OUT
   Mobile Employee App
   ↓
   Reads: Firestore → users/[uid]/attendance (today's check-in)
   ↓
   Calculates: Working hours (checkout - checkin)
   ↓
   Updates: Firestore → attendance record (checkOutTime, workingHours)

6. ADMIN VIEWS REPORTS
   Web Admin Dashboard
   ↓
   Reads: Firestore → users/[uid]/attendance (all records)
   ↓
   Filters: By date range, project, employee
   ↓
   Generates: PDF/CSV with all data
```

### Collections Relationships

```
Firestore Structure:

users (collection)
├── [admin-uid] (document)
│   └── role: admin
├── [supervisor-uid] (document)
│   └── role: supervisor
└── [employee-uid] (document)
    ├── role: employee
    ├── systemGeneratedId: 0001
    ├── customId: EMP001
    ├── deviceInfo: {...}
    ├── supervisorId: [supervisor-uid]
    │
    ├── attendance (subcollection)
    │   ├── [attendance-1] (document)
    │   │   ├── checkInTime: timestamp
    │   │   ├── checkOutTime: timestamp
    │   │   ├── projectId: project-001
    │   │   ├── checkInMethod: gps
    │   │   └── workingHours: 2.5
    │   └── [attendance-2] (document)
    │
    ├── documents (subcollection)
    │   └── [doc-1] (document)
    │       ├── type: id-proof
    │       ├── url: storage-url
    │       └── status: pending
    │
    └── deviceResetRequests (subcollection)
        └── [request-1] (document)
            ├── reason: "Lost phone"
            └── status: pending

projects (collection)
└── [project-001] (document)
    ├── name: Test Project Site A
    ├── location: {lat, lng, radius}
    ├── checkInMethods: [gps, manual]
    └── assignedEmployeeIds: [employee-uid]

auditLogs (collection)
systemSettings (collection)
```

---

## 🧪 Additional Testing Scenarios

### Scenario 1: Multiple Check-Ins Same Day

1. Employee checks in to Project A (Session 1)
2. Employee checks out from Project A
3. Employee checks in to Project A again (Session 2)
4. Employee checks out
5. Verify: Dashboard shows 2/2 check-ins, total working hours is sum

### Scenario 2: Device Reset Request

**From Employee App**:
1. Dashboard → "Device Reset" button
2. View current device info
3. Enter reason: "Lost phone, got new device"
4. Submit request
5. Request status: Pending

**From Supervisor/Admin**:
1. Navigate to Device Reset Approvals
2. See pending request from John Doe
3. View device details
4. Approve request
5. Employee can now login from new device

### Scenario 3: Document Upload & Approval

**From Supervisor App**:
1. Dashboard → "Upload Document"
2. Select Employee: John Doe
3. Document Type: ID Proof
4. Upload image (camera or gallery)
5. Add description
6. Submit
7. Status: Pending

**From Admin Web**:
1. Navigate to Document Management
2. See John Doe's ID Proof (Pending)
3. Click view to open document
4. Click Approve
5. Status: Approved

---

## ❌ Common Issues & Solutions

### Issue 1: "Firebase Not Initialized"
**Solution**: 
- Check Firebase config in `lib/main.dart`
- Verify google-services.json (Android) or GoogleService-Info.plist (iOS) is in place
- Restart app: `flutter clean && flutter run`

### Issue 2: "User Not Found" after login
**Solution**:
- Verify user exists in Authentication
- Verify user document exists in Firestore users collection
- Verify UID matches between Auth and Firestore

### Issue 3: "Permission Denied" in Firestore
**Solution**:
- Go to Firestore → Rules
- For testing, use:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;  // WARNING: TESTING ONLY!
    }
  }
}
```
- **Remember**: Change to proper security rules for production!

### Issue 4: Employee Can't See Projects
**Solution**:
- Go to Firestore → projects → project-001
- Add employee UID to `assignedEmployeeIds` array
- Refresh employee app

### Issue 5: Check-In "Out of Range" Error
**Solution**:
- Increase `radiusInMeters` to 10000 (10km) in project document
- Or use "Manual" check-in method
- Verify location permissions granted

### Issue 6: "Cannot check in" - Already checked in
**Solution**:
- Check out from current session first
- Or verify max check-ins per day not reached (2 by default)

---

## ✅ Testing Completion Checklist

### Admin Web Dashboard
- [ ] Login successful
- [ ] Dashboard displays statistics
- [ ] Can view projects
- [ ] Can create new project
- [ ] Can approve employees
- [ ] Can view documents
- [ ] Can generate reports (PDF/CSV)
- [ ] Can manage device reset requests

### Supervisor Mobile App
- [ ] Login successful
- [ ] Dashboard displays correctly
- [ ] Can add employee
- [ ] Employee gets system ID (0001, 0002...)
- [ ] Can view employee list
- [ ] Can upload documents
- [ ] Can perform manual check-in
- [ ] Can approve device reset requests

### Employee Mobile App
- [ ] Login with ID/PIN works
- [ ] Device binding occurs on first login
- [ ] Dashboard shows assigned projects
- [ ] Can check in (GPS method)
- [ ] Can check out
- [ ] Working hours calculated correctly
- [ ] Can request device reset
- [ ] Dashboard updates in real-time

### Data Verification
- [ ] Attendance records created in Firestore
- [ ] Reports show correct data
- [ ] Documents uploaded to Storage
- [ ] Audit logs created (if implemented)
- [ ] Real-time sync works across platforms

---

## 📞 Need Help?

If you encounter issues:

1. **Check Firebase Console**:
   - Authentication: Verify users exist
   - Firestore: Verify documents exist
   - Storage: Verify files uploaded

2. **Check Logs**:
```bash
flutter logs
```

3. **Check Firestore Rules**:
   - If getting permission errors
   - Use test mode temporarily

4. **Verify Configuration**:
   - Firebase config in `lib/main.dart`
   - google-services.json (Android)
   - GoogleService-Info.plist (iOS)

5. **Clean and Rebuild**:
```bash
flutter clean
flutter pub get
flutter run
```

---

## 🎉 Success!

If all tests pass, your app is working correctly!

**Next Steps**:
1. ✅ Implement proper Firestore security rules
2. ✅ Test on real devices
3. ✅ Perform user acceptance testing
4. ✅ Prepare for production deployment

**See also**:
- `DEPLOYMENT_GUIDE.md` - For production deployment
- `TESTING_GUIDE.md` - For comprehensive test cases
- `FINAL_PROJECT_SUMMARY.md` - For complete feature list

---

*Happy Testing! 🚀*

