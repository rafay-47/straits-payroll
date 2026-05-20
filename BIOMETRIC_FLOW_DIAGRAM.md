# Biometric Authentication Flow - Visual Diagram

## Complete Application Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          APP LAUNCH (main.dart)                         │
│                     Initialize Firebase & Providers                     │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    BiometricLoginScreen (Initial Screen)                │
│                                                                          │
│  • Check if biometric is enrolled in secure storage                     │
│  • Automatically trigger biometric auth if enrolled                     │
│  • Display appropriate UI based on enrollment status                    │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │
                    ┌────────────┴────────────┐
                    │                         │
            Biometric Enrolled?               │
                    │                         │
          ┌─────YES─┴─────┐         ┌────NO──┴──────┐
          │                │         │               │
          ▼                │         ▼               │
┌─────────────────┐        │   ┌──────────────────┐ │
│ Show Biometric  │        │   │ Show "Sign in    │ │
│ Authentication  │        │   │ with Email"      │ │
│ Prompt          │        │   │ Button Only      │ │
└────┬────────────┘        │   └────┬─────────────┘ │
     │                     │        │               │
     │ Tap Authenticate    │        │ Tap Button    │
     │                     │        │               │
     ▼                     │        ▼               │
┌─────────────────────────┐│   ┌──────────────────┐│
│ Device Biometric Prompt ││   │   LoginScreen    ││
│ (Face ID / Fingerprint) ││   │                  ││
└────┬────────────────────┘│   │ • Email/Password ││
     │                     │   │ • Create Account ││
     │ Success?            │   │ • Biometric Login││
     │                     │   └────┬─────────────┘│
     ├─YES→ Continue       │        │              │
     │                     │        │ Sign In OR   │
     └─NO → Retry/Fail     │        │ Create Acct  │
           │               │        │              │
           └───────────────┘        ▼              │
                    │         ┌─────────────────┐  │
                    │         │ Firebase Auth   │  │
                    │         │ • signIn()      │  │
                    │         │ • createAcct()  │  │
                    │         └────┬────────────┘  │
                    │              │               │
                    │              ▼               │
                    │         ┌─────────────────┐  │
                    │         │ Prompt:         │  │
                    │         │ "Enable         │  │
                    │         │  Biometric?"    │  │
                    │         └────┬────────────┘  │
                    │              │               │
                    │         ┌────┴─────┐         │
                    │         │          │         │
                    │    ┌─YES─┘      NO─┴──┐      │
                    │    │                  │      │
                    │    ▼                  ▼      │
                    │ ┌─────────────┐  ┌──────────┐
                    │ │ Enroll      │  │ Skip     │
                    │ │ Biometric   │  │ Continue │
                    │ └─┬───────────┘  └────┬─────┘
                    │   │                   │
                    │   └───────┬───────────┘
                    │           │
                    └───────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    RETRIEVE STORED CREDENTIALS                          │
│                                                                          │
│  1. Get UID from SecureStorage (flutter_secure_storage)                 │
│  2. Get Email from SecureStorage                                        │
│  3. Get Password from SecureStorage                                     │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      VERIFY WITH FIREBASE AUTH                          │
│                                                                          │
│  • Call: signInWithEmailPassword(email, password)                       │
│  • Get: UserCredential with User object                                 │
│  • Verify: user.uid matches stored UID                                  │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │
                    ┌────────────┴────────────┐
                    │                         │
            Authentication Success?           │
                    │                         │
          ┌─────YES─┴─────┐         ┌────NO──┴──────┐
          │                │         │               │
          ▼                │         ▼               │
┌─────────────────┐        │   ┌──────────────────┐ │
│ Proceed to      │        │   │ Clear Invalid    │ │
│ Profile Check   │        │   │ Credentials      │ │
└────┬────────────┘        │   └────┬─────────────┘ │
     │                     │        │               │
     │                     │        └───────────────┘
     │                     │                │
     ▼                     │                ▼
                           │   ┌──────────────────────┐
                           │   │ Show Error &         │
                           │   │ Redirect to          │
                           │   │ LoginScreen          │
                           │   └──────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                     FETCH USER PROFILE FROM FIRESTORE                   │
