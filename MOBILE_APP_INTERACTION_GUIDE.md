# 📱 Mobile App Interaction Guide
## Employee & Supervisor App Usage

---

## 🎯 Overview

This guide shows you **exactly how to interact** with the Employee and Supervisor mobile apps based on real-world scenarios.

---

## 📋 Prerequisites

### Before You Start:
1. ✅ **Admin has created accounts via Web Dashboard**
   - Admin logged into web dashboard
   - Created supervisor account (with Firebase Auth credentials)
   - Created employee account (linked to supervisor/project)

2. ✅ **Project Setup Complete**
   - Project created by admin
   - Project assigned to supervisor
   - Check-in methods configured (GPS/NFC/QR/Manual)

---

## 🧑‍💼 SUPERVISOR APP - Complete Workflow

### 🔐 Step 1: Login to Supervisor App

```
📱 Launch Mobile App
   ↓
🔑 Select "Supervisor Login"
   ↓
📧 Enter Email: supervisor@company.com
🔒 Enter Password: [password set by admin]
   ↓
✅ Click "Login"
   ↓
🎉 Redirected to Supervisor Dashboard
```

**What You'll See:**
- Welcome card with your name
- Your assigned projects
- Quick action buttons

---

### 📊 Step 2: View Your Dashboard

**Main Dashboard Features:**

```
╔══════════════════════════════════════╗
║   SUPERVISOR DASHBOARD               ║
║   Welcome back, [Supervisor Name]    ║
╠══════════════════════════════════════╣
║  📋 Active Projects                  ║
║     • Project Name                   ║
║     • Location                       ║
║     • Check-in Methods               ║
╠══════════════════════════════════════╣
║  🎯 Quick Actions                    ║
║     [➕ Add Employee]                ║
║     [👥 View Employees]              ║
║     [✅ Manual Check-in]             ║
║     [📄 Upload Documents]            ║
║     [📱 Device Reset Approvals]      ║
╚══════════════════════════════════════╝
```

---

### 👤 Step 3: Add New Employee

**Scenario:** You need to onboard a new employee who doesn't have a smartphone.

```
📱 Supervisor Dashboard
   ↓
🔘 Tap "Add Employee" button
   ↓
📝 Fill Employee Details:
   ├─ Name: John Smith
   ├─ Email: john@company.com
   ├─ Phone: +1234567890
   ├─ Position: Labor Worker
   ├─ Custom ID: EMP001 (optional)
   └─ Assign to Project: [Select from dropdown]
   ↓
💾 Tap "Add Employee"
   ↓
✅ Success! Employee account created
```

**Important Notes:**
- ✅ System auto-generates a unique **System ID** (e.g., 0001, 0002)
- ✅ Employee can login with either **Custom ID** OR **System ID**
- ✅ Employee account status = "approved" by default
- ✅ No Firebase Auth created (employee uses ID-based login)

---

### 👥 Step 4: View & Manage Employees

```
📱 Supervisor Dashboard
   ↓
🔘 Tap "View Employees" button
   ↓
📋 Employee List Screen
   ├─ Search bar (search by name/ID)
   ├─ Filter options
   └─ List of all your employees
   ↓
🔘 Tap on any employee
   ↓
📊 Employee Details View:
   ├─ Personal Info
   ├─ Contact Details
   ├─ Account Info (System ID, Custom ID)
   ├─ Device Info (if registered)
   ├─ Status & Dates
   └─ [Actions: Edit | Delete]
```

---

### ✅ Step 5: Manual Check-in for Employees

**Scenario:** Employee doesn't have a smartphone, you check them in.

```
📱 Supervisor Dashboard
   ↓
🔘 Tap "Manual Check-in" button
   ↓
📋 Manual Check-in Screen
   ↓
👤 Select Employee:
   ├─ Search by name or ID
   └─ Select from list
   ↓
📍 Select Project:
   └─ Choose active project
   ↓
⏰ Action Type:
   ├─ ☑️ Check-in (start work)
   └─ ☐ Check-out (end work)
   ↓
📝 Add Notes (optional):
   └─ "Started morning shift"
   ↓
✅ Tap "Submit Check-in"
   ↓
🎉 Attendance recorded!
```

**Auto-Captured:**
- ✅ Timestamp
- ✅ GPS location (if enabled)
- ✅ Supervisor ID (who did the check-in)
- ✅ Method: "Manual"

