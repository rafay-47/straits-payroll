# 🌐 Platform Detection - One Project, Multiple Platforms

## ✅ YES! You Can Have ALL in One Flutter Project

### **What You Get:**

```
┌────────────────────────────────────────┐
│   SINGLE FLUTTER PROJECT               │
├────────────────────────────────────────┤
│                                        │
│  📱 MOBILE APP                         │
│     ├─ Android APK                     │
│     └─ iOS IPA                         │
│        ├─ Employee Login & Features    │
│        └─ Supervisor Login & Features  │
│                                        │
│  💻 WEB DASHBOARD                      │
│     └─ Web App (browser)               │
│        └─ Admin Login & Features       │
│                                        │
│  🔧 SHARED CODE                        │
│     ├─ Models                          │
│     ├─ Services                        │
│     ├─ Providers                       │
│     └─ Business Logic                  │
│                                        │
└────────────────────────────────────────┘
```

---

## 🎯 **Platform Detection Logic**

### **main.dart (Entry Point)**

```dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

// Import platform-specific apps
import 'mobile/mobile_app.dart';
import 'web/web_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: kIsWeb
        ? FirebaseOptions(
            // Web config
            apiKey: "your-web-api-key",
            projectId: "your-project-id",
            // ... other web config
          )
        : null, // Mobile uses google-services.json/plist
  );
  
  runApp(
    ProviderScope(
      child: kIsWeb ? WebApp() : MobileApp(),
    ),
  );
}
```

**How it works:**
- `kIsWeb` is a Flutter constant
- `true` when running on web
- `false` when running on mobile
- Automatically routes to correct app!

---

## 📱 **Mobile App (Employee + Supervisor)**

### **lib/mobile/mobile_app.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/auth/role_selection_screen.dart';

class MobileApp extends ConsumerWidget {
  const MobileApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Employee App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: RoleSelectionScreen(), // Employee or Supervisor
    );
  }
}
```

### **Role Selection on Mobile**

```dart
// lib/mobile/screens/auth/role_selection_screen.dart

class RoleSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Select Your Role', style: TextStyle(fontSize: 24)),
            SizedBox(height: 40),
            
            // Employee Button
            ElevatedButton.icon(
              icon: Icon(Icons.person),
              label: Text('Employee Login'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EmployeeLoginScreen(),
                  ),
                );
              },
            ),
            
            SizedBox(height: 20),
            
            // Supervisor Button
            ElevatedButton.icon(
              icon: Icon(Icons.supervisor_account),
              label: Text('Supervisor Login'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SupervisorLoginScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 💻 **Web Dashboard (Admin Only)**

### **lib/web/web_app.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'screens/auth/admin_login_screen.dart';

class WebApp extends ConsumerWidget {
  const WebApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Admin Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      builder: (context, child) => ResponsiveWrapper.builder(
        child,
        maxWidth: 1920,
        minWidth: 450,
        defaultScale: true,
        breakpoints: [
          ResponsiveBreakpoint.resize(450, name: MOBILE),
          ResponsiveBreakpoint.autoScale(800, name: TABLET),
          ResponsiveBreakpoint.resize(1000, name: DESKTOP),
        ],
      ),
      home: AdminLoginScreen(), // Admin only
    );
  }
}
```

---

## 🗂️ **Complete File Structure**

```
straights_psyroll/
├── lib/
│   ├── main.dart                       # 🎯 Platform detection entry
│   │
│   ├── shared/                         # 📦 Shared across all platforms
│   │   ├── models/
│   │   │   ├── user_model.dart
│   │   │   ├── project_model.dart
│   │   │   ├── attendance_model.dart
│   │   │   └── document_model.dart
│   │   │
│   │   ├── services/
│   │   │   ├── auth_service.dart       # Used by mobile & web
│   │   │   ├── firestore_service.dart  # Used by mobile & web
│   │   │   ├── device_service.dart     # Mobile only
│   │   │   ├── location_service.dart   # Mobile only
│   │   │   ├── nfc_service.dart        # Mobile only
│   │   │   └── qr_service.dart         # Mobile only
│   │   │
│   │   ├── providers/
│   │   │   ├── auth_provider.dart
│   │   │   ├── user_provider.dart
│   │   │   ├── project_provider.dart
│   │   │   └── attendance_provider.dart
│   │   │
│   │   ├── constants/
│   │   │   ├── app_colors.dart
│   │   │   └── app_strings.dart
│   │   │
│   │   └── widgets/                    # Shared widgets
│   │       ├── custom_button.dart
│   │       ├── custom_text_field.dart
│   │       └── loading_widget.dart
│   │
│   ├── mobile/                         # 📱 Mobile-specific code
│   │   ├── mobile_app.dart             # Mobile app entry
│   │   │
│   │   ├── screens/
│   │   │   ├── auth/
│   │   │   │   ├── role_selection_screen.dart
│   │   │   │   ├── employee_login_screen.dart
│   │   │   │   ├── supervisor_login_screen.dart
│   │   │   │   └── first_time_setup_screen.dart
│   │   │   │
│   │   │   ├── employee/
│   │   │   │   ├── employee_dashboard_screen.dart
│   │   │   │   ├── check_in_screen.dart
│   │   │   │   ├── attendance_history_screen.dart
│   │   │   │   └── employee_profile_screen.dart
│   │   │   │
│   │   │   ├── supervisor/
│   │   │   │   ├── supervisor_dashboard_screen.dart
│   │   │   │   ├── add_employee_screen.dart
│   │   │   │   ├── employee_list_screen.dart
│   │   │   │   └── manual_checkin_screen.dart
│   │   │   │
│   │   │   └── common/
│   │   │       ├── qr_scanner_screen.dart
│   │   │       ├── nfc_reader_screen.dart
│   │   │       └── map_view_screen.dart
│   │   │
│   │   └── widgets/
│   │       ├── project_card.dart
│   │       └── attendance_card.dart
│   │
│   └── web/                            # 💻 Web-specific code
│       ├── web_app.dart                # Web app entry
│       │
│       ├── screens/
│       │   ├── auth/
│       │   │   └── admin_login_screen.dart
│       │   │
│       │   ├── dashboard/
│       │   │   └── admin_dashboard_screen.dart
│       │   │
│       │   ├── projects/
│       │   │   ├── project_list_screen.dart
│       │   │   ├── create_project_screen.dart
│       │   │   └── project_details_screen.dart
│       │   │
│       │   ├── employees/
│       │   │   ├── pending_employees_screen.dart
│       │   │   ├── all_employees_screen.dart
│       │   │   └── employee_details_screen.dart
│       │   │
│       │   ├── devices/
│       │   │   └── device_reset_approval_screen.dart
│       │   │
│       │   ├── reports/
│       │   │   ├── reports_screen.dart
│       │   │   └── analytics_screen.dart
│       │   │
│       │   └── settings/
│       │       ├── system_settings_screen.dart
│       │       └── audit_logs_screen.dart
│       │
│       └── widgets/
│           ├── sidebar_navigation.dart
│           ├── data_table_widget.dart
│           └── responsive_layout.dart
│
├── android/                            # Android build config
├── ios/                                # iOS build config
├── web/                                # Web build config
│   ├── index.html
│   └── manifest.json
│
└── pubspec.yaml                        # Single package file
```

---

## 🔧 **Platform-Specific Features**

### **Use Flutter's Platform Detection**

```dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class PlatformHelper {
  // Check if running on web
  static bool get isWeb => kIsWeb;
  
  // Check if running on mobile
  static bool get isMobile => !kIsWeb;
  
  // Check specific mobile platform
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  static bool get isIOS => !kIsWeb && Platform.isIOS;
  
  // Get platform name
  static String get platformName {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }
}
```

**Usage:**

```dart
// In any widget or service

if (PlatformHelper.isWeb) {
  // Web-specific code
  print('Running on web browser');
} else if (PlatformHelper.isMobile) {
  // Mobile-specific code
  print('Running on mobile');
  
  if (PlatformHelper.isAndroid) {
    // Android-specific
    print('Android device');
  } else if (PlatformHelper.isIOS) {
    // iOS-specific
    print('iOS device');
  }
}
```

---

## 🚀 **Build & Run Commands**

### **1. Run Mobile App (Employee + Supervisor)**

```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Specific device
flutter run -d <device_id>
```

**Result:** Mobile app with Employee + Supervisor roles

---

### **2. Run Web Dashboard (Admin)**

```bash
# Run on Chrome
flutter run -d chrome

