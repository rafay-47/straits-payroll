# 🚀 Quick Test Reference Card

## ⚡ Super Quick Start (5 Minutes)

### 1. Firebase Setup (One-time)
```bash
# Go to: https://console.firebase.google.com/
# Create project: "straights-psyroll-test"
# Enable: Authentication (Email/Password)
# Enable: Firestore Database (test mode)
# Enable: Storage
```

### 2. Create Test Users

**In Firebase Console → Authentication → Add User:**

| Role | Email | Password | UID |
|------|-------|----------|-----|
| Admin | admin@test.com | Admin@123 | Copy UID! |
| Supervisor | supervisor@test.com | Super@123 | Copy UID! |

**In Firebase Console → Firestore → Create Collection "users":**

Add 2 documents (one for each user) with copied UIDs:
```
uid: [copied-uid]
name: "Admin User" / "Test Supervisor"
email: admin@test.com / supervisor@test.com
role: admin / supervisor
status: active
biometricEnabled: false
createdAt: [now]
updatedAt: [now]
```

### 3. Create Test Project

**In Firestore → Create Collection "projects":**
```
projectId: project-001
name: Test Project Site A
description: Test project
location: {
  address: "123 Test Street"
  latitude: 37.7749
  longitude: -122.4194
  radiusInMeters: 10000
}
checkInMethods: ["gps", "manual"]
isActive: true
createdBy: [admin-uid]
assignedEmployeeIds: []
createdAt: [now]
updatedAt: [now]
```

---

## 🧪 Testing Order (30 Minutes)

### Phase 1: Admin Web (5 min)
```bash
flutter run -d chrome
```
✅ Login: admin@test.com / Admin@123  
✅ See dashboard  
✅ Click "Manage Projects" → See test project  

### Phase 2: Supervisor Mobile (5 min)
```bash
flutter run  # on emulator/device
```
✅ Select "Supervisor"  
✅ Login: supervisor@test.com / Super@123  
✅ Tap "Add Employee"  
✅ Name: John Doe, Email: john@test.com, Phone: +1234567890  
✅ **Note the ID: 0001 and PIN: 1234**  

### Phase 3: Approve Employee (Web) (2 min)
✅ Admin Dashboard → "Approve Employees"  
✅ Approve John Doe  
✅ Optional: Custom ID = EMP001  

### Phase 4: Employee Mobile (8 min)
✅ Mobile App → Select "Employee"  
✅ Login: ID=0001, PIN=123456  
✅ See dashboard with project  
✅ Tap "Check In" → Select GPS → Allow location  
✅ Wait 2 min  
✅ Tap "Check Out"  
✅ See working hours calculated  

### Phase 5: Verify (Web) (5 min)
✅ Admin Dashboard → Updated stats  
✅ "View Reports" → Attendance Report  
✅ See John's check-in/out  
✅ Export PDF & CSV  

---

## 📝 Quick Credentials Reference

### For Testing

| What | Credentials | Notes |
|------|-------------|-------|
| **Admin (Web)** | admin@test.com / Admin@123 | Web dashboard only |
| **Supervisor (Mobile)** | supervisor@test.com / Super@123 | Mobile app |
| **Employee (Mobile)** | ID: 0001 / PIN: 123456 | Created by supervisor |

### Test Data

| Item | Value |
|------|-------|
| **Project Name** | Test Project Site A |
| **Project Location** | 37.7749, -122.4194 |
| **Check-in Radius** | 10000m (10km for testing) |
| **Employee Name** | John Doe |
| **Employee Email** | john@test.com |
| **System ID** | 0001 (auto-generated) |
| **Default PIN** | 1234 or 123456 |

---

## 🔄 Complete Testing Flow (Visual)

