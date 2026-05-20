# 📱 QR Code Scanning - Complete Usage Guide

**Date:** February 2, 2026  
**Status:** ✅ **IMPLEMENTED & READY**

---

## 🎯 **Overview**

QR codes are used for employee check-in/check-out at project sites. This guide explains:
1. ✅ How QR codes are generated (Admin)
2. ✅ Where to display/print QR codes (Project Site)
3. ✅ How employees scan QR codes (Mobile App)

---

## 📋 **Complete Flow**

```
┌─────────────────────────────────────────────────────────┐
│  STEP 1: ADMIN GENERATES QR CODE                       │
│  (Web Dashboard → Project Management)                   │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  STEP 2: ADMIN PRINTS/DISPLAYS QR CODE                 │
│  (At Project Site - Poster, Screen, etc.)              │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  STEP 3: EMPLOYEE SCANS QR CODE                        │
│  (Mobile App → Check-In → QR Code)                     │
└─────────────────────────────────────────────────────────┘
```

---

## 🔧 **STEP 1: Generate QR Code (Admin - Web Dashboard)**

### **Location:** Web Dashboard → Projects → Add/Edit Project

### **Steps:**

1. **Login as Admin** (Company Code + Email + Password)

2. **Navigate to Project Management:**
   - Click "Manage Projects" or "Projects" in sidebar

3. **Create/Edit Project:**
   - Click "Add Project" (new) or "Edit" (existing project)

4. **Enable QR Code Check-in:**
   - Scroll to "Check-in Methods" section
   - ✅ Check the "QR Code" checkbox

5. **Generate QR Code:**
   - After checking QR Code checkbox, you'll see:
     - "Generate QR Code" button
   - Click "Generate QR Code" button
   - ✅ QR code will appear with:
     - Visual QR code image (scannable)
     - QR code data string (text format)
     - "Copy Code" button
     - "Regenerate" button

6. **Save Project:**
   - Click "Add" (new) or "Update" (edit)
   - ✅ QR code is saved to project

### **What You'll See:**

```
┌─────────────────────────────────────┐
│  QR Code Generated                  │
│                                     │
│  [QR CODE IMAGE]                    │
│                                     │
│  QR Code Data:                      │
│  PROJECT:proj_123:Site A:1234567890 │
│                                     │
│  [Copy Code]  [Regenerate]         │
└─────────────────────────────────────┘
```

### **QR Code Format:**
```
PROJECT:{projectId}:{projectName}:{timestamp}
Example: PROJECT:proj_abc123:Construction Site A:1706899200000
```

---

## 🖨️ **STEP 2: Print/Display QR Code (At Project Site)**

### **Option A: Print QR Code Image**

1. **Take Screenshot:**
   - When QR code is displayed in web dashboard
   - Take a screenshot of the QR code image
   - Or use browser's print feature

2. **Print:**
   - Print the screenshot/image
   - Recommended size: **At least 4x4 inches** (10x10 cm)
   - Use good quality paper/printer

3. **Display at Site:**
   - Place printed QR code at project entrance
   - Use protective cover (laminated or plastic sleeve)
   - Ensure good lighting for scanning

### **Option B: Export QR Code Data**

1. **Copy QR Code Data:**
   - Click "Copy Code" button in project management
   - QR code data is copied to clipboard
   - Format: `PROJECT:proj_123:Site A:1234567890`

2. **Generate QR Code Online:**
   - Go to any QR code generator website:
     - https://www.qr-code-generator.com/
     - https://www.qrcode-monkey.com/
     - https://www.the-qrcode-generator.com/
   - Paste the QR code data
   - Generate and download QR code image
   - Print the downloaded image

3. **Display at Site:**
   - Print and place at project location
   - Ensure it's visible and accessible

### **Option C: Display on Digital Screen**

1. **Screenshot QR Code:**
   - Take screenshot from web dashboard

2. **Display on Screen:**
   - Show QR code on tablet/iPad at project site
   - Or display on TV/monitor
   - Ensure screen is bright and clear

### **Best Practices:**

✅ **QR Code Size:**
- Minimum: 4x4 inches (10x10 cm)
- Recommended: 6x6 inches (15x15 cm) or larger
- Larger = easier to scan from distance

✅ **Placement:**
- At project entrance/gate
- Eye level (not too high/low)
- Good lighting (not in shadows)
- Protected from weather (if outdoors)

✅ **Quality:**
- High contrast (black on white)
- Clear, sharp image
- No blur or distortion
- Not damaged or wrinkled

---

## 📱 **STEP 3: Employee Scans QR Code (Mobile App)**

### **Location:** Mobile App → Employee Dashboard → Check-In

### **Steps:**

1. **Login as Employee:**
   - Open mobile app
   - Select "Employee" role
   - Enter: Company Code + Employee ID + PIN
   - Login

2. **Navigate to Check-In:**
   - From Employee Dashboard
   - Click "Check-In" button or card

3. **Select Project:**
   - Choose project from dropdown
   - ✅ Project must have QR code check-in enabled

