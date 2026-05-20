# 🏗️ Updated Architecture - Mobile App + Web Dashboard

## 📋 Requirements Summary (Confirmed)

### ✅ Answers Received:

1. **Employer Management**: ✅ Employers have **WEB DASHBOARD** (not mobile)
2. **Employee ID**: ✅ Auto-generated (0001...) + optional custom (EMP123)
3. **Check-In Rules**: ✅ Multiple projects, 2 check-ins/day per project, must check-out before new project
4. **Device Binding**: ✅ 1 reset/month, employee requests → admin approves
5. **Reports**: ✅ Both PDF + CSV with detailed data points
6. **Migration**: ✅ Start fresh

---

## 🎯 Platform Split

### **Mobile App (Flutter)**
**Users:**
- ✅ Employees
- ✅ Supervisors

**Features:**
- Employee: Check-in/out, attendance, profile
- Supervisor: Employee management, manual check-in, documents

---

### **Web Dashboard (Flutter Web OR React/Vue)**
**Users:**
- ✅ Employers/Admins

**Features:**
- Project creation & assignment
- Supervisor assignment
- Employee approval & custom ID assignment
- Attendance/report review
- Device reset approvals
- System settings & audit logs

---

## 🗂️ Updated Database Structure

```
users/
  {userId}/
    - role: 'employee' | 'supervisor' | 'admin'
    - employeeId: '0001' | 'EMP123' (for employees)
    - systemGeneratedId: '0001' (auto)
    - customId: 'EMP123' | null (admin-assigned)
    - status: 'pending' | 'approved' | 'suspended'
    - deviceInfo: {
        deviceId: string
        deviceModel: string
        registeredAt: timestamp
        resetCount: number
        lastResetAt: timestamp | null
      }
    - supervisorId: string (for employees)
    - employerId: string
    - approvedBy: userId | null (admin who approved)
    - approvedAt: timestamp | null
    
    attendance/ (subcollection)
      {attendanceId}/
        - projectId: string
        - checkInTime: timestamp
        - checkOutTime: timestamp | null
        - checkInMethod: 'gps' | 'nfc' | 'qr' | 'manual'
        - checkInLocation: { lat, lng, address, accuracy }
        - checkOutLocation: { lat, lng, address, accuracy } | null
        - verifiedBy: userId | null (if manual)
        - deviceInfo: { deviceId, model }
        - workingHours: number
        - status: 'checked_in' | 'checked_out'
        - sessionNumber: number (1st or 2nd check-in of day)
    
    documents/ (subcollection)
      {docId}/
        - type: 'id_proof' | 'bank_statement' | 'contract' | 'other'
        - name: string
        - url: string
        - uploadedBy: userId (supervisor/admin)
        - uploadedAt: timestamp
        - status: 'pending' | 'approved' | 'rejected'
    
    deviceResetRequests/ (subcollection)
      {requestId}/
        - requestedAt: timestamp
        - reason: string
        - status: 'pending' | 'approved' | 'rejected'
        - reviewedBy: userId | null
        - reviewedAt: timestamp | null
        - oldDeviceInfo: { deviceId, model }
        - newDeviceInfo: { deviceId, model } | null

projects/
  {projectId}/
    - name: string
    - description: string
    - employerId: string
    - supervisorId: string
    - location: {
        lat: number
        lng: number
        address: string
        radius: number (meters)
      }
    - checkInMethods: ['gps', 'nfc', 'qr', 'manual']
    - nfcTagId: string | null
    - qrCode: string | null
    - maxCheckInsPerDay: number (default: 2)
    - maxCheckOutsPerDay: number (default: 2)
    - isActive: boolean
    - createdBy: userId (admin)
    - createdAt: timestamp
    
    assignedEmployees/ (subcollection)
      {employeeId}/
        - userId: string
        - name: string
        - employeeId: string
        - assignedAt: timestamp
        - assignedBy: userId (supervisor/admin)
        - isActive: boolean

employers/
  {employerId}/
    - companyName: string
    - email: string
    - phoneNumber: string
    - adminUsers: [userId] (array of admin user IDs)
    - settings: {
        maxDeviceResetsPerMonth: number (default: 1)
        maxCheckInsPerProjectPerDay: number (default: 2)
        requireCheckOutBeforeNewCheckIn: boolean (default: true)
        autoApproveEmployees: boolean (default: false)
      }
    - createdAt: timestamp
    
    supervisors/ (subcollection)
      {supervisorId}/
        - userId: string
        - name: string
        - email: string
        - assignedAt: timestamp
        - assignedBy: userId (admin)
        - isActive: boolean

notifications/
  {notificationId}/
    - recipientId: userId
    - senderId: userId | 'system'
    - type: 'check_in_reminder' | 'device_reset_request' | 'device_reset_approved' | 'employee_approved' | 'message'
    - title: string
    - message: string
    - isRead: boolean
    - createdAt: timestamp
    - relatedEntityId: string | null (projectId, requestId, etc.)

auditLogs/
  {logId}/
    - userId: userId (who performed action)
    - action: 'create_project' | 'approve_employee' | 'reset_device' | 'assign_supervisor' | etc.
    - entityType: 'user' | 'project' | 'attendance' | 'device'
    - entityId: string
    - details: map (action-specific details)
    - timestamp: timestamp
    - ipAddress: string | null
    - platform: 'mobile' | 'web'

systemSettings/
  global/
    - employeeIdCounter: number (for auto-generating IDs)
    - companyName: string
    - timezone: string
    - workingHoursStart: string ('09:00')
    - workingHoursEnd: string ('17:00')
    - updatedBy: userId
    - updatedAt: timestamp
```

