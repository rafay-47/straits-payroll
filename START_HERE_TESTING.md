# 🚀 START HERE - Complete Testing Guide

**Quick start guide to test all functionalities**

---

## 📖 Which Guide to Use?

- **📘 Complete Testing Guide** (`COMPLETE_TESTING_GUIDE.md`) - Detailed step-by-step instructions
- **⚡ Quick Reference** (`QUICK_TESTING_REFERENCE.md`) - Fast 5-minute test
- **📊 Flow Diagram** (`TESTING_FLOW_DIAGRAM.md`) - Visual flow charts

**Start with this document for overview, then use the detailed guides above.**

---

## 🎯 Complete Testing Flow Summary

### Step 1: Super Admin Setup (5 minutes)

```
1. Login as Super Admin (Web)
2. Create Company:
   - Name: "Test Company"
   - Code: "TST" (3-6 letters)
   - Contact: admin@testco.com
3. ✅ Company Admin auto-created
```

**Save:** Company Code (TST) and Admin credentials

---

### Step 2: Admin Setup (10 minutes)

```
1. Login as Admin (Web)
   - Company Code: TST
   - Email: admin@testco.com
   - Password: [from Step 1]

2. Create Supervisor:
   - Name: "Supervisor 1"
   - Email: supervisor@testco.com
   - Password: Supervisor123!

3. Create Project:
   - Name: "Site 1"
   - Location: [your address + GPS]
   - Assign Supervisor: Supervisor 1
   - Enable Methods:
     ☑ GPS
     ☑ NFC → Enter Tag ID (optional) OR leave empty
     ☑ QR → Click "Generate QR Code"
     ☑ Manual

4. Create Employee:
   - Name: "Worker 1"
   - Email: worker@testco.com
   - Employee ID: TST-0001 (auto-generated)
   - PIN: 1234 (save this!)
   - Assign to Project: Site 1

5. Approve Employee:
   - Find worker in "Pending Approvals"
   - Click ✅ Approve
```

**Save:** 
- Supervisor credentials
- Employee ID (TST-0001) and PIN (1234)
- NFC Tag ID (if entered)
- QR Code (screenshot or copy data)

---

### Step 3: Supervisor Testing (5 minutes)

```
1. Open Mobile App
2. Select "Supervisor" role
3. Login:
   - Company Code: TST
   - Email: supervisor@testco.com
   - Password: Supervisor123!

4. Verify:
   ✅ See assigned project "Site 1"
   ✅ Can add employees
   ✅ Can upload documents
   ✅ Can perform manual check-in
```

---

### Step 4: Employee Testing - Check-In (10 minutes)

```
1. Open Mobile App
2. Select "Employee" role
3. Login:
   - Company Code: TST
   - Employee ID: TST-0001
   - PIN: 1234

4. Verify Dashboard:
   ✅ See assigned project "Site 1"
   ✅ Status: "Not Checked In"

5. Test GPS Check-In:
   - Tap "Check In"
   - Select Project: Site 1
   - Tap "GPS Check-in"
   - ✅ Grant location permission
   - ✅ Check-in succeeds

6. Test NFC Check-In:
   - Tap "Check In"
   - Select Project: Site 1
   - Tap "NFC Check-in"
   - Hold phone near NFC tag
   - ✅ Tag detected
   - ✅ Check-in succeeds (if tag matches)

7. Test QR Check-In:
   - Tap "Check In"
   - Select Project: Site 1
   - Tap "QR Check-in"
   - Scan QR code (from admin dashboard)
   - ✅ QR detected
   - ✅ Check-in succeeds (if QR matches)
```

---

### Step 5: Employee Testing - Check-Out (5 minutes)

```
1. After check-in, dashboard shows "Checked In"
2. Tap "Check Out" button
3. Select Method:
   - Choose "NFC Tag" OR "QR Code"
4. Validate:
   - NFC: Tap tag → System validates
   - QR: Scan code → System validates
5. ✅ Check-out succeeds
6. ✅ Working hours calculated
```

---

### Step 6: Validation Testing (5 minutes)

```
Test Wrong NFC Tag:
1. Try check-in with different NFC tag
2. ❌ Should fail: "NFC tag does not match"

Test Wrong QR Code:
1. Try check-in with different QR code
2. ❌ Should fail: "QR code does not match"

Test GPS Outside Radius:
1. Move away from project location
2. Try GPS check-in
3. ❌ Should fail: "You are X meters away"
```

---

## ✅ Success Criteria

All functionalities work correctly if:

### Admin (Web):
- ✅ Can create company
- ✅ Can create project with NFC/QR configuration
- ✅ Can see NFC Tag ID field when NFC enabled
- ✅ Can generate QR code when QR enabled
- ✅ Can create and approve employees

### Supervisor (Mobile):
- ✅ Can see assigned project
- ✅ Can add employees
- ✅ Can upload documents
- ✅ Can perform manual check-in

### Employee (Mobile):
- ✅ Can see assigned projects
- ✅ Can check-in with GPS/NFC/QR
- ✅ Can check-out with NFC/QR
- ✅ Wrong NFC tag is rejected
- ✅ Wrong QR code is rejected

---

## 🔍 Quick Verification

### Check NFC Configuration:
```
Admin Dashboard → Manage Projects → Edit Project
✅ NFC checkbox checked
✅ NFC Tag ID field visible
✅ Tag ID saved (if entered)
```

### Check QR Configuration:
```
Admin Dashboard → Manage Projects → Edit Project
✅ QR checkbox checked
✅ QR Code generated and displayed
✅ QR code data visible
```

### Check Employee Assignment:
```
Admin Dashboard → Manage Projects → Assign Employees
✅ Employee appears in list
✅ Employee checked/assigned
✅ Save successful
```

### Check Employee Status:
```
Admin Dashboard → Manage Employees
✅ Employee status: Active (not Pending)
✅ Employee has assigned projects
```

---

## 🐛 Common Issues

| Issue | Quick Fix |
|-------|-----------|
| NFC not working | Enable NFC in device settings |
| QR not scanning | Grant camera permission |
| Employee can't see projects | Verify employee is approved & assigned |
| NFC tag rejected | Check NFC Tag ID matches in project settings |
| QR code rejected | Regenerate QR code in project settings |

---

## 📱 Testing Checklist

### Setup Phase:
- [ ] Super Admin account created
- [ ] Company created
- [ ] Admin account working
- [ ] Supervisor created
- [ ] Project created with NFC/QR
- [ ] Employee created and approved
- [ ] Employee assigned to project

### Testing Phase:
- [ ] Supervisor can login
- [ ] Employee can login
- [ ] GPS check-in works
- [ ] NFC check-in works (correct tag)
- [ ] NFC check-in fails (wrong tag)
- [ ] QR check-in works (correct code)
- [ ] QR check-in fails (wrong code)
- [ ] NFC check-out works
- [ ] QR check-out works

---

## 🎓 Next Steps

1. **Read:** `COMPLETE_TESTING_GUIDE.md` for detailed steps
2. **Reference:** `QUICK_TESTING_REFERENCE.md` for quick commands
3. **Visualize:** `TESTING_FLOW_DIAGRAM.md` for flow charts

---

## 📞 Need Help?

Check these files:
- `NFC_QR_CHECKOUT_IMPLEMENTATION.md` - NFC/QR implementation details
- `QR_NFC_CONFIGURATION_ADDED.md` - Configuration features
- `APP_FLOWS_REVIEW.md` - Complete app architecture

---

**Ready to test! Start with Step 1 above.** 🚀
