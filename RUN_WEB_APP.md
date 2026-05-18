# 🚀 How to Run the Web App (Without Web Security)

## The Issue
Browser CORS/web security can block Firebase requests during local development.

---

## ✅ Solution: Run with Security Disabled

### Option 1: Flutter Run with Flags (Recommended)

```bash
cd /Users/mac/Documents/straights_psyroll
flutter run -d chrome --web-browser-flag "--disable-web-security" --web-browser-flag "--user-data-dir=/tmp/chrome_dev_test"
```

**What these flags do:**
- `--disable-web-security` - Disables CORS restrictions
- `--user-data-dir=/tmp/chrome_dev_test` - Uses a separate Chrome profile (required for security flag to work)

---

### Option 2: Open Chrome Manually (Alternative)

#### On macOS:
```bash
open -n -a /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --args --user-data-dir="/tmp/chrome_dev_test" --disable-web-security --disable-site-isolation-trials
```

Then navigate to: `http://localhost:5000` (or whatever port Flutter uses)

#### On Windows:
```cmd
"C:\Program Files\Google\Chrome\Application\chrome.exe" --user-data-dir="C:\temp\chrome_dev_test" --disable-web-security --disable-site-isolation-trials
```

#### On Linux:
```bash
google-chrome --user-data-dir="/tmp/chrome_dev_test" --disable-web-security --disable-site-isolation-trials
```

---

### Option 3: Update Firestore Rules (Better for Production)

If you want proper security rules instead of disabling browser security:

1. **Go to Firebase Console**
2. **Firestore Database** → **Rules** tab
3. **Replace with these TEST rules:**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // TESTING ONLY - Allow all access
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

4. **Click "Publish"**

⚠️ **WARNING:** These rules allow ANYONE to read/write your database!  
Only use for testing on a local/test Firebase project!

---

## 🎯 Quick Start Script

Save this as `run_web.sh`:

```bash
#!/bin/bash
cd /Users/mac/Documents/straights_psyroll
flutter run -d chrome \
  --web-browser-flag "--disable-web-security" \
  --web-browser-flag "--user-data-dir=/tmp/chrome_dev_test"
```

Make it executable:
```bash
chmod +x run_web.sh
./run_web.sh
```

---

## 🔍 Verify It's Working

After running with disabled security, you should see:
1. ✅ No CORS errors in browser console
2. ✅ Firebase requests succeed
3. ✅ Login works without "User is NULL" error
4. ✅ Dashboard loads properly

---

## 💡 Pro Tips

1. **Always use a separate Chrome profile** (`--user-data-dir`) when disabling security
2. **Never use these flags for production** - only for local development
3. **Close the dev Chrome instance** when done testing to avoid security risks
4. **For production**, deploy with proper Firestore security rules

---

## 🆘 Still Not Working?

If you still see "User is NULL" after disabling web security:

1. **Check Firebase Console logs:**
   - Firebase Console → Firestore → "Usage" tab
   - Look for denied requests

2. **Check browser console:**
   - Press F12 → Console tab
   - Look for Firebase errors

3. **Verify document exists:**
   - Firebase Console → Firestore → `users` collection
   - Your UID document should be there with role: "admin"

Let me know what you see! 🚀


