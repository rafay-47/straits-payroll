# 🎨 Visual Flow Summary - Employee & Supervisor Apps

## 📱 Quick Reference Guide

---

## 👤 EMPLOYEE APP - 5 Main Flows

### **1️⃣ First-Time Setup (One-time)**
```
📱 Open App
  ↓
🆔 Enter Employee ID (0001 or EMP123)
  ↓
📲 Device Binding (Automatic)
  ↓
🔒 Create 6-digit PIN
  ↓
✅ Confirm PIN
  ↓
👤 Optional: Enable Face ID/Fingerprint
  ↓
🎉 Setup Complete → Dashboard
```

**Duration:** 2-3 minutes
**Done:** Only once per device

---

### **2️⃣ Daily Login (Every time)**
```
📱 Open App
  ↓
👤 Face ID Authentication (or Enter PIN)
  ↓
✅ Device Verification (Automatic)
  ↓
📊 Dashboard (Shows assigned projects)
```

**Duration:** 5-10 seconds
**Frequency:** Every time app opens

---

### **3️⃣ GPS Check-In**
```
📊 Dashboard → Select Project
  ↓
📍 Choose "GPS Check-In"
  ↓
🗺️ App Gets Location
  ↓
📏 Calculates Distance to Project
  ↓
✅ Within 200m? → Show "Check In" Button
❌ Too Far? → Show Error + Distance
  ↓
✅ Tap "Check In Now"
  ↓
🎉 Success! Currently Checked In
```

**Duration:** 10-15 seconds
**Use Case:** Most common, outdoor work

---

### **4️⃣ NFC Check-In**
```
📊 Dashboard → Select Project
  ↓
📱 Choose "NFC Check-In"
  ↓
🔵 Hold phone near NFC tag
  ↓
📡 Tag Detected → Reads ID
  ↓
✅ Tag Matches Project? → Check-In Success
❌ Wrong Tag? → Show Error
  ↓
🎉 Success! Currently Checked In
```

**Duration:** 5 seconds
**Use Case:** Fixed locations with NFC tags

---

### **5️⃣ QR Code Check-In**
```
📊 Dashboard → Select Project
  ↓
📷 Choose "QR Code Check-In"
  ↓
📸 Camera Opens
  ↓
🔲 Point at QR Code
  ↓
📱 Auto-Scans → Decodes Project ID
  ↓
✅ Valid Project + Assigned? → Check-In Success
❌ Invalid? → Show Error
  ↓
🎉 Success! Currently Checked In
```

**Duration:** 5-10 seconds
**Use Case:** Dynamic locations, client sites

---

### **6️⃣ Check-Out**
```
📊 Dashboard (While Checked In)
  ↓
🔴 Tap "Check Out Now"
  ↓
📋 Confirmation Dialog (Shows Summary)
  ↓
✅ Confirm Check-Out
  ↓
📍 Records Current Location
  ↓
⏱️ Calculates Working Hours
  ↓
🎉 Check-Out Success!
  ↓
📊 Dashboard (Can Check-In to Another Project)
```

**Duration:** 5-10 seconds
**Required:** Before checking into different project

---

## 👔 SUPERVISOR APP - 4 Main Flows

### **1️⃣ Login**
```
📱 Open App
  ↓
📧 Enter Email Address
  ↓
🔒 Enter Password
  ↓
✅ Login Success
  ↓
📊 Supervisor Dashboard
```

**Duration:** 10-15 seconds
**Note:** No device binding for supervisors

---

