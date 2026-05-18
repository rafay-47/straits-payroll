# Biometric Login Flow Documentation

## Overview
This document describes the complete logic flow for biometric authentication in the mobile application, including user identification, profile verification, and navigation routing.

---

## Architecture Components

### Services
1. **BiometricService** (`lib/services/biometric_service.dart`)
   - Handles biometric authentication using `local_auth` package
   - Supports Face ID, Touch ID, and Fingerprint authentication
   - Provides device capability checks

2. **SecureStorageService** (`lib/services/secure_storage_service.dart`)
   - Manages secure credential storage using `flutter_secure_storage`
   - Stores user credentials (email, UID) encrypted on device
   - Provides biometric enrollment status

3. **AuthService** (`lib/services/auth_service.dart`)
   - Manages Firebase Authentication
   - Handles email/password sign-in and account creation
   - Provides auth state streams

4. **FirestoreService** (`lib/services/firestore_service.dart`)
   - Manages user profile data in Firestore
   - Checks profile completion status
   - Updates user information

### Providers
1. **BiometricAuthProvider** (`lib/providers/biometric_auth_provider.dart`)
   - Manages biometric authentication state
   - Orchestrates the biometric login flow
   - Handles UID verification and storage

2. **AuthProvider** (`lib/providers/auth_provider.dart`)
   - Manages Firebase auth state
   - Provides current user data
   - Handles profile state

### Screens
1. **BiometricLoginScreen** (`lib/screens/auth/biometric_login_screen.dart`)
   - First screen shown on app launch
   - Displays biometric authentication prompt
   - Provides fallback to email/password login

2. **LoginScreen** (`lib/screens/auth/login_screen.dart`)
   - Traditional email/password authentication
   - Enables biometric enrollment after successful login

3. **ProfileSetupScreen** (`lib/screens/auth/profile_setup_screen.dart`)
   - Collects user profile information
   - Validates required fields
   - Updates profile completion status

4. **DashboardScreen** (`lib/dashboard_screen.dart`)
   - Main application interface
   - Accessible only after authentication and profile setup

---

## Detailed Logic Flow

### 1. Application Launch
```
App Starts
    ↓
main.dart initializes
    ↓
BiometricLoginScreen displayed immediately
```

**Implementation:**
- `main.dart` sets `BiometricLoginScreen` as the initial route
- No splash screen delay unless loading assets
- Biometric prompt triggers automatically on screen load

---

### 2. Biometric Authentication Check
```
BiometricLoginScreen loads
    ↓
Check if biometric is enrolled
    ├─ YES: Show "Tap to authenticate" button
    └─ NO: Show "Sign in with email" option only
```

**Logic:**
```dart
Future<bool> isBiometricEnrolled() async {
  final email = await _secureStorage.getUserEmail();
  final uid = await _secureStorage.getUserUID();
  return email != null && uid != null;
}
```

---

### 3. Biometric Authentication Flow

#### 3a. User Triggers Biometric Authentication
```
User taps biometric button
    ↓
BiometricService.authenticate() called
    ↓
Device biometric prompt appears
    ├─ Success: Proceed to Step 3b
    ├─ Failure: Show error & allow retry
    └─ Cancel: Stay on BiometricLoginScreen
```

#### 3b. Retrieve Stored Credentials
```
Biometric authentication successful
    ↓
SecureStorageService retrieves stored UID
    ↓
Verify UID exists in secure storage
    ├─ YES: Proceed to Step 4
    └─ NO: Show error & redirect to LoginScreen
```

**Implementation:**
```dart
Future<String?> getStoredUID() async {
  return await _secureStorage.getUserUID();
}
```

---

### 4. Firebase User Verification
```
UID retrieved from secure storage
    ↓
Sign in to Firebase with stored credentials
    ↓
Verify user exists in Firebase Auth
    ├─ YES: Proceed to Step 5
    └─ NO: Clear stored credentials & redirect to LoginScreen
```

**Logic:**
```dart
Future<User?> signInWithStoredCredentials() async {
  final email = await _secureStorage.getUserEmail();
  final password = await _secureStorage.getUserPassword();
  
  if (email != null && password != null) {
    final credential = await _authService.signInWithEmailPassword(
      email, 
      password
    );
    return credential?.user;
  }
  return null;
}
```

---

### 5. Profile Completion Check
```
Firebase user authenticated
    ↓
Fetch UserModel from Firestore using UID
    ↓
Check isProfileComplete field
    ├─ TRUE: Navigate to DashboardScreen (Step 6b)
    └─ FALSE: Navigate to ProfileSetupScreen (Step 6a)
```

**Firestore Query:**
```dart
Future<UserModel?> getUserProfile(String uid) async {
  final doc = await _firestore.collection('users').doc(uid).get();
  if (doc.exists) {
    return UserModel.fromMap(doc.data()!);
  }
  return null;
}
```

