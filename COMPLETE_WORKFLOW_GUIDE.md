# Complete System Workflow Guide

## 🎯 Quick Overview

**Admin Dashboard (Web)** → Creates everything  
**Supervisor App (Mobile)** → Manages employees & attendance  
**Employee App (Mobile)** → Check-in/out & view info

---

## 📋 System Hierarchy (Dependencies)

```
1. ADMIN (Web Dashboard)
   ↓ Creates Projects
   ↓ Creates Supervisor Accounts
   ↓ Approves Employees
   
2. SUPERVISOR (Mobile App)
   ↓ Logs in to assigned project
   ↓ Adds Employees to project
   ↓ Assigns Employee IDs & PINs
   
3. EMPLOYEE (Mobile App)
   ↓ Logs in with ID & PIN
   ↓ Checks in/out
   ↓ Views attendance
```

---

## 🚀 Complete Setup Flow (Step-by-Step)

### **PHASE 1: Admin Setup (Web Dashboard)**

1. **Create Admin User in Firebase Console**
   - Go to: Firebase Console → Authentication
   - Add user: `admin@company.com` / `admin123`
   - Go to: Firestore Database → `users` collection
   - Create document with ID from Authentication UID:
     ```
     uid: [copy from Auth]
     email: "admin@company.com"
     name: "Admin User"
     role: "admin"
     status: "approved"
     createdAt: [timestamp]
     updatedAt: [timestamp]
     ```

2. **Login to Web Dashboard**
   ```bash
   flutter run -d chrome --web-browser-flag "--disable-web-security" --web-browser-flag "--user-data-dir=/tmp/chrome_dev_test"
   ```
   - Open browser console (F12) to see debug logs
   - Login with: `admin@company.com` / `admin123`

3. **Create a Project**
   - Dashboard → Projects → Add Project
   - Example:
     ```
     Name: Construction Site A
     Location: Downtown
     Supervisor: (leave empty for now)
     Status: Active
     ```

4. **Create Supervisor Account**
   - Dashboard → Employees → Add Employee
   - Fill form:
     ```
     Name: John Supervisor
     Email: supervisor1@company.com
     Password: super123
     Phone: +1234567890
     Role: supervisor
     Project: Construction Site A
     ```
   - Click "Add Employee"
   - System creates Firebase Auth account + Firestore document
   - **Status will be "approved" automatically**

---

### **PHASE 2: Supervisor Setup (Mobile App)**

5. **Run Supervisor App**
   ```bash
   flutter run -d <device>
   # Or for Android emulator:
   flutter run -d emulator-5554
   ```

6. **Supervisor Login**
   - Open app → Select "Login"
   - **Login Method: Email/Password** (not ID/PIN)
   - Email: `supervisor1@company.com`
   - Password: `super123`
   - App detects role = "supervisor" → Shows Supervisor Dashboard

7. **Add First Employee**
   - Supervisor Dashboard → "Manage Employees" or "Add Employee"
   - Fill form:
     ```
     Name: Alice Worker
     Email: alice@company.com
     Phone: +1234567891
     Position: Construction Worker
     ```
   - Click "Add"
   - **System AUTO-ASSIGNS:**
     - Employee ID: `0001` (first employee)
     - PIN: `1234` (4-digit, auto-generated)
     - Project: Supervisor's project (Construction Site A)
     - Status: `pending` (needs admin approval)

8. **View Employee Details**
   - After adding, supervisor sees:
     ```
     Employee ID: 0001
     PIN: 1234
     Status: Pending Approval
     ```
   - **Note down the ID and PIN** to give to the employee

---

### **PHASE 3: Admin Approval (Web Dashboard)**

9. **Approve Employee**
   - Go back to Web Dashboard
   - Navigate to "Employees" → "Pending Approvals"
   - Find "Alice Worker" (Status: Pending)
   - Click "Approve"
   - Status changes to: `approved`
   - Now employee can login!

---

### **PHASE 4: Employee Usage (Mobile App)**

10. **Employee Login**
    - Open Employee App (same app, different login)
    - Select "Login"
    - **Login Method: ID/PIN**
    - Employee ID: `0001`
    - PIN: `1234`
    - App detects role = "employee" → Shows Employee Dashboard

11. **Employee Check-In**
    - Dashboard → "Check In" button
    - Choose method:
      - **GPS Check-In**: Uses current location (easiest for testing)
      - **QR Code**: Requires QR code scan
      - **Geofence**: Requires being within project area
    - For testing, use **GPS Check-In**
    - Status changes to "Checked In"
    - Timer starts

12. **Employee Check-Out**
    - Dashboard → "Check Out" button
    - Confirms check-out
    - Calculates work hours
    - Shows in attendance history

---

## 🔄 Complete Testing Scenario

### **Scenario 1: Full Day Workflow**

