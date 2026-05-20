# 🧪 Simple Client Testing Guide

## What is This App?

This is an **Employee Attendance System** that works on:
- **Web Browser** (for admins)
- **Mobile Phone** (for supervisors and employees)

---

## 🎯 How to Test - Simple Steps

### **Step 1: Open the App**

#### For Web (Admin Dashboard):
1. Open your web browser (Chrome, Safari, etc.)
2. Go to the app URL (your developer will provide this)
3. You'll see a login screen

#### For Mobile (Supervisor/Employee):
1. Install the app on your phone (your developer will provide the app file)
2. Open the app
3. You'll see a screen asking: "Are you an Employee or Supervisor?"

---

## 👥 Who Can Test What?

### **1. Super Admin** (You - Company Owner)
**Platform:** Web Browser

**What You Can Do:**
- Create companies (e.g., "ABC Construction", "XYZ Builders")
- See all companies in one place
- Manage company settings

**How to Test:**
1. Login with: `superadmin@yourcompany.com` / `SuperAdmin123!`
2. Click "Create Company"
3. Fill in company name and code (e.g., "ABC")
4. Click "Save"
5. ✅ **Success!** Company appears in your list

---

### **2. Company Admin** (Manager)
**Platform:** Web Browser

**What You Can Do:**
- Approve employees created by supervisors
- Create projects (work sites)
- View reports and attendance data
- Manage company settings

**How to Test:**
1. Login with: Company Code (e.g., "ABC") + Email + Password
2. See dashboard showing your company's data
3. Click "Approve Employees" → See pending employees → Click "Approve"
4. Click "Manage Projects" → Create a new project
5. ✅ **Success!** You can only see YOUR company's data (not other companies)

---

### **3. Supervisor** (Site Manager)
**Platform:** Mobile Phone

**What You Can Do:**
- Add new employees
- Upload employee documents
- Do manual check-ins for employees
- View employee list

**How to Test:**
1. Open mobile app
2. Select "Supervisor"
3. Login with: Company Code (e.g., "ABC") + Email + Password
4. Tap "Add Employee"
5. Fill in: Name, Email, Phone
6. Tap "Submit"
7. ✅ **Success!** Employee gets ID like "ABC-0001" automatically
8. Employee status is "Pending" (needs admin approval)

---

### **4. Employee** (Worker)
**Platform:** Mobile Phone

**What You Can Do:**
- Check in when arriving at work site
- Check out when leaving
- See your attendance history
- View assigned projects

**How to Test:**
1. Open mobile app
2. Select "Employee"
3. Login with: Company Code (e.g., "ABC") + Employee ID (e.g., "0001")
4. **First Login:** Your phone is automatically registered (device binding)
5. See dashboard with your name and projects
6. Tap "Check In"
7. Select a project
8. Choose check-in method (GPS or Manual)
9. ✅ **Success!** You're checked in
10. After work, tap "Check Out"
11. ✅ **Success!** Working hours are calculated automatically

---

## 🔄 Complete Testing Flow

### **Day 1: Setup**

1. **Super Admin creates company:**
   - Login → Create "ABC Construction" (Code: ABC)
   - ✅ Company created

2. **Create Company Admin:**
   - Developer creates admin account: `admin@abc.com`
   - Login with: ABC + admin@abc.com
   - ✅ Can see ABC company dashboard

3. **Create Supervisor:**
   - Developer creates supervisor: `supervisor@abc.com`
   - Login on mobile: ABC + supervisor@abc.com
   - ✅ Can see supervisor dashboard

4. **Supervisor adds employees:**
   - Tap "Add Employee"
   - Add: "John Worker"
   - ✅ Gets ID: ABC-0001
   - Add: "Jane Builder"
   - ✅ Gets ID: ABC-0002

5. **Admin approves employees:**
   - Login on web as admin
   - Go to "Approve Employees"
   - See John (ABC-0001) and Jane (ABC-0002) pending
   - Click "Approve" for both
   - ✅ Employees can now login

### **Day 2: Test Attendance**

6. **Employee checks in:**
   - John opens mobile app
   - Login: ABC + 0001
   - Tap "Check In"
   - Select project
   - ✅ Checked in successfully

7. **Employee checks out:**
   - After some time, John taps "Check Out"
   - ✅ Working hours calculated (e.g., 2.5 hours)

8. **Admin views report:**
   - Admin logs in on web
   - Go to "Reports"
   - See John's check-in/out record
   - Export as PDF or CSV
   - ✅ Report downloaded

---

## ✅ What to Check (Testing Checklist)

### **Login Tests:**
- [ ] Super Admin can login
- [ ] Company Admin can login (with company code)
- [ ] Supervisor can login (mobile, with company code)
- [ ] Employee can login (mobile, with company code + ID)

### **Data Isolation Tests:**
- [ ] ABC Admin cannot see XYZ company data
- [ ] ABC Employee cannot see XYZ projects
- [ ] Super Admin can see all companies

### **Employee Flow Tests:**
- [ ] Supervisor can add employee
- [ ] Employee gets auto-generated ID (ABC-0001, ABC-0002...)
- [ ] Admin can approve employee
- [ ] Employee can login after approval
- [ ] Employee's phone is registered on first login

### **Check-In Tests:**
- [ ] Employee can check in (GPS method)
- [ ] Employee can check in (Manual method)
- [ ] Check-in saves location and time
- [ ] Employee can check out
- [ ] Working hours calculated correctly

### **Dashboard Tests:**
- [ ] Admin sees correct statistics
- [ ] Supervisor sees employee list
- [ ] Employee sees assigned projects
- [ ] Data updates in real-time

---

## 🐛 Common Issues & Solutions

### **"Cannot Login"**
- Check: Email/Password correct?
- Check: Company code correct?
- Check: Employee approved by admin?

### **"No Projects Showing"**
- Check: Projects created by admin?
- Check: Employee assigned to project?

### **"Check-In Failed - Too Far"**
- Check: GPS location enabled?
- Check: Project radius large enough?
- Solution: Use "Manual" check-in method

### **"Cannot See Employee"**
- Check: Employee approved by admin?
- Check: Using correct company code?

---

## 📱 Testing on Different Devices

### **Web Browser:**
- Chrome (recommended)
- Safari
- Firefox
- Edge

### **Mobile:**
- iPhone (iOS 14+)
- Android Phone (Android 8+)
- Tablet (iPad/Android Tablet)

---

## 🎯 Success Criteria

**Everything works when:**

✅ You can login as all roles (Super Admin, Admin, Supervisor, Employee)  
✅ Companies are isolated (ABC cannot see XYZ data)  
✅ Employees get auto-generated IDs (ABC-0001, ABC-0002...)  
✅ Check-in/out works correctly  
✅ Working hours calculated automatically  
✅ Reports can be exported  
✅ Data appears in real-time  

---

## 📞 Need Help?

If something doesn't work:

1. **Check your login credentials** (email, password, company code)
2. **Check if employee is approved** (must be approved by admin)
3. **Check internet connection**
4. **Contact your developer** with:
   - What you were trying to do
   - What error message you saw
   - Screenshot if possible

---

## 🎉 You're Ready!

Follow these steps to test the app. Start with:
1. Super Admin → Create company
2. Admin → Approve employees
3. Supervisor → Add employees
4. Employee → Check in/out

**Happy Testing!** 🚀