# Run on any browser
flutter run -d web-server --web-port=8080
```

**Result:** Web dashboard for Admin only

**Access:** `http://localhost:8080`

---

### **3. Build for Production**

```bash
# Build Android APK
flutter build apk --release

# Build iOS IPA (requires Mac)
flutter build ios --release

# Build Web
flutter build web --release
```

---

## 📦 **Single pubspec.yaml for All Platforms**

```yaml
name: straights_psyroll
description: Employee Management System

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # Core packages (work on mobile + web)
  flutter_riverpod: ^2.5.1
  firebase_core: ^2.24.2
  firebase_auth: ^4.16.0
  cloud_firestore: ^4.14.0
  firebase_storage: ^11.5.6
  
  # Mobile-only packages (auto-disabled on web)
  device_info_plus: ^9.1.1
  platform_device_id: ^1.0.1
  nfc_manager: ^3.3.0
  qr_code_scanner: ^1.0.1
  geolocator: ^10.1.0
  geocoding: ^2.1.1
  local_auth: ^2.1.8
  
  # Web-specific packages
  flutter_web_plugins:
    sdk: flutter
  responsive_framework: ^1.1.1
  
  # Works on both
  qr_flutter: ^4.1.0
  image_picker: ^1.0.5
  file_picker: ^6.1.1
  pdf: ^3.10.7
  csv: ^6.0.0
  url_launcher: ^6.2.2
  intl: ^0.18.1
```

**Flutter automatically:**
- Ignores mobile-only packages when building for web
- Ignores web-only packages when building for mobile

---

## 🎯 **How Routing Works**

### **Flow Diagram:**

```
App Launch
    ↓
main.dart
    ↓
Check: kIsWeb?
    ├─ YES (Web Browser)
    │   ↓
    │   WebApp()
    │   ↓
    │   AdminLoginScreen
    │   ↓
    │   Admin Dashboard
    │
    └─ NO (Mobile Device)
        ↓
        MobileApp()
        ↓
        RoleSelectionScreen
        ├─ Employee Login
        │   ↓
        │   Employee Dashboard
        │
        └─ Supervisor Login
            ↓
            Supervisor Dashboard
```

---

## 🔐 **Role-Based Access Control**

### **Shared Auth Service (works on mobile + web)**

```dart
// lib/shared/services/auth_service.dart

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestore = FirestoreService();
  
  // Login (works on mobile + web)
  Future<UserModel?> login(String identifier, String password) async {
    try {
      // Determine if identifier is email or employee ID
      String email = identifier.contains('@') 
          ? identifier 
          : await _getEmailFromEmployeeId(identifier);
      
      // Sign in with Firebase
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Get user data from Firestore
      final user = await _firestore.getUserProfile(credential.user!.uid);
      
      return user;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }
  
  // Get current user role
  Future<String?> getUserRole() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;
    
    final user = await _firestore.getUserProfile(userId);
    return user?.role; // 'employee', 'supervisor', or 'admin'
  }
  
  // Check if user has permission
  bool hasPermission(String userRole, String requiredRole) {
    const roleHierarchy = {
      'admin': 3,
      'supervisor': 2,
      'employee': 1,
    };
    
    return (roleHierarchy[userRole] ?? 0) >= (roleHierarchy[requiredRole] ?? 0);
  }
}
```

---

## 🎨 **Conditional Features**

### **Example: Device Binding (Mobile Only)**