### **2️⃣ Add New Employee (Complete Flow)**
```
📊 Dashboard → Tap "Add Employee"
  ↓
📝 Fill Employee Details:
   - Name
   - Email
   - Phone
   - Auto-generated ID (0012)
  ↓
📄 Upload Documents:
   - ID Proof (Required)
   - Bank Statement (Required)
   - Contract (Optional)
   📷 Take Photo OR 📁 Choose File
  ↓
🏢 Assign to Projects:
   ☑️ Construction Site A
   ☑️ Warehouse C
   ☐ Office Building B
  ↓
✅ Create Employee
  ↓
⏳ Employee Status: PENDING
  ↓
📧 Notification Sent to Admin
  ↓
⏳ Wait for Admin Approval
  ↓
✅ Admin Approves + Assigns Custom ID
  ↓
🎉 Employee Can Now Login!
```

**Duration:** 5-10 minutes
**Frequency:** As needed
**Important:** Employee CANNOT login until admin approves

---

### **3️⃣ Manual Check-In (For Employees Without Phone)**
```
📊 Dashboard → Tap "Manual Check-In"
  ↓
🔍 Search & Select Employee:
   "John Doe (0001)"
  ↓
🏢 Select Project:
   ○ Construction Site A
   ○ Office Building B
   ● Warehouse C ✓
  ↓
📝 Select Reason:
   ● Employee has no smartphone
   ○ Employee phone not working
   ○ Special circumstances
  ↓
💬 Add Notes (Optional):
   "Employee's phone was stolen"
  ↓
✅ Tap "Check In Employee"
  ↓
🎉 Employee Checked In!
   (Verified by: Supervisor Name)
```

**Duration:** 30-60 seconds
**Use Case:** Employee doesn't have smartphone or device issues
**Important:** Records supervisor as verifier

---

### **4️⃣ View Employee Status & Reports**
```
📊 Dashboard → "My Employees"
  ↓
📋 Employee List Shows:
   👤 John Doe (0001)
      Status: ✅ Approved
      Currently: ✅ Checked In
      Project: Construction Site A
      Hours Today: 6h 30m
   
   👤 John Smith (0012)
      Status: ⏳ Pending Approval
      Currently: ⏳ Waiting for Admin
   
   👤 Mary Johnson (EMP123)
      Status: ✅ Approved
      Currently: ❌ Not Checked In
      Last Active: 2 hours ago
  ↓
📊 Generate Reports:
   - Select Date Range
   - Select Employees (All or Specific)
   - Select Projects (All or Specific)
   - Generate PDF/CSV
```

**Duration:** Instant view, 1-2 min for reports
**Use Case:** Monitor employee attendance, generate reports

---

## 🔐 Security & Validation Rules

### **Employee Check-In Validations:**

```
BEFORE CHECK-IN, SYSTEM CHECKS:

1️⃣ Is employee assigned to this project?
   ✅ Yes → Continue
   ❌ No → Error: "Not assigned to this project"

2️⃣ Is employee already checked in elsewhere?
   ✅ No active check-in → Continue
   ❌ Checked in to "Office B" → Error: "Check out from Office B first"

3️⃣ How many check-ins today for this project?
   ✅ 0 or 1 → Continue (Allow up to 2)
   ❌ Already 2 → Error: "Maximum 2 check-ins per day reached"

4️⃣ Does device match registered device?
   ✅ Match → Continue
   ❌ Mismatch → Error: "Unauthorized device. Request reset."

5️⃣ GPS: Within project radius?
   ✅ Within 200m → Allow
   ❌ Too far (500m) → Error: "You are 500m away from site"

6️⃣ NFC: Tag matches project?
   ✅ Match → Allow
   ❌ Wrong tag → Error: "Invalid NFC tag"

7️⃣ QR: Code valid for project?
   ✅ Valid → Allow
   ❌ Invalid → Error: "Invalid QR code"

IF ALL PASS → ✅ CHECK-IN SUCCESSFUL
```

---

## 📊 Data Flow (What Happens Behind the Scenes)

### **When Employee Checks In (GPS):**

