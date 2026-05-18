# Testing Guide - Straights Psyroll App

## Overview
This guide provides comprehensive testing procedures for all features of the Straights Psyroll application across mobile (Employee & Supervisor) and web (Admin) platforms.

---

## Prerequisites

### Test Environment Setup
1. **Firebase Project**: Ensure Firebase is properly configured
2. **Test Accounts**: Create test users for each role
3. **Test Data**: Populate with sample projects, employees, and attendance records

### Test User Accounts

#### Employee Test Accounts
```
Employee 1:
- System ID: 0001
- PIN: 123456
- Name: John Doe
- Role: Employee

Employee 2:
- System ID: 0002
- PIN: 123456
- Name: Jane Smith
- Role: Employee
```

#### Supervisor Test Account
```
Supervisor:
- Email: supervisor@test.com
- Password: Test@123
- Name: Mike Johnson
- Role: Supervisor
```

#### Admin Test Account
```
Admin:
- Email: admin@test.com
- Password: Admin@123
- Name: Admin User
- Role: Admin
```

---

## 1. Authentication & Authorization Testing

### 1.1 Employee Login (Mobile)
- [ ] **Valid ID/PIN Login**
  - Launch app → Role Selection → Employee
  - Enter valid system ID (e.g., 0001)
  - Enter valid 6-digit PIN (123456)
  - Verify successful login to dashboard
  
- [ ] **Invalid Credentials**
  - Enter invalid ID → Verify error message
  - Enter invalid PIN → Verify error message
  - Enter wrong PIN format → Verify validation

- [ ] **Device Binding**
  - First login on new device → Verify device info captured
  - Second login attempt on different device → Verify rejection
  - Check device binding status in profile

- [ ] **Biometric Setup**
  - After first login, enable biometric
  - Logout and verify biometric login works
  - Test Face ID/Touch ID/Fingerprint

### 1.2 Supervisor Login (Mobile)
- [ ] **Valid Email/Password Login**
  - Launch app → Role Selection → Supervisor
  - Enter valid email and password
  - Verify successful login to supervisor dashboard

- [ ] **Invalid Credentials**
  - Enter invalid email format → Verify validation
  - Enter wrong password → Verify error message
  - Test password visibility toggle

- [ ] **Biometric Setup**
  - Enable biometric after first login
  - Test biometric login on subsequent attempts

### 1.3 Admin Login (Web)
- [ ] **Valid Email/Password Login**
  - Navigate to web app URL
  - Enter admin credentials
  - Verify successful login to admin dashboard

- [ ] **Role Verification**
  - Attempt login with non-admin account
  - Verify rejection with appropriate error

---

## 2. Employee Features Testing (Mobile)

### 2.1 Employee Dashboard
- [ ] **Dashboard Display**
  - Verify user name and ID displayed correctly
  - Check assigned projects list
  - Verify today's attendance status
  - Check total working hours

- [ ] **Quick Actions**
  - Test "Check In" button navigation
  - Test "Attendance" button (coming soon message)
  - Test "Device Reset" button navigation

- [ ] **Project Cards**
  - Verify all assigned projects displayed
  - Check project name, location, status
  - Test tap on project card

### 2.2 Check-In/Check-Out
- [ ] **GPS Check-In**
  - Navigate to Check-In screen
  - Select project with GPS enabled
  - Verify location permission request
  - Test check-in within radius → Success
  - Test check-in outside radius → Failure
  - Verify location captured and displayed

- [ ] **NFC Check-In**
  - Select project with NFC enabled
  - Tap NFC tag
  - Verify successful check-in
  - Check NFC tag ID captured

- [ ] **QR Code Check-In**
  - Select project with QR enabled
  - Scan valid QR code
  - Verify successful check-in
  - Test invalid QR code → Verify error

- [ ] **Check-Out**
  - After successful check-in
  - Verify "Check Out" button appears
  - Perform check-out
  - Verify working hours calculated
  - Check attendance record created

- [ ] **Check-In Limits**
  - Perform 2 check-ins for same project (limit)
  - Attempt 3rd check-in → Verify rejection
  - Test check-in to multiple projects