```
┌────────────────────┐
│  FIREBASE CONSOLE  │
│  Create Admin +    │
│  Supervisor Users  │
│  Create Project    │
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│   WEB ADMIN APP    │
│   (Chrome)         │
│   Login as Admin   │
│   Verify Dashboard │
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│  MOBILE SUPERVISOR │
│  Login & Add       │
│  Employee (0001)   │
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│   WEB ADMIN APP    │
│   Approve Employee │
│   (Status=Active)  │
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│  MOBILE EMPLOYEE   │
│  Login (0001/PIN)  │
│  Check-In/Out GPS  │
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│   WEB ADMIN APP    │
│   View Reports     │
│   Export PDF/CSV   │
└────────────────────┘
```

---

## 🎯 What Each Screen Does

### Admin Web Dashboard
- 👀 **View**: All employees, projects, attendance
- ✅ **Approve**: Pending employees, documents
- 📊 **Generate**: Reports (PDF/CSV)
- 🔧 **Manage**: Projects, system settings
- 📱 **Handle**: Device reset requests

### Supervisor Mobile App
- ➕ **Add**: New employees (get auto ID)
- 📄 **Upload**: Employee documents
- ✓ **Perform**: Manual check-ins
- 👥 **View**: Their employees list
- ✅ **Approve**: Device reset requests

### Employee Mobile App
- 🔐 **Login**: With ID + PIN
- 📍 **Check-In**: GPS/NFC/QR/Manual
- ⏱️ **Check-Out**: Auto-calculate hours
- 📊 **View**: Today's status, working hours
- 📱 **Request**: Device reset

---

## 🔗 How Data Flows

```
1. Supervisor ADDS Employee
   ↓
   Firebase creates account
   ↓
   Firestore: users/[uid] (status: pending)

2. Admin APPROVES Employee  
   ↓
   Firestore: users/[uid] (status: active)
   ↓
   Employee can now login

3. Employee LOGS IN
   ↓
   Device binding occurs
   ↓
   Sees assigned projects

4. Employee CHECKS IN
   ↓
   Firestore: users/[uid]/attendance/[id]
   ↓
   Real-time update to dashboard

5. Employee CHECKS OUT
   ↓
   Working hours calculated
   ↓
   Attendance record complete

6. Admin VIEWS REPORTS
   ↓
   Reads all attendance records
   ↓
   Generates PDF/CSV
```

---

## ⚠️ Common Issues Quick Fix

| Issue | Quick Fix |
|-------|-----------|
| Can't login | Check user exists in both Auth + Firestore |
| No projects shown | Add employee UID to project's assignedEmployeeIds |
| Check-in fails | Increase radius to 10000m OR use Manual |
| Permission denied | Firestore rules: allow read, write: if true (test only) |
| App crashes | Check Firebase config in lib/main.dart |

---

## 🏃 Start Testing NOW!

```bash
# 1. Install dependencies
flutter pub get

# 2. Run web (admin testing)
flutter run -d chrome

# 3. Run mobile (supervisor/employee testing)
flutter run  # on emulator/device

# 4. View logs if issues
flutter logs
```

---

## 📚 Full Guides Available

- **`PRACTICAL_TESTING_GUIDE.md`** ⭐ - Detailed step-by-step (START HERE!)
- **`TESTING_GUIDE.md`** - Comprehensive test cases
- **`DEPLOYMENT_GUIDE.md`** - Production deployment
- **`FINAL_PROJECT_SUMMARY.md`** - Complete feature list

---

## ✅ Testing Complete When:

- [ ] Admin can login and see dashboard ✓
- [ ] Supervisor can add employee (gets ID 0001) ✓
- [ ] Admin can approve employee ✓
- [ ] Employee can login with ID/PIN ✓
- [ ] Employee can check-in (GPS) ✓
- [ ] Employee can check-out ✓
- [ ] Working hours calculated ✓
- [ ] Admin can view reports ✓
- [ ] PDF/CSV export works ✓

---

**🎉 ALL FEATURES WORKING? → Ready for production!**

**Need help? See `PRACTICAL_TESTING_GUIDE.md` for detailed instructions.**

