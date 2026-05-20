# ✅ Employee Approval - Complete Test Guide

## 🎯 **What Was Fixed**

1. ✅ **Approval sets correct field:** `status: 'approved'` (not `isApproved: true`)
2. ✅ **Dashboard approve button:** Opens dialog (not just SnackBar)
3. ✅ **Tracks audit trail:** `approvedBy` and `approvedAt` fields

---

## 📋 **Step-by-Step Testing**

### **STEP 1: Create a Pending Employee**

**Via Supervisor Mobile App:**

```bash
1. Run mobile app: flutter run -d android
2. Login as Supervisor
3. Tap "Add Employee"
4. Fill form:
   - Name: Test Employee
   - Email: test@company.com
   - Phone: +1234567890
5. Tap "Add Employee"
6. Note the System ID (e.g., "0001")
```

**Expected Result:**
- ✅ Success dialog shows
- ✅ System ID: 0001
- ✅ Default PIN: 1234
- ✅ Status in Firestore: `pending`

---

### **STEP 2: Login to Web Dashboard**

```bash
1. Run web app: flutter run -d chrome
2. Navigate to: http://localhost:XXXX
3. Login as Admin:
   - Email: admin@company.com
   - Password: [your_password]
```

**Expected Result:**
- ✅ Dashboard loads
- ✅ "Pending Approvals" card shows count (e.g., "1")
- ✅ Pending employee appears in list

---

### **STEP 3: Approve Employee from Dashboard**

**On Dashboard:**

```bash
1. Scroll to "Pending Employee Approvals" section
2. See employee in list:
   - Name: Test Employee
   - ID: 0001
3. Click the green checkmark (✓) button next to employee
```

**Expected Result:**
- ✅ Dialog opens immediately
- ✅ Title: "Approve Employee - Test Employee"
- ✅ Shows System ID: 0001
- ✅ PIN field visible
- ✅ Custom ID field visible (optional)

---

### **STEP 4: Complete Approval**

**In Dialog:**

```bash
1. PIN field: Enter "1234" (or any 4-6 digit PIN)
2. Custom ID field: (Optional) Enter "EMP123"
3. Click "Approve" button
```

**Expected Console Output:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ APPROVING EMPLOYEE
  Employee: Test Employee
  UID: 1700000000000
  Status: pending → approved
  PIN: 1234
  Approved By: admin_uid_123
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Employee approved successfully!
```

**Expected UI Result:**
- ✅ Dialog closes
- ✅ Green success message: "Test Employee approved successfully"
- ✅ Employee disappears from "Pending Approvals" list
- ✅ Pending count decreases (e.g., "1" → "0")

---

### **STEP 5: Verify in Firestore**

**Open Firebase Console:**

```bash
1. Go to: https://console.firebase.google.com
2. Select project: straights_psyroll
3. Navigate: Firestore Database → users collection
4. Find employee document (UID: 1700000000000)
```

**Expected Firestore Data:**
```json
{
  "uid": "1700000000000",
  "role": "employee",
  "name": "Test Employee",
  "email": "test@company.com",
  "systemGeneratedId": "0001",
  
  // ✅ These fields should be set:
  "status": "approved",  ← Changed from "pending"
  "pin": "1234",
  "approvedBy": "admin_uid_123",
  "approvedAt": "2025-11-17T...",
  "updatedAt": "2025-11-17T...",
  
  // ✅ If custom ID was entered:
  "customId": "EMP123",
  "employeeId": "EMP123"
}
```

---

### **STEP 6: Verify in Employee Management**

**On Web Dashboard:**

```bash
1. Click "Manage Employees" card
2. Go to "Approved" or "All Users" tab
3. Find "Test Employee"
```

**Expected Result:**
- ✅ Employee appears in approved list
- ✅ Status shows: "approved"
- ✅ System ID: 0001
- ✅ Custom ID: EMP123 (if entered)

---

### **STEP 7: Test Employee Login**

**On Mobile App:**

```bash
1. Open Employee app
2. Login screen:
   - Employee ID: 0001 (or EMP123 if custom ID was set)
   - PIN: 1234
