# 🏗️ New App Architecture & Implementation Plan

## 📋 Overview

Complete restructuring of the Employee Management app with:
- **Role-based access** (Employee vs Supervisor)
- **Multiple authentication methods** (ID-based + optional biometric)
- **Device binding** for security
- **Multi-modal check-in** (GPS, NFC, QR, Manual)
- **Project management** system
- **Advanced document handling**

---

## 🎯 Core Changes from Current App

### Current App
- ❌ Biometric-first authentication
- ❌ No role system
- ❌ Simple GPS check-in only
- ❌ Basic document upload
- ❌ No project management

### New App
- ✅ ID-based authentication (biometric optional)
- ✅ Employee + Supervisor roles
- ✅ GPS + NFC + QR + Manual check-in
- ✅ Advanced document management
- ✅ Full project management system
- ✅ Device binding security

---

## 🗂️ New Database Structure

```
Firestore Hierarchy:

users/
  {userId}/
    - role: 'employee' | 'supervisor'
    - employeeId: '0001' | 'EMP123'
    - name: string
    - email: string
    - phoneNumber: string
    - supervisorId: string (for employees)
    - deviceInfo: {
        deviceId: string
        deviceModel: string
        registeredAt: timestamp
        isActive: boolean
      }
    - biometricEnabled: boolean
    - createdAt: timestamp
    - updatedAt: timestamp
    
    documents/ (subcollection)
      {docId}/
        - type: 'id_proof' | 'bank_statement' | 'other'
        - name: string
        - url: string
        - uploadedBy: userId (supervisor)
        - uploadedAt: timestamp
    
    attendance/ (subcollection)
      {attendanceId}/
        - projectId: string
        - checkInTime: timestamp
        - checkOutTime: timestamp | null
        - checkInMethod: 'gps' | 'nfc' | 'qr' | 'manual'
        - checkInLocation: { lat, lng, address }
        - checkOutLocation: { lat, lng, address } | null
        - verifiedBy: userId | null (if manual)
        - workingHours: number
        - status: 'checked_in' | 'checked_out'

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
        radius: number (in meters, e.g., 200)
      }
    - checkInMethods: ['gps', 'nfc', 'qr', 'manual']
    - nfcTagId: string | null
    - qrCode: string | null
    - isActive: boolean
    - createdAt: timestamp
    
    assignedEmployees/ (subcollection)
      {employeeId}/
        - userId: string
        - name: string
        - assignedAt: timestamp
        - assignedBy: userId (supervisor)

employers/
  {employerId}/
    - companyName: string
    - email: string
    - phoneNumber: string
    - createdAt: timestamp
    
    supervisors/ (subcollection)
      {supervisorId}/
        - userId: string
        - name: string
        - assignedAt: timestamp

notifications/
  {notificationId}/
    - recipientId: userId
    - senderId: userId
    - type: 'message' | 'check_in_request' | 'device_reset'
    - title: string
    - message: string
    - isRead: boolean
    - createdAt: timestamp
```

---

## 🔐 Authentication Flow Changes

### Current Flow
```
App Launch → Biometric Login → Profile Check → Dashboard
```

### New Flow

#### **Employee Login**
```
1. Login Screen
   ↓
2. Enter Employee ID (0001 or EMP123)
   ↓
3. First-time user?
   YES → Device Binding Setup
         → Create PIN/Password
         → Optional: Enable Biometric
   NO  → Enter PIN/Password (or use biometric if enabled)
   ↓
4. Verify Device Match
   ↓
5. Employee Dashboard
```

#### **Supervisor Login**
```
1. Login Screen
   ↓
2. Enter Email/Username & Password
   ↓
3. Optional: Biometric (if previously enabled)
   ↓
4. Supervisor Dashboard
```

---

## 📱 New Screen Structure

### Employee Screens
1. **LoginScreen** (ID-based)
2. **FirstTimeSetupScreen** (device binding + PIN)
3. **EmployeeDashboardScreen**
4. **CheckInScreen** (multi-modal)
5. **AttendanceHistoryScreen**
6. **ProfileScreen**
7. **NotificationsScreen**

### Supervisor Screens
1. **SupervisorLoginScreen**
2. **SupervisorDashboardScreen**
3. **EmployeeManagementScreen**
   - Add Employee
   - View/Edit Employee
   - Assign to Project
   - Reset Device
