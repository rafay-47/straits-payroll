# 🧪 Complete Testing Guide - End-to-End Flow

**Date:** February 2, 2026  
**Purpose:** Complete step-by-step guide to test all functionalities

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Super Admin Flow](#super-admin-flow)
3. [Company Admin Flow](#company-admin-flow)
4. [Supervisor Flow](#supervisor-flow)
5. [Employee Flow](#employee-flow)
6. [Complete End-to-End Test Scenario](#complete-end-to-end-test-scenario)

---

## 🔧 Prerequisites

### Required Accounts:
- ✅ Super Admin account (email + password)
- ✅ Company Admin account (will be created)
- ✅ Supervisor account (will be created)
- ✅ Employee account (will be created)

### Required Devices:
- 📱 **Mobile Device** (Android/iOS) for Employee & Supervisor apps
- 💻 **Web Browser** (Chrome/Firefox/Safari) for Admin dashboard
- 📡 **NFC Tag** (optional, for NFC testing)
- 📷 **QR Code** (will be generated)

### Required Apps:
- ✅ Web app running (localhost or deployed)
- ✅ Mobile app installed (Android APK or iOS build)

---

## 👑 Super Admin Flow

### Step 1: Login as Super Admin

**Platform:** Web Browser  
**URL:** Your web app URL

```
1. Open web browser
2. Navigate to your app URL
3. You should see "Super Admin Login" screen
4. Enter:
   - Email: [your-super-admin-email]
   - Password: [your-super-admin-password]
5. Click "Login"
6. ✅ Should redirect to Super Admin Dashboard
```

**Expected Result:**
- ✅ Dashboard shows platform statistics
- ✅ Companies list (empty if first time)
- ✅ "Create Company" button visible

---

### Step 2: Create Company

**From:** Super Admin Dashboard

```
1. Click "Create Company" button (floating action button)
2. Fill in company details:
   ├─ Company Name: "Test Construction Co."
   ├─ Company Code: "TCC" (3-6 letters, unique)
   ├─ Primary Contact Name: "John Admin"
   ├─ Primary Contact Email: "admin@testco.com"
   ├─ Primary Contact Phone: "+1234567890"
   ├─ Address: "123 Main St, City, State"
   └─ Logo: (optional) Upload company logo
3. Click "Create Company"
4. ✅ Company created successfully
5. ✅ Company Admin account auto-created
```

**Expected Result:**
- ✅ Company appears in dashboard list
- ✅ Company Admin account created automatically
- ✅ Company Admin email = Primary Contact Email
- ✅ Company Admin password = (check console/logs for auto-generated password)

**Note:** Save the Company Admin credentials for next step!

---

### Step 3: View Company Details

```
1. Click on company card in dashboard
2. ✅ Company Details screen opens
3. View:
   ├─ Company information
   ├─ Statistics (employees, projects, etc.)
   ├─ Company Admin details
   └─ Company status (Active/Suspended)
```

---

## 🏢 Company Admin Flow

### Step 1: Login as Company Admin

**Platform:** Web Browser

```
1. Navigate to web app URL
2. Click "Admin Login" or navigate to /admin-login
3. Enter:
   ├─ Company Code: "TCC" (from Step 2)
   ├─ Email: "admin@testco.com" (from Step 2)
   └─ Password: [auto-generated password]
4. Click "Login"
5. ✅ Should redirect to Admin Dashboard
```

**Expected Result:**
- ✅ Admin Dashboard shows:
  - Total Projects: 0
  - Total Employees: 0
  - Pending Approvals: 0
  - Active Today: 0

---

### Step 2: Create Supervisor

**From:** Admin Dashboard

```
1. Click "Manage Employees" button
2. Click "Create Supervisor" button
3. Fill in supervisor details:
   ├─ Name: "Supervisor Smith"
   ├─ Email: "supervisor@testco.com"
   ├─ Phone: "+1234567891"
   ├─ Password: "Supervisor123!"
   └─ Assign Project: (leave empty for now)
4. Click "Create"
5. ✅ Supervisor account created
```

**Expected Result:**
- ✅ Supervisor appears in employees list
- ✅ Role: Supervisor
- ✅ Status: Active (no approval needed for supervisors)

**Note:** Save supervisor credentials for later!

---

### Step 3: Create Project with NFC & QR

**From:** Admin Dashboard

```
1. Click "Manage Projects" button
2. Click "Add Project" button
3. Fill in project details:
   ├─ Project Name: "Construction Site A"
   ├─ Description: "Main construction site"
   ├─ Assign Supervisor: "Supervisor Smith" (from Step 2)
   ├─ Address: "456 Construction Ave, City"
   ├─ Latitude: 40.7128 (or your location)
   ├─ Longitude: -74.0060 (or your location)
   └─ Check-in Radius: 200 (meters)
4. Check-in Methods:
   ├─ ☑ GPS Location
   ├─ ☑ NFC Tag ← CHECK THIS
   ├─ ☑ QR Code ← CHECK THIS
   └─ ☑ Manual
5. NFC Configuration:
   ├─ NFC Tag ID field appears (because NFC is checked)
   ├─ (Optional) Enter NFC Tag ID: "04:AB:CD:EF:12:34:56"
   └─ Or leave empty to accept any tag
6. QR Configuration:
   ├─ Click "Generate QR Code" button
   ├─ ✅ QR code appears with visual display
   ├─ Copy QR code data (or screenshot)
   └─ Note: QR code format is "PROJECT:{id}:{name}:{timestamp}"
7. Click "Add" button
8. ✅ Project created successfully
```

**Expected Result:**
- ✅ Project appears in projects list
- ✅ Supervisor assigned to project
- ✅ NFC Tag ID saved (if entered)
- ✅ QR Code saved
- ✅ Check-in methods: GPS, NFC, QR, Manual

**Important:** 
- Save the QR code data or take screenshot
- Note the NFC Tag ID if you entered one
- You'll need these for employee testing!

---

### Step 4: Create Employee

**From:** Admin Dashboard → Manage Employees

```
1. Click "Create Employee" button
2. Fill in employee details:
   ├─ Name: "John Employee"
   ├─ Email: "employee@testco.com"
   ├─ Phone: "+1234567892"
   ├─ Position: "Construction Worker"
   ├─ Assign Supervisor: "Supervisor Smith"
   ├─ Assign Projects: Select "Construction Site A"
   └─ Employee ID: (auto-generated, e.g., "TCC-0001")
3. Click "Create"
4. ✅ Employee created
5. ✅ PIN generated (4 digits, e.g., "1234")
```

**Expected Result:**
- ✅ Employee appears in employees list
- ✅ Status: Pending (requires approval)
- ✅ Employee ID: TCC-0001
- ✅ PIN: 1234 (save this!)

**Note:** Save employee credentials:
- Company Code: TCC
- Employee ID: TCC-0001
- PIN: 1234

---

### Step 5: Approve Employee

**From:** Admin Dashboard

```
1. View "Pending Employee Approvals" widget
2. Find "John Employee" in the list
3. Click ✅ (Approve) button
4. Review employee details in dialog
5. Click "Approve" button
6. ✅ Employee status changes to "Active"
```

**Expected Result:**
- ✅ Employee status: Active
- ✅ Employee can now log in
- ✅ Employee removed from pending list

---

### Step 6: Assign Employees to Project

**From:** Admin Dashboard → Manage Projects

```
1. Find "Construction Site A" project
2. Click 👥 (Assign Employees) icon
3. Check ☑ "John Employee"
4. Click "Save"
5. ✅ Employee assigned to project
```

**Expected Result:**
- ✅ Employee count increases in project row
- ✅ Employee can see project in mobile app

---

## 👨‍💼 Supervisor Flow

### Step 1: Login as Supervisor

**Platform:** Mobile App (Android/iOS)

```
1. Open mobile app
2. You should see "Role Selection" screen
3. Tap "Supervisor" card
4. Enter:
   ├─ Company Code: "TCC"
   ├─ Email: "supervisor@testco.com"
   └─ Password: "Supervisor123!"
5. Tap "Login"
6. ✅ Should redirect to Supervisor Dashboard
```

**Expected Result:**
- ✅ Supervisor Dashboard shows:
  - Welcome message with supervisor name
  - Assigned Project: "Construction Site A"
  - Quick Actions buttons

---

### Step 2: View Assigned Project

**From:** Supervisor Dashboard

```
1. Scroll down to "Your Assigned Project" section
2. ✅ Should see "Construction Site A" card
3. Tap on project card (optional)
4. ✅ Project details shown
```

---

### Step 3: Add Employee (Alternative Method)

**From:** Supervisor Dashboard

```
1. Tap "Add Employee" button
2. Fill in employee details:
   ├─ Name: "Jane Worker"
   ├─ Email: "jane@testco.com"
   ├─ Phone: "+1234567893"
   ├─ Position: "Laborer"
   └─ Employee ID: (auto-generated)
3. Tap "Create"
4. ✅ Employee created
5. ✅ Status: Pending (requires admin approval)
```

**Note:** This employee will need admin approval before they can log in.

---

### Step 4: View Employee List

**From:** Supervisor Dashboard

```
1. Tap "My Employees" button
2. ✅ List of employees appears
3. View employee details:
   ├─ Name
   ├─ Employee ID
   ├─ Status (Active/Pending)
   └─ Assigned Projects
```

---

### Step 5: Upload Document for Employee

**From:** Supervisor Dashboard

```
1. Tap "Upload Document" button
2. Select Employee: "John Employee"
3. Select Document Type:
   ├─ ID Proof
   ├─ Bank Statement
   ├─ Employment Contract
   └─ Other
4. Choose File:
   ├─ Tap "Choose File" button
   ├─ Select from gallery or take photo
   └─ File types: JPG, PNG, PDF, DOC, DOCX
5. Tap "Upload"
6. ✅ Document uploaded successfully
7. ✅ Status: Pending (requires admin approval)
```

**Expected Result:**
- ✅ Document uploaded to Firebase Storage
- ✅ Document record created in Firestore
- ✅ Status: Pending
- ✅ Admin can view and approve in web dashboard

---

### Step 6: Manual Check-In for Employee

**From:** Supervisor Dashboard

```
1. Tap "Manual Check-In" button
2. Select Employee: "John Employee"
3. Select Project: "Construction Site A"
4. Enter Notes: "Employee arrived late, supervisor verified"
5. Tap "Submit Check-In"
6. ✅ Manual check-in recorded
```

**Expected Result:**
- ✅ Check-in recorded immediately
- ✅ Method: Manual
- ✅ Verified by: Supervisor
- ✅ Notes saved

---

### Step 7: Approve Device Reset Request

**From:** Supervisor Dashboard

```
1. Tap "Device Reset Approvals" button
2. ✅ List of pending device reset requests appears
3. Find employee's request
4. View details:
   ├─ Employee name
   ├─ Current device info
   ├─ Reason for reset
   └─ Request date
5. Tap "Approve" button
6. ✅ Device reset approved
7. ✅ Employee can now register new device
```

---

## 👷 Employee Flow

### Step 1: Login as Employee

**Platform:** Mobile App

```
1. Open mobile app
2. Tap "Employee" card on Role Selection screen
3. Enter:
   ├─ Company Code: "TCC"
   └─ Employee ID: "TCC-0001" (or just "0001")
4. Tap "Continue"
5. Enter PIN: "1234" (4 digits)
6. Tap "Login"
7. ✅ Should redirect to Employee Dashboard
```

**Expected Result:**
- ✅ Employee Dashboard shows:
  - Welcome message
  - Employee ID displayed
  - Today's Status: "Not Checked In"
  - Assigned Projects list

**First-Time Login:**
- ✅ Device binding happens automatically
- ✅ Device info saved to user profile

---

### Step 2: View Assigned Projects

**From:** Employee Dashboard

```
1. Scroll down to "Assigned Projects" section
2. ✅ Should see "Construction Site A" project
3. Project card shows:
   ├─ Project name
   ├─ Location address
   └─ Arrow icon
```

---

### Step 3: Check-In with GPS

**From:** Employee Dashboard

```
1. Tap "Check In" button
2. ✅ Check-In screen opens
3. Select Project: "Construction Site A" (dropdown)
4. Check-in methods appear:
   ├─ 📍 GPS Check-in
   ├─ 📱 NFC Check-in
   ├─ 📷 QR Check-in
   └─ ✏️ Manual Check-in
5. Tap "GPS Check-in" card
6. ✅ System requests location permission
7. Grant location permission
8. ✅ System checks GPS location
9. ✅ Validates within project radius (200m)
10. ✅ Check-in successful!
```

**Expected Result:**
- ✅ Success dialog: "GPS Check-in Successful"
- ✅ Dashboard shows: "Checked In - Project: Construction Site A"
- ✅ Check-in recorded with:
  - Timestamp
  - GPS coordinates
  - Method: GPS
  - Device info

**If Outside Radius:**
- ❌ Error: "You are X meters away from the project site"
- ❌ Check-in fails

---

### Step 4: Check-In with NFC

**Prerequisites:**
- ✅ NFC enabled on device
- ✅ NFC tag available (physical tag or another phone)

**From:** Check-In Screen

```
1. Select Project: "Construction Site A"
2. Tap "NFC Check-in" card
3. ✅ System shows: "Hold your phone near the NFC tag"
4. Hold phone near NFC tag (back of phone to tag)
5. ✅ Tag detected
6. ✅ System reads tag ID
7. ✅ Validates tag matches project.nfcTagId (if set)
8. ✅ Check-in successful!
```

**Expected Result:**
- ✅ Success dialog: "NFC Check-in Successful"
- ✅ Check-in recorded with NFC tag ID in notes
- ✅ Tag ID saved: "04:AB:CD:EF:12:34:56" (or your tag ID)

**If Tag Doesn't Match:**
- ❌ Error: "NFC tag does not match this project. Expected: X, Got: Y"
- ❌ Check-in fails

**If No Tag ID Set:**
- ✅ Any NFC tag works (flexible mode)

---

### Step 5: Check-In with QR Code

**Prerequisites:**
- ✅ QR code generated (from Admin → Project Management)
- ✅ QR code printed or displayed on screen

**From:** Check-In Screen

```
1. Select Project: "Construction Site A"
2. Tap "QR Check-in" card
3. ✅ QR Scanner screen opens
4. ✅ Camera view appears
5. Point camera at QR code
6. ✅ QR code detected automatically
7. ✅ System validates QR code
8. ✅ Validates QR matches project.qrCode (if set)
9. ✅ Check-in successful!
```

**Expected Result:**
- ✅ Success dialog: "QR Check-in Successful"
- ✅ Check-in recorded with QR code data in notes
- ✅ QR code data saved

**If QR Doesn't Match:**
- ❌ Error: "QR code does not match this project"
- ❌ Check-in fails

**If No QR Code Set:**
- ✅ Any QR code works (flexible mode)

---

### Step 6: Check-Out with NFC

**Prerequisites:**
- ✅ Employee is currently checked in
- ✅ NFC tag available

**From:** Employee Dashboard

```
1. ✅ Dashboard shows: "Currently Checked In"
2. Tap "Check Out" button
3. ✅ Method selection dialog appears:
   ├─ GPS Location
   ├─ NFC Tag
   ├─ QR Code
   └─ Manual
4. Tap "NFC Tag" option
5. ✅ System shows: "Hold your phone near the NFC tag to check out"
6. Hold phone near NFC tag
7. ✅ Tag detected
8. ✅ System validates tag matches project.nfcTagId
9. ✅ Check-out successful!
```

**Expected Result:**
- ✅ Success dialog: "Check-out Successful"
- ✅ Dashboard shows: "Not Checked In"
- ✅ Check-out recorded with:
  - Check-out timestamp
  - Check-out method: NFC
  - NFC tag ID in notes
  - Total working hours calculated

**If Tag Doesn't Match:**
- ❌ Error: "NFC tag does not match this project"
- ❌ Check-out fails

---

### Step 7: Check-Out with QR Code

**From:** Employee Dashboard → Check Out

```
1. Tap "Check Out" button
2. Select "QR Code" from method dialog
3. ✅ QR Scanner screen opens
4. Point camera at QR code
5. ✅ QR code detected
6. ✅ System validates QR code
7. ✅ Check-out successful!
```

**Expected Result:**
- ✅ Check-out recorded with QR code data
- ✅ Working hours calculated

---

### Step 8: Request Device Reset

**From:** Employee Dashboard

```
1. Tap "Device Reset Request" button
2. ✅ Device Reset Request screen opens
3. View current device info:
   ├─ Device Model
   ├─ OS Version
   └─ Registration Date
4. Select Reason:
   ├─ Lost/stolen phone
   ├─ Upgraded to new phone
   ├─ Phone damaged
   └─ Other
5. (Optional) Enter Additional Details
6. Tap "Submit Request"
7. ✅ Request submitted
8. ✅ Status: Pending
```

**Expected Result:**
- ✅ Request appears in supervisor/admin dashboard
- ✅ Status: Pending
- ✅ Supervisor/Admin can approve

**After Approval:**
- ✅ Device binding cleared
- ✅ Employee can register new device on next login

---

## 🔄 Complete End-to-End Test Scenario

### Scenario: Full Workflow Test

**Goal:** Test complete flow from company creation to employee check-in/check-out

---

### Phase 1: Setup (Super Admin + Admin)

```
1. ✅ Super Admin creates company "ABC Corp" (Code: ABC)
2. ✅ Admin logs in (auto-created account)
3. ✅ Admin creates supervisor "Supervisor A"
4. ✅ Admin creates project "Site 1" with:
   ├─ GPS enabled
   ├─ NFC enabled (Tag ID: "04:AA:BB:CC:DD")
   ├─ QR enabled (generated QR code)
   └─ Manual enabled
5. ✅ Admin assigns supervisor to project
6. ✅ Admin creates employee "Worker 1" (ID: ABC-0001, PIN: 5678)
7. ✅ Admin assigns employee to project
8. ✅ Admin approves employee
```

---

### Phase 2: Supervisor Actions

```
1. ✅ Supervisor logs in on mobile app
2. ✅ Supervisor sees assigned project "Site 1"
3. ✅ Supervisor adds employee "Worker 2" (optional)
4. ✅ Supervisor uploads document for Worker 1
5. ✅ Supervisor performs manual check-in for Worker 1 (optional)
```

---

### Phase 3: Employee Check-In (All Methods)

```
1. ✅ Employee logs in (ABC-0001, PIN: 5678)
2. ✅ Employee sees assigned project "Site 1"

Test GPS Check-In:
3. ✅ Employee selects "Site 1"
4. ✅ Employee taps "GPS Check-in"
5. ✅ System validates location
6. ✅ Check-in successful

Test NFC Check-In:
7. ✅ Employee selects "Site 1"
8. ✅ Employee taps "NFC Check-in"
9. ✅ Employee taps NFC tag
10. ✅ System validates tag ID matches "04:AA:BB:CC:DD"
11. ✅ Check-in successful

Test QR Check-In:
12. ✅ Employee selects "Site 1"
13. ✅ Employee taps "QR Check-in"
14. ✅ Employee scans QR code
15. ✅ System validates QR code
16. ✅ Check-in successful
```

---

### Phase 4: Employee Check-Out (All Methods)

```
Test NFC Check-Out:
1. ✅ Employee taps "Check Out"
2. ✅ Employee selects "NFC Tag"
3. ✅ Employee taps NFC tag
4. ✅ System validates tag
5. ✅ Check-out successful

Test QR Check-Out:
6. ✅ Employee checks in again (any method)
7. ✅ Employee taps "Check Out"
8. ✅ Employee selects "QR Code"
9. ✅ Employee scans QR code
10. ✅ System validates QR code
11. ✅ Check-out successful
```

---

### Phase 5: Validation Tests

```
Test NFC Validation (Wrong Tag):
1. ✅ Employee tries to check-in with different NFC tag
2. ❌ Error: "NFC tag does not match this project"
3. ❌ Check-in fails

Test QR Validation (Wrong Code):
4. ✅ Employee tries to check-in with different QR code
5. ❌ Error: "QR code does not match this project"
6. ❌ Check-in fails

Test GPS Validation (Outside Radius):
7. ✅ Employee moves away from project location
8. ✅ Employee tries GPS check-in
9. ❌ Error: "You are X meters away"
10. ❌ Check-in fails
```

---

## 📊 Verification Checklist

### Admin Dashboard Verification:

- [ ] Company created successfully
- [ ] Supervisor created and assigned to project
- [ ] Project created with all check-in methods enabled
- [ ] NFC Tag ID configured (if applicable)
- [ ] QR Code generated and displayed
- [ ] Employee created and approved
- [ ] Employee assigned to project
- [ ] Documents visible in document management
- [ ] Device reset requests visible

### Supervisor Dashboard Verification:

- [ ] Supervisor can see assigned project
- [ ] Supervisor can add employees
- [ ] Supervisor can view employee list
- [ ] Supervisor can upload documents
- [ ] Supervisor can perform manual check-in
- [ ] Supervisor can approve device resets

### Employee Dashboard Verification:

- [ ] Employee can see assigned projects
- [ ] Employee can check-in with GPS
- [ ] Employee can check-in with NFC
- [ ] Employee can check-in with QR
- [ ] Employee can check-out with NFC
- [ ] Employee can check-out with QR
- [ ] NFC validation works (rejects wrong tags)
- [ ] QR validation works (rejects wrong codes)
- [ ] Device reset request works

---

## 🐛 Troubleshooting

### NFC Not Working:

**Issue:** NFC check-in fails
**Solutions:**
1. Check NFC is enabled on device (Settings → NFC)
2. Check device supports NFC
3. Try different NFC tag
4. Check NFC Tag ID matches (if configured)
5. Try leaving NFC Tag ID empty in project settings

### QR Code Not Scanning:

**Issue:** QR scanner doesn't detect code
**Solutions:**
1. Check camera permission granted
2. Ensure good lighting
3. Hold phone steady
4. Try regenerating QR code
5. Check QR code matches project QR code

### GPS Check-In Fails:

**Issue:** "You are not at the work location"
**Solutions:**
1. Check location permission granted
2. Verify GPS coordinates in project settings
3. Check radius setting (increase if needed)
4. Ensure you're actually at the location
5. Try refreshing location

### Employee Can't See Projects:

**Issue:** "No projects assigned"
**Solutions:**
1. Verify employee is approved (status: Active)
2. Check employee is assigned to project in admin dashboard
3. Refresh employee dashboard (pull down)
4. Check company code matches

---

## 📝 Test Data Summary

### Company:
- **Name:** Test Construction Co.
- **Code:** TCC
- **Admin Email:** admin@testco.com

### Supervisor:
- **Name:** Supervisor Smith
- **Email:** supervisor@testco.com
- **Password:** Supervisor123!

### Employee:
- **Name:** John Employee
- **ID:** TCC-0001
- **PIN:** 1234
- **Email:** employee@testco.com

### Project:
- **Name:** Construction Site A
- **Location:** 456 Construction Ave
- **NFC Tag ID:** (your tag ID or leave empty)
- **QR Code:** (generated in admin dashboard)

---

## ✅ Success Criteria

All functionalities are working correctly if:

1. ✅ Super Admin can create companies
2. ✅ Admin can create projects with NFC/QR configuration
3. ✅ Admin can create and approve employees
4. ✅ Supervisor can manage employees and documents
5. ✅ Employee can check-in with GPS/NFC/QR
6. ✅ Employee can check-out with NFC/QR
7. ✅ NFC validation rejects wrong tags
8. ✅ QR validation rejects wrong codes
9. ✅ Device reset requests work
10. ✅ All data appears correctly in dashboards

---

**Happy Testing! 🚀**