---

### 📄 Step 6: Upload Employee Documents

**Scenario:** Upload employee's ID, bank statement, contract.

```
📱 Supervisor Dashboard
   ↓
🔘 Tap "Upload Documents" button
   ↓
📋 Upload Document Screen
   ↓
👤 Select Employee:
   └─ Choose from dropdown
   ↓
📁 Select Document Type:
   ├─ ID Card
   ├─ Bank Statement
   ├─ Contract
   └─ Other
   ↓
📸 Choose Upload Method:
   ├─ 📷 Take Photo (camera)
   └─ 📁 Browse Files
   ↓
📝 Add Description (optional):
   └─ "Employee ID - Front side"
   ↓
☁️ Tap "Upload"
   ↓
⏳ Uploading... (progress bar)
   ↓
✅ Document uploaded successfully!
```

**Where it's stored:**
- ✅ Firebase Storage
- ✅ Linked to employee ID
- ✅ Visible in web dashboard

---

### 📱 Step 7: Approve Device Reset Requests

**Scenario:** Employee lost phone and requested device reset.

```
📱 Supervisor Dashboard
   ↓
🔘 Tap "Device Reset Approvals" button
   ↓
📋 Device Reset Requests List
   ├─ Pending Requests (yellow badge)
   ├─ Approved Requests (green)
   └─ Rejected Requests (red)
   ↓
🔘 Tap on a pending request
   ↓
📊 Request Details:
   ├─ Employee Name
   ├─ Current Device Info
   ├─ Request Date
   ├─ Reason
   └─ Reset Count (this month)
   ↓
💬 Review the request
   ↓
Choose Action:
   ├─ ✅ Approve
   └─ ❌ Reject
   ↓
If Approving:
   └─ Confirm approval
      ↓
      ✅ Device reset approved!
      └─ Employee can now login with new device
   
If Rejecting:
   └─ Enter rejection reason
      ↓
      ❌ Request rejected
      └─ Employee receives notification
```

---

## 👷 EMPLOYEE APP - Complete Workflow

### 🔐 Step 1: First Time Login

```
📱 Launch Mobile App
   ↓
🔑 Select "Employee Login"
   ↓
📋 Enter ONE of these:
   ├─ System ID: 0001 (auto-generated by system)
   └─ Custom ID: EMP001 (set by supervisor)
   ↓
✅ Click "Login"
   ↓
🎉 Redirected to Employee Dashboard
```

**What Happens:**
- ✅ System captures device information automatically
- ✅ Device is bound to this employee account
- ✅ Future logins only allowed from THIS device

**First Login Captures:**
- Device Model
- Platform (iOS/Android)
- OS Version
- Unique Device ID

---

### 📊 Step 2: View Your Dashboard

**Main Dashboard Features:**

```
╔══════════════════════════════════════╗
║   EMPLOYEE DASHBOARD                 ║
║   Welcome back, [Employee Name]      ║
║   ID: 0001                           ║
╠══════════════════════════════════════╣
║  📊 Today's Status                   ║
║     🔵 Checked In: 09:00 AM         ║
║     ⏱️  Working Hours: 4h 30m        ║
╠══════════════════════════════════════╣
║  📋 Your Projects                    ║
║     • Project Name                   ║
║     • Location                       ║
║     • Check-in Method                ║
╠══════════════════════════════════════╣
║  🎯 Quick Actions                    ║
║     [✅ Check In/Out]                ║
║     [📱 Device Reset Request]        ║
╚══════════════════════════════════════╝
```

---

### ✅ Step 3: Check-In to Work

**Scenario:** Employee arrives at work location.

#### Method A: GPS Check-In

```
📱 Employee Dashboard
   ↓
🔘 Tap "Check In" button
   ↓
📍 Check-in Screen Opens
   ↓
📡 System checks GPS location automatically
   ↓
✅ If within project radius:
   ├─ Select Project
   ├─ Confirm check-in
   └─ ✅ Checked in successfully!
   
❌ If outside project radius:
   └─ Error: "You are not at the work location"
```

#### Method B: NFC Check-In

```
📱 Employee Dashboard
   ↓
🔘 Tap "Check In" button
   ↓
📱 Check-in Screen Opens
   ↓
🔘 Tap "NFC Scan" button
   ↓
📡 Hold phone near NFC tag
   ↓
✅ Tag detected!
   ├─ System validates tag
   ├─ Matches project
   └─ ✅ Checked in successfully!
```

