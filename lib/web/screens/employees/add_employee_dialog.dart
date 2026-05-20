import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/project_provider.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/firestore_service.dart';
import '../../../shared/services/company_service.dart';
import '../../../shared/constants/app_colors.dart';

/// Dialog for Adding/Editing Employee or Supervisor
class AddEmployeeDialog extends ConsumerStatefulWidget {
  final UserModel? userToEdit;

  const AddEmployeeDialog({Key? key, this.userToEdit}) : super(key: key);

  @override
  ConsumerState<AddEmployeeDialog> createState() => _AddEmployeeDialogState();
}

class _AddEmployeeDialogState extends ConsumerState<AddEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _phoneController;
  late TextEditingController _positionController;
  late TextEditingController _customIdController;

  String _selectedRole = 'employee'; // employee, supervisor, admin
  final List<String> _selectedProjectIds = [];
  String? _selectedSupervisorId; // SA-9: Assign supervisor to employee
  bool _isLoading = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.userToEdit != null;

    _nameController = TextEditingController(text: widget.userToEdit?.name ?? '');
    _emailController = TextEditingController(text: widget.userToEdit?.email ?? '');
    _passwordController = TextEditingController();
    _phoneController = TextEditingController(text: widget.userToEdit?.phoneNumber ?? '');
    _positionController = TextEditingController(text: widget.userToEdit?.position ?? '');
    _customIdController = TextEditingController(
      text: _isEditMode ? (widget.userToEdit!.customId ?? '') : '',
    );

    if (_isEditMode) {
      _selectedRole = widget.userToEdit!.role;
      _selectedProjectIds.addAll(widget.userToEdit!.assignedProjectIds);
      if (_selectedProjectIds.isEmpty &&
          widget.userToEdit!.assignedProjectId != null) {
        _selectedProjectIds.add(widget.userToEdit!.assignedProjectId!);
      }
      _selectedSupervisorId = widget.userToEdit!.supervisorId;
      if (_selectedRole == 'supervisor') {
        _hydrateSupervisorProjectsFromProjectRecords();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _positionController.dispose();
    _customIdController.dispose();
    super.dispose();
  }

  /// Same rules as employee activation: optional, unique per company when set.
  String? _validateOptionalCustomId(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    final validPattern = RegExp(r'^[A-Za-z0-9_-]{3,30}$');
    if (!validPattern.hasMatch(v)) {
      return 'Use 3-30 chars: letters, numbers, - or _';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(activeProjectsProvider);

    return AlertDialog(
      title: Text(_isEditMode ? 'Edit User' : 'Add Employee/Supervisor'),
      content: SizedBox(
        width: 600,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Role Selection (Important - determines account type)
                const Text(
                  'Role *',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        title: const Text('Employee'),
                        subtitle: const Text('Regular employee account (ID/PIN login)'),
                        value: 'employee',
                        groupValue: _selectedRole,
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                          });
                        },
                      ),
                      const Divider(height: 1),
                      RadioListTile<String>(
                        title: const Text('Supervisor'),
                        subtitle: const Text('Can manage employees (email/password login)'),
                        value: 'supervisor',
                        groupValue: _selectedRole,
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                          });
                        },
                      ),
                      const Divider(height: 1),
                      RadioListTile<String>(
                        title: const Text('Admin'),
                        subtitle: const Text('Full system access'),
                        value: 'admin',
                        groupValue: _selectedRole,
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Basic Information
                const Text(
                  'Basic Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    hintText: 'John Doe',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter full name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    hintText: 'john@company.com',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password (only for supervisor/admin and new accounts)
                if (!_isEditMode && (_selectedRole == 'supervisor' || _selectedRole == 'admin'))
                  Column(
                    children: [
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password *',
                          hintText: 'Minimum 6 characters',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                          helperText: 'Supervisor/Admin login password',
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (_selectedRole == 'supervisor' || _selectedRole == 'admin') {
                            if (value == null || value.isEmpty) {
                              return 'Please enter password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // Phone
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '+1234567890',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),

                // Position (optional)
                TextFormField(
                  controller: _positionController,
                  decoration: const InputDecoration(
                    labelText: 'Position/Job Title',
                    hintText: 'e.g., Construction Worker, Site Manager',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.work),
                  ),
                ),
                const SizedBox(height: 16),

                // Custom ID for supervisors / company admins (optional, unique within company)
                if (_selectedRole == 'supervisor' ||
                    _selectedRole == 'admin' ||
                    _selectedRole == 'companyadmin') ...[
                  TextFormField(
                    controller: _customIdController,
                    decoration: const InputDecoration(
                      labelText: 'Custom ID (Optional)',
                      hintText: 'e.g., SUP001',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge_outlined),
                      helperText:
                          'Unique within your company. Stored as CompanyCode-ID (email still used to log in)',
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: _validateOptionalCustomId,
                  ),
                  const SizedBox(height: 24),
                ],

                // Supervisor Assignment (for employees only) - SA-9
                if (_selectedRole == 'employee') ...[
                  const Text(
                    'Supervisor Assignment',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Assign this employee to a supervisor for oversight and document access.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  _buildSupervisorDropdown(),
                  const SizedBox(height: 24),
                ],

                // Project Assignment (required for employees, optional for supervisor edits)
                if (_selectedRole == 'employee' ||
                    (_isEditMode && _selectedRole == 'supervisor')) ...[
                  const Text(
                    'Project Assignment',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  projectsAsync.when(
                    data: (projects) {
                      if (projects.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning, color: Colors.orange),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'No projects available. Please create a project first.',
                                  style: TextStyle(color: Colors.orange),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: projects.map((project) {
                                final selected = _selectedProjectIds.contains(project.projectId);
                                return CheckboxListTile(
                                  title: Text(project.name),
                                  subtitle: Text('ID: ${project.projectId}'),
                                  value: selected,
                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedProjectIds.add(project.projectId);
                                      } else {
                                        _selectedProjectIds.remove(project.projectId);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedRole == 'supervisor'
                                ? 'Optional: assign projects to this supervisor'
                                : 'Employee can be assigned to multiple projects',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (error, stack) => Text(
                      'Error loading projects: $error',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Information Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'What happens next:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_selectedRole == 'supervisor' || _selectedRole == 'admin')
                        const Text(
                          '• Firebase Auth account created (email/password)\n'
                          '• Can login immediately to web/mobile app\n'
                          '• Status: Approved automatically',
                        )
                      else
                        const Text(
                          '• Firestore document created only\n'
                          '• System generates Employee ID (0001, 0002...)\n'
                          '• Status: Pending (requires admin approval)\n'
                          '• After approval, admin sets PIN for login',
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(_isEditMode ? 'Update' : 'Create Account'),
        ),
      ],
    );
  }

  /// Build supervisor dropdown for employee role (SA-9)
  Widget _buildSupervisorDropdown() {
    final firestoreService = ref.read(firestoreServiceProvider);

    return FutureBuilder<List<UserModel>>(
      future: firestoreService.getUsersByRole('supervisor'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text(
            'Error loading supervisors: ${snapshot.error}',
            style: const TextStyle(color: Colors.red),
          );
        }

        final supervisors = snapshot.data ?? [];

        if (supervisors.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No supervisors available. Create a supervisor first, or assign one later.',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              ],
            ),
          );
        }

        return DropdownButtonFormField<String>(
          value: _selectedSupervisorId,
          decoration: const InputDecoration(
            labelText: 'Assign Supervisor',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.supervisor_account),
            helperText: 'Select the supervisor who will manage this employee',
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('No Supervisor'),
            ),
            ...supervisors.map((supervisor) {
              return DropdownMenuItem<String>(
                value: supervisor.uid,
                child: Text('${supervisor.name} (${supervisor.email})'),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _selectedSupervisorId = value;
            });
          },
        );
      },
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final firestoreService = ref.read(firestoreServiceProvider);

      if (_isEditMode) {
        // Update existing user
        await _handleUpdate(firestoreService);
      } else {
        // Create new user
        await _handleCreate(authService, firestoreService);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode 
                  ? 'User updated successfully' 
                  : '${_selectedRole.toUpperCase()} account created successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _hydrateSupervisorProjectsFromProjectRecords() async {
    try {
      final user = widget.userToEdit;
      if (user == null) return;
      final projects = await ref.read(firestoreServiceProvider).getAllProjects();
      final projectIds = projects
          .where((p) => p.supervisorId == user.uid)
          .map((p) => p.projectId)
          .toList();
      if (!mounted) return;
      setState(() {
        _selectedProjectIds
          ..clear()
          ..addAll(projectIds);
      });
    } catch (_) {
      // Keep existing fallback values from user document if project lookup fails.
    }
  }

  Future<void> _handleCreate(AuthService authService, FirestoreService firestoreService) async {
    String? userUid;

    // Get current user's companyId
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) {
      throw 'User session not found. Please login again.';
    }
    
    final companyId = currentUser.companyId;
    if (companyId == null || companyId.isEmpty) {
      throw 'Company ID not found. Please contact support.';
    }
    final normalizedEmail = _emailController.text.trim().toLowerCase();
    final emailAvailable = await firestoreService.isEmailAvailable(
      companyId: companyId,
      email: normalizedEmail,
    );
    if (!emailAvailable) {
      throw 'Email "$normalizedEmail" is already used by another user in this company.';
    }

    print('🏢 Creating user for company: $companyId');

    // STEP 1: Create Firebase Auth account for Supervisor/Admin
    if (_selectedRole == 'supervisor' || _selectedRole == 'admin' || _selectedRole == 'companyadmin') {
      final credential = await authService.createCompanyUser(
        companyId: companyId, // ⭐ Fixed: Use actual company ID
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
      );
      userUid = credential.user?.uid;

      if (userUid == null) {
        throw 'Failed to create authentication account';
      }

      print('✅ Firebase Auth account created: $userUid');
    } else {
      // For employees, generate a UID (will be used for Firestore only)
      userUid = DateTime.now().millisecondsSinceEpoch.toString();
      print('✅ Generated UID for employee: $userUid');
    }

    // STEP 2: Generate employee ID with company code prefix (e.g., ABC-0001)
    String? systemGeneratedId;
    String? employeeId;
    if (_selectedRole == 'employee') {
      // Use CompanyService to generate proper employee ID with company code prefix
      final companyService = CompanyService();
      final result = await companyService.getNextEmployeeId(companyId);
      final parts = result.split('|');
      employeeId = parts[0];
      systemGeneratedId = parts.length > 1 ? parts[1] : employeeId.split('-').last;
      print('✅ Generated Employee ID: $employeeId');
      print('✅ System Generated ID: $systemGeneratedId');
    }

    String? supervisorCustomId;
    String? supervisorPrefixedId;
    if (_selectedRole == 'supervisor' ||
        _selectedRole == 'admin' ||
        _selectedRole == 'companyadmin') {
      final rawCustom = _customIdController.text.trim();
      if (rawCustom.isNotEmpty) {
        supervisorCustomId = rawCustom.toUpperCase();
        final available = await firestoreService.isCustomIdAvailable(
          companyId: companyId,
          customId: supervisorCustomId,
        );
        if (!available) {
          throw 'Custom ID "$supervisorCustomId" already exists in this company.';
        }
        final prefix = companyId.trim().toUpperCase();
        supervisorPrefixedId = '$prefix-$supervisorCustomId';
      }
    }

    // STEP 3: Create Firestore user document
    final newUser = UserModel(
      uid: userUid,
      companyId: companyId, // ⭐ Fixed: Include company ID
      email: _emailController.text.trim(),
      name: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim().isEmpty 
          ? null 
          : _phoneController.text.trim(),
      position: _positionController.text.trim().isEmpty 
          ? null 
          : _positionController.text.trim(),
      role: _selectedRole,
      employeeId: employeeId ?? supervisorPrefixedId,
      employeeIdNumber: systemGeneratedId,
      systemGeneratedId: systemGeneratedId,
      customId: supervisorCustomId,
      assignedProjectId: _selectedRole == 'employee' && _selectedProjectIds.isNotEmpty
          ? _selectedProjectIds.first
          : null,
      assignedProjectIds: _selectedProjectIds,
      supervisorId: _selectedRole == 'employee' ? _selectedSupervisorId : null, // SA-9
      status: (_selectedRole == 'supervisor' ||
                  _selectedRole == 'admin' ||
                  _selectedRole == 'companyadmin')
          ? 'approved'
          : 'pending',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await firestoreService.createUser(newUser);
    print('✅ Firestore document created');

    // STEP 4a: If employee with project, add to project's assignedEmployeeIds (so mobile check-in works)
    if (_selectedRole == 'employee' && _selectedProjectIds.isNotEmpty) {
      print('✅ Adding employee to project assigned lists for check-in...');
      for (final projectId in _selectedProjectIds) {
        await firestoreService.addEmployeeToProjectAssignedList(projectId, userUid);
      }
      print('✅ Employee added to assigned project lists');
    }

    // STEP 4b: Update projects with supervisor ID for all selected assignments
    if (_selectedRole == 'supervisor' && _selectedProjectIds.isNotEmpty) {
      print('✅ Updating projects with supervisor ID...');
      for (final projectId in _selectedProjectIds) {
        await firestoreService.updateProject(
          projectId,
          {'supervisorId': userUid},
        );
      }
      print('✅ Projects updated with supervisor assignment');
    }

    // Invalidate providers to refresh UI
    ref.invalidate(allProjectsProvider);
    ref.invalidate(activeProjectsProvider);
    ref.invalidate(employeeProjectsProvider);
    ref.invalidate(supervisorProjectsProvider);
    ref.invalidate(supervisorProjectProvider);

    print('');
    print('🎉 ${_selectedRole.toUpperCase()} ACCOUNT CREATED SUCCESSFULLY!');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('Name: ${newUser.name}');
    print('Email: ${newUser.email}');
    print('Role: ${newUser.role}');
    if (employeeId != null) {
      print('Employee ID: $employeeId');
    }
    if (systemGeneratedId != null) {
      print('System ID: $systemGeneratedId');
    }
    if (_selectedProjectIds.isNotEmpty) {
      print('Project IDs: ${_selectedProjectIds.join(", ")}');
    }
    print('Status: ${newUser.status}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('');

    if (_selectedRole == 'supervisor' || _selectedRole == 'admin') {
      print('✅ Supervisor/Admin can now login with:');
      print('   Email: ${newUser.email}');
      print('   Password: [as entered]');
    } else {
      print('⏳ Employee needs admin approval before login');
      print('   Employee ID: $employeeId');
      print('   Status: pending → Admin must approve and set PIN');
    }
  }

  Future<void> _handleUpdate(FirestoreService firestoreService) async {
    final currentUser = ref.read(currentUserProvider).value;
    final companyId = widget.userToEdit!.companyId;
    if (companyId == null || companyId.isEmpty) {
      throw 'Company ID missing for this user.';
    }
    final normalizedEmail = _emailController.text.trim().toLowerCase();
    final oldEmail = widget.userToEdit!.email.trim().toLowerCase();
    if (normalizedEmail != oldEmail) {
      final emailAvailable = await firestoreService.isEmailAvailable(
        companyId: companyId,
        email: normalizedEmail,
        excludeUserId: widget.userToEdit!.uid,
      );
      if (!emailAvailable) {
        throw 'Email "$normalizedEmail" is already used by another user in this company.';
      }
    }

    final oldRole = widget.userToEdit!.role;
    final oldProjectIds = <String>{
      ...widget.userToEdit!.assignedProjectIds,
      if (widget.userToEdit!.assignedProjectId != null)
        widget.userToEdit!.assignedProjectId!,
    };
    final newProjectIds = <String>{..._selectedProjectIds};
    
    final updates = <String, dynamic>{
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'role': _selectedRole,
      'status': (_selectedRole == 'supervisor' || _selectedRole == 'admin' || _selectedRole == 'companyadmin')
          ? 'approved'
          : (widget.userToEdit!.status),
      'phoneNumber': _phoneController.text.trim().isEmpty 
          ? null 
          : _phoneController.text.trim(),
      'position': _positionController.text.trim().isEmpty 
          ? null 
          : _positionController.text.trim(),
      'assignedProjectId': _selectedRole == 'employee' && _selectedProjectIds.isNotEmpty
          ? _selectedProjectIds.first
          : null,
      'assignedProjectIds': _selectedProjectIds,
      'supervisorId': _selectedRole == 'employee' ? _selectedSupervisorId : null, // SA-9
    };

    if (_selectedRole == 'supervisor' ||
        _selectedRole == 'admin' ||
        _selectedRole == 'companyadmin') {
      final raw = _customIdController.text.trim();
      final newCustom = raw.isEmpty ? null : raw.toUpperCase();
      final oldCustom = widget.userToEdit!.customId?.trim().toUpperCase();
      if (newCustom != oldCustom) {
        if (newCustom != null && newCustom.isNotEmpty) {
          final cid = widget.userToEdit!.companyId;
          if (cid == null || cid.isEmpty) {
            throw 'Company ID missing for this user.';
          }
          final available = await firestoreService.isCustomIdAvailable(
            companyId: cid,
            customId: newCustom,
            excludeUserId: widget.userToEdit!.uid,
          );
          if (!available) {
            throw 'Custom ID "$newCustom" already exists in this company.';
          }
          updates['customId'] = newCustom;
          updates['employeeId'] = '${cid.trim().toUpperCase()}-$newCustom';
        } else {
          updates['customId'] = null;
          updates['employeeId'] = null;
        }
      }
    }

    await firestoreService.updateUser(widget.userToEdit!.uid, updates);
    print('✅ User updated: ${widget.userToEdit!.name}');

    // Employee project membership cleanup when role changes away from employee.
    if (oldRole == 'employee' && _selectedRole != 'employee') {
      for (final projectId in oldProjectIds) {
        await firestoreService.removeEmployeeFromProjectAssignedList(
          projectId,
          widget.userToEdit!.uid,
        );
      }
      print('✅ Removed previous employee project assignments');
    }

    // Supervisor cleanup when role changes away from supervisor.
    if (oldRole == 'supervisor' && _selectedRole != 'supervisor') {
      for (final projectId in oldProjectIds) {
        await firestoreService.updateProject(
          projectId,
          {'supervisorId': null},
        );
      }
      print('✅ Removed previous supervisor project ownership');
    }

    // If employee's projects changed, sync project assignedEmployeeIds (so mobile check-in works)
    if (_selectedRole == 'employee') {
      final removed = oldProjectIds.difference(newProjectIds);
      final added = newProjectIds.difference(oldProjectIds);
      for (final projectId in removed) {
        print('🔄 Removing employee from project assigned list: $projectId');
        await firestoreService.removeEmployeeFromProjectAssignedList(projectId, widget.userToEdit!.uid);
      }
      for (final projectId in added) {
        print('✅ Adding employee to project assigned list: $projectId');
        await firestoreService.addEmployeeToProjectAssignedList(projectId, widget.userToEdit!.uid);
      }
      print('✅ Project assigned list sync complete');
    }

    // Supervisor project ownership sync
    if (_selectedRole == 'supervisor') {
      final removed = oldProjectIds.difference(newProjectIds);
      final added = newProjectIds.difference(oldProjectIds);
      for (final projectId in removed) {
        print('🔄 Removing supervisor from project: $projectId');
        await firestoreService.updateProject(
          projectId,
          {'supervisorId': null},
        );
      }
      for (final projectId in added) {
        print('✅ Adding supervisor to project: $projectId');
        await firestoreService.updateProject(
          projectId,
          {'supervisorId': widget.userToEdit!.uid},
        );
      }
      print('✅ Project-Supervisor sync complete');
    }

    // Invalidate providers to refresh UI
    ref.invalidate(allProjectsProvider);
    ref.invalidate(activeProjectsProvider);
    ref.invalidate(employeeProjectsProvider);
    ref.invalidate(supervisorProjectsProvider);
    ref.invalidate(supervisorProjectProvider);
  }
}