4. **ProjectManagementScreen**
   - View Projects
   - Manage Employee Assignments
   - Configure Check-in Methods
5. **DocumentManagementScreen**
   - Upload Documents
   - View Documents
   - Delete/Replace
6. **AttendanceMonitoringScreen**
   - View All Employee Attendance
   - Manual Check-in/out
7. **ReportsScreen**
   - Generate Reports
   - Export CSV/PDF

---

## 🎨 New Features Breakdown

### 1. Device Binding

**Implementation:**
```dart
// Get device info
import 'package:device_info_plus/device_info_plus.dart';
import 'package:platform_device_id/platform_device_id.dart';

Future<DeviceInfo> getDeviceInfo() async {
  final deviceInfo = DeviceInfoPlugin();
  final deviceId = await PlatformDeviceId.getDeviceId;
  
  if (Platform.isAndroid) {
    final androidInfo = await deviceInfo.androidInfo;
    return DeviceInfo(
      deviceId: deviceId,
      model: androidInfo.model,
      brand: androidInfo.brand,
    );
  } else {
    final iosInfo = await deviceInfo.iosInfo;
    return DeviceInfo(
      deviceId: deviceId,
      model: iosInfo.model,
      brand: 'Apple',
    );
  }
}

// Verify device on login
Future<bool> verifyDevice(String userId, String deviceId) async {
  final user = await firestore.collection('users').doc(userId).get();
  final registeredDeviceId = user.data()?['deviceInfo']['deviceId'];
  
  return registeredDeviceId == deviceId;
}
```

### 2. GPS Check-in

**Implementation:**
```dart
// Check if within project radius
Future<bool> isWithinProjectRadius(
  double userLat,
  double userLng,
  double projectLat,
  double projectLng,
  double radiusMeters,
) async {
  final distance = Geolocator.distanceBetween(
    userLat, userLng, projectLat, projectLng,
  );
  
  return distance <= radiusMeters;
}
```

### 3. NFC Check-in

**New Package:**
```yaml
dependencies:
  nfc_manager: ^3.3.0
```

**Implementation:**
```dart
import 'package:nfc_manager/nfc_manager.dart';

Future<String?> readNfcTag() async {
  String? tagId;
  
  await NfcManager.instance.startSession(
    onDiscovered: (NfcTag tag) async {
      tagId = tag.data['ndef']?['identifier'];
      await NfcManager.instance.stopSession();
    },
  );
  
  return tagId;
}
```

### 4. QR Code Check-in

**New Package:**
```yaml
dependencies:
  qr_code_scanner: ^1.0.1
  qr_flutter: ^4.1.0  # For generating QR codes
```

**Implementation:**
```dart
import 'package:qr_code_scanner/qr_code_scanner.dart';

// Scan QR code
Future<String?> scanQrCode(BuildContext context) async {
  // Show QR scanner screen
  final result = await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => QrScannerScreen()),
  );
  
  return result; // Returns project QR code
}

// Generate QR code (supervisor)
String generateProjectQrCode(String projectId) {
  return 'PROJECT:$projectId:${DateTime.now().millisecondsSinceEpoch}';
}
```

### 5. Offline Support

**New Packages:**
```yaml
dependencies:
  connectivity_plus: ^4.0.0
  hive: ^2.2.3
  hive_flutter: ^1.1.0
```

**Implementation:**
```dart
// Store offline check-ins
await Hive.box('offline_checkins').add({
  'userId': userId,
  'projectId': projectId,
  'checkInTime': DateTime.now().toIso8601String(),
  'location': {'lat': lat, 'lng': lng},
  'method': 'gps',
});

// Sync when online
void syncOfflineData() async {
  final box = Hive.box('offline_checkins');
  for (var i = 0; i < box.length; i++) {
    final data = box.getAt(i);
    await firestoreService.createAttendance(data);
    await box.deleteAt(i);
  }
}
```

---

## 📦 New Packages Required

### Essential Packages

