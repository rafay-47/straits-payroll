# 📚 Documentation Guide - Start Here!

## 🎯 Which Guide Should I Read?

### **I'm starting fresh and want to test everything:**
→ Read: **`QUICK_START_CHECKLIST.md`** ⭐
- 30-minute setup checklist
- Step-by-step with checkboxes
- Perfect for first-time setup

---

### **I don't understand how accounts are created:**
→ Read: **`ACCOUNT_CREATION_GUIDE.md`** 📖
- **Part 1:** How to create admin account (Firebase Console)
- **Part 2:** How admin creates supervisor account (Web Dashboard)
- **Part 3:** How supervisor creates employee account (Mobile App)
- **Part 4:** How everything links together (projectId, supervisorId)
- Shows exact forms, fields, and what happens behind the scenes

---

### **I want to understand the complete system flow:**
→ Read: **`COMPLETE_WORKFLOW_GUIDE.md`**
- Full detailed workflow
- Multiple testing scenarios
- Common issues & solutions
- Reference for everything

---

### **I need visual diagrams of how data flows:**
→ Read: **`SYSTEM_FLOW_DIAGRAM.md`**
- Visual flow diagrams
- Database relationships
- Architecture overview
- Authentication flow

---

### **I want to know how to use the mobile apps:**
→ Read: **`MOBILE_APP_INTERACTION_GUIDE.md`** ⭐
- **Complete guide for Employee & Supervisor mobile apps**
- Step-by-step workflows for all features
- Real-world scenarios with examples
- Troubleshooting tips for mobile apps

---

### **I want to see the complete interaction flow:**
→ Read: **`INTERACTION_FLOW_DIAGRAM.md`**
- Visual flow diagrams for daily work
- How Admin/Supervisor/Employee interact
- Data flow diagrams
- Real-time updates explained

---

### **I'm having login issues on web dashboard:**
→ Read: **`RUN_WEB_APP.md`** (if it exists)
- How to run web app with disabled security
- Firestore security rules setup

---

### **Supervisor can't login or project doesn't show:**
→ Read: **`SUPERVISOR_TROUBLESHOOTING_GUIDE.md`** 🔧
- **Supervisor login issues and fixes**
- Project assignment troubleshooting
- Firestore data verification
- Debug console outputs explained
- Step-by-step fix guide

---

## 📋 Quick Reference

### Account Creation Summary

```
┌─────────────────────────────────────────────────┐
│ ACCOUNT TYPE │ CREATED BY │ CREATED WHERE      │
├──────────────┼────────────┼────────────────────┤
│ Admin        │ Manual     │ Firebase Console   │
│ Supervisor   │ Admin      │ Web Dashboard      │
│ Employee     │ Supervisor │ Mobile App         │
└─────────────────────────────────────────────────┘
```

### Linking Summary

```
Project (xyz123)
    │
    ├─ Supervisor (role: "supervisor")
    │  └─ projectId: xyz123  ◄─── LINKED
    │
    └─ Employees (role: "employee")
       ├─ Employee 1
       │  ├─ projectId: xyz123      ◄─── LINKED TO PROJECT
       │  └─ supervisorId: supUid   ◄─── LINKED TO SUPERVISOR
       │
       └─ Employee 2
          ├─ projectId: xyz123      ◄─── SAME PROJECT
          └─ supervisorId: supUid   ◄─── SAME SUPERVISOR
```

---

## 🚀 Recommended Reading Order

### **For First-Time Setup:**
1. ✅ `QUICK_START_CHECKLIST.md` - Follow the checklist
2. 📖 `ACCOUNT_CREATION_GUIDE.md` - If you get stuck on account creation
3. 🔧 Debug using browser console (F12) during web login

### **For Understanding the System:**
1. 📖 `ACCOUNT_CREATION_GUIDE.md` - Understand account creation
2. 📱 `MOBILE_APP_INTERACTION_GUIDE.md` - Learn mobile app usage
3. 🔄 `INTERACTION_FLOW_DIAGRAM.md` - See complete interaction flows
4. 📊 `SYSTEM_FLOW_DIAGRAM.md` - See visual diagrams
5. 📚 `COMPLETE_WORKFLOW_GUIDE.md` - Read full details

### **For Mobile App Users:**
1. 📱 `MOBILE_APP_INTERACTION_GUIDE.md` - Complete mobile guide
2. 🔄 `INTERACTION_FLOW_DIAGRAM.md` - Visual flows
3. 📖 `ACCOUNT_CREATION_GUIDE.md` - How accounts are created

### **For Troubleshooting:**
1. 🔍 Check browser console (F12) during login
2. 📖 `ACCOUNT_CREATION_GUIDE.md` → Part 1 (for admin issues)
3. 📱 `MOBILE_APP_INTERACTION_GUIDE.md` → Troubleshooting section
4. 📚 `COMPLETE_WORKFLOW_GUIDE.md` → "Common Issues" section

---

## 🎓 Key Concepts Explained

### **What is projectId?**
- A unique ID that identifies a project
- Stored in supervisor and employee documents
- Used to link everyone working on the same project
- **Example:** If projectId = "xyz123", all users with this ID belong to same project

### **What is supervisorId?**
- A unique ID that identifies a supervisor
- Stored in employee documents
- Links employees to their supervisor
- **Example:** If supervisorId = "supAbc", all employees with this ID report to same supervisor