---

## 🎨 Three User Roles

### 1️⃣ **Employee** (Mobile Only)
- Login with Employee ID (system or custom)
- Device binding on first login
- Check-in/out to assigned projects
- View attendance history
- View profile
- Request device reset

### 2️⃣ **Supervisor** (Mobile Only)
- Login with email/password
- View assigned employees
- Add new employees (pending approval)
- Assign employees to projects (if admin-approved)
- Upload employee documents
- Manual check-in for employees
- View reports

### 3️⃣ **Admin/Employer** (Web Only)
- Full system access
- Create & manage projects
- Assign supervisors
- Approve/reject employees
- Assign custom IDs
- Approve device resets
- View all reports
- System settings
- Audit logs

---

## 🚀 Implementation Strategy

### **Option 1: Flutter for Both (Recommended)**
**Pros:**
- Single codebase
- Shared business logic
- Shared models and services
- Consistent UI/UX

**Implementation:**
```
straights_psyroll/
├── lib/
│   ├── mobile/        # Mobile-specific screens
│   ├── web/           # Web-specific screens
│   ├── shared/        # Shared code (models, services, providers)
│   └── main.dart      # Platform detection
```

### **Option 2: Separate Projects**
**Pros:**
- Optimized for each platform
- Independent deployment
- Better web performance

**Cons:**
- Duplicate code
- More maintenance
- Separate deployments

**Recommendation: Option 1** (Flutter for both with platform detection)

---

## 📱 Updated Mobile App Structure

### Employee Screens (Mobile)
1. Employee Login Screen
2. First-Time Setup (Device Binding + PIN)
3. Employee Dashboard
4. Check-In Screen (Multi-modal)
5. Attendance History
6. Employee Profile
7. Device Reset Request
8. Notifications

### Supervisor Screens (Mobile)
1. Supervisor Login Screen
2. Supervisor Dashboard
3. Employee Management
4. Add Employee (creates pending)
5. Project Assignments
6. Document Upload
7. Manual Check-In
8. Reports (view only)

---

## 💻 New Web Dashboard Structure

### Admin/Employer Screens (Web)
1. **Login Screen**
   - Email/password
   - Admin authentication

2. **Dashboard**
   - Overview stats
   - Pending approvals
   - Recent activity
   - Quick actions

3. **Project Management**
   - Create new project
   - Edit project details
   - Configure check-in methods
   - Set location & radius
   - Assign supervisor
   - View project attendance

4. **Employee Management**
   - Pending employees (approve/reject)
   - Approved employees list
   - Assign custom IDs
   - View employee details
   - Suspend/activate employees
   - View employee attendance

5. **Supervisor Management**
   - Add supervisor
   - Assign to projects
   - View supervisor activity
   - Activate/deactivate

6. **Device Management**
   - Device reset requests
   - Approve/reject resets
   - View device history
   - Suspicious activity alerts

7. **Reports & Analytics**
   - Generate reports (PDF/CSV)
   - Date range selection
   - Filter by project/employee/supervisor
   - Export bulk data
   - Charts and graphs

8. **System Settings**
   - Company settings
   - Check-in rules
   - Device reset limits
   - Working hours
   - Notification preferences

9. **Audit Logs**
   - View all system actions
   - Filter by user/action/date
   - Export logs

10. **Notifications**
    - System notifications
    - Pending actions
    - Alerts

---

