# Xcode Configuration for iOS Biometric Authentication

## 📱 Xcode Settings Required

For biometric authentication to work, you need to configure a few things in Xcode. Here's the complete guide:

---

## 🚀 Quick Answer

**Minimal Xcode Configuration Required:**
1. ✅ **Signing & Capabilities** - Configure your team and bundle ID
2. ⚠️ **No special capabilities needed** for biometrics (handled automatically by iOS)
3. ✅ **Build Settings** - Usually auto-configured by Flutter

---

## 📋 Step-by-Step Xcode Configuration

### Step 1: Open Project in Xcode

```bash
cd /Users/mac/Documents/straights_psyroll
open ios/Runner.xcworkspace
```

**⚠️ IMPORTANT**: Always open `.xcworkspace`, NOT `.xcodeproj`!

---

### Step 2: Configure Signing & Capabilities

1. **Select Runner target** in the left sidebar
2. **Go to "Signing & Capabilities" tab**

#### A. Signing Configuration:

**Automatically manage signing (Recommended)**:
- ✅ Check "Automatically manage signing"
- Select your **Team** from dropdown
- Xcode will automatically provision your app

**Manual signing** (if you prefer):
- ⬜ Uncheck "Automatically manage signing"
- Select **Provisioning Profile** manually
- Select **Signing Certificate** manually

#### B. Bundle Identifier:
```
com.yourcompany.straights-psyroll
```
(Should already be set)

#### C. Capabilities:
**For biometric authentication, you DON'T need to add any special capabilities!**

The following are automatically handled by iOS:
- ❌ NO "Face ID" capability needed
- ❌ NO "Biometric" capability needed
- ❌ NO special entitlements needed

Face ID/Touch ID permissions are handled purely through `Info.plist` (already done! ✅)

---

### Step 3: Verify Build Settings

1. Select **Runner** target
2. Go to **Build Settings** tab
3. Search for these settings:

#### A. iOS Deployment Target
```
Minimum: iOS 12.0 (already set to 15.0 ✅)
```

#### B. Swift Language Version
```
Swift 5.0 or later (auto-configured ✅)
```

#### C. Enable Bitcode
```
NO (default for Flutter apps ✅)
```

---

### Step 4: Info.plist Verification (Already Done ✅)

In Xcode, verify `Info.plist` contains:

1. Navigate to: **Runner → Info.plist**
2. Check for key: `NSFaceIDUsageDescription`
3. Value: "We use Face ID for secure authentication"

**Status**: ✅ Already configured (line 37-38 in your Info.plist)

---

## 🎯 Complete Xcode Setup Checklist

### Required Settings:

- [ ] Open `ios/Runner.xcworkspace` (not .xcodeproj)
- [ ] Select "Runner" target
- [ ] Go to "Signing & Capabilities"
- [ ] Enable "Automatically manage signing" OR select manual signing
- [ ] Select your Apple Developer Team
- [ ] Verify Bundle Identifier is correct
- [ ] iOS Deployment Target: 12.0 or higher (yours is 15.0 ✅)
- [ ] `NSFaceIDUsageDescription` in Info.plist (already done ✅)

### NOT Required:

- ⬜ Special capabilities for Face ID (handled by iOS)
- ⬜ Custom entitlements file
- ⬜ Keychain sharing capability (unless you need it for other features)
- ⬜ App Groups capability (unless you need it for widgets/extensions)

---

## 📸 Visual Guide

### 1. Opening in Xcode:

```bash
# In terminal, from your project root:
open ios/Runner.xcworkspace
```

### 2. Xcode Window Layout:

```
┌─────────────────────────────────────────┐
│ Xcode                                   │
├─────────────┬───────────────────────────┤
│ Navigator   │ Editor Area               │
│             │                           │
│ ├─ Runner   │ ┌─────────────────────┐   │
│ │  ├─ Pods  │ │ Signing & Capabil. │   │
│ │  └─ ...   │ │                     │   │
│             │ │ Team: [Select]      │   │
│             │ │ Bundle ID: ...      │   │
│             │ │                     │   │
│             │ └─────────────────────┘   │
└─────────────┴───────────────────────────┘
```

### 3. Signing & Capabilities Tab:

**What you should see**:

```
✅ Automatically manage signing
Team: [Your Apple Developer Account]
Bundle Identifier: com.yourcompany.straights-psyroll

No additional capabilities needed!
```

---

## 🔐 Apple Developer Account Requirements

### For Development (Testing on Device):

**Option 1: Free Apple ID** (Recommended for testing)
- Sign in with your Apple ID in Xcode
- Xcode → Settings → Accounts → Add (+) → Apple ID
- No paid developer account needed!
- Can test on your own device for 7 days
- App expires after 7 days (need to re-deploy)

**Option 2: Paid Developer Account** ($99/year)
- Full App Store distribution
- No 7-day expiration
- TestFlight access
- Unlimited devices

### For App Store Release:

**Required**: Apple Developer Program ($99/year)
- Sign up at: https://developer.apple.com/programs/

---

## 🧪 Testing Configuration

### Test on Real Device:

1. **Connect iPhone/iPad** to Mac via USB
2. **Trust the device** (if first time)
3. **Select device** in Xcode toolbar
4. **Click Run** (▶️ button) or:
   ```bash
   flutter run
   ```
5. **First time**: Device will show "Untrusted Developer"
   - On device: Settings → General → VPN & Device Management
   - Trust your developer certificate