```dart
// lib/shared/services/device_service.dart

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:platform_device_id/platform_device_id.dart';

class DeviceService {
  // Get device info (mobile only)
  Future<DeviceInfo?> getDeviceInfo() async {
    // Skip on web
    if (kIsWeb) {
      return DeviceInfo(
        deviceId: 'web-device',
        model: 'Web Browser',
        brand: 'Browser',
      );
    }
    
    // Mobile implementation
    final deviceInfo = DeviceInfoPlugin();
    final deviceId = await PlatformDeviceId.getDeviceId;
    
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return DeviceInfo(
        deviceId: deviceId ?? 'unknown',
        model: androidInfo.model,
        brand: androidInfo.brand,
      );
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return DeviceInfo(
        deviceId: deviceId ?? 'unknown',
        model: iosInfo.model,
        brand: 'Apple',
      );
    }
    
    return null;
  }
  
  // Verify device (mobile only)
  Future<bool> verifyDevice(String userId) async {
    // Skip verification on web
    if (kIsWeb) return true;
    
    // Get current device
    final currentDevice = await getDeviceInfo();
    if (currentDevice == null) return false;
    
    // Get registered device from Firestore
    final user = await FirestoreService().getUserProfile(userId);
    final registeredDeviceId = user?.deviceInfo?.deviceId;
    
    // Compare
    return currentDevice.deviceId == registeredDeviceId;
  }
}
```

---

## 💡 **Best Practices**

### **1. Separate Business Logic from UI**

```dart
// ✅ GOOD: Logic in shared service
// lib/shared/services/attendance_service.dart
class AttendanceService {
  Future<bool> canCheckIn(String userId, String projectId) async {
    // Business logic (works on mobile + web)
    return true; // after validation
  }
}

// ❌ BAD: Logic in UI widget
// lib/mobile/screens/check_in_screen.dart
class CheckInScreen extends StatelessWidget {
  void checkIn() {
    // Don't put business logic here
  }
}
```

### **2. Use Responsive Design for Web**

```dart
// lib/web/widgets/responsive_layout.dart
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget desktop;
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) {
          return mobile; // Mobile layout
        } else {
          return desktop; // Desktop layout
        }
      },
    );
  }
}
```

### **3. Platform-Specific Services**

```dart
// lib/shared/services/location_service.dart
import 'package:flutter/foundation.dart' show kIsWeb;

class LocationService {
  Future<LocationData?> getCurrentLocation() async {
    if (kIsWeb) {
      // Web: Use browser geolocation API
      return _getWebLocation();
    } else {
      // Mobile: Use geolocator package
      return _getMobileLocation();
    }
  }
  
  Future<LocationData?> _getWebLocation() async {
    // Web implementation
    // Uses browser's navigator.geolocation
    return null;
  }
  
  Future<LocationData?> _getMobileLocation() async {
    // Mobile implementation
    final position = await Geolocator.getCurrentPosition();
    return LocationData(
      lat: position.latitude,
      lng: position.longitude,
    );
  }
}
```

---

## 🎯 **Development Workflow**

### **During Development:**

```bash
# Terminal 1: Run mobile app
flutter run -d android

# Terminal 2: Run web dashboard
flutter run -d chrome

# Both run simultaneously from SAME codebase!
```

### **Testing:**

```bash
# Test mobile
flutter test test/mobile/

# Test web
flutter test test/web/

# Test shared
flutter test test/shared/
```

---

## 📊 **Summary**

### ✅ **What You Get:**

| Platform | Users | Features |
|----------|-------|----------|
| **Mobile (Android)** | Employee + Supervisor | Login, Check-in, Attendance, Profile |
| **Mobile (iOS)** | Employee + Supervisor | Same as Android |
| **Web (Browser)** | Admin only | Approve employees, Projects, Reports, Settings |

### ✅ **Benefits:**

1. **Single Codebase** - Write once, deploy everywhere
2. **Shared Logic** - Models, services, providers used by all
3. **Platform-Specific UI** - Optimized for each platform
4. **Easy Maintenance** - Update once, affects all platforms
5. **Cost-Effective** - One team, one codebase
6. **Consistent** - Same business rules everywhere

### ✅ **Build Outputs:**

```
flutter build apk         → Android APK (Employee + Supervisor)
flutter build ios         → iOS IPA (Employee + Supervisor)
flutter build web         → Web App (Admin Dashboard)
```

---

## 🚀 **Ready to Build?**

**YES! You can have:**
- ✅ Mobile app with Employee + Supervisor roles
- ✅ Web dashboard with Admin role
- ✅ All in ONE Flutter project
- ✅ Shared codebase and logic
- ✅ Platform-specific features when needed

---

**This is the POWER of Flutter! 💪**

Ready to start implementation? Say "GO"! 🚀