#### Method C: QR Code Check-In

```
📱 Employee Dashboard
   ↓
🔘 Tap "Check In" button
   ↓
📱 Check-in Screen Opens
   ↓
🔘 Tap "Scan QR Code" button
   ↓
📷 Camera opens
   ↓
🔲 Scan QR code at location
   ↓
✅ Code validated!
   └─ ✅ Checked in successfully!
```

**Auto-Captured with Check-In:**
- ✅ Timestamp
- ✅ GPS coordinates
- ✅ Device info
- ✅ Check-in method used

---

### 🏁 Step 4: Check-Out from Work

```
📱 Employee Dashboard
   ↓
📊 Current Status: "Checked In"
   ↓
🔘 Tap "Check Out" button
   ↓
⚠️  Confirmation Dialog:
   "Are you sure you want to check out?"
   ↓
✅ Confirm
   ↓
🎉 Checked out successfully!
   ├─ Check-out time recorded
   ├─ Total hours calculated
   └─ Dashboard updated
```

**What's Recorded:**
- ✅ Check-out timestamp
- ✅ Total work hours
- ✅ Location (if GPS enabled)

---

### 📱 Step 5: Request Device Reset

**Scenario:** Employee lost phone or got a new device.

```
📱 Employee Dashboard
   ↓
🔘 Tap "Device Reset Request" button
   ↓
📋 Device Reset Request Screen
   ↓
📝 Fill Request Details:
   ├─ Reason: [Select from dropdown]
   │   ├─ Device Lost
   │   ├─ Device Stolen
   │   ├─ New Device
   │   └─ Device Damaged
   └─ Additional Notes (optional)
   ↓
📊 View Your Request History:
   ├─ Pending requests
   ├─ Approved requests
   └─ Rejected requests
   ↓
✅ Tap "Submit Request"
   ↓
🎉 Request submitted!
   └─ Wait for supervisor approval
```

**Important Rules:**
- ⚠️ Limited to **1 reset per month** (configurable)
- ✅ Can check request status in app
- ✅ Receives notification on approval/rejection

---

### 🔄 Step 6: After Device Reset Approval

```
📱 New Device
   ↓
🔑 Login with your ID
   ├─ System ID: 0001
   └─ OR Custom ID: EMP001
   ↓
✅ Login successful!
   ├─ Old device unbound
   ├─ New device registered
   └─ Can now check-in from new device
```

---

## 🔄 Complete Real-World Scenarios

### Scenario 1: New Employee Onboarding (No Smartphone)

```
STEP 1: Admin creates supervisor account (Web Dashboard)
   ↓
STEP 2: Supervisor logs into mobile app
   ↓
STEP 3: Supervisor adds new employee
   ├─ Name: John
   ├─ ID: EMP001
   └─ Project: Construction Site A
   ↓
STEP 4: Supervisor uploads employee documents
   ├─ ID Card photo
   └─ Contract
   ↓
STEP 5: Every day, supervisor does manual check-in/out
   ├─ Morning: Check-in John
   └─ Evening: Check-out John
```

---

### Scenario 2: Employee with Smartphone (GPS Check-In)

```
STEP 1: Admin creates supervisor account (Web Dashboard)
   ↓
STEP 2: Supervisor logs into mobile app
   ↓
STEP 3: Supervisor adds new employee
   ├─ Name: Sarah
   ├─ ID: 0002
   └─ Project: Office Building
   ↓
STEP 4: Employee (Sarah) logs into mobile app
   ├─ Enter ID: 0002
   └─ Device automatically registered
   ↓
STEP 5: Employee arrives at work location
   ↓
STEP 6: Employee opens app → Tap "Check In"
   ├─ GPS verified
   └─ ✅ Checked in
   ↓
STEP 7: End of day → Tap "Check Out"
   └─ ✅ Checked out (hours calculated)
```

---

### Scenario 3: Employee Lost Phone