---

### 6. Navigation Routing

#### 6a. Profile Setup Required
```
isProfileComplete == false
    ↓
Navigate to ProfileSetupScreen
    ↓
User fills profile information:
    - Full Name (required)
    - Phone Number (required)
    - Designation (required)
    - Profile Photo (optional)
    ↓
Submit profile
    ↓
Update Firestore: isProfileComplete = true
    ↓
Navigate to DashboardScreen
```

**Profile Setup Logic:**
```dart
Future<void> completeProfile({
  required String uid,
  required String name,
  required String phone,
  required String designation,
  File? profileImage,
}) async {
  String? imageUrl;
  if (profileImage != null) {
    imageUrl = await _storageService.uploadProfileImage(uid, profileImage);
  }
  
  await _firestoreService.updateUserProfile(uid, {
    'name': name,
    'phone': phone,
    'designation': designation,
    'profileImageUrl': imageUrl,
    'isProfileComplete': true,
    'updatedAt': FieldValue.serverTimestamp(),
  });
}
```

#### 6b. Profile Already Complete
```
isProfileComplete == true
    ↓
Navigate directly to DashboardScreen
    ↓
User accesses full application functionality
```

---

### 7. First-Time User Flow (No Biometric Enrolled)

```
New user opens app
    ↓
BiometricLoginScreen shows "Sign in with Email"
    ↓
User taps → Navigate to LoginScreen
    ↓
User enters email & password
    ↓
Create account OR Sign in
    ↓
Firebase creates user with UID
    ↓
Store UID in Firestore (UserModel created)
    ↓
Prompt: "Enable biometric login for faster access?"
    ├─ YES: Store credentials in SecureStorage
    └─ NO: Skip biometric enrollment
    ↓
Check isProfileComplete
    ├─ TRUE: Navigate to DashboardScreen
    └─ FALSE: Navigate to ProfileSetupScreen
```

**Biometric Enrollment:**
```dart
Future<void> enrollBiometric(String email, String password, String uid) async {
  final authenticated = await _biometricService.authenticate(
    reason: 'Enable biometric login for future access'
  );
  
  if (authenticated) {
    await _secureStorage.saveUserCredentials(
      email: email,
      password: password,
      uid: uid,
    );
  }
}
```

---

## State Management Flow

### Riverpod Providers Structure

```dart
// Biometric enrollment status
final biometricEnrolledProvider = FutureProvider<bool>((ref) async {
  final secureStorage = ref.watch(secureStorageServiceProvider);
  final uid = await secureStorage.getUserUID();
  return uid != null;
});

// Biometric authentication state
final biometricAuthStateProvider = 
  StateNotifierProvider<BiometricAuthController, AsyncValue<User?>>((ref) {
    return BiometricAuthController(
      ref.watch(biometricServiceProvider),
      ref.watch(secureStorageServiceProvider),
      ref.watch(authServiceProvider),
    );
  });

// User profile state
final userProfileProvider = StreamProvider.family<UserModel?, String>((ref, uid) {
  return ref.watch(firestoreServiceProvider).streamUserProfile(uid);
});
```

---

## Security Considerations

### 1. Secure Storage
- All credentials encrypted using platform-specific secure storage
- iOS: Keychain
- Android: EncryptedSharedPreferences
- Credentials never stored in plain text

### 2. Biometric Security
- Biometric data never leaves the device
- Only authentication result is used
- Device-level biometric encryption

### 3. Firebase Security
- UID is unique and non-guessable
- Firestore security rules enforce user-specific data access
- Email/password stored securely in Firebase Auth

### 4. Session Management
- Firebase Auth token auto-refreshed
- Automatic sign-out on token expiry
- Biometric re-authentication for sensitive operations

---

## Error Handling

### Biometric Failures
```dart
try {
  final authenticated = await biometricService.authenticate();
  if (!authenticated) {
    // User cancelled or failed authentication
    showSnackBar('Authentication failed. Please try again.');
  }
} catch (e) {
  // Biometric not available or error
  showSnackBar('Biometric authentication unavailable. Please sign in with email.');
  navigateToLoginScreen();
}
```

### Network Errors
```dart
try {
  await signInWithStoredCredentials();
} catch (e) {
  if (e is FirebaseAuthException) {
    if (e.code == 'network-request-failed') {
      showSnackBar('No internet connection. Please try again.');
    } else if (e.code == 'user-not-found') {
      // Clear invalid stored credentials
      await secureStorage.clearCredentials();
      navigateToLoginScreen();
    }
  }
}
```

