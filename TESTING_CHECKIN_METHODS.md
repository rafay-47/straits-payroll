# 🧪 Testing Check-In Methods - Complete Guide

## 📋 **Prerequisites**

### **1. Required Setup:**
- ✅ Super Admin account created
- ✅ At least one company created
- ✅ Company Admin account created
- ✅ At least one supervisor created
- ✅ At least one employee created
- ✅ At least one project created with check-in methods enabled

### **2. Devices Needed:**
- **For GPS Testing:** Mobile device with GPS/Location enabled
- **For NFC Testing:** Mobile device with NFC capability
- **For QR Testing:** Mobile device with camera
- **For Manual Testing:** Any mobile device

---

## 🎯 **STEP-BY-STEP TESTING GUIDE**

### **Phase 1: Create a Test Project (Web Dashboard)**

#### **1. Login as Company Admin:**
```
URL: http://localhost:port/admin-login

Company Code: Your company code (e.g., ABC123)
Email: companyadmin@yourcompany.com
Password: Your password
```

#### **2. Navigate to Project Management:**
```
Dashboard → Manage Projects → Add Project
```

#### **3. Create Test Project:**

**Option A: GPS-Only Project**
```
Project Name: GPS Test Project
Description: Testing GPS check-in
Location: Your Current Address
Latitude: YOUR_LATITUDE (use Google Maps to get this)
Longitude: YOUR_LONGITUDE
Radius: 200 meters

Check-in Methods:
☑ GPS Location
☐ NFC Tag
☐ QR Code
☐ Manual

Assign Supervisor: Select a supervisor
```

**Option B: All Methods Project**
```
Project Name: Multi-Method Test Project
Description: Testing all check-in methods
Location: Your Office/Test Location
Latitude: YOUR_LATITUDE
Longitude: YOUR_LONGITUDE
Radius: 200 meters

Check-in Methods:
☑ GPS Location
☑ NFC Tag
☑ QR Code
☑ Manual

Assign Supervisor: Select a supervisor
```

#### **4. Assign Employees to Project:**
```
Click on "Assign Employees" icon for the project
Select test employees
Save
```

---

### **Phase 2: Testing GPS Check-In**

#### **Prerequisites:**
- ✅ Project has GPS enabled
- ✅ Employee is assigned to the project
- ✅ Location services enabled on mobile device
- ✅ You are within the project radius (200m by default)

#### **Steps:**

**1. Login as Employee (Mobile App):**
```
Company Code: ABC123
Employee ID: ABC-0001 (your employee ID)
PIN: Your 4-digit PIN
```

**2. Navigate to Check-In:**
```
Dashboard → Check In button
```

**3. Select Project:**
```
Select "GPS Test Project" from dropdown
```

**4. Click GPS Check-In:**
```
The app will:
✅ Request location permission (grant it)
✅ Get your current GPS location
✅ Calculate distance to project location
✅ Validate if you're within radius
```

**Expected Results:**

**✅ SUCCESS (Within Radius):**
```
✅ "GPS Check-in Successful"
✅ "Checked in at [Your Address]"
✅ Dashboard shows "Checked In" status
✅ Attendance record created in Firestore
```

**❌ FAILURE (Outside Radius):**
```
❌ "You are X km away from the project site. Please move closer."
❌ Check-in not recorded
```

#### **How to Test Without Being at Location:**

**Option 1: Use Emulator with Custom Location**
```
Android Studio Emulator:
1. Open Extended Controls (...)
2. Go to Location
3. Enter test latitude/longitude
4. Click "Send"
```

**Option 2: Temporarily Increase Radius**
```
Edit project → Change radius to 50000 meters (50km)
Now any location will work for testing
```

**Option 3: Use Your Current Location**
```
1. Get your current GPS coordinates (Google Maps)
2. Update project location to match your coordinates
3. Test from your current location
```

---

### **Phase 3: Testing NFC Check-In**

#### **Prerequisites:**
- ✅ Project has NFC enabled
- ✅ Employee is assigned to the project
- ✅ NFC-capable Android device
- ✅ Physical NFC tag (or another NFC device)

#### **Steps:**

**1. Prepare NFC Tag (Company Admin/Supervisor):**
```
Option A: Write NFC Tag
- Use NFC Tools app (Android)
- Write a unique ID to the tag
- Note the tag ID (e.g., "PROJECT-001-NFC")

Option B: Use Existing NFC Device
- Use another phone with NFC
- Use NFC card/key fob
```