- [ ] **Real-Time Updates**
  - After check-in, verify dashboard updates immediately
  - Check "Today's Status" reflects new check-in
  - Verify working hours updated

### 2.3 Device Reset Request
- [ ] **View Current Device**
  - Open Device Reset screen
  - Verify current device info displayed
  - Check model, OS, registration date

- [ ] **View Reset History**
  - Verify previous requests shown
  - Check status indicators (pending/approved/rejected)

- [ ] **Submit Request**
  - Enter reason (less than 10 chars) → Verify validation
  - Enter valid reason
  - Submit request
  - Verify success message
  - Check request appears in history

- [ ] **Monthly Limit**
  - Submit request
  - Attempt to submit another request same month
  - Verify limit reached message

---

## 3. Supervisor Features Testing (Mobile)

### 3.1 Supervisor Dashboard
- [ ] **Dashboard Display**
  - Verify supervisor name displayed
  - Check statistics (total employees, active projects)
  - Verify quick actions available

- [ ] **Quick Actions**
  - Test all 5 quick action buttons:
    1. Add Employee
    2. My Employees
    3. Upload Document
    4. Manual Check-In
    5. Device Reset Approvals

### 3.2 Employee Management
- [ ] **Add New Employee**
  - Open Add Employee screen
  - Fill in all required fields (name, email, phone)
  - Verify system-generated ID auto-created
  - Test PIN generation (auto or manual)
  - Assign to projects
  - Submit and verify employee created
  - Check status is "pending"

- [ ] **View Employee List**
  - Open Employee List screen
  - Verify all employees displayed
  - Check employee cards show correct info
  - Test search functionality
  - Test filter by status

- [ ] **Employee Details**
  - Tap on employee card
  - Verify all details displayed
  - Check assigned projects
  - View attendance history
  - Access documents

### 3.3 Document Management
- [ ] **Upload Document**
  - Open Upload Document screen
  - Select employee
  - Choose document type
  - Upload from camera → Verify capture works
  - Upload from gallery → Verify file picker works
  - Enter description
  - Submit and verify upload progress
  - Check document saved

- [ ] **View Documents**
  - Open employee documents screen
  - Verify all documents listed
  - Check document type icons
  - Test view document (opens URL)
  - Test delete document with confirmation

### 3.4 Manual Check-In
- [ ] **Manual Check-In Process**
  - Open Manual Check-In screen
  - Select employee
  - Select project
  - Choose check-in method
  - Capture location (if GPS)
  - Add notes
  - Submit and verify check-in created

### 3.5 Device Reset Approvals
- [ ] **View Requests**
  - Open Device Reset Approvals screen
  - Verify all requests displayed
  - Test filter by status (all/pending/approved/rejected)
  - Check request cards show complete info

- [ ] **Approve Request**
  - Select pending request
  - Tap Approve button
  - Confirm in dialog
  - Verify approval success
  - Check employee's device binding cleared
  - Verify request status updated

- [ ] **Reject Request**
  - Select pending request
  - Tap Reject button
  - Enter rejection reason
  - Confirm rejection
  - Verify request status updated
  - Check reason saved

---

## 4. Admin Features Testing (Web)

### 4.1 Admin Dashboard
- [ ] **Dashboard Display**
  - Verify statistics cards (employees, projects, attendance)
  - Check quick action cards functional
  - Verify recent activity section

- [ ] **Quick Actions**
  - Test all quick action cards:
    1. Manage Projects
    2. Approve Employees
    3. Manage Documents
    4. View Reports
    5. Device Requests
    6. System Settings

### 4.2 Project Management
- [ ] **View Projects**
  - Open Project Management screen
  - Verify data table displays all projects
  - Check column headers and data
  - Test sorting by columns

- [ ] **Create Project**
  - Click "Create Project" button
  - Fill in project details:
    - Name, description
    - Location (address, coordinates)
    - Check-in radius
    - Check-in methods
  - Save and verify project created

- [ ] **Edit Project**
  - Click edit icon on project row
  - Modify project details
  - Save changes
  - Verify updates reflected

