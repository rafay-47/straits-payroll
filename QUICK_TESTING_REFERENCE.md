# ⚡ Quick Testing Reference - Step by Step

**Quick guide for testing all functionalities**

---

## 🎯 Quick Start - 5 Minute Test

### 1️⃣ Super Admin → Create Company (2 min)

```
Web Browser:
1. Login as Super Admin
2. Click "Create Company"
3. Fill: Name="Test Co", Code="TST"
4. Click "Create"
✅ Company Admin auto-created
```

### 2️⃣ Admin → Setup Project (3 min)

```
Web Browser:
1. Login as Admin (Company Code: TST)
2. Create Supervisor: "Supervisor 1"
3. Create Project: "Site 1"
   ├─ Enable NFC (enter tag ID or leave empty)
   ├─ Enable QR (click Generate)
   └─ Assign Supervisor
4. Create Employee: "Worker 1" (save PIN!)
5. Approve Employee
6. Assign Employee to Project
```

### 3️⃣ Employee → Test Check-In (2 min)

```
Mobile App:
1. Login as Employee (Code: TST, ID: TST-0001, PIN: [saved])
2. Tap "Check In"
3. Select Project: "Site 1"
4. Test NFC: Tap NFC card → ✅ Success
5. Test QR: Scan QR code → ✅ Success
```

---

## 📱 Complete Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    SUPER ADMIN (Web)                         │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ 1. Login → Dashboard                                  │  │
│  │ 2. Create Company → Auto-creates Admin               │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                  COMPANY ADMIN (Web)                        │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ 1. Login (Company Code + Email + Password)           │  │
│  │ 2. Create Supervisor                                 │  │
│  │ 3. Create Project:                                   │  │
│  │    ├─ Enable NFC → Enter Tag ID (optional)          │  │
│  │    ├─ Enable QR → Generate QR Code                   │  │
│  │    └─ Assign Supervisor                              │  │
│  │ 4. Create Employee → Save PIN!                       │  │
│  │ 5. Approve Employee                                  │  │
│  │ 6. Assign Employee to Project                        │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    SUPERVISOR (Mobile)                      │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ 1. Login (Company Code + Email + Password)           │  │
│  │ 2. View Assigned Project                             │  │
│  │ 3. Add Employees (optional)                          │  │
│  │ 4. Upload Documents                                  │  │
│  │ 5. Manual Check-In                                   │  │
│  │ 6. Approve Device Resets                             │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                     EMPLOYEE (Mobile)                       │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ 1. Login (Company Code + Employee ID + PIN)         │  │
│  │ 2. View Assigned Projects                            │  │
│  │ 3. CHECK-IN:                                         │  │
│  │    ├─ GPS → Validates location                      │  │
│  │    ├─ NFC → Reads tag → Validates                   │  │
│  │    ├─ QR → Scans code → Validates                   │  │
│  │    └─ Manual → Requires approval                    │  │
│  │ 4. CHECK-OUT:                                        │  │
│  │    ├─ Select Method (NFC/QR/GPS/Manual)            │  │
│  │    ├─ NFC → Validates tag                           │  │
│  │    └─ QR → Validates code                           │  │
│  │ 5. Request Device Reset                             │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔑 Test Credentials Template

Create these accounts for testing:

### Super Admin:
```
Email: superadmin@test.com
Password: SuperAdmin123!
```

### Company Admin (Auto-created):
```
Company Code: TST
Email: admin@testco.com (from company creation)
Password: [Check console/logs for auto-generated]
```

### Supervisor:
```
Company Code: TST
Email: supervisor@testco.com
Password: Supervisor123!
```

### Employee:
```
Company Code: TST
Employee ID: TST-0001
PIN: [Generated, e.g., 1234]
```

---

## ✅ Feature Testing Checklist

### Web Admin Features:
- [ ] Create Company
- [ ] Create Supervisor
- [ ] Create Project with NFC enabled
- [ ] Enter NFC Tag ID in project
- [ ] Generate QR Code in project
- [ ] Create Employee
- [ ] Approve Employee
- [ ] Assign Employee to Project
- [ ] View Documents
- [ ] Approve/Reject Documents
- [ ] View Reports
- [ ] Manage Device Resets