### **What is Employee ID?**
- A 4-digit number auto-generated when supervisor adds employee
- Format: 0001, 0002, 0003, etc.
- Used by employee to login (along with PIN)
- NOT the same as Firebase UID

### **What is PIN?**
- A 4-digit number auto-generated when supervisor adds employee
- Used by employee to login (along with Employee ID)
- Acts like a password for employees

### **Why no Firebase Auth for employees initially?**
- Employees don't need email/password login
- They use Employee ID + PIN instead
- Simpler for workers who may not have email
- Firebase Auth may be created later if needed (for future features)

---

## 📱 App Navigation Quick Reference

### **Web Dashboard (Admin):**
```
Login (admin@company.com) 
  └─> Dashboard
      ├─> Projects (create, edit, view)
      ├─> Employees
      │   ├─> Add Employee (create supervisor)
      │   ├─> Pending Approvals (approve employees)
      │   └─> Active List (view all)
      ├─> Attendance (view all records)
      ├─> Reports (export PDF/CSV)
      └─> Settings
```

### **Mobile App - Supervisor:**
```
Login (email/password)
  └─> Supervisor Dashboard
      ├─> My Project (view assigned project)
      ├─> Add Employee (create employee accounts)
      ├─> Employee List (view team)
      ├─> Attendance (view team attendance)
      └─> Profile
```

### **Mobile App - Employee:**
```
Login (ID/PIN)
  └─> Employee Dashboard
      ├─> Check In (GPS/QR/Geofence)
      ├─> Check Out
      ├─> Attendance History
      ├─> Work Hours
      ├─> Documents
      └─> Profile
```

---

## 🎯 Most Common Questions

### **Q: How do I create the first supervisor account?**
**A:** Read `ACCOUNT_CREATION_GUIDE.md` → Part 2
- Admin logs into web dashboard
- Goes to Employees → Add Employee
- Fills form and selects "Supervisor" as role
- Assigns to a project
- System creates both Auth account and Firestore document

### **Q: How does employee get their ID and PIN?**
**A:** Read `ACCOUNT_CREATION_GUIDE.md` → Part 3
- Supervisor adds employee in mobile app
- System auto-generates ID (0001) and PIN (1234)
- Supervisor sees these credentials in success dialog
- Supervisor shares with employee

### **Q: Why can't employee login after supervisor creates account?**
**A:** Employee needs admin approval first!
- Supervisor creates employee → Status: "pending"
- Admin must approve in web dashboard
- After approval → Status: "approved"
- Then employee can login

### **Q: How is employee linked to a project?**
**A:** Read `ACCOUNT_CREATION_GUIDE.md` → Part 4
- Supervisor is linked to project (has projectId in their document)
- When supervisor adds employee, system automatically:
  - Copies supervisor's projectId to employee document
  - Employee is now linked to same project
  - No need for employee to select project

### **Q: Can I have multiple supervisors on one project?**
**A:** Yes!
- Admin can assign multiple supervisors to same project
- All will have same projectId
- Each can add their own employees
- All employees will have same projectId

### **Q: Where is the "Add Employee" button in web dashboard?**
**A:** 
- Login to web dashboard
- Click "Employees" in left sidebar
- Top right corner: "+ Add Employee" button
- This is used to create SUPERVISOR accounts
- (Employees are created by supervisors in mobile app)

---

## 🆘 Getting Help

### **If admin can't login to web dashboard:**
1. Check browser console (F12) - detailed debug logs added
2. Verify admin user exists in Firestore with role: "admin"
3. See `ACCOUNT_CREATION_GUIDE.md` → Part 1

### **If supervisor can't add employees:**
1. Verify supervisor is assigned to a project
2. Check Firestore: supervisor document has projectId field
3. See `ACCOUNT_CREATION_GUIDE.md` → Part 2

### **If employee can't login:**
1. Verify employee status is "approved" in Firestore
2. Check ID format: must be 4 digits (0001 not 1)
3. Check PIN is correct (case-sensitive)
4. See `ACCOUNT_CREATION_GUIDE.md` → Part 3

---

## ✨ Success Indicators

You know everything is working when:

✅ **Admin:** Can create projects and supervisors  
✅ **Supervisor:** Can add employees and see auto-generated IDs  
✅ **Employee:** Can login with ID/PIN and check in/out  
✅ **Linking:** All users in same project see same data  

---

## 📖 All Available Guides

| File Name | Purpose | When to Read |
|-----------|---------|--------------|
| `README_GUIDES.md` | Guide to all guides (this file) | Start here |
| `QUICK_START_CHECKLIST.md` | 30-min setup checklist | First-time setup |
| `ACCOUNT_CREATION_GUIDE.md` | How to create all account types | Don't understand account creation |
| `MOBILE_APP_INTERACTION_GUIDE.md` | Mobile app usage guide | Want to use Employee/Supervisor apps |
| `INTERACTION_FLOW_DIAGRAM.md` | Visual interaction flows | Want to see how everything connects |
| `SUPERVISOR_TROUBLESHOOTING_GUIDE.md` | Supervisor login & project issues | Supervisor can't login or see project |
| `COMPLETE_WORKFLOW_GUIDE.md` | Full system workflow | Want complete reference |
| `SYSTEM_FLOW_DIAGRAM.md` | Visual diagrams | Want to see architecture |
| `RUN_WEB_APP.md` | Web app setup | Web security issues |

---

**Ready to start?** → Open `QUICK_START_CHECKLIST.md` and begin! 🚀