### Profile Load Errors
```dart
final userProfile = await getUserProfile(uid);
if (userProfile == null) {
  // Profile doesn't exist - create one
  await createUserProfile(UserModel(
    uid: uid,
    email: email,
    isProfileComplete: false,
    createdAt: DateTime.now(),
  ));
  navigateToProfileSetup();
}
```

---

## Testing Scenarios

### Test Case 1: First-Time User
1. Launch app → BiometricLoginScreen shown
2. No biometric enrolled → "Sign in with Email" option visible
3. Sign in with email/password
4. Prompt to enable biometric
5. Authenticate with biometric → Credentials stored
6. Profile incomplete → ProfileSetupScreen shown
7. Complete profile → DashboardScreen shown

### Test Case 2: Returning User (Biometric Enrolled, Profile Complete)
1. Launch app → BiometricLoginScreen shown
2. Biometric prompt appears automatically
3. Authenticate with biometric
4. Profile complete → DashboardScreen shown immediately

### Test Case 3: Returning User (Biometric Enrolled, Profile Incomplete)
1. Launch app → BiometricLoginScreen shown
2. Authenticate with biometric
3. Profile incomplete → ProfileSetupScreen shown
4. Complete profile → DashboardScreen shown

### Test Case 4: Biometric Failure
1. Launch app → BiometricLoginScreen shown
2. Attempt biometric authentication → Fails
3. Retry option shown
4. Fallback: "Sign in with Email" button enabled

### Test Case 5: Invalid Stored Credentials
1. Launch app → BiometricLoginScreen shown
2. Authenticate with biometric
3. Firebase auth fails (user deleted/password changed)
4. Clear stored credentials
5. Navigate to LoginScreen
6. User re-authenticates

---

## Flow Diagram (Simplified)

```
┌─────────────────────────────┐
│   App Launch                │
└──────────┬──────────────────┘
           │
           ▼
┌─────────────────────────────┐
│ BiometricLoginScreen        │
│ - Check enrollment status   │
└──────────┬──────────────────┘
           │
           ├─── Enrolled? ────┐
           │                  │
        YES│               NO│
           │                  │
           ▼                  ▼
┌──────────────────┐   ┌────────────────┐
│ Show Biometric   │   │ Show Email     │
│ Button           │   │ Login Option   │
└────┬─────────────┘   └────┬───────────┘
     │                      │
     │ Authenticate         │ Navigate
     │                      │
     ▼                      ▼
┌──────────────────┐   ┌────────────────┐
│ Verify UID       │   │ LoginScreen    │
│ in Firebase      │   │                │
└────┬─────────────┘   └────┬───────────┘
     │                      │
     │ Success              │ Sign In
     │                      │
     ▼                      ▼
┌──────────────────────────────┐
│ Check Profile Complete       │
│ (isProfileComplete field)    │
└────┬─────────────────────────┘
     │
     ├─── Complete? ───┐
     │                 │
  YES│              NO│
     │                 │
     ▼                 ▼
┌──────────┐   ┌─────────────────┐
│Dashboard │   │ ProfileSetup    │
│Screen    │   │ Screen          │
└──────────┘   └────┬────────────┘
                    │
                    │ Submit
                    │
                    ▼
               ┌──────────┐
               │Dashboard │
               │Screen    │
               └──────────┘
```

---

## Implementation Checklist

- [x] BiometricService - Device biometric authentication
- [x] SecureStorageService - Encrypted credential storage
- [x] AuthService - Firebase authentication
- [x] FirestoreService - Profile data management
- [ ] BiometricAuthProvider - Orchestrate biometric flow
- [ ] BiometricLoginScreen - Initial auth screen
- [ ] Update LoginScreen - Add biometric enrollment prompt
- [ ] Update ProfileSetupScreen - Navigate correctly after completion
- [ ] Update main.dart - Route to BiometricLoginScreen first
- [ ] Add error handling for all failure scenarios
- [ ] Implement biometric re-enrollment flow
- [ ] Add unit tests for authentication logic
- [ ] Add integration tests for complete flow
- [ ] Update Firestore security rules
- [ ] Document user-facing biometric setup instructions

---

## Future Enhancements

1. **Multi-Device Support**
   - Allow biometric enrollment on multiple devices
   - Sync biometric preferences via Firestore

2. **Biometric Type Preference**
   - Let users choose Face ID vs Fingerprint
   - Store preference in secure storage

3. **Automatic Re-enrollment**
   - Detect when credentials become invalid
   - Prompt user to re-authenticate and update stored data

4. **Biometric Security Settings**
   - Allow users to disable biometric login
   - Require password re-entry periodically

5. **Analytics**
   - Track biometric success/failure rates
   - Monitor user adoption of biometric login

---

## Conclusion

This biometric login flow provides a seamless, secure authentication experience while maintaining flexibility for users without biometric capabilities. The flow prioritizes user convenience without compromising security, using industry-standard encryption and authentication methods.

