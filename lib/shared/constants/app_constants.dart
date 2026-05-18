/// Application configuration constants
class AppConstants {
  AppConstants._(); // Private constructor

  // ============================================
  // FIREBASE COLLECTION NAMES
  // ============================================
  static const String usersCollection = 'users';
  static const String projectsCollection = 'projects';
  static const String employersCollection = 'employers';
  static const String auditLogsCollection = 'auditLogs';
  static const String systemSettingsCollection = 'systemSettings';

  // Subcollections
  static const String attendanceSubcollection = 'attendance';
  static const String documentsSubcollection = 'documents';
  static const String deviceResetRequestsSubcollection = 'deviceResetRequests';
  static const String assignedEmployeesSubcollection = 'assignedEmployees';
  static const String supervisorsSubcollection = 'supervisors';

  // ============================================
  // CHECK-IN CONFIGURATION
  // ============================================
  static const int defaultMaxCheckInsPerDay = 2;
  static const int defaultMaxCheckOutsPerDay = 2;
  static const double defaultProjectRadiusMeters = 200.0;
  static const bool defaultRequireCheckOutBeforeNewCheckIn = true;

  // Check-in methods
  static const String checkInMethodGPS = 'gps';
  static const String checkInMethodNFC = 'nfc';
  static const String checkInMethodQR = 'qr';
  static const String checkInMethodManual = 'manual';
  static const String checkInMethodMulti = 'multi';
  static const String checkInRequirementAnyOne = 'any_one';
  static const String checkInRequirementAllEnabled = 'all_enabled';

  // Attendance status
  static const String attendanceStatusCheckedIn = 'checked_in';
  static const String attendanceStatusCheckedOut = 'checked_out';

  // Attendance configuration
  static const int maxCheckInsPerDay = 2;
  static const int maxCheckOutsPerDay = 2;
  static const double defaultCheckInRadiusMeters = 200.0;

  // ============================================
  // DEVICE MANAGEMENT
  // ============================================
  static const int defaultMaxDeviceResetsPerMonth = 1;
  static const int maxDeviceResetsPerMonth = 1; // Alias for backward compatibility
  static const int pinLength = 6;

  // ============================================
  // USER ROLES
  // ============================================
  static const String roleEmployee = 'employee';
  static const String roleSupervisor = 'supervisor';
  static const String roleAdmin = 'admin';

  // User status
  static const String statusPending = 'pending';
  static const String statusApproved = 'approved';
  static const String statusActive = 'active';
  static const String statusSuspended = 'suspended';

  // ============================================
  // DOCUMENT TYPES
  // ============================================
  static const String documentTypeIdProof = 'id_proof';
  static const String documentTypeBankStatement = 'bank_statement';
  static const String documentTypeContract = 'contract';
  static const String documentTypeOther = 'other';

  // Document status
  static const String documentStatusPending = 'pending';
  static const String documentStatusApproved = 'approved';
  static const String documentStatusRejected = 'rejected';

  // ============================================
  // DEVICE RESET REASONS
  // ============================================
  static const String resetReasonLostStolen = 'Lost/stolen phone';
  static const String resetReasonUpgraded = 'Upgraded to new phone';
  static const String resetReasonDamaged = 'Phone damaged';
  static const String resetReasonOther = 'Other';

  static const List<String> deviceResetReasons = [
    resetReasonLostStolen,
    resetReasonUpgraded,
    resetReasonDamaged,
    resetReasonOther,
  ];

  // ============================================
  // GPS & LOCATION
  // ============================================
  static const double minAcceptableGPSAccuracy = 50.0; // meters
  static const int locationTimeoutSeconds = 30;
  static const double earthRadiusKm = 6371.0; // For distance calculations

  // ============================================
  // FILE UPLOAD
  // ============================================
  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10 MB
  static const List<String> allowedImageExtensions = ['jpg', 'jpeg', 'png', 'heic'];
  static const List<String> allowedDocumentExtensions = ['pdf', 'doc', 'docx'];

  // Storage paths
  static const String storageDocumentsPath = 'documents';
  static const String storageProfilePhotosPath = 'profile_photos';

