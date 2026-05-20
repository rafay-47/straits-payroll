import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';
import '../../../shared/services/company_service.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/storage_service.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/models/company_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/widgets/company_logo_widget.dart';

/// Screen to create a new company
class CreateCompanyScreen extends ConsumerStatefulWidget {
  final Future<void> Function()? onCompanyCreated;

  const CreateCompanyScreen({
    Key? key,
    this.onCompanyCreated,
  }) : super(key: key);

  @override
  ConsumerState<CreateCompanyScreen> createState() =>
      _CreateCompanyScreenState();
}

class _CreateCompanyScreenState extends ConsumerState<CreateCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyService = CompanyService();
  final _authService = AuthService();
  final _storageService = StorageService();

  // Form controllers
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _adminPasswordController = TextEditingController(); // ⭐ NEW: Admin password
  final _employeeLimitController = TextEditingController();

  // SA-7: Company Settings controllers
  final _employeeIdPrefixController = TextEditingController();
  final _nextEmployeeNumberController = TextEditingController(text: '1');
  final _maxCheckInsController = TextEditingController(text: '2');
  final _geofenceRadiusController = TextEditingController(text: '200');
  final _workingHoursStartController = TextEditingController(text: '09:00');
  final _workingHoursEndController = TextEditingController(text: '17:00');
  final _maxDeviceResetsController = TextEditingController(text: '1');
  List<String> _selectedCheckInMethods = ['gps', 'nfc', 'qr', 'manual'];
  bool _allowSuperAdminView = true; // SA-6: toggle

  bool _isLoading = false;
  String? _logoUrl;
  Uint8List? _logoPreviewBytes;
  String? _logoPreviewName;
  String? _errorMessage;
  bool _obscurePassword = true; // ⭐ NEW: For password visibility toggle

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _contactNameController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _adminPasswordController.dispose();
    _employeeLimitController.dispose();
    _employeeIdPrefixController.dispose();
    _nextEmployeeNumberController.dispose();
    _maxCheckInsController.dispose();
    _geofenceRadiusController.dispose();
    _workingHoursStartController.dispose();
    _workingHoursEndController.dispose();
    _maxDeviceResetsController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() => _isLoading = true);

        // Upload to Firebase Storage
        final bytes = await image.readAsBytes();
        final fileName = 'company_logo_${DateTime.now().millisecondsSinceEpoch}_${image.name}';
        setState(() {
          _logoPreviewBytes = bytes;
          _logoPreviewName = image.name;
        });
        
        final url = await _storageService.uploadFileFromBytes(
          bytes: bytes,
          fileName: fileName,
          storagePath: 'company_logos',
        );

        setState(() {
          _logoUrl = url;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload logo: $e')),
      );
    }
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    String? createdCompanyId;
    bool createdAdminAuth = false;

    try {
      final superAdminUid = _authService.currentUserId;
      if (superAdminUid == null) {
        throw 'Not authenticated';
      }

      final companyCode = _codeController.text.trim().toUpperCase();
      final adminEmail = _contactEmailController.text.trim();
      final adminPassword = _adminPasswordController.text;
      final adminName = _contactNameController.text.trim();
      final adminPhone = _contactPhoneController.text.trim();

      // SA-7: Build CompanySettings from form inputs
      final employeeIdPrefix = _employeeIdPrefixController.text.trim().isEmpty
          ? companyCode
          : _employeeIdPrefixController.text.trim().toUpperCase();
      final nextEmployeeNumber = int.tryParse(_nextEmployeeNumberController.text) ?? 1;
      final maxCheckIns = int.tryParse(_maxCheckInsController.text) ?? 2;
      final geofenceRadius = int.tryParse(_geofenceRadiusController.text) ?? 200;
      final maxDeviceResets = int.tryParse(_maxDeviceResetsController.text) ?? 1;
      final workStart = _workingHoursStartController.text.trim().isEmpty
          ? '09:00'
          : _workingHoursStartController.text.trim();
      final workEnd = _workingHoursEndController.text.trim().isEmpty
          ? '17:00'
          : _workingHoursEndController.text.trim();

      final companySettings = CompanySettings(
        employeeIdPrefix: employeeIdPrefix,
        employeeIdCounter: nextEmployeeNumber - 1, // Counter is 0-based, form shows 1-based
        maxCheckInsPerDay: maxCheckIns,
        maxDeviceResetsPerMonth: maxDeviceResets,
        allowedCheckInMethods: _selectedCheckInMethods,
        geofenceRadius: geofenceRadius,
        workingHours: WorkingHours(start: workStart, end: workEnd),
      );

      // ⭐ STEP 1: Create company
      final companyId = await _companyService.createCompany(
        name: _nameController.text.trim(),
        companyCode: companyCode,
        superAdminUid: superAdminUid,
        logoUrl: _logoUrl,
        allowSuperAdminView: _allowSuperAdminView,
        primaryContact: CompanyContact(
          name: adminName,
          email: adminEmail,
          phone: adminPhone.isEmpty ? null : adminPhone,
        ),
        settings: companySettings, // SA-7: pass custom settings
        subscription: _employeeLimitController.text.trim().isEmpty
            ? null
            : CompanySubscription(
                employeeLimit: int.tryParse(_employeeLimitController.text),
              ),
      );
      createdCompanyId = companyId;

      // ⭐ STEP 2: Create Firebase Auth user for Company Admin
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );
      createdAdminAuth = true;

      if (userCredential.user == null) {
        throw 'Failed to create admin user account';
      }

      // ⭐ STEP 3: Create Firestore user document with companyId
      final firestoreService = ref.read(firestoreServiceProvider);
      final now = DateTime.now();
      
      final adminUser = UserModel(
        uid: userCredential.user!.uid,
        companyId: companyId,
        role: 'companyadmin',
        name: adminName,
        email: adminEmail,
        phoneNumber: adminPhone.isEmpty ? null : adminPhone,
        status: 'active',
        createdAt: now,
        updatedAt: now,
      );
      
      await firestoreService.createUser(adminUser);

      if (widget.onCompanyCreated != null) {
        await widget.onCompanyCreated!();
      }

      if (mounted) {
        // Show success dialog with credentials
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 32),
                const SizedBox(width: 12),
                const Text('Company Created Successfully!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Company: ${_nameController.text}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Company Admin Login Credentials:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildCredentialRow('Company Code', companyCode),
                _buildCredentialRow('Email', adminEmail),
                _buildCredentialRow('Password', adminPassword),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.info.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.info, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Save these credentials! The Company Admin can now login.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(true); // Return to dashboard
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (createdAdminAuth) {
        try {
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            await currentUser.delete();
          }
        } catch (_) {
          await FirebaseAuth.instance.signOut();
        }
      }

      if (createdCompanyId != null) {
        try {
          await _companyService.deleteCompanyPermanently(createdCompanyId);
        } catch (_) {
          // Ignore rollback failures; surface the original error below.
        }
      }

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _buildCredentialRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Company'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Error message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),

            // Company Logo
            _buildLogoSection(),
            const SizedBox(height: 32),

            // Basic Information
            Text(
              'Basic Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Company Name *',
                hintText: 'ABC Construction',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Company name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: 'Company Code * (3-6 uppercase letters)',
                hintText: 'ABC',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Company code is required';
                }
                if (!_authService.isValidCompanyCode(value)) {
                  return 'Code must be 3-6 uppercase letters (e.g., ABC)';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Primary Contact
            Text(
              'Primary Contact',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _contactNameController,
              decoration: InputDecoration(
                labelText: 'Contact Name *',
                hintText: 'John Admin',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Contact name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _contactEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Contact Email *',
                hintText: 'admin@abc.com',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Contact email is required';
                }
                if (!_authService.isValidEmail(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _contactPhoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Contact Phone (Optional)',
                hintText: '+1234567890',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ⭐ NEW: Admin Password Field
            TextFormField(
              controller: _adminPasswordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Admin Password *',
                hintText: 'Create a secure password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                helperText: 'This will be the login password for the Company Admin',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Admin password is required';
                }
                if (value.length < 8) {
                  return 'Password must be at least 8 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Info Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: AppColors.info, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'A Company Admin account will be created automatically with these credentials. They can login using: Company Code + Email + Password',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Company Configuration (SA-7)
            Text(
              'Company Configuration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Configure employee ID format, attendance rules, and working hours.',
              style: TextStyle(fontSize: 13, color: AppColors.textLight),
            ),
            const SizedBox(height: 16),

            // Row 1: Employee ID Prefix + Next Employee Number
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _employeeIdPrefixController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'Employee ID Prefix',
                      hintText: 'e.g., ABC (defaults to Company Code)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      helperText: 'Prefix for employee IDs (e.g., ABC-0001)',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _nextEmployeeNumberController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Next Employee Number',
                      hintText: '1',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      helperText: 'Starting number for employee IDs',
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final n = int.tryParse(value);
                        if (n == null || n < 1) return 'Must be at least 1';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Row 2: Max Check-ins/Day + Geofence Radius
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _maxCheckInsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Max Check-ins/Day',
                      hintText: '2',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      helperText: 'Maximum check-in attempts per day',
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final n = int.tryParse(value);
                        if (n == null || n < 1) return 'Must be at least 1';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _geofenceRadiusController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Geofence Radius (meters)',
                      hintText: '200',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      helperText: 'Check-in allowed within this radius',
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final n = int.tryParse(value);
                        if (n == null || n < 10) return 'Must be at least 10m';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Row 3: Working Hours Start + End
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _workingHoursStartController,
                    decoration: InputDecoration(
                      labelText: 'Working Hours Start',
                      hintText: '09:00',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      helperText: '24-hour format (HH:MM)',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _workingHoursEndController,
                    decoration: InputDecoration(
                      labelText: 'Working Hours End',
                      hintText: '17:00',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      helperText: '24-hour format (HH:MM)',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Row 4: Max Device Resets + Employee Limit
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _maxDeviceResetsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Max Device Resets/Month',
                      hintText: '1',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      helperText: 'Monthly device reset limit per employee',
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final n = int.tryParse(value);
                        if (n == null || n < 0) return 'Must be 0 or more';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _employeeLimitController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Employee Limit',
                      hintText: 'Leave empty for unlimited',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      helperText: 'Maximum number of employees allowed',
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final number = int.tryParse(value);
                        if (number == null || number <= 0) {
                          return 'Must be a positive number';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Allowed Check-in Methods (checkboxes)
            Text(
              'Allowed Check-in Methods',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildCheckInMethodChip('gps', 'GPS Location', Icons.location_on),
                _buildCheckInMethodChip('nfc', 'NFC Tag', Icons.nfc),
                _buildCheckInMethodChip('qr', 'QR Code', Icons.qr_code),
                _buildCheckInMethodChip('manual', 'Manual (Supervisor)', Icons.person),
              ],
            ),
            const SizedBox(height: 20),

            // SA-6: Super Admin View toggle
            SwitchListTile(
              title: const Text('Allow Super Admin Troubleshooting'),
              subtitle: const Text(
                'When enabled, the super admin can view this company\'s employees and supervisors for troubleshooting.',
              ),
              value: _allowSuperAdminView,
              onChanged: (value) {
                setState(() {
                  _allowSuperAdminView = value;
                });
              },
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 40),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleCreate,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.add),
                  label: const Text('Create Company'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckInMethodChip(String method, String label, IconData icon) {
    final isSelected = _selectedCheckInMethods.contains(method);
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedCheckInMethods.add(method);
          } else {
            _selectedCheckInMethods.remove(method);
          }
        });
      },
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
      ),
      checkmarkColor: Colors.white,
    );
  }

  Widget _buildLogoSection() {
    return Center(
      child: Column(
        children: [
          CompanyLogoWidget(
            size: 120,
            borderRadius: BorderRadius.circular(12),
            backgroundColor: AppColors.surfaceLight,
            borderColor: AppColors.borderMedium,
            iconColor: AppColors.textLight,
            imageUrl: _logoUrl,
            imageBytes: _logoPreviewBytes,
            imageName: _logoPreviewName,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _pickLogo,
            icon: const Icon(Icons.upload),
            label: Text(_logoUrl == null ? 'Upload Logo' : 'Change Logo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.backgroundWhite,
              foregroundColor: AppColors.primary,
            ),
          ),
          if (_logoUrl != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => setState(() {
                _logoUrl = null;
                _logoPreviewBytes = null;
                _logoPreviewName = null;
              }),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Remove Logo'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

