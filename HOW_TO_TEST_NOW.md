# 🧪 How to Test the Employee App - Step by Step

## ✅ What's Ready to Test RIGHT NOW

The Employee mobile app is **fully functional** for testing! Here's exactly what you can do:

---

## 🚀 Quick Start - Test in 5 Minutes

### Step 1: Run the App
```bash
cd /Users/mac/Documents/straights_psyroll
flutter run
```

### Step 2: What You'll See
1. **Role Selection Screen** appears
2. Tap **"Employee"** button
3. **Employee Login Screen** opens

### Step 3: Test Login
**Important**: You need to create test data first (see Setup section below)

- Enter Employee ID: `0001` (or your test ID)
- Tap "Continue"
- Enter 4-digit PIN: `1234` (or your test PIN)
- Tap "Login"

### Step 4: Explore Dashboard
After login, you'll see:
- ✅ Welcome card with your name
- ✅ Today's status (Not Checked In)
- ✅ Quick action buttons
- ✅ Assigned projects list

### Step 5: Test Check-In
1. Tap **"Check In"** button
2. Select a project from dropdown
3. Choose check-in method:
   - **GPS**: Tests your location automatically
   - **NFC**: Prompts to tap NFC tag
4. Check in successfully!
5. Dashboard updates to show "Checked In" status

### Step 6: Test Check-Out
1. Go back to Check-In screen
2. See "Currently Checked In" card
3. Tap **"Check Out"** button
4. Working hours calculated automatically!

---

## ⚙️ Setup Required (One-Time)

### 1. Update Firebase Configuration

Edit `lib/main.dart` (lines 17-25):
```dart
options: kIsWeb
    ? const FirebaseOptions(
        apiKey: "YOUR_ACTUAL_API_KEY",              // ← Add your key
        authDomain: "YOUR_PROJECT.firebaseapp.com", // ← Add your project
        projectId: "YOUR_PROJECT_ID",               // ← Add your project
        storageBucket: "YOUR_PROJECT.appspot.com",  // ← Add your bucket
        messagingSenderId: "YOUR_SENDER_ID",        // ← Add your ID
        appId: "YOUR_APP_ID",                       // ← Add your app ID
      )
    : null,
```

**Where to find these values:**
- Firebase Console → Project Settings → Your apps → Web app config

### 2. Create Test Data in Firestore

#### A. Create a Test Employee

Go to Firebase Console → Firestore → Create document:

**Collection**: `users`  
**Document ID**: (auto-generated)  
**Fields**:
```json
{
  "uid": "<same-as-document-id>",
  "email": "employee0001@test.com",
  "systemGeneratedId": "0001",
  "customEmployeeId": null,
  "name": "Test Employee",
  "role": "employee",
  "status": "approved",
  "supervisorId": null,
  "deviceInfo": null,
  "biometricEnabled": false,
  "createdAt": "2025-01-15T10:00:00.000Z",
  "updatedAt": "2025-01-15T10:00:00.000Z"
}
```

#### B. Create Firebase Auth User

Firebase Console → Authentication → Add user:
- Email: `employee0001@test.com`
- Password: `1234` (or any 4-digit PIN)

**Important**: The `uid` in Firestore must match the Authentication UID!

#### C. Create a Test Project

**Collection**: `projects`  
**Document ID**: `proj_001`  
**Fields**:
```json
{
  "projectId": "proj_001",
  "name": "Test Construction Site",
  "location": "123 Main St, City",
  "latitude": 37.7749,
  "longitude": -122.4194,
  "checkInRadiusMeters": 500,
  "isActive": true,
  "createdBy": "admin",
  "createdAt": "2025-01-15T10:00:00.000Z",
  "nfcTagId": null,
  "qrCodeData": null,
  "checkInMethods": ["gps", "nfc", "qr", "manual"],
  "maxCheckInsPerDay": 2
}
```

#### D. Assign Employee to Project

**Collection**: `projects/proj_001/assignedEmployees`  
**Document ID**: `<employee-uid>`  
**Fields**:
```json
{
  "userId": "<employee-uid>",
  "name": "Test Employee",
  "assignedAt": "2025-01-15T10:00:00.000Z",
  "assignedBy": "admin",
  "isActive": true
}
```

---

## 📱 Testing GPS Check-In

### What It Tests:
- ✅ Location permission request
- ✅ GPS accuracy
- ✅ Distance calculation
- ✅ Geofencing validation
- ✅ Address geocoding

### How to Test:

#### Test 1: Inside Radius (Success)
1. Update project's latitude/longitude to **your current location**
2. Set `checkInRadiusMeters: 50000` (50km - large radius for testing)
3. Try GPS check-in → Should succeed

#### Test 2: Outside Radius (Failure)
1. Keep project location far away (e.g., San Francisco)
2. Set `checkInRadiusMeters: 100` (100 meters)
3. Try GPS check-in → Should fail with distance message

