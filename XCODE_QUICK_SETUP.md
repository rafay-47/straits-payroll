# Xcode Quick Setup - 5 Minutes ⏱️

## 🎯 TL;DR - What You Need to Do in Xcode

### ✅ Short Answer:
Just **3 steps** in Xcode:
1. **Sign in** with your Apple ID
2. **Select your Team** in Signing & Capabilities
3. **Run the app** on your device

**That's it!** No special capabilities needed for biometrics. ✅

---

## 📋 Step-by-Step (First Time Only)

### Step 1: Open Xcode Project (1 min)

```bash
cd /Users/mac/Documents/straights_psyroll
open ios/Runner.xcworkspace
```

⚠️ **Important**: Open `.xcworkspace`, NOT `.xcodeproj`

---

### Step 2: Sign in with Apple ID (1 min)

1. **Xcode** → **Settings** (or press `⌘,`)
2. Click **"Accounts"** tab
3. Click **"+"** button (bottom left)
4. Select **"Apple ID"**
5. Enter your Apple ID and password
6. Click **"Continue"**

**Done!** ✅ Your Apple ID is now connected.

**Free or Paid?**
- ✅ **Free Apple ID** = Works for testing (7-day expiration)
- ✅ **Paid Developer Account** = No expiration, App Store release

---

### Step 3: Select Team in Project (2 min)

1. In Xcode, click **"Runner"** in the left sidebar (top item with blue icon)
2. Make sure **"Runner"** target is selected (not "Pods" or "RunnerTests")
3. Click **"Signing & Capabilities"** tab at the top
4. Under **"Signing"**:
   - ✅ Check **"Automatically manage signing"**
   - Select **"Team"** from dropdown (your Apple ID will appear)
   - Verify **"Bundle Identifier"** looks correct

**What you should see**:
```
✅ Automatically manage signing
Team: [Your Name (Personal Team)]  ← Select this
Bundle Identifier: com.yourcompany.straights-psyroll
```

**Done!** ✅ Signing is configured.

---

### Step 4: No Capabilities Needed! (0 min)

**Do NOT add any capabilities for biometric authentication.**

Face ID/Touch ID works automatically through `Info.plist` (already configured ✅)

**You should NOT see these**:
- ❌ Face ID capability
- ❌ Biometric capability
- ❌ Any special entitlements

---

## 🧪 Test on Real Device

### First-Time Device Setup:

1. **Connect your iPhone/iPad** via USB
2. **Unlock your device**
3. **Trust this computer** (if prompted on device)
4. In Xcode toolbar, **select your device** from the device dropdown
5. Click the **▶️ Run button** (or press `⌘R`)

**First Run** - On your device:
```
Settings → General → VPN & Device Management
→ Select your developer certificate
→ Tap "Trust"
```

Then run the app again from Xcode.

---

### Or Use Flutter Command:

```bash
# Close Xcode (optional)
flutter run
```

Flutter will automatically use your Xcode configuration.

---

## ✅ Complete Checklist

### In Xcode:
- [ ] Opened `ios/Runner.xcworkspace`
- [ ] Added Apple ID in Xcode Settings → Accounts
- [ ] Selected "Runner" target
- [ ] Went to "Signing & Capabilities" tab
- [ ] Checked "Automatically manage signing"
- [ ] Selected Team from dropdown
- [ ] Bundle Identifier looks correct
- [ ] No red errors in Signing section

### On Device:
- [ ] Device connected via USB
- [ ] Device unlocked
- [ ] Trusted computer
- [ ] Face ID or Touch ID enrolled
- [ ] Developer certificate trusted (after first run)

### Ready to Test:
- [ ] Run app from Xcode or `flutter run`
- [ ] Test check-in (should prompt for Face ID/Touch ID)
- [ ] Test check-out (should prompt for Face ID/Touch ID)

---

## 🎯 Visual Xcode Guide

### Xcode → Settings → Accounts:
```
┌─────────────────────────────────┐
│ Settings                        │
├─────────────────────────────────┤
│ Accounts              │         │
│                       │  [+]    │  ← Click + to add Apple ID
│ [Apple ID Icon]       │         │
│ your@email.com        │         │
│                       │         │
└─────────────────────────────────┘
```

### Runner → Signing & Capabilities:
```
┌───────────────────────────────────────┐
│ Runner    ▼                           │
├───────────────────────────────────────┤
│ General | Signing & Capabilities ... │ ← Click here
├───────────────────────────────────────┤
│                                       │
│ Signing                               │
│ ✅ Automatically manage signing       │
│                                       │
│ Team: [Your Name (Personal Team)]  ▼ │ ← Select your team
│                                       │
│ Bundle Identifier:                    │
│ com.yourcompany.straights-psyroll     │
│                                       │
│ ✅ No errors or warnings              │
└───────────────────────────────────────┘
```

---

## ⚠️ Common First-Time Issues

### Issue: "No Team" in dropdown

**Solution**:
1. Add Apple ID first (Xcode → Settings → Accounts)
2. Then return to Signing & Capabilities
3. Team dropdown should now show your Apple ID

---

### Issue: "Failed to install app on device"

**Solution**:
1. On device: Settings → General → VPN & Device Management
2. Trust your developer certificate
3. Try running again

---

### Issue: "Provisioning profile error"

**Solution**:
1. Clean build: Product → Clean Build Folder (⇧⌘K)
2. Reselect Team in Signing & Capabilities
3. Try again

---

## 🚀 Quick Commands

```bash
# Open in Xcode
open ios/Runner.xcworkspace

# Or just run with Flutter (uses Xcode config)
flutter run

# Clean and rebuild if issues
flutter clean
cd ios && pod install && cd ..
flutter run
```

---

## 💡 Pro Tips

1. **Use "Automatically manage signing"** - Easiest for beginners
2. **Free Apple ID is fine** - No need to pay $99/year for testing
3. **Test on real device** - Simulator can't use real Face ID/Touch ID
4. **Close Xcode** - Flutter CLI is often easier to use
5. **Archive only when ready** - For App Store submission later

---

## 📱 What You DON'T Need

For biometric authentication, you DON'T need to:

- ❌ Add Face ID capability
- ❌ Add Keychain capability (unless for other features)
- ❌ Create custom entitlements
- ❌ Modify build settings
- ❌ Add frameworks manually
- ❌ Paid developer account (for testing)

**Everything works with just Team selection!** ✅

---

## 🎉 That's It!

**3 steps**:
1. ✅ Add Apple ID to Xcode
2. ✅ Select Team in Signing & Capabilities
3. ✅ Run on device and test

**Biometric authentication will work immediately!** 📱🔐

---

## 📚 More Details

- Full guide: [XCODE_CONFIGURATION.md](./XCODE_CONFIGURATION.md)
- iOS setup: [IOS_BIOMETRIC_SETUP.md](./IOS_BIOMETRIC_SETUP.md)
- Quick reference: [IOS_BIOMETRIC_QUICK_REFERENCE.md](./IOS_BIOMETRIC_QUICK_REFERENCE.md)

---

**Ready to test in 5 minutes!** 🚀

*Last Updated: November 3, 2025*