- [ ] **Assign Employees**
  - Click assign icon
  - Select employees from list
  - Assign to project
  - Verify assignments saved
  - Check employees can see project on mobile

- [ ] **Toggle Project Status**
  - Click activate/deactivate button
  - Verify status changes
  - Check inactive projects not available for check-in

### 4.3 Employee Approval
- [ ] **View Pending Employees**
  - Open Employee Approval screen
  - Verify pending employees displayed
  - Check employee details shown

- [ ] **Approve Employee**
  - Select pending employee
  - Enter custom ID (optional)
  - Approve
  - Verify employee status changed to "approved"
  - Check employee can now login

- [ ] **Reject Employee**
  - Select pending employee
  - Click Reject
  - Enter rejection reason
  - Confirm rejection
  - Verify employee status updated

### 4.4 Document Management
- [ ] **View All Documents**
  - Open Document Management screen
  - Verify data table shows all documents
  - Check search functionality
  - Test filter by type and status

- [ ] **Approve Document**
  - Select pending document
  - Click Approve
  - Verify status updated

- [ ] **Reject Document**
  - Select pending document
  - Click Reject
  - Enter reason
  - Verify rejection recorded

- [ ] **Download Document**
  - Click download icon
  - Verify file downloads correctly

- [ ] **Delete Document**
  - Click delete icon
  - Confirm deletion
  - Verify document removed

### 4.5 Reports & Export
- [ ] **Attendance Report**
  - Select date range
  - Generate report
  - Verify data displayed correctly
  - Export as PDF → Check PDF format
  - Export as CSV → Check CSV format
  - Verify data accuracy

- [ ] **Project Report**
  - Select project(s)
  - Generate report
  - Check project statistics
  - Export and verify formats

- [ ] **Employee Report**
  - Select employee(s)
  - Generate report
  - Check employee attendance data
  - Export and verify formats

### 4.6 Device Reset Management
- [ ] **View All Requests**
  - Open Device Reset Management screen
  - Verify data table shows all requests
  - Test search by name/ID
  - Test filter by status

- [ ] **Approve Request**
  - Select pending request
  - View details in modal
  - Approve request
  - Verify device binding cleared
  - Check audit trail

- [ ] **Reject Request**
  - Select pending request
  - Reject with reason
  - Verify rejection recorded

### 4.7 System Settings
- [ ] **View Settings**
  - Open System Settings screen
  - Verify all settings displayed

- [ ] **Update Settings**
  - Modify settings:
    - Max check-ins per day
    - Max device resets per month
    - Check-in radius
  - Save changes
  - Verify updates applied

- [ ] **View Audit Logs**
  - Check audit log table
  - Verify actions logged
  - Test date range filter

---

## 5. Cross-Platform Integration Testing

### 5.1 Data Synchronization
- [ ] **Real-Time Updates**
  - Employee checks in on mobile
  - Verify update appears on supervisor mobile
  - Verify update appears on admin web dashboard
  - Check delay (should be < 2 seconds)

- [ ] **Project Assignment**
  - Admin assigns project to employee on web
  - Verify project appears in employee mobile dashboard
  - Check notification (if implemented)

- [ ] **Device Reset Workflow**
  - Employee submits request on mobile
  - Supervisor sees request on mobile
  - Admin sees request on web
  - Admin approves on web
  - Verify employee device cleared immediately

### 5.2 Document Flow
- [ ] **Upload & Approval**
  - Supervisor uploads document on mobile
  - Admin sees document on web
  - Admin approves document on web
  - Verify status updates on mobile

---

## 6. Performance Testing

### 6.1 Load Testing
- [ ] **Large Data Sets**
  - Test with 100+ employees
  - Test with 50+ projects
  - Test with 1000+ attendance records
  - Verify no performance degradation

### 6.2 Response Times
- [ ] **Login**: < 2 seconds
- [ ] **Dashboard Load**: < 3 seconds
- [ ] **Check-In**: < 2 seconds
- [ ] **Report Generation**: < 5 seconds for 1 month data
- [ ] **Document Upload**: Based on file size