**2. (Optional) Register NFC Tag with Project:**
```
Web Dashboard → Edit Project
NFC Tag ID: PROJECT-001-NFC
Save
```

**3. Login as Employee (Mobile):**
```
Company Code: ABC123
Employee ID: ABC-0001
PIN: Your PIN
```

**4. Navigate to Check-In:**
```
Dashboard → Check In button
Select Project
```

**5. Tap NFC Check-In:**
```
The app will:
✅ Request NFC permission (grant it)
✅ Show "Hold your phone near the NFC tag"
✅ Wait for tag detection
```

**6. Hold Phone to NFC Tag:**
```
Place your phone's back (where NFC antenna is) against the NFC tag
Hold steady for 1-2 seconds
```

**Expected Results:**

**✅ SUCCESS:**
```
✅ "NFC Check-in Successful"
✅ "Checked in using NFC tag"
✅ Dashboard shows "Checked In" status
✅ Attendance record created with NFC tag ID
```

**❌ FAILURE (Wrong Tag):**
```
❌ "NFC tag does not match this project"
(If project has specific nfcTagId set)
```

**❌ FAILURE (No NFC):**
```
❌ "NFC is not available on this device"
or
❌ "NFC is disabled. Please enable it in Settings"
```

#### **Testing Without Physical NFC Tag:**

**Option 1: Disable Tag Validation**
```
Leave project.nfcTagId empty in database
Any NFC tag will work
```

**Option 2: Use Two Phones**
```
Phone A (checking in):
- Login as employee
- Tap NFC Check-in

Phone B (as NFC tag):
- Install NFC Tools
- Enable "Card Emulation"
- Touch phones together
```

---

### **Phase 4: Testing QR Code Check-In**

#### **Prerequisites:**
- ✅ Project has QR enabled
- ✅ Employee is assigned to the project
- ✅ Mobile device with camera
- ✅ QR code generated and printed/displayed

#### **Steps:**

**1. Generate QR Code for Project:**

**Option A: Online QR Generator**
```
1. Go to qr-code-generator.com or similar
2. Generate QR code with text: "PROJECT-001-QR"
3. Download and print OR display on screen
```

**Option B: Use Flutter Package (Future Enhancement)**
```
// This can be added to project details screen
import 'package:qr_flutter/qr_flutter.dart';

QrImageView(
  data: project.projectId, // or custom code
  version: QrVersions.auto,
  size: 200.0,
)
```

**2. (Optional) Register QR Code with Project:**
```
Web Dashboard → Edit Project
QR Code: PROJECT-001-QR
Save
```

**3. Login as Employee (Mobile):**
```
Company Code: ABC123
Employee ID: ABC-0001
PIN: Your PIN
```

**4. Navigate to Check-In:**
```
Dashboard → Check In button
Select Project
```

**5. Tap QR Code Check-In:**
```
The app will:
✅ Open QR scanner screen
✅ Request camera permission (grant it)
✅ Show camera viewfinder with scanning frame
```

**6. Scan QR Code:**
```
Point camera at QR code
Hold steady until detection (usually instant)
```

**Expected Results:**

**✅ SUCCESS:**
```
✅ QR code detected and scanned
✅ "QR Check-in Successful"
✅ "Checked in using QR code"
✅ Dashboard shows "Checked In" status
✅ Attendance record created with QR code data
```

**❌ FAILURE (Wrong QR):**
```
❌ "QR code does not match this project"
(If project has specific qrCode set)
```

**❌ FAILURE (Invalid QR):**
```
❌ Scanner reads QR but doesn't match expected format
```

#### **Quick Test Without Printing:**

**Option 1: Display QR on Another Device**
```
1. Generate QR code online
2. Display full-screen on laptop/tablet
3. Scan from phone
```

**Option 2: Disable QR Validation**
```
Leave project.qrCode empty in database
Any QR code will work (for testing only!)
```

---

### **Phase 5: Testing Manual Check-In**

#### **Prerequisites:**
- ✅ Project has Manual enabled
- ✅ Employee is assigned to the project
- ✅ Supervisor login available for approval

#### **Steps:**

**1. Employee Requests Manual Check-In:**

