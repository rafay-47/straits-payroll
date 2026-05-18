/// Application string constants
class AppStrings {
  AppStrings._(); // Private constructor

  // App Info
  static const String appName = 'Employee Management';
  static const String appTagline = 'Smart Attendance Tracking';

  // Roles
  static const String roleEmployee = 'employee';
  static const String roleSupervisor = 'supervisor';
  static const String roleAdmin = 'admin';

  // Role Display Names
  static const String roleEmployeeDisplay = 'Employee';
  static const String roleSupervisorDisplay = 'Supervisor';
  static const String roleAdminDisplay = 'Admin';

  // Auth Screens
  static const String welcomeBack = 'Welcome Back';
  static const String selectYourRole = 'Select Your Role';
  static const String employeeLogin = 'Employee Login';
  static const String supervisorLogin = 'Supervisor Login';
  static const String adminLogin = 'Admin Login';
  static const String enterEmployeeId = 'Enter Employee ID';
  static const String enterEmail = 'Enter Email Address';
  static const String enterPassword = 'Enter Password';
  static const String enterPin = 'Enter PIN';
  static const String forgotPassword = 'Forgot Password?';
  static const String loginButton = 'Login';
  static const String logoutButton = 'Logout';

  // First-Time Setup
  static const String firstTimeSetup = 'First-Time Setup';
  static const String deviceBinding = 'Device Binding';
  static const String deviceBindingDesc = 'Your device will be registered for security';
  static const String createPin = 'Create PIN';
  static const String createPinDesc = 'Create a 6-digit PIN for quick login';
  static const String confirmPin = 'Confirm PIN';
  static const String confirmPinDesc = 'Re-enter your PIN to confirm';
  static const String enableBiometric = 'Enable Biometric?';
  static const String enableBiometricDesc = 'Use Face ID/Fingerprint for faster login';
  static const String setupComplete = 'Setup Complete!';
  static const String setupCompleteDesc = 'Your account is now secured';

  // Dashboard
  static const String dashboard = 'Dashboard';
  static const String employeeDashboard = 'Employee Dashboard';
  static const String supervisorDashboard = 'Supervisor Dashboard';
  static const String adminDashboard = 'Admin Dashboard';
  static const String todayStatus = 'Today\'s Status';
  static const String checkedIn = 'Checked In';
  static const String notCheckedIn = 'Not Checked In';
  static const String workingHours = 'Working Hours';
  static const String assignedProjects = 'Assigned Projects';
  static const String myEmployees = 'My Employees';
  static const String quickActions = 'Quick Actions';

  // Check-In
  static const String checkIn = 'Check In';
  static const String checkOut = 'Check Out';
  static const String selectProject = 'Select Project';
  static const String selectCheckInMethod = 'Select Check-In Method';
  static const String gpsCheckIn = 'GPS Check-In';
  static const String nfcCheckIn = 'NFC Check-In';
  static const String qrCheckIn = 'QR Code Check-In';
  static const String manualCheckIn = 'Manual Check-In';
  static const String verifyLocation = 'Verify your location';
  static const String tapNfcTag = 'Tap your device on NFC tag';
  static const String scanQrCode = 'Scan QR code at site';
  static const String withinRange = 'Within range';
  static const String tooFar = 'Too far from site';
  static const String checkInSuccess = 'Check-In Successful!';
  static const String checkOutSuccess = 'Check-Out Successful!';

  // Attendance
  static const String attendance = 'Attendance';
  static const String attendanceHistory = 'Attendance History';
  static const String recentAttendance = 'Recent Attendance';
  static const String totalHours = 'Total Hours';
  static const String averageHours = 'Average Hours/Day';
  static const String checkInTime = 'Check-In Time';
  static const String checkOutTime = 'Check-Out Time';
  static const String duration = 'Duration';
  static const String location = 'Location';
  static const String method = 'Method';

  // Projects
  static const String projects = 'Projects';
  static const String projectDetails = 'Project Details';
  static const String createProject = 'Create Project';
  static const String editProject = 'Edit Project';
  static const String projectName = 'Project Name';
  static const String projectDescription = 'Description';
  static const String projectLocation = 'Location';
  static const String checkInMethods = 'Check-In Methods';
  static const String checkInMethodGPS = 'GPS Location';
  static const String checkInMethodNFC = 'NFC Tag';
  static const String checkInMethodQR = 'QR Code';
  static const String checkInMethodManual = 'Manual';
  static const String activeProjects = 'Active Projects';