  // ============================================
  // UI CONFIGURATION
  // ============================================
  static const double defaultBorderRadius = 12.0;
  static const double smallBorderRadius = 8.0;
  static const double largeBorderRadius = 16.0;
  
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  static const double defaultElevation = 2.0;
  static const double mediumElevation = 4.0;
  static const double highElevation = 8.0;

  // ============================================
  // ANIMATION DURATIONS
  // ============================================
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // ============================================
  // NETWORK & API
  // ============================================
  static const Duration networkTimeout = Duration(seconds: 30);
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // ============================================
  // PAGINATION
  // ============================================
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // ============================================
  // CACHING
  // ============================================
  static const Duration cacheExpiration = Duration(minutes: 15);
  static const String cacheKeyPrefix = 'cache_';

  // ============================================
  // DATE & TIME FORMATS
  // ============================================
  static const String dateFormat = 'MMM dd, yyyy';
  static const String timeFormat = 'hh:mm a';
  static const String dateTimeFormat = 'MMM dd, yyyy hh:mm a';
  static const String timeOnlyFormat = 'HH:mm';
  static const String monthYearFormat = 'MMMM yyyy';

  // ============================================
  // VALIDATION REGEX
  // ============================================
  static const String emailRegex = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  static const String phoneRegex = r'^\+?[\d\s-]{10,}$';
  static const String employeeIdRegex = r'^\d{4,}$'; // Minimum 4 digits
  static const String customIdRegex = r'^[A-Z]{3}\d{3,}$'; // Format: ABC123

  // ============================================
  // WORKING HOURS
  // ============================================
  static const String defaultWorkStartTime = '09:00';
  static const String defaultWorkEndTime = '17:00';
  static const int standardWorkingHours = 8;
  static const int workingDaysPerWeek = 5;

  // ============================================
  // REPORTS
  // ============================================
  static const String reportFormatPDF = 'pdf';
  static const String reportFormatCSV = 'csv';
  static const String reportTypeDaily = 'daily';
  static const String reportTypeWeekly = 'weekly';
  static const String reportTypeMonthly = 'monthly';
  static const String reportTypeCustom = 'custom';

  // ============================================
  // PLATFORM DETECTION
  // ============================================
  static const String platformWeb = 'web';
  static const String platformMobile = 'mobile';
  static const String platformAndroid = 'android';
  static const String platformIOS = 'ios';

  // ============================================
  // SECURE STORAGE KEYS
  // ============================================
  static const String keyUserId = 'user_id';
  static const String keyEmployeeId = 'employee_id';
  static const String keyUserRole = 'user_role';
  static const String keyPin = 'user_pin';
  static const String keyBiometricEnabled = 'biometric_enabled';
  static const String keyDeviceId = 'device_id';
  static const String keyLastSyncTime = 'last_sync_time';

  // ============================================
  // SHARED PREFERENCES KEYS
  // ============================================
  static const String prefKeyThemeMode = 'theme_mode';
  static const String prefKeyLanguage = 'language';
  static const String prefKeyFirstLaunch = 'first_launch';
  static const String prefKeyOnboardingComplete = 'onboarding_complete';

  // ============================================
  // ERROR CODES
  // ============================================
  static const String errorCodeUnauthorized = 'unauthorized';
  static const String errorCodeNotFound = 'not_found';
  static const String errorCodeInvalidData = 'invalid_data';
  static const String errorCodeNetworkError = 'network_error';
  static const String errorCodePermissionDenied = 'permission_denied';
  static const String errorCodeDeviceMismatch = 'device_mismatch';
  static const String errorCodeMaxCheckInsReached = 'max_checkins_reached';
  static const String errorCodeAlreadyCheckedIn = 'already_checked_in';

  // ============================================
  // DEFAULT VALUES
  // ============================================
  static const String defaultEmployerName = 'My Company';
  static const String defaultTimeZone = 'UTC';
  static const String defaultCountryCode = 'US';
  static const String defaultCurrency = 'USD';

  // ============================================
  // APP LIMITS
  // ============================================
  static const int maxProjectsPerEmployee = 10;
  static const int maxEmployeesPerSupervisor = 50;
  static const int maxDocumentsPerEmployee = 20;
  static const int maxAuditLogsPerQuery = 100;
  static const int maxNotificationsPerUser = 50;
}