```
Mobile App:
1. Login as Employee
2. Dashboard → Check In
3. Select Project
4. Tap "Manual Check-in"
5. See message: "Manual Check-in Requested"
   "Your check-in request has been submitted. 
    Waiting for supervisor approval."
```

**2. Supervisor Approves Check-In:**

**Option A: Mobile Supervisor App**
```
1. Login as Supervisor
2. Dashboard → Pending Approvals
3. See manual check-in request
4. Review details
5. Tap "Approve" or "Reject"
```

**Option B: Web Dashboard**
```
1. Login as Company Admin/Supervisor
2. Attendance Management → Pending Approvals
3. See manual check-in request
4. Review details
5. Click "Approve" or "Reject"
```

**Expected Results:**

**✅ After Request:**
```
✅ Attendance record created with status: "pending"
✅ Employee sees "Waiting for approval" status
✅ Supervisor sees pending approval notification
```

**✅ After Approval:**
```
✅ Attendance status changed to "approved"
✅ Employee sees "Checked In" status
✅ Check-in time recorded
```

**❌ After Rejection:**
```
❌ Attendance status changed to "rejected"
❌ Employee can request again
```

---

## 🔍 **VERIFICATION CHECKLIST**

### **After Each Check-In, Verify:**

**1. Mobile App:**
```
✅ Employee Dashboard shows "Checked In" status
✅ Current project name displayed
✅ Check-in time shown
✅ "Check Out" button available
```

**2. Firestore Database:**
```
✅ New document in 'attendance' collection
✅ Correct companyId
✅ Correct userId
✅ Correct projectId
✅ checkInMethod: 'gps' / 'nfc' / 'qr' / 'manual'
✅ checkInTime recorded
✅ checkInLocation (if GPS)
✅ deviceInfo present
```

**3. Web Dashboard:**
```
✅ Attendance appears in Attendance Management
✅ Correct employee name
✅ Correct project name
✅ Correct check-in method shown
✅ Check-in time displayed
```

---

## 🚨 **TROUBLESHOOTING**

### **GPS Issues:**

**"Location permission denied"**
```
Fix: Go to device Settings → Apps → Your App → Permissions → Location → Allow
```

**"You are too far from project site"**
```
Fix Options:
1. Move closer to project location
2. Increase project radius in web dashboard
3. Update project location to your current location
4. Use emulator with custom GPS coordinates
```

**"Unable to get current location"**
```
Fix:
1. Enable Location Services in device settings
2. Ensure GPS is enabled (not just Wi-Fi location)
3. Go outside if indoors (GPS needs satellite signal)
4. Restart app and try again
```

### **NFC Issues:**

**"NFC is not available"**
```
Check:
1. Device has NFC hardware (not all phones do)
2. NFC is enabled in Settings
3. NFC permission granted to app
```

**"Failed to read NFC tag"**
```
Fix:
1. Hold phone closer to tag
2. Remove phone case (may block NFC)
3. Try different position/angle
4. Hold steady for 2-3 seconds
5. Ensure tag is working (test with NFC Tools app)
```

### **QR Issues:**

**"Camera permission denied"**
```
Fix: Go to device Settings → Apps → Your App → Permissions → Camera → Allow
```

**"QR code not detecting"**
```
Fix:
1. Ensure good lighting
2. Hold phone steady
3. Ensure QR code is clear and unobstructed
4. Try different distance (not too close, not too far)
5. Clean camera lens
```

**"QR code does not match this project"**
```
Fix:
1. Check project.qrCode in database matches scanned code
2. OR leave project.qrCode empty for testing
```

### **Manual Check-In Issues:**

**"Waiting for approval forever"**
```
Check:
1. Supervisor has notifications enabled
2. Supervisor knows where to find pending approvals
3. Check Firestore for attendance record status
```

---

## 📊 **TEST SCENARIOS MATRIX**