## 🔐 Updated Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function getUserData() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data;
    }
    
    function getUserRole() {
      return getUserData().role;
    }
    
    function isEmployee() {
      return getUserRole() == 'employee';
    }
    
    function isSupervisor() {
      return getUserRole() == 'supervisor';
    }
    
    function isAdmin() {
      return getUserRole() == 'admin';
    }
    
    function isAdminOrSupervisor() {
      return isAdmin() || isSupervisor();
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if isAuthenticated() && 
                    (request.auth.uid == userId || isAdminOrSupervisor());
      allow create: if isAuthenticated() && isAdminOrSupervisor();
      allow update: if isAuthenticated() && 
                      (request.auth.uid == userId || isAdmin());
      
      // Device reset requests
      match /deviceResetRequests/{requestId} {
        allow create: if isAuthenticated() && request.auth.uid == userId;
        allow read: if isAuthenticated() && 
                      (request.auth.uid == userId || isAdmin());
        allow update: if isAuthenticated() && isAdmin();
      }
      
      // Documents
      match /documents/{docId} {
        allow read: if isAuthenticated() && 
                      (request.auth.uid == userId || isAdminOrSupervisor());
        allow write: if isAuthenticated() && isAdminOrSupervisor();
      }
      
      // Attendance
      match /attendance/{attendanceId} {
        allow create: if isAuthenticated() && 
                        (request.auth.uid == userId || isAdminOrSupervisor());
        allow read: if isAuthenticated() && 
                      (request.auth.uid == userId || isAdminOrSupervisor());
        allow update: if isAuthenticated() && 
                        (request.auth.uid == userId || isAdminOrSupervisor());
      }
    }
    
    // Projects
    match /projects/{projectId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() && isAdmin();
      
      match /assignedEmployees/{employeeId} {
        allow read: if isAuthenticated();
        allow write: if isAuthenticated() && isAdminOrSupervisor();
      }
    }
    
    // Employers
    match /employers/{employerId} {
      allow read: if isAuthenticated() && isAdmin();
      allow write: if isAuthenticated() && isAdmin();
      
      match /supervisors/{supervisorId} {
        allow read: if isAuthenticated();
        allow write: if isAuthenticated() && isAdmin();
      }
    }
    
    // Notifications
    match /notifications/{notifId} {
      allow read: if isAuthenticated() && 
                    resource.data.recipientId == request.auth.uid;
      allow create: if isAuthenticated();
      allow update: if isAuthenticated() && 
                      resource.data.recipientId == request.auth.uid;
    }
    
    // Audit Logs
    match /auditLogs/{logId} {
      allow read: if isAuthenticated() && isAdmin();
      allow create: if isAuthenticated();
    }
    
    // System Settings
    match /systemSettings/{docId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() && isAdmin();
    }
  }
}
```

---

## 📊 Updated Implementation Phases

### **Phase 1: Foundation** (Days 1-3)
- Day 1: Database structure + security rules
- Day 2: Models + services (shared)
- Day 3: Platform detection + routing

### **Phase 2: Mobile - Employee** (Days 4-6)
- Day 4: Employee login + device binding
- Day 5: Check-in system (GPS, NFC, QR)
- Day 6: Attendance + profile

### **Phase 3: Mobile - Supervisor** (Days 7-9)
- Day 7: Supervisor login + dashboard
- Day 8: Employee management (add pending)
- Day 9: Manual check-in + documents

### **Phase 4: Web - Admin Dashboard** (Days 10-14)
- Day 10: Admin login + dashboard
- Day 11: Project management
- Day 12: Employee approval + custom IDs
- Day 13: Device reset approvals
- Day 14: Reports + analytics

### **Phase 5: Advanced Features** (Days 15-17)
- Day 15: Notifications system
- Day 16: Offline support (mobile)
- Day 17: Audit logs + system settings

### **Phase 6: Testing & Polish** (Days 18-20)
- Day 18: Integration testing
- Day 19: UI/UX polish
- Day 20: Deployment + documentation

**Total: 20 working days** (was 15, +5 for web dashboard)

---

## 🔄 Employee Workflow

### 1. **Supervisor Creates Employee** (Mobile)
```
Supervisor → Add Employee Form → Submit
└─> Creates user with status: 'pending'
└─> Sends notification to Admin
```

### 2. **Admin Approves Employee** (Web)
```
Admin → Pending Employees → Review
└─> Approve button
    ├─> Assign custom ID (optional)
    ├─> Confirm project assignments
    └─> Status: 'pending' → 'approved'
└─> System sends employee credentials
```

### 3. **Employee First Login** (Mobile)
```
Employee → Enter ID (0001 or EMP123)
└─> First time? → Device Binding
    ├─> Capture device info
    ├─> Create PIN (6-digit)
    ├─> Confirm PIN
    └─> Optional: Enable biometric
└─> Dashboard
```

### 4. **Employee Check-In** (Mobile)
```
Employee → Select Project → Choose Method
├─> GPS: Verify within radius
├─> NFC: Tap tag
└─> QR: Scan code
└─> Check session count (max 2/day)
└─> Verify checked out from other projects
└─> Create attendance record
```

### 5. **Device Reset** (Mobile → Web → Mobile)
```
Employee → Request Device Reset → Submit Reason
└─> Creates request with status: 'pending'
└─> Notification to Admin