### Mobile Supervisor Features:
- [ ] Login as Supervisor
- [ ] View Assigned Project
- [ ] Add Employee
- [ ] View Employee List
- [ ] Upload Document
- [ ] Manual Check-In
- [ ] Approve Device Reset

### Mobile Employee Features:
- [ ] Login as Employee
- [ ] View Assigned Projects
- [ ] GPS Check-In
- [ ] NFC Check-In (with correct tag)
- [ ] NFC Check-In (with wrong tag) → Should fail
- [ ] QR Check-In (with correct code)
- [ ] QR Check-In (with wrong code) → Should fail
- [ ] NFC Check-Out
- [ ] QR Check-Out
- [ ] Request Device Reset

---

## 🧪 Testing Scenarios

### Scenario 1: NFC Validation Test

**Setup:**
1. Create project with NFC Tag ID: "04:AA:BB:CC"
2. Get NFC tag with ID: "04:AA:BB:CC" (correct)
3. Get NFC tag with ID: "04:XX:YY:ZZ" (wrong)

**Test:**
```
✅ Correct Tag:
1. Employee taps NFC Check-in
2. Taps correct tag (04:AA:BB:CC)
3. ✅ Check-in succeeds

❌ Wrong Tag:
1. Employee taps NFC Check-in
2. Taps wrong tag (04:XX:YY:ZZ)
3. ❌ Error: "NFC tag does not match this project"
4. ❌ Check-in fails
```

---

### Scenario 2: QR Validation Test

**Setup:**
1. Create project and generate QR code
2. QR Code: "PROJECT:proj123:Site A:1234567890"
3. Print/display QR code

**Test:**
```
✅ Correct QR:
1. Employee taps QR Check-in
2. Scans correct QR code
3. ✅ Check-in succeeds

❌ Wrong QR:
1. Employee taps QR Check-in
2. Scans different QR code
3. ❌ Error: "QR code does not match this project"
4. ❌ Check-in fails
```

---

### Scenario 3: Check-Out Flow Test

**Setup:**
1. Employee checks in (any method)
2. Employee is now "Checked In"

**Test:**
```
1. Employee taps "Check Out"
2. Method dialog appears
3. Select "NFC Tag"
4. Tap NFC tag
5. ✅ System validates tag
6. ✅ Check-out succeeds
7. ✅ Working hours calculated
```

---

## 📋 Quick Command Reference

### Web URLs (if using routing):
```
Super Admin Login: /super-admin-login
Admin Login: /admin-login
Admin Dashboard: /admin-dashboard
Project Management: /projects
Employee Management: /employees
```

### Mobile Routes:
```
Role Selection: /
Employee Login: /employee-login
Supervisor Login: /supervisor-login
Employee Dashboard: (after login)
Supervisor Dashboard: (after login)
```

---

## 🐛 Common Issues & Fixes

| Issue | Solution |
|-------|----------|
| NFC not detected | Enable NFC in device settings |
| QR not scanning | Grant camera permission |
| GPS check-in fails | Check location permission & coordinates |
| Employee can't see projects | Verify employee is approved & assigned |
| NFC tag doesn't match | Check NFC Tag ID in project settings |
| QR code doesn't match | Regenerate QR code in project settings |

---

## 📞 Testing Support

If you encounter issues:

1. **Check Console Logs:**
   - Web: Browser DevTools (F12)
   - Mobile: Flutter DevTools or `flutter logs`

2. **Verify Firebase:**
   - Check Firestore data structure
   - Verify companyId is set correctly
   - Check project.nfcTagId and project.qrCode

3. **Check Permissions:**
   - Location permission (GPS)
   - Camera permission (QR)
   - NFC enabled (NFC)

---

**Ready to test! Follow the complete guide above for detailed steps.** 🚀