```
08:00 AM - Admin creates project "Site A"
08:15 AM - Admin creates supervisor account
08:30 AM - Supervisor logs in
08:45 AM - Supervisor adds 3 employees
09:00 AM - Admin approves all 3 employees
09:15 AM - Employee 1 checks in (GPS)
09:20 AM - Employee 2 checks in (GPS)
09:25 AM - Employee 3 checks in (GPS)
12:00 PM - Employees check out for lunch
01:00 PM - Employees check in again
05:00 PM - All employees check out
05:30 PM - Supervisor reviews attendance
06:00 PM - Admin exports daily report
```

### **Scenario 2: Multi-Project Setup**

```
Step 1: Admin creates 2 projects
   - Project A: Construction
   - Project B: Renovation

Step 2: Admin creates 2 supervisors
   - Supervisor A → Project A
   - Supervisor B → Project B

Step 3: Supervisor A adds employees to Project A
   - Employees get IDs: 0001, 0002, 0003

Step 4: Supervisor B adds employees to Project B
   - Employees get IDs: 0004, 0005, 0006

Step 5: Admin approves all

Step 6: Employees check in to their respective projects
```

---

## 📊 Testing Flows by Role

### **Admin Testing Flow**
1. ✅ Login to dashboard
2. ✅ Create project
3. ✅ Create supervisor account
4. ✅ View pending employees
5. ✅ Approve employee
6. ✅ Assign supervisor to project
7. ✅ View attendance reports
8. ✅ Export reports (PDF/CSV)
9. ✅ Manage system settings

### **Supervisor Testing Flow**
1. ✅ Login with email/password
2. ✅ View assigned project
3. ✅ Add new employee
4. ✅ View employee list
5. ✅ Check employee status
6. ✅ View attendance records
7. ✅ Monitor check-ins in real-time

### **Employee Testing Flow**
1. ✅ Login with ID/PIN
2. ✅ View profile
3. ✅ Check in (GPS/QR/Geofence)
4. ✅ Check out
5. ✅ View attendance history
6. ✅ View work hours
7. ✅ View project details

---

## 🔧 Quick Reference

### **Default Credentials for Testing**

```
ADMIN:
Email: admin@company.com
Password: admin123

SUPERVISOR (after admin creates):
Email: supervisor1@company.com
Password: super123

EMPLOYEE (after supervisor creates):
ID: 0001
PIN: 1234
```

### **Auto-Generated Values**

| Field | Format | Example |
|-------|--------|---------|
| Employee ID | 4 digits | 0001, 0002, 0003 |
| Employee PIN | 4 digits | 1234, 5678, 9012 |
| Project ID | Firebase UID | auto-generated |
| User UID | Firebase UID | auto-generated |

### **Status Flow**

```
Employee Status:
pending → (admin approves) → approved → (admin activates) → active

Project Status:
active / inactive / completed
```

---

## 🎯 Common Issues & Solutions

### **Issue 1: Supervisor can't add employees**
- ✅ Check: Supervisor must be assigned to a project
- ✅ Fix: Admin assigns supervisor to project in dashboard

### **Issue 2: Employee can't login**
- ✅ Check: Employee status must be "approved"
- ✅ Fix: Admin approves employee in dashboard

### **Issue 3: Employee ID not working**
- ✅ Check: Use 4-digit format (0001, not 1)
- ✅ Check: PIN is correct (case-sensitive)

### **Issue 4: Check-in fails**
- ✅ Check: Employee must be "approved" status
- ✅ Check: GPS permissions enabled
- ✅ Check: Not already checked in

### **Issue 5: "userId: null" in dashboard**
- ✅ Check: Admin user document exists in Firestore
- ✅ Check: Role field = "admin" (lowercase)
- ✅ Check: Status field = "approved"
- ✅ Check: Firestore security rules allow read

---

## 📱 Running Each App

### **Web Dashboard (Admin)**
```bash
# Terminal 1
cd /Users/mac/Documents/straights_psyroll
flutter run -d chrome --web-browser-flag "--disable-web-security" --web-browser-flag "--user-data-dir=/tmp/chrome_dev_test"
```

### **Mobile App (Supervisor + Employee)**
```bash
# Terminal 2
cd /Users/mac/Documents/straights_psyroll
flutter run -d <device-id>

# List available devices:
flutter devices
```

**Note:** Same mobile app for both Supervisor and Employee - role detection is automatic based on login method and Firestore role field.

---

## 🎉 Success Indicators

You know everything is working when:

✅ **Admin Dashboard:** Can see projects, employees, attendance  
✅ **Supervisor App:** Can add employees and see auto-generated IDs  
✅ **Employee App:** Can check in/out and see attendance history  
✅ **Data Flow:** Changes in one app reflect in others in real-time  

---

## 📝 Next Steps After Basic Testing

1. Test device management (IMEI registration)
2. Test document uploads
3. Test report exports (PDF/CSV)
4. Test device reset requests
5. Configure production Firestore security rules
6. Set up proper Firebase authentication rules
7. Deploy web dashboard to hosting

---

**Need Help?** Check browser console (F12) for detailed debug logs!

