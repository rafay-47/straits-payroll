# 🔑 SUPER ADMIN LOGIN GUIDE

## ✅ **QUICK START - 3 STEPS**

### **Step 1: Create Super Admin in Firebase** ⭐

1. **Open Firebase Console:**  
   👉 https://console.firebase.google.com

2. **Go to your project:**  
   👉 `straights-payroll`

3. **Navigate to Authentication:**  
   Left sidebar → **Authentication** → **Users** tab

4. **Add User:**  
   Click **"Add User"** button

5. **Fill in credentials:**
   ```
   Email:    superadmin@yourcompany.com
   Password: SuperAdmin123!
   ```

6. **Click "Add User"**

7. **COPY THE UID** (very important!)  
   Example: `sJkL9mNoPqRsT123456789`

---

### **Step 2: Create Super Admin User Document** ⭐

1. **Go to Firestore Database:**  
   Left sidebar → **Firestore Database**

2. **Navigate to users collection:**  
   Click **"users"** collection  
   _(If it doesn't exist, click "Start collection" and name it "users")_

3. **Add Document:**  
   Click **"Add Document"** button

4. **Document ID:**  
   Paste the UID you copied from Step 1

5. **Add Fields (click "Add field" for each):**

   | Field Name | Type | Value |
   |------------|------|-------|
   | `uid` | string | `[paste UID from Step 1]` |
   | `role` | string | `superadmin` |
   | `companyId` | null | `null` (select "null" from dropdown) |
   | `name` | string | `Platform Owner` |
   | `email` | string | `superadmin@yourcompany.com` |
   | `status` | string | `active` |
   | `createdAt` | string | `2025-12-06T12:00:00.000Z` |
   | `updatedAt` | string | `2025-12-06T12:00:00.000Z` |

6. **Click "Save"**

✅ **Super Admin account created!**

---

### **Step 3: Run App & Login** ⭐

1. **Open Terminal:**

   ```bash
   cd /Users/mac/Documents/straights_psyroll
   ```

2. **Run the web app:**

   ```bash
   flutter run -d chrome
   ```

   Or with CORS disabled (recommended for development):

   ```bash
   flutter run -d chrome --web-browser-flag "--disable-web-security" --web-browser-flag "--user-data-dir=/tmp/chrome_dev_test"
   ```

3. **Wait for app to compile and open in Chrome**

4. **You should see the Super Admin Login screen automatically!**

   The app now starts at: `/super-admin-login`

5. **Enter credentials:**

   ```
   Email:    superadmin@yourcompany.com
   Password: SuperAdmin123!
   ```

6. **Click "Login as Super Admin"**

✅ **SUCCESS! You're now logged in as Super Admin!**

You should see:
- Super Admin Dashboard
- Platform statistics (0 companies at first)
- "Create Company" button
- Company list (empty initially)

---

## 🎯 **WHAT YOU CAN DO AS SUPER ADMIN**

### **Dashboard Features:**

✅ View platform-wide statistics:
- Total companies
- Total users across all companies
- Total projects across all companies
- Total attendance records

✅ Manage all companies:
- Create new companies
- View company details
- Update company settings
- Suspend/activate companies
- Delete companies

✅ View all company data (read-only):
- See all users in any company
- See all projects in any company
- See all attendance in any company
- Access for support purposes

---

## 🔐 **LOGIN FLOW DIAGRAM**

```
┌────────────────────────────────────────────────┐
│  1. Open App in Browser                        │
│     → App starts at /super-admin-login         │
└────────────────┬───────────────────────────────┘
                 │
                 ▼
┌────────────────────────────────────────────────┐
│  2. Super Admin Login Screen                   │
│     ┌──────────────────────────────┐           │
│     │ Email:    __________________ │           │
│     │ Password: __________________ │           │
│     │                              │           │
│     │  [Login as Super Admin]      │           │
│     └──────────────────────────────┘           │
└────────────────┬───────────────────────────────┘
                 │
                 ▼
┌────────────────────────────────────────────────┐
│  3. Firebase Authentication                    │
│     → Validate email & password                │
│     → Get user UID                             │
└────────────────┬───────────────────────────────┘
                 │
                 ▼
┌────────────────────────────────────────────────┐
│  4. Fetch User Document from Firestore         │
│     users/{uid}                                │
│     → Check role == "superadmin"               │
│     → Check status == "active"                 │
│     → Check companyId == null                  │
└────────────────┬───────────────────────────────┘
                 │
                 ▼
┌────────────────────────────────────────────────┐
│  5. Navigate to Super Admin Dashboard          │
│     /super-admin-dashboard                     │
│                                                │
│  ✅ Full platform access granted!              │
└────────────────────────────────────────────────┘
```

---

## 🚨 **TROUBLESHOOTING**

### **Issue 1: "User not found" error**

**Problem:** Firebase Auth account exists but Firestore user document doesn't

**Solution:**
1. Check Firebase Console → Firestore Database
2. Look for `users/{uid}` document
3. If missing, create it following Step 2 above
4. Make sure UID matches exactly

---

### **Issue 2: "Access denied" error**

**Problem:** User document exists but role is not "superadmin"

**Solution:**
1. Open Firestore → users collection
2. Find your user document
3. Check the `role` field
4. It must be exactly: `superadmin` (lowercase, no spaces)
5. Check `status` field is: `active`
6. Check `companyId` is: `null`

---

### **Issue 3: "Could not find a generator for route" error**

**Problem:** Routes not properly configured

**Solution:**
✅ This is now fixed! The `web_app.dart` has been updated with proper routing:
- `/super-admin-login` → Super Admin Login Screen
- `/admin-login` → Company Admin Login Screen
- `/super-admin-dashboard` → Super Admin Dashboard
- `/create-company` → Create Company Screen
- `/company/:id` → Company Details Screen

Just restart your app:
```bash
# Press 'r' in the terminal to hot reload
# Or press 'R' to hot restart
# Or stop and run again: flutter run -d chrome
```

---

### **Issue 4: Can't see the login screen**

**Problem:** App redirects somewhere else or shows error

**Solution:**
1. The app now starts at `/super-admin-login` by default
2. If it doesn't, manually navigate in browser:
   ```
   http://localhost:xxxxx/#/super-admin-login
   ```
3. Or click "Super Admin Login" link if on another login screen

---

### **Issue 5: Login button doesn't work**

**Problem:** JavaScript error or validation issue

**Solution:**
1. Check browser console (F12) for errors
2. Make sure email is valid format
3. Make sure password is not empty
4. Check Firebase console that user exists
5. Check internet connection

---

## 📊 **FIRESTORE STRUCTURE CHECK**

After setup, your Firestore should look like this:

```
straights-payroll (Firestore Database)
│
└─ users (collection)
   │
   └─ sJkL9mNoPqRsT123456789 (document - your UID)
      ├─ uid: "sJkL9mNoPqRsT123456789"
      ├─ role: "superadmin"
      ├─ companyId: null
      ├─ name: "Platform Owner"
      ├─ email: "superadmin@yourcompany.com"
      ├─ status: "active"
      ├─ createdAt: "2025-12-06T12:00:00.000Z"
      └─ updatedAt: "2025-12-06T12:00:00.000Z"
```

---

## 🎯 **WHAT TO DO AFTER LOGIN**

Once you're logged in as Super Admin:

### **1. Create Your First Company**

Click **"Create Company"** button and fill in:

```
Company Name:    ABC Construction
Company Code:    ABC
Contact Name:    John Administrator  
Contact Email:   admin@abc.com
Contact Phone:   +1234567890 (optional)
```

Click **"Create Company"**

### **2. View Company Details**

Click on the company name in the list to see:
- Company information
- Statistics (users, projects, attendance)
- Settings (employee ID format, limits, etc.)
- Actions (suspend, activate, delete)

### **3. Create Company Admin**

Follow the guide in `COMPLETE_TESTING_GUIDE_STEP_BY_STEP.md` (Phase 4) to create a Company Admin for the company.

---

## 🔄 **SWITCHING BETWEEN LOGIN SCREENS**

### **From Super Admin Login → Company Admin Login:**

On the Super Admin login screen, click:  
👉 **"Company Admin Login"** link at the bottom

### **From Company Admin Login → Super Admin Login:**

On the Company Admin login screen, click:  
👉 **"Super Admin Login"** link at the bottom

---

## ✅ **VERIFICATION CHECKLIST**

Before reporting issues, verify:

- [ ] Firebase Auth user created with correct email
- [ ] UID copied correctly
- [ ] Firestore user document created with that UID
- [ ] `role` field is exactly `"superadmin"` (lowercase)
- [ ] `companyId` field is `null`
- [ ] `status` field is `"active"`
- [ ] App is running (flutter run -d chrome)
- [ ] Browser is open and showing login screen
- [ ] Email and password match what you set in Firebase

---

## 🎊 **YOU'RE READY!**

Once logged in, you have **full platform control**:

✅ Create unlimited companies  
✅ Manage all company settings  
✅ View all data across companies  
✅ Support any company when needed  
✅ Control platform-wide settings  

**Next Steps:**  
👉 Read `COMPLETE_TESTING_GUIDE_STEP_BY_STEP.md` for full testing workflow  
👉 Create your first company  
👉 Set up Company Admin, Supervisors, and Employees  

---

**Created:** December 6, 2025  
**Status:** Super Admin Login Fixed & Ready  
**App Entry Point:** `/super-admin-login`






