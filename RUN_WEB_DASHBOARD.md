# 🚀 Run Web Dashboard - Quick Command Guide

**Date:** February 2, 2026

---

## ✅ **Quick Command (Copy & Paste)**

```bash
cd /Users/mac/Documents/straights_psyroll && flutter run -d chrome --web-browser-flag "--disable-web-security" --web-browser-flag "--user-data-dir=/tmp/chrome_dev_test"
```

---

## 📋 **Step-by-Step Instructions**

### **Option 1: Single Command (Recommended)**

Copy and paste this entire command in your terminal:

```bash
cd /Users/mac/Documents/straights_psyroll && flutter run -d chrome --web-browser-flag "--disable-web-security" --web-browser-flag "--user-data-dir=/tmp/chrome_dev_test"
```

**What this does:**
- ✅ Changes to project directory
- ✅ Runs Flutter web app on Chrome
- ✅ Disables web security (needed for Firebase local development)
- ✅ Uses separate Chrome profile (required for security flag)

---

### **Option 2: Step-by-Step**

```bash
# Step 1: Navigate to project directory
cd /Users/mac/Documents/straights_psyroll

# Step 2: Run web dashboard
flutter run -d chrome \
  --web-browser-flag "--disable-web-security" \
  --web-browser-flag "--user-data-dir=/tmp/chrome_dev_test"
```

---

## 🎯 **What You'll See**

1. **Terminal Output:**
   ```
   🚀 Starting app initialization...
   📱 Platform: WEB
   🔥 Initializing Firebase...
   ✅ Firebase initialized successfully
   🎨 Starting Flutter app...
   ```

2. **Browser Opens:**
   - Chrome opens automatically
   - URL: `http://localhost:XXXX` (port number shown in terminal)
   - You'll see: **Super Admin Login Screen**

3. **Login:**
   - Enter Super Admin credentials
   - Or login as Company Admin
   - Access the dashboard

---

## 🔧 **Alternative Commands**

### **Run on Different Browser:**

**Chrome (Default):**
```bash
flutter run -d chrome --web-browser-flag "--disable-web-security" --web-browser-flag "--user-data-dir=/tmp/chrome_dev_test"
```

**Edge:**
```bash
flutter run -d edge --web-browser-flag "--disable-web-security" --web-browser-flag "--user-data-dir=/tmp/edge_dev_test"
```

**Firefox:**
```bash
flutter run -d firefox
```

**Safari (macOS):**
```bash
flutter run -d safari
```

---

## 🛠️ **Troubleshooting**

### **Issue: Port Already in Use**

**Solution:**
```bash
# Kill existing Flutter processes
pkill -f flutter

# Wait 2 seconds, then run again
sleep 2
flutter run -d chrome --web-browser-flag "--disable-web-security" --web-browser-flag "--user-data-dir=/tmp/chrome_dev_test"
```

### **Issue: White Screen**

**Solution:**
```bash
# Clean restart
cd /Users/mac/Documents/straights_psyroll
pkill -f flutter
flutter clean
flutter pub get
flutter run -d chrome --web-browser-flag "--disable-web-security" --web-browser-flag "--user-data-dir=/tmp/chrome_dev_test"
```

### **Issue: Firebase Errors**

**Check:**
- Firebase is initialized in `main.dart`
- Firebase config is correct
- Browser console (F12) for specific errors

---

## 📝 **Quick Reference**

| Command | Purpose |
|---------|---------|
| `flutter run -d chrome` | Run on Chrome |
| `flutter run -d web-server` | Run on web server (no browser) |
| `flutter run -d chrome --release` | Run in release mode |
| `flutter run -d chrome --web-port=8080` | Run on specific port |

---

## ✅ **Success Indicators**

You'll know it's working when:
- ✅ Chrome opens automatically
- ✅ You see "Super Admin Login" screen (not white screen)
- ✅ No errors in terminal
- ✅ Firebase initializes successfully
- ✅ You can login and see dashboard

---

## 🎯 **Default URL**

After running, the app will be available at:
- **Local:** `http://localhost:XXXX` (port shown in terminal)
- Usually: `http://localhost:5000` or `http://localhost:8081`

---

## 📱 **Mobile vs Web**

**Web Dashboard:**
- For: Super Admin, Company Admin
- Login: Email + Password
- Features: Company management, employee management, project management

**Mobile App:**
- For: Employees, Supervisors
- Login: Employee ID + PIN (employees) or Email + Password (supervisors)
- Features: Check-in/out, attendance, documents

---

## 🚀 **Ready to Run!**

Just copy and paste this command:

```bash
cd /Users/mac/Documents/straights_psyroll && flutter run -d chrome --web-browser-flag "--disable-web-security" --web-browser-flag "--user-data-dir=/tmp/chrome_dev_test"
```

**That's it!** The web dashboard will open in Chrome. 🎉