```
STEP 1: Employee lost their phone
   ├─ Can't access app
   └─ Can't check-in
   ↓
STEP 2: Employee tells supervisor
   ↓
STEP 3: Supervisor does manual check-in temporarily
   ↓
STEP 4: Employee gets new phone
   ↓
STEP 5: Employee installs app on new device
   ↓
STEP 6: Try to login with ID
   ↓
❌ Error: "Device mismatch"
   ↓
STEP 7: Employee sees "Request Device Reset" option
   ↓
STEP 8: Employee submits reset request
   ├─ Reason: Device Lost
   └─ Notes: "Lost phone, using new device"
   ↓
STEP 9: Supervisor receives notification
   ↓
STEP 10: Supervisor reviews and approves
   ↓
✅ Employee can now login with new device
```

---

### Scenario 4: Multi-Employee Project with NFC

```
STEP 1: Admin creates project (Web Dashboard)
   ├─ Name: Warehouse Project
   ├─ Check-in: NFC enabled
   └─ NFC tags placed at entrance
   ↓
STEP 2: Admin assigns project to supervisor
   ↓
STEP 3: Supervisor adds 5 employees
   ├─ EMP001, EMP002, EMP003...
   └─ All assigned to Warehouse Project
   ↓
STEP 4: Each employee logs into mobile app
   └─ Device registered for each
   ↓
STEP 5: Morning - All employees arrive
   ↓
STEP 6: Each employee:
   ├─ Opens app
   ├─ Taps "Check In"
   ├─ Taps phone to NFC tag
   └─ ✅ Checked in
   ↓
STEP 7: Evening - All employees:
   ├─ Tap "Check Out"
   ├─ Tap phone to NFC tag
   └─ ✅ Checked out
   ↓
STEP 8: Supervisor/Admin views attendance report
   └─ All 5 employees' hours recorded
```

---

## 📊 Dashboard Feature Comparison

| Feature | Employee App | Supervisor App |
|---------|-------------|----------------|
| **Login Method** | System ID / Custom ID | Email + Password |
| **Check-in** | ✅ Self check-in | ✅ Manual check-in for others |
| **Projects View** | Assigned projects only | All managed projects |
| **Add Employees** | ❌ | ✅ |
| **Upload Documents** | ❌ | ✅ |
| **Device Reset** | Request only | Approve/Reject |
| **Attendance History** | Own history | All employees |
| **Profile Edit** | Limited | Full access |

---

## 🎯 Quick Tips

### For Supervisors:
✅ **Do:**
- Add employees immediately after project assignment
- Upload documents during onboarding
- Review device reset requests promptly
- Use manual check-in for employees without smartphones

❌ **Don't:**
- Forget to assign employees to projects
- Ignore device reset requests
- Share your login credentials

### For Employees:
✅ **Do:**
- Check in/out at exact work times
- Keep your device information up to date
- Request device reset immediately if phone is lost
- Remember your System ID or Custom ID

❌ **Don't:**
- Try to check-in outside project location (GPS mode)
- Share your ID with others
- Attempt to login from multiple devices

---

## 🔧 Troubleshooting

### "Can't Login" (Employee)
- ✅ Check if using correct ID (System ID or Custom ID)
- ✅ Verify account is approved
- ✅ Check device binding status

### "Device Mismatch" (Employee)
- ✅ Submit device reset request
- ✅ Wait for supervisor approval
- ✅ Contact supervisor if urgent

### "Check-in Failed" (Employee)
- ✅ Verify GPS is enabled (GPS mode)
- ✅ Ensure you're at work location
- ✅ Check project is active
- ✅ Verify NFC/QR code is working

### "Can't Add Employee" (Supervisor)
- ✅ Ensure all required fields filled
- ✅ Check project assignment is valid
- ✅ Verify internet connection

---

## 📞 Support Flow

```
Issue Occurs
   ↓
Employee contacts Supervisor
   ↓
Supervisor checks Web Dashboard
   ↓
If can't resolve → Contact Admin
   ↓
Admin checks:
   ├─ Firebase Auth
   ├─ Firestore data
   ├─ Security rules
   └─ Logs
```

---

## 🎓 Next Steps

1. **Review:** [COMPLETE_WORKFLOW_GUIDE.md](COMPLETE_WORKFLOW_GUIDE.md)
2. **Setup:** [QUICK_START_CHECKLIST.md](QUICK_START_CHECKLIST.md)
3. **Accounts:** [ACCOUNT_CREATION_GUIDE.md](ACCOUNT_CREATION_GUIDE.md)
4. **Testing:** Run through Scenario 1 or 2 above

---

**Last Updated:** November 16, 2025
**App Version:** 1.0.0