### Expected Behavior:
- ✅ Permission dialog appears (first time)
- ✅ "Checking location..." loading indicator
- ✅ Success: "GPS Check-in Successful" dialog
- ✅ Failure: Error message with distance
- ✅ Check-in saved to Firestore: `users/<uid>/attendance`

---

## 📡 Testing NFC Check-In

### Requirements:
- Physical device (iOS/Android) - NFC won't work in simulator
- NFC-enabled phone
- NFC tag

### How to Test:

1. **Without NFC tag** (will show error):
   - Select project → Tap NFC check-in
   - Error: "Failed to read NFC tag"

2. **With NFC tag** (real test):
   - Get any NFC tag
   - Write tag ID to project's `nfcTagId` field in Firestore
   - Tap phone to tag
   - Should succeed!

### Expected Behavior:
- ✅ "Hold your phone near NFC tag" message
- ✅ Tag detected (phone vibrates/sound)
- ✅ Tag ID validated
- ✅ Check-in successful
- ✅ Data saved with NFC tag ID in notes

---

## 🔐 Testing Device Binding

### First Login (Device Registration):
1. Login with employee credentials
2. App automatically captures device info
3. Device info saved to Firestore: `users/<uid>/deviceInfo`
4. Success message: "Device registered successfully"

### Second Login (Device Verification):
1. Login again on **same device**
2. Device ID matches → Login succeeds
3. Dashboard loads normally

### Different Device (Should Fail):
1. Try login on **different device**
2. Device ID mismatch detected
3. Error: "This account is registered to a different device"
4. Automatic sign-out
5. Must request device reset

---

## ✅ What to Verify After Testing

### In Firebase Console:

#### 1. Authentication:
- User signed in successfully
- Last sign-in time updated

#### 2. Firestore - Attendance Record:
```
users/<uid>/attendance/<attendance-id>
{
  "attendanceId": "att_1234567890",
  "userId": "<uid>",
  "projectId": "proj_001",
  "checkInTime": "2025-01-15T14:30:00.000Z",
  "checkInMethod": "gps",
  "checkInLocation": {
    "latitude": 37.7749,
    "longitude": -122.4194,
    "address": "123 Main St...",
    "accuracy": 15.5
  },
  "deviceInfo": {
    "deviceId": "ABC123",
    "model": "iPhone 15 Pro",
    ...
  },
  "status": "checked_in",
  "sessionNumber": 1,
  "workingHours": null,
  "checkOutTime": null,
  "checkOutLocation": null
}
```

#### 3. After Check-Out:
- `checkOutTime`: Updated
- `checkOutLocation`: Updated
- `workingHours`: Calculated (e.g., 2.5 hours)
- `status`: "checked_out"

---

## 🐛 Common Issues & Solutions

### Issue 1: "User not found"
**Solution**: Create Firebase Auth user with matching Firestore document

### Issue 2: "No projects assigned"
**Solution**: Add employee to project's `assignedEmployees` subcollection

### Issue 3: GPS permission denied
**Solution**: 
- iOS: Check Info.plist for `NSLocationWhenInUseUsageDescription`
- Android: Check AndroidManifest.xml for location permissions

### Issue 4: NFC not working
**Solution**: 
- Use real device (not simulator)
- Check device has NFC capability
- Enable NFC in device settings

### Issue 5: "Too far from project site"
**Solution**: Either:
- Update project lat/lng to your location
- Increase `checkInRadiusMeters` to 50000 (50km)

---

## 📊 Test Scenarios

### ✅ Happy Path:
1. Open app → Role selection
2. Tap Employee → Login screen
3. Enter ID & PIN → Dashboard
4. Tap Check In → Select project
5. GPS check-in → Success
6. Check out → Success

### ✅ Device Binding:
1. Login on Device A → Success, device registered
2. Login on Device B → Fail, device mismatch

### ✅ Multiple Sessions:
1. Check in → Check out → Session 1 complete
2. Check in again → Session 2 starts
3. Verify `sessionNumber` in Firestore

### ✅ Location Validation:
1. Far from site → Check-in fails
2. Move closer (or increase radius) → Check-in succeeds

---

## 🎯 Success Criteria

You'll know everything works when:

- ✅ Login successful with employee ID & PIN
- ✅ Dashboard shows your name and projects
- ✅ GPS check-in works and saves to Firebase
- ✅ Check-out calculates working hours
- ✅ Device binding prevents login from other devices
- ✅ All data appears in Firestore in real-time

---

## 🚀 Next: What to Build

After testing the Employee app, next priorities:

1. **Supervisor Login & Dashboard** (Days 7-8)
2. **Web Admin Dashboard** (Days 9-10)
3. **Document Management** (Days 11-12)
4. **Reports & Export** (Days 13-14)

---

**Current Status**: Employee Mobile App is **80% complete** and **fully testable!**

**Estimated remaining**: Days 7-17 for Supervisor, Admin, and advanced features.

---

Last Updated: ${DateTime.now().toString().split('.')[0]}