| Scenario | GPS | NFC | QR | Manual | Expected Result |
|----------|-----|-----|----|----|-----------------|
| **Project with GPS only** | ✅ | ❌ | ❌ | ❌ | Only GPS button shows |
| **Project with NFC only** | ❌ | ✅ | ❌ | ❌ | Only NFC button shows |
| **Project with QR only** | ❌ | ❌ | ✅ | ❌ | Only QR button shows |
| **Project with Manual only** | ❌ | ❌ | ❌ | ✅ | Only Manual button shows |
| **Project with ALL methods** | ✅ | ✅ | ✅ | ✅ | All 4 buttons show |
| **Project with NO methods** | ❌ | ❌ | ❌ | ❌ | Warning message shows |
| **GPS - Inside radius** | ✅ | - | - | - | Check-in succeeds |
| **GPS - Outside radius** | ❌ | - | - | - | Error: "Too far away" |
| **NFC - Correct tag** | - | ✅ | - | - | Check-in succeeds |
| **NFC - Wrong tag** | - | ❌ | - | - | Error: "Tag doesn't match" |
| **QR - Correct code** | - | - | ✅ | - | Check-in succeeds |
| **QR - Wrong code** | - | - | ❌ | - | Error: "Code doesn't match" |
| **Manual - Approved** | - | - | - | ✅ | Check-in succeeds |
| **Manual - Rejected** | - | - | - | ❌ | Check-in fails |
| **Already checked in** | ❌ | ❌ | ❌ | ❌ | Show "Check Out" button |

---

## 🎯 **RECOMMENDED TESTING ORDER**

### **Day 1: Basic Setup & Manual**
```
1. ✅ Create company and users
2. ✅ Create project with Manual only
3. ✅ Test Manual check-in
4. ✅ Test Manual approval workflow
5. ✅ Verify in database and dashboard
```

### **Day 2: GPS Testing**
```
1. ✅ Create project with GPS enabled
2. ✅ Set location to your current location
3. ✅ Test GPS check-in (success case)
4. ✅ Move far away (or change project location)
5. ✅ Test GPS check-in (failure case)
6. ✅ Verify location data in database
```

### **Day 3: QR Testing**
```
1. ✅ Generate test QR code
2. ✅ Create project with QR enabled
3. ✅ Register QR code with project (optional)
4. ✅ Print or display QR code
5. ✅ Test QR scan check-in
6. ✅ Verify QR data in database
```

### **Day 4: NFC Testing**
```
1. ✅ Get NFC tag or use another phone
2. ✅ Create project with NFC enabled
3. ✅ Register NFC tag (optional)
4. ✅ Test NFC check-in
5. ✅ Test with wrong tag
6. ✅ Verify NFC data in database
```

### **Day 5: Integration Testing**
```
1. ✅ Create project with ALL methods
2. ✅ Test switching between methods
3. ✅ Test check-out functionality
4. ✅ Test multiple check-ins per day
5. ✅ Test max check-ins limit
6. ✅ Generate attendance reports
```

---

## 📝 **QUICK REFERENCE**

### **Get GPS Coordinates:**
```
1. Open Google Maps
2. Long-press on location
3. Copy coordinates shown at bottom
4. Format: Latitude, Longitude
   Example: 40.7128, -74.0060
```

### **Generate QR Code:**
```
Online: qr-code-generator.com
Text to encode: "PROJECT-001-QR"
Download PNG and print
```

### **Check Firestore Data:**
```
Firebase Console → Firestore Database
Collections:
- companies/{companyId}
- users/{userId}
- projects/{projectId}
- attendance/{attendanceId}
```

### **View Logs:**
```
Flutter app:
- Run in debug mode
- Check console for print statements
- Look for errors in debug console

Firebase:
- Firebase Console → Functions → Logs
- Firestore → Rules → Debug
```

---

## ✅ **COMPLETION CHECKLIST**

- [ ] GPS check-in tested (success case)
- [ ] GPS check-in tested (failure case)
- [ ] NFC check-in tested with tag
- [ ] NFC check-in tested with wrong tag
- [ ] QR check-in tested with code
- [ ] QR check-in tested with wrong code
- [ ] Manual check-in requested
- [ ] Manual check-in approved
- [ ] Manual check-in rejected
- [ ] Check-out functionality tested
- [ ] Multiple methods on same project tested
- [ ] Attendance visible in web dashboard
- [ ] All data correct in Firestore
- [ ] Reports generated successfully
- [ ] Employee can view attendance history

---

## 🎉 **YOU'RE READY!**

All check-in methods are fully implemented and ready for production use. Follow this guide to test each method thoroughly before deploying to real users.

**Need Help?** Refer back to the troubleshooting section or check Firebase logs for detailed error messages.