  // Employees
  static const String employees = 'Employees';
  static const String addEmployee = 'Add Employee';
  static const String editEmployee = 'Edit Employee';
  static const String employeeDetails = 'Employee Details';
  static const String pendingEmployees = 'Pending Employees';
  static const String allEmployees = 'All Employees';
  static const String employeeName = 'Employee Name';
  static const String employeeId = 'Employee ID';
  static const String customId = 'Custom ID';
  static const String assignToProject = 'Assign to Project';

  // Documents
  static const String documents = 'Documents';
  static const String uploadDocument = 'Upload Document';
  static const String idProof = 'ID Proof';
  static const String bankStatement = 'Bank Statement';
  static const String contract = 'Employment Contract';
  static const String otherDocument = 'Other Document';
  static const String selectDocumentType = 'Select Document Type';
  static const String takePhoto = 'Take Photo';
  static const String chooseFile = 'Choose File';

  // Device Reset
  static const String deviceReset = 'Device Reset';
  static const String requestDeviceReset = 'Request Device Reset';
  static const String deviceResetRequests = 'Device Reset Requests';
  static const String resetReason = 'Reset Reason';
  static const String lostStolen = 'Lost/stolen phone';
  static const String upgraded = 'Upgraded to new phone';
  static const String damaged = 'Phone damaged';
  static const String other = 'Other';

  // Reports
  static const String reports = 'Reports';
  static const String generateReport = 'Generate Report';
  static const String exportPdf = 'Export PDF';
  static const String exportCsv = 'Export CSV';
  static const String selectDateRange = 'Select Date Range';
  static const String dailyReport = 'Daily Report';
  static const String weeklyReport = 'Weekly Report';
  static const String monthlyReport = 'Monthly Report';

  // Settings
  static const String settings = 'Settings';
  static const String systemSettings = 'System Settings';
  static const String companySettings = 'Company Settings';
  static const String checkInRules = 'Check-In Rules';
  static const String maxCheckInsPerDay = 'Max Check-Ins Per Day';
  static const String maxResetsPerMonth = 'Max Device Resets Per Month';

  // Audit Logs
  static const String auditLogs = 'Audit Logs';
  static const String viewAuditLogs = 'View Audit Logs';

  // Status
  static const String pending = 'Pending';
  static const String approved = 'Approved';
  static const String rejected = 'Rejected';
  static const String active = 'Active';
  static const String suspended = 'Suspended';

  // Actions
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String view = 'View';
  static const String approve = 'Approve';
  static const String reject = 'Reject';
  static const String submit = 'Submit';
  static const String retry = 'Retry';
  static const String refresh = 'Refresh';
  static const String close = 'Close';
  static const String back = 'Back';
  static const String next = 'Next';
  static const String skip = 'Skip';
  static const String done = 'Done';

  // Messages
  static const String loading = 'Loading...';
  static const String success = 'Success!';
  static const String error = 'Error';
  static const String noData = 'No data available';
  static const String noProjects = 'No projects assigned';
  static const String noEmployees = 'No employees found';
  static const String noAttendance = 'No attendance records';
  static const String confirmAction = 'Are you sure?';
  static const String cannotUndo = 'This action cannot be undone';

  // Validation
  static const String requiredField = 'This field is required';
  static const String invalidEmail = 'Invalid email address';
  static const String invalidPhone = 'Invalid phone number';
  static const String passwordTooShort = 'Password too short';
  static const String pinMismatch = 'PINs do not match';
  static const String invalidId = 'Invalid employee ID';

  // Errors
  static const String authenticationFailed = 'Authentication failed';
  static const String deviceMismatch = 'Unauthorized device';
  static const String notAssignedToProject = 'Not assigned to this project';
  static const String alreadyCheckedIn = 'Already checked in elsewhere';
  static const String maxCheckInsReached = 'Maximum check-ins reached';
  static const String locationPermissionDenied = 'Location permission denied';
  static const String nfcNotSupported = 'NFC not supported';
  static const String qrScanFailed = 'QR scan failed';
  static const String networkError = 'Network error';
  static const String unknownError = 'An unknown error occurred';
}

