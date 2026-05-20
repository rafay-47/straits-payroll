# 🔧 Admin Login - Troubleshooting Guide

## 🎯 What to Do Now

### Step 1: Run the App

```bash
cd /Users/mac/Documents/straights_psyroll
flutter run -d chrome --web-browser-flag "--disable-web-security" --web-browser-flag "--user-data-dir=/tmp/chrome_dev_test"
```

### Step 2: Try Logging In

- Email: `admin@test.com`
- Password: `Admin@123` (or whatever password you set)

### Step 3: Check the Console Output

**Open Browser Console:** Press `F12` (or `Cmd+Option+I` on Mac) → Console tab

---

## 📊 What the Debug Output Will Tell You

### ✅ Scenario 1: Document Doesn't Exist

```
🔍 Firebase Auth UID: abc123xyz789
📄 Attempting DIRECT Firestore fetch...
❌ DIRECT FETCH: Document does NOT exist!
❌ Path checked: users/abc123xyz789
```

**FIX:**
1. Open Firebase Console
2. Go to Firestore Database → `users` collection
3. Click "Add document"
4. **Document ID:** Paste the UID shown above (`abc123xyz789`)
5. Add these fields:

| Field | Type | Value |
|-------|------|-------|
| uid | string | [your UID] |
| name | string | Admin User |
| email | string | admin@test.com |
| role | string | **admin** ← MUST BE LOWERCASE! |
| status | string | active |
| biometricEnabled | boolean | false |
| createdAt | timestamp | [current time] |
| updatedAt | timestamp | [current time] |

6. Click "Save"

---

### ✅ Scenario 2: Document Exists, Wrong Role

```
✅ DIRECT FETCH: Document FOUND!
📋 Full document data:
   role: "Admin"    ← Capital A!
   
🔍 Role check: "admin" == "admin" ?
❌ FAILED! Role is NOT admin.
   Expected: "admin"
   Got: "Admin"
```

**FIX:**
1. Open Firebase Console
2. Firestore Database → `users` → [your UID]
3. Find the `role` field
4. Click the value
5. Change it to: **admin** (lowercase!)
6. Save

---

### ✅ Scenario 3: Success!

```
✅ DIRECT FETCH: Document FOUND!
📋 Full document data:
   role: "admin"    ← Correct!
   
🔍 Role check: "admin" == "admin" ?
🎉 SUCCESS! Role is admin. Navigating to dashboard...
```

You should see the **Admin Dashboard** appear! 🎉

---

## 🖼️ Visual Checklist for Firestore

Your Firestore should look EXACTLY like this:

```
📁 Firestore Database
  └─ 📁 users (collection)
      └─ 📄 [YOUR_UID] (e.g., abc123xyz789)
          ├─ uid: "abc123xyz789"
          ├─ name: "Admin User"
          ├─ email: "admin@test.com"
          ├─ role: "admin"           ← MUST BE LOWERCASE!
          ├─ status: "active"
          ├─ biometricEnabled: false
          ├─ createdAt: (timestamp)
          └─ updatedAt: (timestamp)
```

---

## 🔍 Common Issues

| Issue | Cause | Fix |
|-------|-------|-----|
| "Document does NOT exist" | No Firestore document | Create document with your UID |
| "Role is NOT admin" | Role is "Admin" or "ADMIN" | Change to lowercase "admin" |
| "Firestore error" | Security rules blocking | Set test rules (see below) |
| Can't find UID | Check console output | UID is shown in debug messages |

---

## 🔐 Firestore Security Rules (If Blocked)

If you see "Firestore error: permission denied", update your rules:

1. Firebase Console → Firestore Database → **Rules** tab
2. Replace with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // TESTING ONLY - Allow all
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

3. Click **"Publish"**

⚠️ **WARNING:** These rules allow ANYONE to read/write. Only for testing!

---

## 📝 Step-by-Step Fix Process

### If Document Doesn't Exist:

1. ✅ Run the app and try logging in
2. ✅ Copy the UID from the console
3. ✅ Open Firebase Console → Firestore → users
4. ✅ Add document with that UID
5. ✅ Add all required fields (especially `role: "admin"`)
6. ✅ Save
7. ✅ Refresh the web app
8. ✅ Try logging in again

### If Document Exists but Wrong Role:

1. ✅ Check console output to confirm role value
2. ✅ Open Firebase Console → Firestore → users → [your UID]
3. ✅ Edit `role` field
4. ✅ Change to lowercase: `admin`
5. ✅ Save
6. ✅ Refresh the web app
7. ✅ Try logging in again

---

## 🎯 Expected Result

After fixing, you should see:
- ✅ Console: `🎉 SUCCESS! Role is admin. Navigating to dashboard...`
- ✅ Screen: Admin Dashboard loads
- ✅ You can see: Projects, Employees, Settings, etc.

---

## 🆘 Still Not Working?

**Send me:**
1. The FULL console output (copy everything between `===== DETAILED DEBUG =====` lines)
2. A screenshot of your Firestore document (from Firebase Console)
3. Tell me which scenario you're seeing (1, 2, or 3)

I'll help you fix it! 🚀