### Test on Simulator:

1. **Select simulator** from Xcode device menu
2. **Click Run** or:
   ```bash
   flutter run -d "iPhone 15 Pro"
   ```
3. **Enable Face ID** in simulator:
   - Simulator → Features → Face ID → Enrolled

---

## ⚙️ Build Configurations

### Debug Configuration (Default):
```
- Used for development
- Allows debugging
- Larger app size
```

### Release Configuration (App Store):
```
- Optimized for production
- Smaller app size
- No debugging
```

**Build for Release**:
```bash
flutter build ios --release
```

Then open in Xcode to archive and upload to App Store.

---

## 🔧 Advanced Settings (Usually Not Needed)

### Custom Entitlements:

If you need special capabilities later, you can add:

1. **Select Runner** target
2. **Go to "Signing & Capabilities"**
3. **Click "+ Capability"**
4. **Add capabilities** like:
   - Push Notifications
   - iCloud
   - App Groups
   - etc.

**For biometrics**: None of these are needed! ✅

---

## ⚠️ Common Xcode Issues & Solutions

### Issue 1: "Runner.xcworkspace not found"

**Cause**: Pods not installed

**Solution**:
```bash
cd ios
pod install
cd ..
```

---

### Issue 2: "No signing certificate found"

**Cause**: Not logged into Apple account in Xcode

**Solution**:
1. Xcode → Settings (⌘,)
2. Accounts tab
3. Click "+" to add Apple ID
4. Sign in with your Apple ID

---

### Issue 3: "Provisioning profile doesn't match"

**Cause**: Bundle ID or Team mismatch

**Solution**:
1. Clean build: Product → Clean Build Folder (⇧⌘K)
2. Verify Bundle ID matches your provisioning profile
3. Re-select Team in Signing & Capabilities
4. Try building again

---

### Issue 4: "App installation failed" on device

**Cause**: Device not trusted or free developer account expired

**Solution**:
- On device: Settings → General → VPN & Device Management
- Trust your developer certificate
- If expired (free account), rebuild and install again

---

## 📱 Device-Specific Settings

### On Your iPhone/iPad:

1. **Enable Developer Mode** (iOS 16+):
   ```
   Settings → Privacy & Security → Developer Mode → ON
   ```

2. **Trust Developer Certificate**:
   ```
   Settings → General → VPN & Device Management
   → Select your certificate → Trust
   ```

3. **Enable Face ID/Touch ID**:
   ```
   Settings → Face ID & Passcode → Set up Face ID
   → Enable "Use Face ID For: Other Apps"
   ```

---

## 🚀 Complete Workflow

### From Xcode Setup to Testing:

```bash
# 1. Install dependencies
cd /Users/mac/Documents/straights_psyroll
flutter pub get
cd ios
pod install
cd ..

# 2. Open in Xcode
open ios/Runner.xcworkspace

# 3. Configure in Xcode:
#    - Select Runner target
#    - Signing & Capabilities
#    - Select your Team
#    - Verify Bundle ID

# 4. Close Xcode

# 5. Run on device
flutter run

# 6. On device (first time):
#    Settings → General → Device Management → Trust

# 7. Test biometric authentication!
```

---

## ✅ Verification Checklist

Before testing, verify:

### In Xcode:
- [ ] Opened `.xcworkspace` (not `.xcodeproj`)
- [ ] Runner target selected
- [ ] Team selected in Signing & Capabilities
- [ ] Bundle ID is correct
- [ ] No red errors in Signing section
- [ ] iOS Deployment Target: 12.0+ (yours: 15.0 ✅)

### In Info.plist:
- [ ] `NSFaceIDUsageDescription` present ✅
- [ ] Permission string is user-friendly ✅

### On Device:
- [ ] Face ID or Touch ID enrolled
- [ ] "Use for: Other Apps" enabled
- [ ] Developer Mode ON (iOS 16+)
- [ ] Developer certificate trusted

---

## 📊 Summary

### What You NEED to Configure in Xcode:

1. ✅ **Signing & Capabilities** → Select Team
2. ✅ **Bundle Identifier** → Verify it's correct
3. ✅ **Device Trust** → First time only

### What You DON'T NEED:

- ❌ Special capabilities for Face ID
- ❌ Custom entitlements
- ❌ Additional frameworks
- ❌ Special build settings

**Info.plist already has everything needed!** ✅

---

## 🎓 Quick Tips

1. **Always use `.xcworkspace`** - Never open `.xcodeproj` directly
2. **Clean build often** - Product → Clean Build Folder (⇧⌘K)
3. **Use free Apple ID** - Good enough for development/testing
4. **Test on real device** - Simulator can only simulate biometrics
5. **Archive for App Store** - Product → Archive (when ready)

---

## 📞 Need Help?

If you encounter Xcode issues:

1. **Clean Build**:
   ```bash
   flutter clean
   cd ios
   pod deintegrate
   pod install
   cd ..
   flutter pub get
   ```

2. **Restart Xcode**

3. **Re-run**:
   ```bash
   flutter run
   ```

---

## 🎉 Ready to Go!

With your Apple ID signed in and Team selected, you're all set!

**Next Steps**:
1. Open Xcode: `open ios/Runner.xcworkspace`
2. Select your Team
3. Run: `flutter run`
4. Test biometric authentication on your device! 📱

---

*Last Updated: November 3, 2025*
*Status: ✅ Ready for Configuration*