```
1. Employee taps "Check In"
   ↓
2. App gets GPS coordinates
   ↓
3. Sends to server:
   {
     userId: "user_123",
     projectId: "project_456",
     method: "gps",
     latitude: 40.7128,
     longitude: -74.0060,
     deviceId: "ABC123XYZ",
     timestamp: "2024-05-15T09:15:00Z"
   }
   ↓
4. Server validates (all checks above)
   ↓
5. Server calculates distance
   ↓
6. If valid, creates record in Firestore:
   
   users/user_123/attendance/att_789
     - projectId: "project_456"
     - checkInTime: timestamp
     - checkInMethod: "gps"
     - checkInLocation: { lat, lng, address }
     - deviceInfo: { deviceId, model }
     - status: "checked_in"
     - sessionNumber: 1
     - workingHours: null (calculated on check-out)
   ↓
7. Response sent to app:
   { success: true, attendanceId: "att_789" }
   ↓
8. App updates UI:
   - Shows "Currently Checked In"
   - Starts live timer
   - Locks other projects
   - Shows "Check Out" button
```

---

## 🎯 Status Flow for New Employee

```
SUPERVISOR creates employee
  ↓
Status: PENDING
  ↓
Employee CANNOT login yet
  ↓
Notification sent to ADMIN
  ↓
ADMIN reviews on web dashboard
  ↓
ADMIN approves + assigns custom ID (EMP123)
  ↓
Status: APPROVED
  ↓
Employee CAN now login
  ↓
Employee opens app → First-time setup
  ↓
Status: ACTIVE (after first login)
```

---

## 📱 Screen Count Summary

### **Employee App:**
- Login Screen (1)
- First-Time Setup (4 screens)
- Dashboard (1)
- Check-In Selection (1)
- GPS Check-In (1)
- NFC Check-In (1)
- QR Scanner (1)
- Attendance History (1)
- Profile/Settings (1)
- Device Reset Request (1)

**Total: ~13 screens**

### **Supervisor App:**
- Login Screen (1)
- Dashboard (1)
- Add Employee Form (3 screens)
- Employee List (1)
- Employee Details (1)
- Manual Check-In (1)
- Document Upload (1)
- Reports (1)

**Total: ~11 screens**

---

## 🔄 Real-World Usage Example

### **Typical Employee Day:**

```
8:45 AM - Open app → Face ID login → Dashboard
8:50 AM - Select "Construction Site A" → GPS Check-In
         Distance: 25m ✅ → Check-In Success
         
12:30 PM - Lunch break → Check-Out
           Working: 3h 40m
         
1:15 PM - Return from lunch → GPS Check-In (Session 2)
          Distance: 30m ✅ → Check-In Success
          
5:30 PM - End of day → Check-Out
          Working: 4h 15m
          
5:35 PM - View attendance → Today's total: 7h 55m
```

---

## 🎨 UI/UX Highlights

### **Employee App:**
- ✅ Simple, intuitive interface
- ✅ Large buttons for easy tapping
- ✅ Color-coded status (Green = Checked In, Red = Not Checked In)
- ✅ Live timer showing working hours
- ✅ Clear error messages
- ✅ Haptic feedback on actions

### **Supervisor App:**
- ✅ Clean, professional design
- ✅ Quick actions on dashboard
- ✅ Real-time employee status
- ✅ Easy document upload (camera or file)
- ✅ Searchable employee list
- ✅ Status indicators (pending, approved, active)

---

## 📱 Platform Features

### **iOS:**
- Face ID for authentication
- Native camera integration
- NFC reading (iPhone 7+)
- Native date/time pickers
- Haptic feedback

### **Android:**
- Fingerprint/Face unlock
- Native camera integration
- NFC reading (most devices)
- Material Design components
- Vibration feedback

---

## 🚀 Performance Optimization

- **Lazy loading** for attendance history
- **Image compression** for documents
- **Caching** of project data
- **Background location** for smooth GPS
- **Offline-first** UI (shows cached data)
- **Optimistic updates** (instant UI feedback)

---

**This is the complete visual flow! Any questions?** 📱✨

Ready to start implementation? Just say "GO"! 🚀

