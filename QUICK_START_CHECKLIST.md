# ✅ Quick Start Checklist

## 🎯 30-Minute Setup & Test

### ☑️ STEP 1: Create Admin User (5 min)
- [ ] Open Firebase Console → Authentication
- [ ] Add user: `admin@company.com` / `admin123`
- [ ] Copy the UID from Authentication
- [ ] Open Firestore → `users` collection
- [ ] Create document with copied UID
- [ ] Add fields:
  ```
  uid: [pasted UID]
  email: "admin@company.com"
  name: "Admin User"
  role: "admin"
  status: "approved"
  createdAt: [current timestamp]
  updatedAt: [current timestamp]
  ```

### ☑️ STEP 2: Run & Test Admin Dashboard (5 min)
- [ ] Run command:
  ```bash
  flutter run -d chrome --web-browser-flag "--disable-web-security" --web-browser-flag "--user-data-dir=/tmp/chrome_dev_test"
  ```
- [ ] Login: `admin@company.com` / `admin123`
- [ ] Check browser console (F12) for debug logs
- [ ] ✅ Should see: "🎉 LOGIN SUCCESSFUL!"

### ☑️ STEP 3: Create Project (2 min)
- [ ] Dashboard → Projects → Add Project
- [ ] Fill:
  ```
  Name: Test Project A
  Location: Test Location
  Status: Active
  ```
- [ ] Click Save
- [ ] ✅ Project appears in list

### ☑️ STEP 4: Create Supervisor Account (3 min)
- [ ] Dashboard → Employees → Add Employee
- [ ] Fill the form:
  ```
  Name: Test Supervisor
  Email: supervisor@test.com
  Password: super123
  Phone: +1234567890
  Role: supervisor ◄─── SELECT "SUPERVISOR" FROM DROPDOWN
  Assign Project: Test Project A ◄─── THIS LINKS SUPERVISOR TO PROJECT
  ```
- [ ] Click "Add Employee" button
- [ ] ✅ Supervisor appears in list with status "approved"
- [ ] ✅ Creates Firebase Auth account (email/password)
- [ ] ✅ Creates Firestore document (users collection)
- [ ] ✅ Supervisor is now LINKED to "Test Project A"

**What happens:** Admin creates supervisor → System creates both Auth account AND Firestore document → Supervisor can now login with email/password

📖 **Detailed guide:** See `ACCOUNT_CREATION_GUIDE.md` → Part 2

### ☑️ STEP 5: Run Mobile App (2 min)
- [ ] Open new terminal
- [ ] Run command:
  ```bash
  flutter run
  ```
- [ ] Select device (Android/iOS emulator or physical device)
- [ ] ✅ App launches successfully

### ☑️ STEP 6: Supervisor Adds Employee Account (3 min)
- [ ] In mobile app → Tap "Login"
- [ ] Select "Email/Password" login method
- [ ] Email: `supervisor@test.com`
- [ ] Password: `super123`
- [ ] ✅ Supervisor Dashboard opens (shows assigned project)
- [ ] Tap "Add Employee" or "Manage Employees" button
- [ ] Fill the form:
  ```
  Name: Test Employee
  Email: employee@test.com
  Phone: +1234567891
  Position: Worker
  ```
- [ ] Tap "Add" button
- [ ] ✅ Success dialog appears showing:
  ```
  Employee ID: 0001 ◄─── AUTO-GENERATED
  PIN: 1234        ◄─── AUTO-GENERATED
  Status: Pending Approval
  ```
- [ ] **IMPORTANT: Write down ID and PIN!**
- [ ] ✅ Does NOT create Firebase Auth account
- [ ] ✅ Creates Firestore document only (users collection)
- [ ] ✅ Employee is LINKED to supervisor's project automatically
- [ ] ✅ Status: "pending" (needs admin approval)

**What happens:** Supervisor adds employee → System creates Firestore document → Auto-generates ID (0001) and PIN (1234) → Links to same project as supervisor → Waits for admin approval

📖 **Detailed guide:** See `ACCOUNT_CREATION_GUIDE.md` → Part 3

### ☑️ STEP 7: Admin Approves Employee (2 min)
- [ ] Go back to Web Dashboard
- [ ] Employees → Pending Approvals
- [ ] Find "Test Employee"
- [ ] Click "Approve"
- [ ] ✅ Status changes to "approved"

### ☑️ STEP 8: Employee Logs In (3 min)
- [ ] In mobile app → Logout (if logged in as supervisor)
- [ ] Tap "Login"
- [ ] Select "Employee Login"
- [ ] Employee ID: `0001`
- [ ] PIN: `1234`
- [ ] ✅ Employee Dashboard opens

### ☑️ STEP 9: Employee Checks In (2 min)
- [ ] Tap "Check In" button
- [ ] Choose "GPS Check-In"
- [ ] Allow location permissions
- [ ] ✅ Status changes to "Checked In"
- [ ] ✅ Timer starts

### ☑️ STEP 10: Verify Data Flow (3 min)
- [ ] Go to Web Dashboard
- [ ] Navigate to Attendance
- [ ] ✅ See employee check-in record
- [ ] In mobile app → Employee → Check Out
- [ ] Refresh web dashboard
- [ ] ✅ See check-out record with total hours

---

## ✨ Success! You've completed the full workflow:

✅ Admin created project  
✅ Admin created supervisor  
✅ Supervisor added employee  
✅ Admin approved employee  
✅ Employee checked in/out  
✅ Data flows between all apps  

---

## 🚀 Next: Test Advanced Features

- [ ] Add more employees (IDs: 0002, 0003, ...)
- [ ] Create second project
- [ ] Test QR code check-in
- [ ] Upload documents
- [ ] Export attendance reports
- [ ] Test device management

---

## 🆘 If Something Goes Wrong

### Admin can't login?
→ Check `COMPLETE_WORKFLOW_GUIDE.md` → "Issue 5"  
→ Look at browser console debug logs

### Supervisor can't add employees?
→ Verify supervisor is assigned to a project

### Employee can't login?
→ Verify status is "approved" in Firestore  
→ Check ID format is 4 digits (0001 not 1)

### Check-in fails?
→ Enable location permissions  
→ Check employee status is "approved"

---

**📖 Full details:** See `COMPLETE_WORKFLOW_GUIDE.md`