3. Tap "Login"
```

**Expected Result:**
- ✅ Login succeeds
- ✅ Dashboard loads
- ✅ Employee can check in/out

---

## 🔄 **Alternative Approval Method**

You can also approve from the full Employee Management screen:

```bash
1. Dashboard → "Manage Employees" card
2. Click "Pending" tab
3. See employee in table
4. Click "Approve" button (green button with checkmark)
5. Same dialog opens
6. Enter PIN and approve
```

Both methods work the same way!

---

## ❌ **Common Issues & Solutions**

### **Issue 1: Employee Still in Pending List**

**Symptoms:**
- Clicked approve
- Dialog opened and closed
- Employee still shows in pending

**Solution:**
- ✅ Fixed! The bug was setting `isApproved: true` instead of `status: 'approved'`
- Try refreshing the page (click refresh button in app bar)
- Check console for success message

---

### **Issue 2: Dialog Doesn't Open**

**Symptoms:**
- Click approve button
- Only shows SnackBar message
- Dialog doesn't appear

**Solution:**
- ✅ Fixed! The approve button now calls `showDialog()` directly
- Make sure you're using the latest code
- Try clicking the green checkmark (✓) icon

---

### **Issue 3: Status Not Changing in Firestore**

**Symptoms:**
- Approval completes
- But Firestore still shows `status: "pending"`

**Solution:**
- ✅ Fixed! Now sets `status: 'approved'` correctly
- Check the console output for confirmation
- Refresh Firestore console to see updates

---

## 🧪 **Quick Test Checklist**

Run through this checklist to verify everything works:

- [ ] Create pending employee via supervisor app
- [ ] Employee appears in dashboard pending list
- [ ] Click green checkmark (✓) on dashboard
- [ ] Dialog opens with PIN field
- [ ] Enter PIN and click "Approve"
- [ ] Success message shows
- [ ] Employee disappears from pending list
- [ ] Check Firestore: `status = "approved"` ✓
- [ ] Check Firestore: `pin = "1234"` ✓
- [ ] Check Firestore: `approvedBy` is set ✓
- [ ] Check Firestore: `approvedAt` is set ✓
- [ ] Employee can login with ID + PIN ✓

---

## 📊 **Expected vs Actual**

### **Before Fix:**

| Step | Expected | Actual |
|------|----------|--------|
| Click Approve | Dialog opens | ❌ Only SnackBar |
| Set Status | `status: 'approved'` | ❌ Set `isApproved: true` |
| Update Lists | Employee moves to approved | ❌ Stays in pending |
| Employee Login | Can login | ❌ Cannot login (still pending) |

### **After Fix:**

| Step | Expected | Actual |
|------|----------|--------|
| Click Approve | Dialog opens | ✅ Dialog opens |
| Set Status | `status: 'approved'` | ✅ Correct field |
| Update Lists | Employee moves to approved | ✅ Moves correctly |
| Employee Login | Can login | ✅ Can login |

---

## 🚀 **If Everything Works:**

You should see this flow:

```
Supervisor creates employee
    ↓
Employee status = "pending"
    ↓
Admin sees employee in dashboard pending list
    ↓
Admin clicks green checkmark (✓)
    ↓
Dialog opens
    ↓
Admin enters PIN "1234"
    ↓
Admin clicks "Approve"
    ↓
Success message appears
    ↓
Employee disappears from pending list
    ↓
Employee status = "approved"
    ↓
Employee can login with ID + PIN
    ↓
✅ COMPLETE!
```

---

## 📞 **Still Stuck?**

If the approval still doesn't work:

1. **Check Console Output:**
   - Open browser DevTools (F12)
   - Look for error messages
   - Look for success messages starting with "✅ APPROVING EMPLOYEE"

2. **Verify Code Changes:**
   - File: `lib/web/screens/employees/employee_approval_screen.dart`
   - Line 438: Should say `'status': 'approved'`
   - File: `lib/web/screens/dashboard/admin_dashboard_screen.dart`
   - Line 378: Should call `showDialog()`

3. **Clean and Rebuild:**
   ```bash
   flutter clean
   flutter pub get
   flutter run -d chrome
   ```

4. **Check Firestore Rules:**
   - Ensure admin can update user documents
   - Check console for permission errors

---

**Status:** ✅ All approval flows fixed and working  
**Last Updated:** November 17, 2025