```yaml
dependencies:
  # Existing
  flutter_riverpod: ^2.5.1
  firebase_core: ^2.24.2
  firebase_auth: ^4.16.0
  cloud_firestore: ^4.14.0
  firebase_storage: ^11.5.6
  
  # New for this implementation
  device_info_plus: ^9.1.1          # Device info
  platform_device_id: ^1.0.1        # Unique device ID
  nfc_manager: ^3.3.0               # NFC reading
  qr_code_scanner: ^1.0.1           # QR scanning
  qr_flutter: ^4.1.0                # QR generation
  connectivity_plus: ^4.0.0         # Network status
  hive: ^2.2.3                      # Offline storage
  hive_flutter: ^1.1.0              # Hive Flutter integration
  
  # Already have (keep)
  geolocator: ^10.1.0
  geocoding: ^2.1.1
  image_picker: ^1.0.5
  file_picker: ^6.1.1
  url_launcher: ^6.2.2
  local_auth: ^2.1.8
  flutter_secure_storage: ^9.0.0
  
  # New UI/UX
  flutter_map: ^6.1.0               # Map display
  latlong2: ^0.9.0                  # Lat/Lng handling
  pin_code_fields: ^8.0.1           # PIN input
  pdf: ^3.10.7                      # PDF generation
  csv: ^6.0.0                       # CSV export
  path_provider: ^2.1.1             # File paths
  share_plus: ^7.2.1                # Share reports
```

---

## 🚀 Implementation Phases

### Phase 1: Foundation (Days 1-2)
- ✅ New database structure in Firestore
- ✅ Update security rules for roles
- ✅ Create new models (User, Project, Attendance, etc.)
- ✅ Setup device binding service
- ✅ Create role-based routing

### Phase 2: Authentication (Days 3-4)
- ✅ New login screens (Employee & Supervisor)
- ✅ ID-based authentication
- ✅ Device verification
- ✅ First-time setup flow
- ✅ Optional biometric setup

### Phase 3: Employee Features (Days 5-7)
- ✅ Employee Dashboard
- ✅ GPS check-in implementation
- ✅ NFC check-in implementation
- ✅ QR check-in implementation
- ✅ Attendance history
- ✅ Profile management

### Phase 4: Supervisor Features (Days 8-10)
- ✅ Supervisor Dashboard
- ✅ Employee management (CRUD)
- ✅ Project management
- ✅ Document upload/management
- ✅ Manual check-in for employees

### Phase 5: Advanced Features (Days 11-13)
- ✅ Notifications system
- ✅ Offline support
- ✅ Reports generation (PDF/CSV)
- ✅ Device reset functionality
- ✅ Map visualization

### Phase 6: Testing & Polish (Days 14-15)
- ✅ Integration testing
- ✅ UI/UX polish
- ✅ Bug fixes
- ✅ Performance optimization
- ✅ Documentation

---

## 🔒 Security Considerations

### 1. Role-Based Access
```dart
// Firestore Security Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function getUserRole() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role;
    }
    
    function isEmployee() {
      return getUserRole() == 'employee';
    }
    
    function isSupervisor() {
      return getUserRole() == 'supervisor';
    }
    
    // Users collection
    match /users/{userId} {
      // Users can read their own data
      allow read: if isAuthenticated() && request.auth.uid == userId;
      
      // Supervisors can read employee data
      allow read: if isAuthenticated() && isSupervisor();
      
      // Only supervisors can create/update users
      allow create, update: if isAuthenticated() && isSupervisor();
      
      // User documents
      match /documents/{docId} {
        allow read: if isAuthenticated() && 
                      (request.auth.uid == userId || isSupervisor());
        allow write: if isAuthenticated() && isSupervisor();
      }
      
      // User attendance
      match /attendance/{attendanceId} {
        allow read: if isAuthenticated() && 
                      (request.auth.uid == userId || isSupervisor());
        allow create: if isAuthenticated() && request.auth.uid == userId;
        allow update: if isAuthenticated() && 
                       (request.auth.uid == userId || isSupervisor());
      }
    }
    
    // Projects collection
    match /projects/{projectId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() && isSupervisor();
      
      match /assignedEmployees/{employeeId} {
        allow read: if isAuthenticated();
        allow write: if isAuthenticated() && isSupervisor();
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
  }
}
```

### 2. Device Binding Verification
- First login binds device ID to user account
- All subsequent logins verify device ID match
- Supervisor can reset device binding
- Alert sent to supervisor on device mismatch attempt

### 3. Check-in Verification
- GPS: Verify location within project radius
- NFC: Verify NFC tag ID matches project
- QR: Verify QR code is valid and current (timestamp check)
- Manual: Verify supervisor authorization

---

## 📊 Data Models

