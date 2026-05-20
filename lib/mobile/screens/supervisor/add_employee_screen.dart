import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_strings.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/services/company_service.dart';

/// Screen for supervisors to add new employees
class AddEmployeeScreen extends ConsumerStatefulWidget {
  const AddEmployeeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends ConsumerState<AddEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Generate default 4-digit PIN for employee
  String _generateDefaultPin() {
    return '1234'; // Default 4-digit PIN for employees
  }

  /// Handle employee creation
  Future<void> _handleAddEmployee() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final companyService = CompanyService();
      final currentUser = ref.read(currentUserProvider).value;

      if (currentUser == null) {
        throw 'Supervisor not found';
      }
      
      if (currentUser.companyId == null) {
        throw 'Supervisor has no company assigned';
      }

      print('🔍 Supervisor companyId: ${currentUser.companyId}');

      // Get company to retrieve company code
      // This will work with both old random IDs and new company code IDs
      final companyDoc = await companyService.getCompany(currentUser.companyId!);
      if (companyDoc == null) {
        throw 'Company not found for ID: ${currentUser.companyId}';
      }
      
      // Use the company code as the actual companyId going forward
      // This ensures new employees use the clean company code
      final companyCode = companyDoc.companyCode;
      final actualCompanyId = companyCode; // Use company code as ID
      
      print('✅ Company Code: $companyCode');
      print('✅ Using Company ID: $actualCompanyId');

      // Get next employee ID from company-managed counter to keep strict
      // per-company sequence (ABC-0001, ABC-0002, ...).
      final result = await companyService.getNextEmployeeId(actualCompanyId);
      final parts = result.split('|');
      final employeeId = parts[0];
      final systemId = parts.length > 1 ? parts[1] : employeeId.split('-').last;
      print('✅ Generated Employee ID: $employeeId');
      print('✅ System Generated ID: $systemId');

      final email = _emailController.text.trim();
      final defaultPin = _generateDefaultPin();

      // Generate UID for employee (no Firebase Auth account needed)
      // Employees use Employee ID/PIN login, not email/password
      final uid = DateTime.now().millisecondsSinceEpoch.toString();
      
      print('✅ Generated UID for employee: $uid');
      print('📋 Employee will use ID/PIN login, not email/password');

      // Create Firestore user document
      final newEmployee = UserModel(
        uid: uid,
        companyId: actualCompanyId,  // ✅ CRITICAL: Use company CODE as ID (e.g., "ABC")
        role: 'employee',
        employeeId: employeeId,  // ✅ Full format: ABC-0001
        employeeIdNumber: systemId,  // ✅ Global sequential number
        systemGeneratedId: systemId,  // Backward compatibility
        customId: null,
        name: _nameController.text.trim(),
        email: email,
        phoneNumber: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        supervisorId: currentUser.uid,
        employerId: currentUser.employerId,
        assignedProjectId: currentUser.primaryAssignedProjectId,
        assignedProjectIds: currentUser.assignedProjectIds.isNotEmpty
            ? currentUser.assignedProjectIds
            : (currentUser.assignedProjectId != null
                ? [currentUser.assignedProjectId!]
                : const []),
        deviceInfo: null,
        biometricEnabled: false,
        status: 'pending',
        approvedBy: null,
        approvedAt: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      print('✅ Creating employee with companyId: $actualCompanyId (Company Code)');
      print('✅ Supervisor has old companyId: ${currentUser.companyId}');
      print('✅ Employee will use new companyId: $actualCompanyId');
      print('✅ Assigned projects: ${newEmployee.assignedProjectIds}');

      print('');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📝 CREATING EMPLOYEE IN FIRESTORE');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('Employee Data:');
      print('  - UID: $uid');
      print('  - CompanyId: ${newEmployee.companyId}');
      print('  - Role: ${newEmployee.role}');
      print('  - EmployeeId: ${newEmployee.employeeId}');
      print('  - Name: ${newEmployee.name}');
      print('  - Email: ${newEmployee.email}');
      print('  - Status: ${newEmployee.status}');
      print('  - SupervisorId: ${newEmployee.supervisorId}');
      print('  - ProjectIds: ${newEmployee.assignedProjectIds}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      await firestoreService.createUser(newEmployee);
      print('✅ Firestore document created');

      for (final projectId in newEmployee.assignedProjectIds) {
        await firestoreService.addEmployeeToProjectAssignedList(projectId, uid);
      }
      
      // ✅ CRITICAL: Save PIN separately (not in UserModel)
      await firestoreService.updateUser(uid, {
        'pin': defaultPin,
      });
      
      print('✅ PIN saved: $defaultPin');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('✅ EMPLOYEE CREATED SUCCESSFULLY');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('');
      
      // ✅ CRITICAL: Save PIN separately (not in UserModel)
      await firestoreService.updateUser(uid, {
        'pin': defaultPin,
      });
      
      print('✅ Employee created with PIN: $defaultPin');

      setState(() {
        _isLoading = false;
      });

      // Show success dialog
      if (mounted) {
        _showSuccessDialog(employeeId, defaultPin);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to add employee: ${e.toString()}';
      });
    }
  }

  /// Show success dialog with employee credentials
  void _showSuccessDialog(String employeeId, String pin) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 32),
            SizedBox(width: 12),
            Text('Employee Added!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New employee has been created successfully.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Employee Credentials:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildCredentialRow('Employee ID:', employeeId),
                  _buildCredentialRow('Default PIN:', pin),
                  _buildCredentialRow('Email (optional):', _emailController.text.trim()),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '⚠️ Please share these credentials with the employee. They will need to change the PIN on first login.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to dashboard
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
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
        title: const Text(AppStrings.addEmployee),
        backgroundColor: AppColors.supervisorColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              Card(
                color: AppColors.info.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.info, color: AppColors.info, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'A system-generated Employee ID and default PIN (1234) will be created automatically.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Employee Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Employee Name',
                  prefixIcon: Icon(Icons.person),
                  hintText: 'Enter full name',
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter employee name';
                  }
                  if (value.trim().length < 3) {
                    return 'Name must be at least 3 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email),
                  hintText: 'employee@company.com',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter email address';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Phone Number (Optional)
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number (Optional)',
                  prefixIcon: Icon(Icons.phone),
                  hintText: '+1 234 567 8900',
                ),
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 24),

              // Error Message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Add Employee Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleAddEmployee,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.person_add),
                  label: Text(_isLoading ? 'Creating...' : 'Add Employee'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.supervisorColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

