# Web Admin Dashboard Debug Guide

## Current Status
- ✅ Server running on http://localhost:8081
- ❌ Dashboard not showing output

## Issue Found & Fixed
**Problem:** Duplicate `pendingEmployeesProvider` definition in admin dashboard causing provider conflict.

**Fix Applied:** Removed duplicate provider, now using `allPendingEmployeesProvider` from `auth_provider.dart`

---

## How to Test Right Now

### Step 1: Hot Reload the App
In Terminal 1 where Flutter is running, press **`r`** to hot reload the changes.

### Step 2: Open Browser
Navigate to: http://localhost:8081

### Step 3: What You Should See
**Super Admin Login Screen** with:
- Email field
- Password field
- "Login as Super Admin" button
- Link to "Company Admin Login"

---

## Testing Admin Login Flow

### Option A: Super Admin Login
1. Go to http://localhost:8081
2. Enter Super Admin credentials:
   - Email: your super admin email
   - Password: your password
3. Should navigate to Super Admin Dashboard

### Option B: Company Admin Login
1. Go to http://localhost:8081
2. Click "Company Admin Login"
3. Enter:
   - Company Code (e.g., "ABC")
   - Admin Email
   - Admin Password
4. Should navigate to Admin Dashboard

---

## If Dashboard Still Doesn't Show

### Check 1: Browser Console Errors
1. Open browser (Chrome/Edge)
2. Open Developer Tools (F12)
3. Go to Console tab
4. Look for red errors
5. Share the errors

### Check 2: Check What's Actually Showing
**Question:** What do you see on http://localhost:8081?
- [ ] Blank white page
- [ ] Login screen (working correctly!)
- [ ] Loading spinner forever
- [ ] Error message
- [ ] Something else

### Check 3: After Login, What Happens?
When you try to log in:
- [ ] Nothing happens
- [ ] Error message shows
- [ ] Stays on login screen
- [ ] Briefly loads then goes blank
- [ ] Gets stuck on loading

---

## Common Issues & Solutions

### Issue 1: Blank Page After Login
**Cause:** `currentUserProvider` not loading user data for admin
**Solution:** Already fixed with the provider changes

### Issue 2: Login Screen Shows But Can't Login
**Cause:** Authentication service not working
**Check:** Look for Firebase errors in console

### Issue 3: Dashboard Loads But Shows No Data
**Cause:** Providers returning empty data
**Solution:** Check Firestore for projects/employees

### Issue 4: White Screen on http://localhost:8081
**Cause:** App not initializing
**Solution:** Check browser console for errors

---

## Quick Debug Commands

```bash
# Check if server is running
lsof -i :8081

# View Flutter logs
# Go to Terminal 1 where flutter run is active
# Any errors will show there

# Force restart the app
# In Terminal 1, press 'R' (capital R)
```

---

## What Was Fixed

### Before (Broken):
```dart
// Duplicate provider in admin_dashboard_screen.dart
final pendingEmployeesProvider = FutureProvider<List<UserModel>>(...);

// But using different name:
final pendingEmployees = ref.watch(allPendingEmployeesProvider);
// ❌ Provider not found!
```

### After (Fixed):
```dart
// Removed duplicate, using the one from auth_provider.dart
final pendingEmployees = ref.watch(allPendingEmployeesProvider);
// ✅ Correct provider!
```

---

## Next Steps

1. **Press 'r' in Terminal 1** to hot reload
2. **Refresh browser** at http://localhost:8081
3. **Tell me what you see**:
   - Is it the login screen?
   - Is it blank?
   - Any error messages?
4. **Try logging in** and tell me what happens

---

## Provider Chain for Admin Dashboard

```
Web Admin Flow:
1. main.dart → kIsWeb = true → WebApp
2. WebApp → initialRoute: '/super-admin-login'
3. SuperAdminLoginScreen → Enter credentials
4. signInSuperAdmin() → Firebase Auth
5. Navigate to SuperAdminDashboardScreen
6. Dashboard watches:
   - currentUserProvider ← Should load admin user
   - activeProjectsProvider ← Should load projects
   - allEmployeesProvider ← Should load employees
   - allPendingEmployeesProvider ← Should load pending
```

**Issue was at step 6**: Provider name mismatch prevented dashboard from loading data.

---

## Please Provide This Information

To help debug further, please tell me:

1. **What URL shows in browser?**
   - http://localhost:8081
   - http://localhost:8081/super-admin-login
   - Something else?

2. **What do you see on screen?**
   - Describe exactly what's displayed

3. **Browser console errors?**
   - Press F12, check Console tab
   - Copy/paste any red errors

4. **When did it stop working?**
   - After login?
   - Before login?
   - Page never loads?