### User Model
```dart
class UserModel {
  final String uid;
  final String role; // 'employee' | 'supervisor'
  final String? employeeId; // '0001' | 'EMP123'
  final String name;
  final String email;
  final String? phoneNumber;
  final String? supervisorId;
  final DeviceInfo? deviceInfo;
  final bool biometricEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class DeviceInfo {
  final String deviceId;
  final String deviceModel;
  final String? brand;
  final DateTime registeredAt;
  final bool isActive;
}
```

### Project Model
```dart
class ProjectModel {
  final String projectId;
  final String name;
  final String description;
  final String employerId;
  final String supervisorId;
  final ProjectLocation location;
  final List<String> checkInMethods; // ['gps', 'nfc', 'qr', 'manual']
  final String? nfcTagId;
  final String? qrCode;
  final bool isActive;
  final DateTime createdAt;
}

class ProjectLocation {
  final double lat;
  final double lng;
  final String address;
  final double radius; // in meters
}
```

### Attendance Model
```dart
class AttendanceModel {
  final String attendanceId;
  final String userId;
  final String projectId;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String checkInMethod; // 'gps' | 'nfc' | 'qr' | 'manual'
  final LocationData checkInLocation;
  final LocationData? checkOutLocation;
  final String? verifiedBy; // supervisor userId if manual
  final double? workingHours;
  final String status; // 'checked_in' | 'checked_out'
}

class LocationData {
  final double lat;
  final double lng;
  final String address;
}
```

---

## 🎯 Key Differences from Current App

| Feature | Current App | New App |
|---------|-------------|---------|
| **Auth Method** | Biometric-first | ID + PIN/Password (biometric optional) |
| **Roles** | None | Employee & Supervisor |
| **Device Security** | None | Device binding required |
| **Check-in Methods** | GPS only | GPS + NFC + QR + Manual |
| **Project Management** | None | Full project system |
| **Document Management** | Basic upload | Supervisor-managed with types |
| **Offline Support** | None | Offline check-in queue |
| **Reports** | None | PDF/CSV export |
| **Employee Management** | None | Supervisor can add/edit employees |

---

## ⚠️ Breaking Changes

### What Gets Removed/Changed:
1. ❌ **Biometric-first flow** → Changed to ID-based
2. ❌ **Auto-create account** → Supervisor creates employees
3. ❌ **Current user model** → Completely new structure
4. ❌ **Current attendance model** → New with project linking
5. ❌ **Simple document upload** → New document management
6. ❌ **Current dashboard** → Role-specific dashboards

### Migration Required:
- Existing users need to be re-created with new structure
- Old attendance data needs project assignment
- Documents need to be re-categorized
- **Recommendation: Start fresh database for new version**

---

## 📝 Next Steps

### Before Implementation:
1. ✅ **Review this architecture document**
2. ✅ **Confirm requirements and priorities**
3. ✅ **Decide on implementation approach:**
   - Option A: Complete rewrite (recommended)
   - Option B: Gradual migration (complex)
4. ✅ **Set up new Firebase project** (or clean current one)
5. ✅ **Install new packages**

### Implementation Order:
1. **Phase 1**: Database & Models
2. **Phase 2**: Authentication
3. **Phase 3**: Employee Features
4. **Phase 4**: Supervisor Features
5. **Phase 5**: Advanced Features
6. **Phase 6**: Testing & Polish

---

## ❓ Questions to Clarify

1. **Employer Access**:
   - Will employers have their own dashboard?
   - Or is employer just a data entity managed by admin?

2. **Device Reset**:
   - Should employee be able to request device reset?
   - Or only supervisor can initiate?

3. **Check-in Flexibility**:
   - Can projects have multiple check-in methods active?
   - Or one primary method per project?

4. **Offline Limits**:
   - How many offline check-ins to queue before forcing sync?
   - Should check-out also work offline?

5. **Reports**:
   - What specific data in reports?
   - Daily, weekly, monthly, or custom date range?

6. **Notifications**:
   - Push notifications (FCM) or in-app only?
   - What events trigger notifications?

---

## ✅ Confirmation Needed

Before I start implementation, please confirm:

- [ ] Architecture approved
- [ ] Role definitions clear
- [ ] Database structure acceptable
- [ ] Feature priorities set
- [ ] Timeline expectations realistic
- [ ] Questions above answered

**Estimated Total Time**: 12-15 days for full implementation

---

*This is a complete architectural redesign. Let's discuss any changes needed before starting!*