│                                                                          │
│  • Query: users collection, document ID = UID                           │
│  • Get: UserModel with isProfileComplete field                          │
│  • Check: Does profile exist?                                           │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │
                    ┌────────────┴────────────┐
                    │                         │
             Profile Exists?                  │
                    │                         │
          ┌─────YES─┴─────┐         ┌────NO──┴──────┐
          │                │         │               │
          ▼                │         ▼               │
┌─────────────────┐        │   ┌──────────────────┐ │
│ Check           │        │   │ Create New       │ │
│ isProfileComplete        │   │ UserProfile      │ │
└────┬────────────┘        │   │ isProfileComplete│ │
     │                     │   │ = false          │ │
     │                     │   └────┬─────────────┘ │
     │                     │        │               │
     │                     │        └───────────────┘
     │                     │                │
     ▼                     │                │
┌─────────────────────────┐│                │
│ isProfileComplete?      ││                │
└─────┬───────────────────┘│                │
      │                    │                │
  ┌───┴─────┐              │                │
  │         │              │                │
TRUE│    FALSE             │                │
  │         │              │                │
  ▼         ▼              │                ▼
┌───────┐ ┌─────────────────────────────────────────┐
│       │ │    ProfileSetupScreen                   │
│       │ │                                         │
│       │ │  User provides:                         │
│       │ │  • Full Name (required)                 │
│       │ │  • Phone Number (required)              │
│       │ │  • Designation (required)               │
│       │ │  • Profile Photo (optional)             │
│       │ └─────┬───────────────────────────────────┘
│       │       │
│       │       │ Submit Profile
│       │       │
│       │       ▼
│       │ ┌─────────────────────────────────────────┐
│       │ │  UPDATE FIRESTORE                       │
│       │ │  • Set isProfileComplete = true         │
│       │ │  • Save profile data                    │
│       │ │  • Upload photo to Firebase Storage     │
│       │ └─────┬───────────────────────────────────┘
│       │       │
│       └───────┘
│           │
│           ▼
└───────────────────────────────────────────────────────────────┐
                                                                │
┌───────────────────────────────────────────────────────────────▼─────────┐
│                          DashboardScreen                                │
│                    (Main Application Functionality)                     │
│                                                                          │
│  • Check In / Check Out                                                 │
│  • View Attendance History                                              │
│  • Upload Documents                                                     │
│  • View Profile                                                         │
│  • Settings (including Biometric toggle)                                │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Detailed State Transitions

### 1. App Launch → Biometric Check
```
[App Start]
    ↓
[BiometricLoginScreen.initState()]
    ↓
Check SecureStorage for enrolled credentials
    ↓
    ├─ Has UID, Email, Password → AUTO-TRIGGER biometric auth
    └─ Missing any credential → SHOW email login option
```

### 2. Biometric Authentication Success Flow
```
[Biometric Auth Triggered]
    ↓
[Device Biometric Prompt]
    ↓
[Authentication Successful]
    ↓
[Retrieve: email, password, uid from SecureStorage]
    ↓
[Firebase: signInWithEmailPassword(email, password)]
    ↓
[Verify: userCredential.user.uid == stored_uid]
    ↓
[Firestore: getUserProfile(uid)]
    ↓
    ├─ isProfileComplete == true → Navigate to DashboardScreen
    └─ isProfileComplete == false → Navigate to ProfileSetupScreen
```

### 3. First-Time User Flow (No Biometric)
```
[User opens app for first time]
    ↓
[BiometricLoginScreen]
    ↓
No enrolled credentials detected
    ↓
[Show: "Sign in with Email" button]
    ↓
User taps button
    ↓
[Navigate to LoginScreen]
    ↓
User chooses: "Create Account"
    ↓
[Enter: email, password]
    ↓
[Firebase: createUserWithEmailPassword()]
    ↓
[Firestore: Create UserModel with isProfileComplete = false]
    ↓
[Dialog: "Enable Biometric Login?"]
    ↓
    ├─ User accepts → Device biometric auth → Store credentials
    └─ User declines → Skip
    ↓
[Navigate to ProfileSetupScreen]
    ↓
User fills profile form
    ↓
[Submit: Update Firestore with isProfileComplete = true]
    ↓
[Navigate to DashboardScreen]
```