### 6.3 Memory & Battery
- [ ] **Mobile App**
  - Monitor memory usage over 8-hour period
  - Check battery drain with location services
  - Test with background location off

---

## 7. Security Testing

### 7.1 Authentication
- [ ] **Session Management**
  - Verify session expires after inactivity
  - Test logout functionality
  - Check token refresh

- [ ] **Device Binding**
  - Test device change detection
  - Verify unauthorized device rejection
  - Test device reset process

### 7.2 Authorization
- [ ] **Role-Based Access**
  - Employee cannot access supervisor features
  - Supervisor cannot access admin features
  - Verify API-level authorization

### 7.3 Data Security
- [ ] **Sensitive Data**
  - Verify PINs stored securely
  - Check biometric data handling
  - Verify HTTPS for all API calls

---

## 8. Error Handling Testing

### 8.1 Network Errors
- [ ] **No Internet**
  - Disable network
  - Attempt various operations
  - Verify graceful error messages
  - Test retry mechanisms

- [ ] **Poor Connection**
  - Simulate slow network
  - Test timeout handling
  - Verify loading states

### 8.2 Invalid Input
- [ ] **Form Validation**
  - Test all forms with:
    - Empty required fields
    - Invalid formats (email, phone)
    - Min/max length violations
  - Verify error messages clear

### 8.3 Edge Cases
- [ ] **Simultaneous Actions**
  - Multiple employees check-in to same project
  - Concurrent device reset requests
  - Verify data consistency

---

## 9. UI/UX Testing

### 9.1 Responsiveness (Web)
- [ ] Test on various screen sizes:
  - Desktop (1920x1080)
  - Laptop (1366x768)
  - Tablet landscape (1024x768)
  - Tablet portrait (768x1024)

### 9.2 Mobile Device Compatibility
- [ ] **iOS**
  - iPhone SE (small screen)
  - iPhone 13/14 (standard)
  - iPhone 14 Pro Max (large)
  - iPad

- [ ] **Android**
  - Small phone (5" screen)
  - Standard phone (6")
  - Large phone (6.5"+)
  - Tablet

### 9.3 Accessibility
- [ ] **Font Sizes**: Test with system font scaling
- [ ] **Color Contrast**: Verify readability
- [ ] **Touch Targets**: Minimum 44x44 points
- [ ] **Screen Reader**: Test with TalkBack/VoiceOver (if time permits)

---

## 10. Regression Testing

After any bug fixes or feature additions, re-test:
- [ ] Core login flows (all roles)
- [ ] Check-in/check-out process
- [ ] Device reset workflow
- [ ] Document upload/view
- [ ] Report generation
- [ ] Data synchronization

---

## Bug Reporting Template

When issues are found, document using this format:

```
**Bug ID**: BUG-001
**Severity**: Critical / High / Medium / Low
**Module**: Employee Login / Check-In / etc.
**Platform**: Mobile iOS / Mobile Android / Web

**Steps to Reproduce**:
1. Step 1
2. Step 2
3. Step 3

**Expected Result**:
What should happen

**Actual Result**:
What actually happened

**Screenshots/Logs**:
[Attach if available]

**Device/Browser**:
iOS 17 / Android 13 / Chrome 120

**Additional Notes**:
Any other relevant information
```

---

## Test Results Summary Template

```
## Test Execution Summary
**Date**: [Date]
**Tester**: [Name]
**Build Version**: [Version]

### Results
- Total Test Cases: XX
- Passed: XX
- Failed: XX
- Blocked: XX
- Not Executed: XX

### Pass Rate: XX%

### Critical Issues Found: X
### High Priority Issues: X
### Medium Priority Issues: X
### Low Priority Issues: X

### Recommendations:
[List recommendations for release readiness]
```

---

## Conclusion

This testing guide covers all major features and scenarios. For production release:

1. ✅ Complete all test cases
2. ✅ Fix all critical and high-priority bugs
3. ✅ Document known issues (medium/low priority)
4. ✅ Get stakeholder sign-off
5. ✅ Prepare release notes

**Target Pass Rate for Production**: 95%+