4. **Select QR Code Method:**
   - You'll see check-in method cards:
     - GPS Location
     - NFC Tag
     - **QR Code** ← Select this
     - Manual
   - Tap "QR Code" card

5. **Camera Opens:**
   - ✅ Camera automatically opens
   - Point camera at QR code (printed or displayed)
   - ✅ QR code is automatically detected
   - Camera closes automatically

6. **Validation:**
   - ✅ System validates QR code matches project
   - ✅ If valid: Check-in successful
   - ❌ If invalid: Error message shown

7. **Success:**
   - ✅ "QR Check-in Successful" message
   - ✅ Check-in recorded with timestamp
   - ✅ You can now check-out later

### **What Employee Sees:**

```
┌─────────────────────────────────────┐
│  Scan QR Code                       │
│                                     │
│  [CAMERA VIEW]                      │
│                                     │
│  Point camera at QR code            │
│                                     │
│  [Scanning...]                     │
└─────────────────────────────────────┘
```

---

## 🔍 **How QR Code Validation Works**

### **Strict Validation:**

1. **QR Code Must Match Project:**
   - Scanned QR code data must match `project.qrCode`
   - Format: `PROJECT:{projectId}:{projectName}:{timestamp}`
   - ✅ If matches: Check-in allowed
   - ❌ If doesn't match: Error shown

2. **QR Code Expiry:**
   - QR codes are valid for 24 hours from generation
   - After 24 hours, admin should regenerate QR code
   - Old QR codes will be rejected

3. **Project Must Support QR:**
   - Project must have QR code check-in enabled
   - If disabled, QR option won't appear

---

## 🎯 **Complete Example Flow**

### **Admin Side (Web):**

```
1. Admin logs in → Web Dashboard
2. Navigate to: Projects → Add Project
3. Fill project details:
   - Name: "Construction Site A"
   - Location: "123 Main St"
   - Check-in Methods: ✅ QR Code
4. Click "Generate QR Code"
5. QR code appears:
   - Image: [QR CODE]
   - Data: PROJECT:proj_123:Site A:1234567890
6. Click "Copy Code" (copy data)
7. Print QR code image (screenshot or export)
8. Click "Add" to save project
9. Place printed QR code at project site
```

### **Employee Side (Mobile):**

```
1. Employee opens mobile app
2. Login: Company Code + Employee ID + PIN
3. Tap "Check-In" button
4. Select project: "Construction Site A"
5. Tap "QR Code" card
6. Camera opens automatically
7. Point camera at printed QR code
8. QR code detected automatically
9. System validates:
   - Scanned: PROJECT:proj_123:Site A:1234567890
   - Project QR: PROJECT:proj_123:Site A:1234567890
   - ✅ Match! Check-in successful
10. Success message shown
11. Check-in recorded
```

---

## ❓ **Troubleshooting**

### **Issue: Camera doesn't open**

**Solution:**
- Check camera permissions in device settings
- Ensure app has camera access
- Restart app

### **Issue: QR code not detected**

**Solutions:**
- Ensure good lighting
- Hold phone steady
- Move closer to QR code
- Ensure QR code is clear and not damaged
- Try regenerating QR code (may be expired)

### **Issue: "QR code does not match this project"**

**Causes:**
- Wrong QR code scanned (different project)
- QR code expired (>24 hours old)
- QR code regenerated after printing

**Solutions:**
- Scan the correct QR code for this project
- Admin should regenerate QR code
- Print new QR code

### **Issue: QR Code option not showing**

**Causes:**
- Project doesn't have QR code enabled
- QR code not generated yet

**Solutions:**
- Admin must enable QR code in project settings
- Admin must generate QR code
- Refresh project list

---

## 📊 **QR Code Data Format**

### **Structure:**
```
PROJECT:{projectId}:{projectName}:{timestamp}
```

### **Example:**
```
PROJECT:proj_abc123:Construction Site A:1706899200000
```

### **Parts:**
- `PROJECT:` - Prefix (identifies as project QR code)
- `proj_abc123` - Project ID (unique identifier)
- `Construction Site A` - Project name
- `1706899200000` - Timestamp (milliseconds since epoch)

### **Validation:**
- ✅ Must start with "PROJECT:"
- ✅ Must have at least 3 parts (separated by ":")
- ✅ Timestamp must be within 24 hours

---

## ✅ **Quick Reference**

### **For Admin:**
1. ✅ Enable QR Code in project settings
2. ✅ Generate QR code
3. ✅ Print/display QR code at site
4. ✅ Regenerate every 24 hours (if needed)

### **For Employee:**
1. ✅ Select project
2. ✅ Tap "QR Code" check-in method
3. ✅ Point camera at QR code
4. ✅ Wait for automatic detection
5. ✅ Check-in successful!

---

## 🎯 **Summary**

**QR Code Flow:**
1. ✅ **Admin generates** QR code in web dashboard
2. ✅ **Admin prints/displays** QR code at project site
3. ✅ **Employee scans** QR code with mobile app camera
4. ✅ **System validates** QR code matches project
5. ✅ **Check-in recorded** if valid

**The QR scanner camera opens automatically when employee selects QR Code check-in method!** 📱📷