### 4. Returning User Flow (Biometric Enrolled)
```
[User opens app]
    ↓
[BiometricLoginScreen loads]
    ↓
Credentials detected in SecureStorage
    ↓
[Auto-trigger biometric authentication after 500ms]
    ↓
[Device Biometric Prompt appears]
    ↓
User authenticates (Face ID / Fingerprint)
    ↓
[Success: Sign in to Firebase]
    ↓
[Fetch profile from Firestore]
    ↓
Profile complete
    ↓
[Navigate to DashboardScreen]
    
Total time: ~2-3 seconds from app open to dashboard
```

### 5. Biometric Failure Scenarios

#### Scenario A: Authentication Declined
```
[Biometric Prompt]
    ↓
User cancels or authentication fails
    ↓
[Show SnackBar: "Authentication failed"]
    ↓
[Show Retry button in SnackBar]
    ↓
User can:
    ├─ Tap Retry → Try biometric again
    └─ Tap "Sign in with Email" → Navigate to LoginScreen
```

#### Scenario B: Invalid Stored Credentials
```
[Biometric Authentication Success]
    ↓
[Retrieve credentials from SecureStorage]
    ↓
[Attempt Firebase sign in]
    ↓
Firebase Error: user-not-found / wrong-password
    ↓
[Clear all stored credentials]
    ↓
[Show Error: "Please sign in again"]
    ↓
[Navigate to LoginScreen]
```

#### Scenario C: UID Mismatch
```
[Firebase sign in successful]
    ↓
[Check: stored_uid == firebase_user.uid]
    ↓
Mismatch detected
    ↓
[Clear stored credentials]
    ↓
[Show Error: "User verification failed"]
    ↓
[Navigate to LoginScreen]
```

---

## Data Flow Diagram

```
┌──────────────────────┐
│  User Device         │
│                      │
│  ┌────────────────┐  │
│  │ Biometric      │  │      ┌─────────────────────┐
│  │ Hardware       │◄─┼──────┤ BiometricService    │
│  │ (Face/Touch ID)│  │      │ (local_auth)        │
│  └────────────────┘  │      └─────────────────────┘
│                      │
│  ┌────────────────┐  │
│  │ Secure Storage │  │      ┌─────────────────────┐
│  │ (Keychain/     │◄─┼──────┤ SecureStorageService│
│  │  EncryptedPrefs│  │      │ (flutter_secure_    │
│  └────────────────┘  │      │  storage)           │
└──────────────────────┘      └─────────────────────┘
                                       │
                              Stores   │   Retrieves
                              ┌────────┴────────┐
                              │  • Email        │
                              │  • Password     │
                              │  • UID          │
                              │  • BiometricFlag│
                              └────────┬────────┘
                                       │
                              ┌────────▼────────┐
                              │ Authentication  │
                              │ Controller      │
                              └────────┬────────┘
                                       │
                    ┌──────────────────┼──────────────────┐
                    │                  │                  │
                    ▼                  ▼                  ▼
        ┌──────────────────┐ ┌──────────────┐ ┌──────────────────┐
        │ Firebase Auth    │ │ Firestore    │ │ Firebase Storage │
        │                  │ │              │ │                  │
        │ • signIn()       │ │ users/       │ │ profile_images/  │
        │ • createUser()   │ │   {uid}/     │ │   {uid}.jpg      │
        │ • getUser()      │ │              │ │                  │
        └──────────────────┘ └──────────────┘ └──────────────────┘
                │                    │                  │
                └────────────────────┴──────────────────┘
                                     │
                              ┌──────▼───────┐
                              │ UserModel    │
                              │              │
                              │ • uid        │
                              │ • email      │
                              │ • name       │
                              │ • phone      │
                              │ • isProfile  │
                              │   Complete   │
                              └──────────────┘
```

---

## Security Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    SECURITY LAYERS                              │
└─────────────────────────────────────────────────────────────────┘

Layer 1: Biometric Authentication
    ├─ Device-level biometric verification
    ├─ No biometric data leaves device
    └─ Result: Boolean (authenticated / not authenticated)

Layer 2: Secure Credential Storage
    ├─ iOS: Keychain (hardware-encrypted)
    ├─ Android: EncryptedSharedPreferences
    └─ Encryption: AES-256