Admin → Device Reset Requests → Review
└─> Approve/Reject
└─> If approved: Clear device binding
└─> Notification to Employee

Employee → Login on new device
└─> Bind new device
└─> Continue work
```

---

## 🎯 Check-In Logic (Detailed)

### Rules Implementation:

```dart
class CheckInValidator {
  // Rule 1: Must be assigned to project
  Future<bool> isAssignedToProject(String userId, String projectId) async {
    final assignment = await firestore
      .collection('projects')
      .doc(projectId)
      .collection('assignedEmployees')
      .doc(userId)
      .get();
    
    return assignment.exists && assignment.data()?['isActive'] == true;
  }
  
  // Rule 2: Check if already checked in to another project
  Future<String?> getCurrentCheckedInProject(String userId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    
    final snapshot = await firestore
      .collection('users')
      .doc(userId)
      .collection('attendance')
      .where('checkInTime', isGreaterThanOrEqualTo: startOfDay)
      .where('status', isEqualTo: 'checked_in')
      .get();
    
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.data()['projectId'];
    }
    return null;
  }
  
  // Rule 3: Check session count for today
  Future<int> getTodayCheckInCount(String userId, String projectId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    
    final snapshot = await firestore
      .collection('users')
      .doc(userId)
      .collection('attendance')
      .where('projectId', isEqualTo: projectId)
      .where('checkInTime', isGreaterThanOrEqualTo: startOfDay)
      .get();
    
    return snapshot.docs.length;
  }
  
  // Main validation
  Future<CheckInValidationResult> validateCheckIn(
    String userId,
    String projectId,
    int maxCheckInsPerDay,
  ) async {
    // Check 1: Assigned to project?
    if (!await isAssignedToProject(userId, projectId)) {
      return CheckInValidationResult(
        isValid: false,
        error: 'You are not assigned to this project',
      );
    }
    
    // Check 2: Already checked in elsewhere?
    final currentProject = await getCurrentCheckedInProject(userId);
    if (currentProject != null && currentProject != projectId) {
      return CheckInValidationResult(
        isValid: false,
        error: 'Please check out from current project first',
      );
    }
    
    // Check 3: Exceeded max check-ins?
    final todayCount = await getTodayCheckInCount(userId, projectId);
    if (todayCount >= maxCheckInsPerDay) {
      return CheckInValidationResult(
        isValid: false,
        error: 'Maximum check-ins reached for today ($maxCheckInsPerDay)',
      );
    }
    
    return CheckInValidationResult(isValid: true);
  }
}
```

---

## 📦 Additional Packages for Web

```yaml
dependencies:
  # Web-specific
  flutter_web_plugins:
    sdk: flutter
  
  # Responsive design
  responsive_framework: ^1.1.1
  
  # Web routing
  go_router: ^13.0.0
  
  # Web file download
  universal_html: ^2.2.4
  
  # Charts for admin dashboard
  fl_chart: ^0.66.0
  syncfusion_flutter_charts: ^24.2.3  # Or fl_chart
  
  # Data tables
  data_table_2: ^2.5.9
  
  # Date pickers
  flutter_datetime_picker: ^1.5.1
```

---

## 🌐 Platform Detection

```dart
// main.dart
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  runApp(
    ProviderScope(
      child: kIsWeb ? WebApp() : MobileApp(),
    ),
  );
}

class MobileApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Employee App',
      home: MobileLoginRouter(),
    );
  }
}

class WebApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Dashboard',
      home: WebAdminLogin(),
    );
  }
}
```

---

## ✅ Updated Success Criteria

### Mobile - Employee
- ✅ Login with system or custom ID
- ✅ Device binding on first login
- ✅ Check-in to assigned projects only
- ✅ Max 2 check-ins per project per day
- ✅ Must check-out before new project check-in
- ✅ Request device reset

### Mobile - Supervisor
- ✅ Add employees (pending status)
- ✅ Assign to projects
- ✅ Upload documents
- ✅ Manual check-in
- ✅ View reports

### Web - Admin
- ✅ Approve/reject pending employees
- ✅ Assign custom IDs
- ✅ Create & manage projects
- ✅ Assign supervisors
- ✅ Approve device resets (1/month limit)
- ✅ Generate PDF/CSV reports
- ✅ View audit logs
- ✅ System settings

---

## 🚦 Ready to Start?

**Confirmed Implementation:**
- ✅ 3 roles: Employee (mobile), Supervisor (mobile), Admin (web)
- ✅ Flutter for both mobile + web
- ✅ Start fresh database
- ✅ 20-day timeline
- ✅ All rules clarified

**Next Step: Phase 1 - Foundation** (Days 1-3)

---

**Shall I begin implementation?** 🚀