Layer 3: Firebase Authentication
    ├─ Email/Password verification
    ├─ JWT token generation
    └─ Token auto-refresh

Layer 4: UID Verification
    ├─ Compare stored UID with Firebase UID
    └─ Prevent account switching attacks

Layer 5: Firestore Security Rules
    ├─ User can only access own data
    ├─ Rule: request.auth.uid == resource.data.uid
    └─ Server-side validation

┌─────────────────────────────────────────────────────────────────┐
│                    ATTACK PREVENTION                            │
└─────────────────────────────────────────────────────────────────┘

• Credential Theft → Encrypted storage + biometric gate
• Man-in-the-Middle → Firebase SSL/TLS encryption
• Account Takeover → UID verification + Firebase auth
• Brute Force → Firebase rate limiting
• Device Compromise → Biometric re-authentication required
```

---

## Profile Completion States

```
┌───────────────────────────────────────────────────────────────┐
│                   PROFILE STATE MACHINE                       │
└───────────────────────────────────────────────────────────────┘

State 1: NEW USER (No Profile)
    ├─ isProfileComplete: undefined or false
    ├─ Fields: email, uid, createdAt
    └─ Next: → ProfileSetupScreen

State 2: PROFILE INCOMPLETE
    ├─ isProfileComplete: false
    ├─ Fields: email, uid, createdAt
    ├─ Missing: name, phone, designation
    └─ Next: → ProfileSetupScreen

State 3: PROFILE COMPLETE
    ├─ isProfileComplete: true
    ├─ Fields: All required fields filled
    │   • uid ✓
    │   • email ✓
    │   • name ✓
    │   • phone ✓
    │   • designation ✓
    │   • profileImageUrl (optional)
    └─ Next: → DashboardScreen

Transitions:
[NEW/INCOMPLETE] --[Submit Profile Form]--> [COMPLETE]
[COMPLETE] --[Edit Profile]--> [COMPLETE] (stays in same state)
```

---

## Timeline: User Journey

### First-Time User (Cold Start)
```
0:00  → App opens
0:01  → BiometricLoginScreen renders
0:02  → User sees "Sign in with Email" button
0:03  → User taps button
0:04  → LoginScreen renders
0:05  → User enters email/password
0:10  → User taps "Create Account"
0:11  → Firebase creates account
0:12  → Dialog: "Enable Biometric?"
0:13  → User taps "Enable"
0:14  → Biometric authentication prompt
0:15  → User authenticates successfully
0:16  → Credentials stored securely
0:17  → Navigate to ProfileSetupScreen
0:18  → User fills profile information
0:30  → User submits profile
0:31  → Firestore updates profile
0:32  → Navigate to DashboardScreen
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total: 32 seconds (with user interaction)
```

### Returning User (Biometric Enrolled)
```
0:00  → App opens
0:01  → BiometricLoginScreen renders
0:01.5→ Auto-trigger biometric
0:02  → Biometric prompt appears
0:03  → User authenticates
0:04  → Retrieve credentials from SecureStorage
0:05  → Sign in to Firebase
0:06  → Fetch profile from Firestore
0:07  → Verify profile complete
0:08  → Navigate to DashboardScreen
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total: 8 seconds (mostly automated)
```

---

## Error Recovery Flows

### Error 1: Biometric Hardware Unavailable
```
BiometricService.canCheckBiometrics() → false
    ↓
Hide biometric option
    ↓
Show only: "Sign in with Email"
```

### Error 2: Network Error During Sign In
```
Firebase.signIn() → throws NetworkException
    ↓
Show error: "No internet connection"
    ↓
Provide retry button
    ↓
User can retry when connection restored
```

### Error 3: Firestore Profile Not Found
```
Firestore.getUserProfile(uid) → null
    ↓
Automatically create new UserModel
    ↓
Set isProfileComplete = false
    ↓
Navigate to ProfileSetupScreen
```

### Error 4: Profile Setup Fails
```
ProfileSetup.submit() → throws Error
    ↓
Show error message
    ↓
Keep user on ProfileSetupScreen
    ↓
Allow retry with same data
    ↓
Data persists in form fields
```

---

This flow diagram provides a comprehensive visual representation of how the biometric authentication system works from app launch to main functionality access.

