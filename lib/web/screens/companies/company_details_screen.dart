import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../shared/services/company_service.dart';
import '../../../shared/services/storage_service.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/firestore_service.dart';
import '../../../shared/models/company_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/attendance_model.dart';
import '../../../shared/models/project_model.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/widgets/company_logo_widget.dart';
import '../reports/services/report_service.dart';
import '../reports/widgets/download_helper_stub.dart'
    if (dart.library.html) '../reports/widgets/download_helper_web.dart';
import '../employees/add_employee_dialog.dart';

/// Company details screen for super admin
class CompanyDetailsScreen extends ConsumerStatefulWidget {
  final String companyId;
  final Future<void> Function()? onCompanyChanged;

  const CompanyDetailsScreen({
    Key? key,
    required this.companyId,
    this.onCompanyChanged,
  }) : super(key: key);

  @override
  ConsumerState<CompanyDetailsScreen> createState() =>
      _CompanyDetailsScreenState();
}

class _CompanyDetailsScreenState extends ConsumerState<CompanyDetailsScreen> {
  final _companyService = CompanyService();
  final _storageService = StorageService();
  Map<String, int>? _companyStats;
  bool _isLoadingStats = true;
  bool _handledMissingCompany = false;

  @override
  void initState() {
    super.initState();
    _loadCompanyStats();
  }

  Future<void> _loadCompanyStats() async {
    try {
      final stats = await _companyService.getCompanyStats(widget.companyId);
      if (!mounted) return;
      setState(() {
        _companyStats = stats;
        _isLoadingStats = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _toggleCompanyStatus(CompanyModel company) async {
    try {
      if (company.isActive) {
        await _companyService.suspendCompany(widget.companyId);
        if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Company suspended')),
        );
        }
      } else {
        await _companyService.activateCompany(widget.companyId);
        if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Company activated')),
        );
        }
      }
    } catch (e) {
      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      }
    }
  }

  // SA-2: Show edit company dialog
  Future<void> _showEditCompanyDialog(CompanyModel company) async {
    final nameController = TextEditingController(text: company.name);
    final contactNameController = TextEditingController(text: company.primaryContact.name);
    final emailController = TextEditingController(text: company.primaryContact.email);
    final phoneController = TextEditingController(text: company.primaryContact.phone ?? '');
    final regNoController = TextEditingController(text: company.registrationNumber ?? '');
    final addressController = TextEditingController(text: company.address ?? '');
    final notesController = TextEditingController(text: company.notes ?? '');
    final maxDeviceResetsController = TextEditingController(
      text: company.settings.maxDeviceResetsPerMonth.toString(),
    );
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;
    bool allowSuperAdminView = company.allowSuperAdminView;
    String? logoUrl = company.logo;
    Uint8List? logoPreviewBytes;
    String? logoPreviewName;
    bool isUploadingLogo = false;

    Future<void> pickLogo(StateSetter setDialogState) async {
      try {
        final picker = ImagePicker();
        final image = await picker.pickImage(source: ImageSource.gallery);

        if (image == null) return;

        final bytes = await image.readAsBytes();
        setDialogState(() {
          logoPreviewBytes = bytes;
          logoPreviewName = image.name;
          isUploadingLogo = true;
        });

        final fileName = 'company_logo_${DateTime.now().millisecondsSinceEpoch}_${image.name}';
        final url = await _storageService.uploadFileFromBytes(
          bytes: bytes,
          fileName: fileName,
          storagePath: 'company_logos',
        );

        setDialogState(() {
          logoUrl = url;
          isUploadingLogo = false;
        });
      } catch (e) {
        setDialogState(() => isUploadingLogo = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload logo: $e')),
          );
        }
      }
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Company Details'),
          content: SizedBox(
            width: 500,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Company Name
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Company Name *',
                        prefixIcon: Icon(Icons.business),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    // Registration Number (SA-3)
                    TextFormField(
                      controller: regNoController,
                      decoration: const InputDecoration(
                        labelText: 'Registration / Tax ID',
                        prefixIcon: Icon(Icons.numbers),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Address (SA-3)
                    TextFormField(
                      controller: addressController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        prefixIcon: Icon(Icons.location_on),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Company Logo', style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary,
                    )),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CompanyLogoWidget(
                          size: 72,
                          borderRadius: BorderRadius.circular(12),
                          backgroundColor: AppColors.primary.withOpacity(0.08),
                          iconColor: AppColors.primary,
                          imageUrl: logoUrl,
                          imageBytes: logoPreviewBytes,
                          imageName: logoPreviewName,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ElevatedButton.icon(
                                onPressed: isUploadingLogo
                                    ? null
                                    : () => pickLogo(setDialogState),
                                icon: isUploadingLogo
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.image),
                                label: Text(
                                  isUploadingLogo ? 'Uploading...' : 'Change Logo',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Upload a new company logo from your device.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text('Primary Contact', style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary,
                    )),
                    const SizedBox(height: 12),
                    // Contact Name
                    TextFormField(
                      controller: contactNameController,
                      decoration: const InputDecoration(
                        labelText: 'Contact Name *',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    // Email
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email *',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (!v.contains('@')) return 'Invalid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Phone
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Notes (SA-3)
                    TextFormField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        prefixIcon: Icon(Icons.notes),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Max Device Resets Per Month
                    TextFormField(
                      controller: maxDeviceResetsController,
                      decoration: const InputDecoration(
                        labelText: 'Max Device Resets Per Month *',
                        prefixIcon: Icon(Icons.device_unknown),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (int.tryParse(v) == null) return 'Must be a valid integer';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Allow Super Admin Troubleshooting'),
                      subtitle: const Text(
                        'When enabled, the super admin can view this company\'s employees and supervisors for troubleshooting.',
                      ),
                      value: allowSuperAdminView,
                      onChanged: (value) {
                        setDialogState(() {
                          allowSuperAdminView = value;
                        });
                      },
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isSaving = true);
                      try {
                        // Check if the contact email changed.
                        final oldEmail = company.primaryContact.email.trim().toLowerCase();
                        final newEmail = emailController.text.trim().toLowerCase();
                        final emailChanged = newEmail != oldEmail;

                        if (emailChanged) {
                          // Migrate the company admin user to the new email.
                          final firestoreService = FirestoreService();
                          final authService = AuthService();

                          final admin = await firestoreService.getCompanyAdmin(widget.companyId);
                          if (admin == null) {
                            throw 'No company admin found for this company.';
                          }

                          // Create a new Firebase Auth account with the new email.
                          final tempPassword = authService.generateSecurePassword(length: 12);
                          final credential = await authService.createAuthAccountWithNewEmail(
                            email: newEmail,
                            password: tempPassword,
                          );

                          // Migrate all Firestore data to the new UID.
                          await firestoreService.migrateUserToNewUid(
                            oldUid: admin.uid,
                            newUid: credential.user!.uid,
                            newEmail: emailController.text.trim(),
                          );
                          // Send password reset so the user can set their own password.
                          await authService.sendPasswordResetEmail(email: newEmail);
                        }

                        final updatedSettings = company.settings.copyWith(
                          maxDeviceResetsPerMonth: int.tryParse(maxDeviceResetsController.text) ?? company.settings.maxDeviceResetsPerMonth,
                        );

                        await _companyService.updateCompany(widget.companyId, {
                          'name': nameController.text.trim(),
                          'registrationNumber': regNoController.text.trim().isEmpty
                              ? null
                              : regNoController.text.trim(),
                          'address': addressController.text.trim().isEmpty
                              ? null
                              : addressController.text.trim(),
                          'notes': notesController.text.trim().isEmpty
                              ? null
                              : notesController.text.trim(),
                          'logo': logoUrl,
                          'allowSuperAdminView': allowSuperAdminView,
                          'primaryContact': {
                            'name': contactNameController.text.trim(),
                            'email': emailController.text.trim(),
                            'phone': phoneController.text.trim().isEmpty
                                ? null
                                : phoneController.text.trim(),
                          },
                          'settings': updatedSettings.toMap(),
                        });
                        if (context.mounted) {
                        if (widget.onCompanyChanged != null) {
                          await widget.onCompanyChanged!();
                        }
                          Navigator.pop(context);
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text(
                                emailChanged
                                    ? 'Company details updated. Admin can now log in with the new email. A password reset may be needed.'
                                    : 'Company details updated',
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<CompanyModel?>(
        stream: _companyService.streamCompany(widget.companyId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading company: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            if (!_handledMissingCompany) {
              _handledMissingCompany = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              });
            }

            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final company = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Company Header
              _buildHeader(company),
              const SizedBox(height: 32),

              // Statistics
              _buildStatistics(),
              const SizedBox(height: 32),

              // Company Information
              _buildInfoSection('Company Information', [
                _buildInfoRow('Name', company.name),
                _buildInfoRow('Code', company.companyCode),
                _buildInfoRow('Status', company.status.toUpperCase()),
                if (company.registrationNumber != null && company.registrationNumber!.isNotEmpty)
                  _buildInfoRow('Registration No.', company.registrationNumber!),
                if (company.address != null && company.address!.isNotEmpty)
                  _buildInfoRow('Address', company.address!),
                _buildInfoRow(
                  'Created',
                  '${company.createdAt.day}/${company.createdAt.month}/${company.createdAt.year}',
                ),
              ]),
              const SizedBox(height: 24),

              // Contact Information
              _buildInfoSection('Primary Contact', [
                _buildInfoRow('Name', company.primaryContact.name),
                _buildInfoRow('Email', company.primaryContact.email),
                if (company.primaryContact.phone != null)
                  _buildInfoRow('Phone', company.primaryContact.phone!),
              ]),
              const SizedBox(height: 24),

              // Notes (SA-3)
              if (company.notes != null && company.notes!.isNotEmpty) ...[
                _buildInfoSection('Notes', [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      company.notes!,
                      style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                    ),
                  ),
                ]),
                const SizedBox(height: 24),
              ],

              // Settings
              _buildInfoSection('Settings', [
                _buildInfoRow('Employee ID Prefix',
                    company.settings.employeeIdPrefix),
                _buildInfoRow('Next Employee Number',
                    (company.settings.employeeIdCounter + 1).toString()),
                _buildInfoRow('Max Check-ins/Day',
                    company.settings.maxCheckInsPerDay.toString()),
                _buildInfoRow('Max Device Resets/Month',
                    company.settings.maxDeviceResetsPerMonth.toString()),
                _buildInfoRow('Geofence Radius',
                    '${company.settings.geofenceRadius}m'),
                _buildInfoRow('Working Hours',
                    '${company.settings.workingHours.start} - ${company.settings.workingHours.end}'),
                _buildInfoRow(
                  'Super Admin Troubleshooting',
                  company.allowSuperAdminView ? 'Enabled' : 'Disabled',
                ),
              ]),
              const SizedBox(height: 32),

              // Actions
              _buildActionButtons(company),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(CompanyModel company) {
    return Row(
      children: [
        CompanyLogoWidget(
          size: 80,
          borderRadius: BorderRadius.circular(12),
          backgroundColor: AppColors.primary.withOpacity(0.1),
          iconColor: AppColors.primary,
          imageUrl: company.logo,
        ),
        const SizedBox(width: 20),

        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                company.name,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Code: ${company.companyCode}',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // Status Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: company.isActive
                ? AppColors.success.withOpacity(0.1)
                : AppColors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: company.isActive ? AppColors.success : AppColors.error,
            ),
          ),
          child: Text(
            company.status.toUpperCase(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: company.isActive ? AppColors.success : AppColors.error,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatistics() {
    if (_isLoadingStats) {
      return const Center(child: CircularProgressIndicator());
    }

    final stats = _companyStats ?? {};

    return Row(
      children: [
        _buildStatCard('Users', stats['users'] ?? 0, Icons.people),
        const SizedBox(width: 16),
        _buildStatCard('Projects', stats['projects'] ?? 0, Icons.work),
        const SizedBox(width: 16),
        _buildStatCard('Attendance', stats['attendance'] ?? 0, Icons.check_circle),
      ],
    );
  }

  Widget _buildStatCard(String label, int value, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(icon, size: 32, color: AppColors.primary),
              const SizedBox(height: 12),
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(CompanyModel company) {
    return Column(
      children: [
        Row(
          children: [
            // SA-2: Edit Company button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showEditCompanyDialog(company),
                icon: const Icon(Icons.edit),
                label: const Text('Edit Company Details'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // SA-5: View Reports button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => CompanyReportsScreen(
                        companyId: widget.companyId,
                        companyName: company.name,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.bar_chart),
                label: const Text('View Reports'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // SA-6: View Employees & Supervisors button (only if allowed)
        if (company.allowSuperAdminView) ...[
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CompanyUsersScreen(
                          companyId: widget.companyId,
                          companyName: company.name,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.people),
                  label: const Text('View Employees & Supervisors'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _toggleCompanyStatus(company),
            icon: Icon(company.isActive ? Icons.pause : Icons.play_arrow),
            label: Text(company.isActive ? 'Suspend Company' : 'Activate Company'),
            style: ElevatedButton.styleFrom(
              backgroundColor: company.isActive ? AppColors.error : AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
            const SizedBox(width: 16),
            // SA-8: Delete Company button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showDeleteCompanyDialog(company),
                icon: const Icon(Icons.delete_forever),
                label: const Text('Delete Company'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
        // SA-8: Show cancellation option if pending deletion
        if (company.status == 'pendingDeletion') ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.red.shade700),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'This company is scheduled for deletion. You can cancel the deletion to restore it.',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await _companyService.cancelScheduledDeletion(widget.companyId);
                      if (widget.onCompanyChanged != null) {
                        await widget.onCompanyChanged!();
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Scheduled deletion cancelled. Company is now suspended.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        setState(() {}); // Refresh
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Cancel Deletion'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // SA-8: Delete company dialog with confirmation
  void _showDeleteCompanyDialog(CompanyModel company) {
    final confirmController = TextEditingController();
    int selectedGraceDays = 30;
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
    final pageNavigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.delete_forever, color: Colors.red.shade700),
              const SizedBox(width: 8),
              const Text('Delete Company'),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This action will delete "${company.name}" and ALL its data '
                          '(users, projects, attendance records, documents).',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Grace period selection
                const Text(
                  'Deletion Timing:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: selectedGraceDays,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    helperText: 'Grace period before permanent deletion',
                  ),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Delete Immediately')),
                    DropdownMenuItem(value: 7, child: Text('7 days grace period')),
                    DropdownMenuItem(value: 14, child: Text('14 days grace period')),
                    DropdownMenuItem(value: 30, child: Text('30 days grace period')),
                    DropdownMenuItem(value: 60, child: Text('60 days grace period')),
                    DropdownMenuItem(value: 90, child: Text('90 days grace period')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedGraceDays = value ?? 30;
                    });
                  },
                ),
                const SizedBox(height: 20),

                if (selectedGraceDays > 0)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'The company will be suspended immediately and permanently '
                      'deleted after $selectedGraceDays days. You can cancel the '
                      'deletion during this period.',
                      style: TextStyle(color: Colors.blue.shade800, fontSize: 13),
                    ),
                  ),

                if (selectedGraceDays == 0)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'WARNING: Immediate deletion is irreversible! All data will '
                      'be permanently removed.',
                      style: TextStyle(
                        color: Colors.red.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),

                const SizedBox(height: 20),
                Text(
                  'Type "${company.companyCode}" to confirm:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: confirmController,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: company.companyCode,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (confirmController.text.trim().toUpperCase() !=
                    company.companyCode.toUpperCase()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Company code does not match. Please try again.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);

                try {
                  await _companyService.scheduleCompanyDeletion(
                    widget.companyId,
                    graceDays: selectedGraceDays,
                  );

                  if (widget.onCompanyChanged != null) {
                    await widget.onCompanyChanged!();
                  }

                  if (mounted && scaffoldMessenger != null) {
                    if (selectedGraceDays == 0) {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('Company permanently deleted.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      pageNavigator.pop(true); // Back to dashboard
                    } else {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            'Company scheduled for deletion in $selectedGraceDays days. '
                            'You can cancel from the company details page.',
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      setState(() {}); // Refresh
                    }
                  }
                } catch (e) {
                  if (mounted && scaffoldMessenger != null) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade800,
                foregroundColor: Colors.white,
              ),
              child: Text(
                selectedGraceDays == 0 ? 'Delete Permanently' : 'Schedule Deletion',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// SA-5: Company-scoped Reports Screen
// ============================================

/// Reports screen scoped to a specific company (for super admin)
class CompanyReportsScreen extends ConsumerStatefulWidget {
  final String companyId;
  final String companyName;

  const CompanyReportsScreen({
    Key? key,
    required this.companyId,
    required this.companyName,
  }) : super(key: key);

  @override
  ConsumerState<CompanyReportsScreen> createState() => _CompanyReportsScreenState();
}

class _CompanyReportsScreenState extends ConsumerState<CompanyReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reports - ${widget.companyName}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_today), text: 'Attendance'),
            Tab(icon: Icon(Icons.business_center), text: 'Projects'),
            Tab(icon: Icon(Icons.people), text: 'Employees'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CompanyAttendanceReport(companyId: widget.companyId),
          _CompanyProjectReport(companyId: widget.companyId),
          _CompanyEmployeeReport(companyId: widget.companyId),
        ],
      ),
    );
  }
}

/// Attendance report scoped to a company - with real data
class _CompanyAttendanceReport extends ConsumerStatefulWidget {
  final String companyId;
  const _CompanyAttendanceReport({required this.companyId});

  @override
  ConsumerState<_CompanyAttendanceReport> createState() => _CompanyAttendanceReportState();
}

class _CompanyAttendanceReportState extends ConsumerState<_CompanyAttendanceReport> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String? _selectedProjectId;
  String? _selectedEmployeeId;
  bool _isGenerating = false;
  bool _isLoading = true;

  List<AttendanceModel> _attendanceData = [];
  List<ProjectModel> _projects = [];
  List<UserModel> _employees = [];
  final _reportService = ReportService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final results = await Future.wait([
        firestoreService.getAttendanceByCompanyAndDateRange(widget.companyId, _startDate, _endDate),
        firestoreService.getProjectsByCompanyId(widget.companyId),
        firestoreService.getUsersByCompanyId(widget.companyId),
      ]);
      if (!mounted) return;
      setState(() {
        _attendanceData = results[0] as List<AttendanceModel>;
        _projects = results[1] as List<ProjectModel>;
        _employees = (results[2] as List<UserModel>).where((u) => u.role == 'employee').toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<AttendanceModel> get _filteredAttendance {
    var filtered = _attendanceData;
    if (_selectedProjectId != null) {
      filtered = filtered.where((a) => a.projectId == _selectedProjectId).toList();
    }
    if (_selectedEmployeeId != null) {
      filtered = filtered.where((a) => a.userId == _selectedEmployeeId).toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = _filteredAttendance;
    final usersMap = {for (var u in _employees) u.uid: u};
    final projectsMap = {for (var p in _projects) p.projectId: p};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Attendance Report', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('${filtered.length} records found', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 24),

          // Filters
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildDateField('Start Date', _startDate, (d) {
                        setState(() => _startDate = d);
                        _loadData();
                      })),
                      const SizedBox(width: 16),
                      Expanded(child: _buildDateField('End Date', _endDate, (d) {
                        setState(() => _endDate = d);
                        _loadData();
                      })),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          value: _selectedProjectId,
                          decoration: const InputDecoration(labelText: 'Filter by Project', border: OutlineInputBorder()),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('All Projects')),
                            ..._projects.map((p) => DropdownMenuItem(value: p.projectId, child: Text(p.name))),
                          ],
                          onChanged: (v) => setState(() => _selectedProjectId = v),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          value: _selectedEmployeeId,
                          decoration: const InputDecoration(labelText: 'Filter by Employee', border: OutlineInputBorder()),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('All Employees')),
                            ..._employees.map((e) => DropdownMenuItem(
                                  value: e.uid,
                                  child: Text('${e.name} (${e.employeeId ?? e.systemGeneratedId ?? ''})'),
                                )),
                          ],
                          onChanged: (v) => setState(() => _selectedEmployeeId = v),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Data table
          Card(
            child: filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(48),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.event_busy, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text('No attendance records found for selected filters.',
                              style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Employee')),
                        DataColumn(label: Text('Project')),
                        DataColumn(label: Text('Method')),
                        DataColumn(label: Text('Check-In')),
                        DataColumn(label: Text('Check-Out')),
                        DataColumn(label: Text('Hours')),
                        DataColumn(label: Text('Status')),
                      ],
                      rows: filtered.take(100).map((a) {
                        final user = usersMap[a.userId];
                        final project = projectsMap[a.projectId];
                        return DataRow(cells: [
                          DataCell(Text(user?.name ?? 'Unknown')),
                          DataCell(Text(project?.name ?? 'Unknown')),
                          DataCell(Text(a.checkInMethod.toUpperCase())),
                          DataCell(Text(_fmtDateTime(a.checkInTime))),
                          DataCell(Text(a.checkOutTime != null ? _fmtDateTime(a.checkOutTime!) : 'Active')),
                          DataCell(Text(a.workingHours != null ? '${a.workingHours!.toStringAsFixed(1)}h' : '-')),
                          DataCell(Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: a.status == 'checked_out' ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(a.status.toUpperCase(),
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: a.status == 'checked_out' ? Colors.green : Colors.blue)),
                          )),
                        ]);
                      }).toList(),
                    ),
                  ),
          ),
          if (filtered.length > 100)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Showing first 100 of ${filtered.length} records. Export for full data.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            ),
          const SizedBox(height: 24),

          // Export buttons
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Export', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isGenerating ? null : () => _exportCSV(filtered, usersMap, projectsMap),
                          icon: const Icon(Icons.table_chart),
                          label: const Text('Export CSV'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isGenerating ? null : () => _exportPDF(filtered, usersMap, projectsMap),
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Export PDF'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                        ),
                      ),
                    ],
                  ),
                  if (_isGenerating)
                    const Padding(padding: EdgeInsets.only(top: 16), child: Center(child: CircularProgressIndicator())),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(String label, DateTime date, Function(DateTime) onChanged) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), suffixIcon: const Icon(Icons.calendar_today)),
        child: Text('${date.day}/${date.month}/${date.year}'),
      ),
    );
  }

  String _fmtDateTime(DateTime dt) => '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  Future<void> _exportCSV(List<AttendanceModel> data, Map<String, UserModel> users, Map<String, ProjectModel> projects) async {
    setState(() => _isGenerating = true);
    try {
      final csv = _reportService.generateAttendanceCSV(data, users, projects);
      final bytes = Uint8List.fromList(utf8.encode(csv));
      downloadFile(bytes, 'attendance_${widget.companyId}_${DateTime.now().millisecondsSinceEpoch}.csv', 'text/csv');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV exported successfully'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _exportPDF(List<AttendanceModel> data, Map<String, UserModel> users, Map<String, ProjectModel> projects) async {
    setState(() => _isGenerating = true);
    try {
      final pdf = await _reportService.generateAttendancePDF(data, users, projects, _startDate, _endDate);
      final bytes = await pdf.save();
      downloadFile(bytes, 'attendance_${widget.companyId}_${DateTime.now().millisecondsSinceEpoch}.pdf', 'application/pdf');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF exported successfully'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }
}

/// Project report scoped to a company - with real data
class _CompanyProjectReport extends ConsumerStatefulWidget {
  final String companyId;
  const _CompanyProjectReport({required this.companyId});

  @override
  ConsumerState<_CompanyProjectReport> createState() => _CompanyProjectReportState();
}

class _CompanyProjectReportState extends ConsumerState<_CompanyProjectReport> {
  bool _isLoading = true;
  bool _isGenerating = false;
  bool _includeInactive = false;
  List<ProjectModel> _projects = [];
  List<UserModel> _users = [];
  final _reportService = ReportService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final results = await Future.wait([
        firestoreService.getProjectsByCompanyId(widget.companyId),
        firestoreService.getUsersByCompanyId(widget.companyId),
      ]);
      if (!mounted) return;
      setState(() {
        _projects = results[0] as List<ProjectModel>;
        _users = results[1] as List<UserModel>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading projects: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<ProjectModel> get _filteredProjects =>
      _includeInactive ? _projects : _projects.where((p) => p.isActive).toList();

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final projects = _filteredProjects;
    final supervisorMap = {for (var u in _users.where((u) => u.role == 'supervisor')) u.uid: u};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Project Report', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('${projects.length} projects', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 24),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CheckboxListTile(
                title: const Text('Include Inactive Projects'),
                value: _includeInactive,
                onChanged: (v) => setState(() => _includeInactive = v ?? false),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Summary cards
          Row(
            children: [
              _buildStatCard('Total Projects', '${_projects.length}', Icons.business_center, Colors.blue),
              const SizedBox(width: 16),
              _buildStatCard('Active', '${_projects.where((p) => p.isActive).length}', Icons.check_circle, Colors.green),
              const SizedBox(width: 16),
              _buildStatCard('Inactive', '${_projects.where((p) => !p.isActive).length}', Icons.pause_circle, Colors.orange),
              const SizedBox(width: 16),
              _buildStatCard('Total Employees Assigned',
                  '${_projects.fold<int>(0, (sum, p) => sum + p.assignedEmployeeIds.length)}',
                  Icons.people, Colors.purple),
            ],
          ),
          const SizedBox(height: 24),

          Card(
            child: projects.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(48),
                    child: Center(child: Text('No projects found.', style: TextStyle(color: Colors.grey.shade600))),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Project Name')),
                        DataColumn(label: Text('Supervisor')),
                        DataColumn(label: Text('Employees')),
                        DataColumn(label: Text('Check-in Methods')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Created')),
                      ],
                      rows: projects.map((p) {
                        final supervisor = p.supervisorId != null ? supervisorMap[p.supervisorId] : null;
                        return DataRow(cells: [
                          DataCell(Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(supervisor?.name ?? 'Unassigned')),
                          DataCell(Text('${p.assignedEmployeeIds.length}')),
                          DataCell(Text(p.checkInMethods.map((m) => m.toUpperCase()).join(', '))),
                          DataCell(Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: p.isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(p.isActive ? 'ACTIVE' : 'INACTIVE',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: p.isActive ? Colors.green : Colors.grey)),
                          )),
                          DataCell(Text(p.createdAt != null ? '${p.createdAt!.day}/${p.createdAt!.month}/${p.createdAt!.year}' : 'N/A')),
                        ]);
                      }).toList(),
                    ),
                  ),
          ),
          const SizedBox(height: 24),

          // Export
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Export', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isGenerating ? null : _exportCSV,
                          icon: const Icon(Icons.table_chart),
                          label: const Text('Export CSV'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isGenerating ? null : _exportPDF,
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Export PDF'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                        ),
                      ),
                    ],
                  ),
                  if (_isGenerating)
                    const Padding(padding: EdgeInsets.only(top: 16), child: Center(child: CircularProgressIndicator())),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportCSV() async {
    setState(() => _isGenerating = true);
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final projectAttendance = <String, List<AttendanceModel>>{};
      for (final p in _filteredProjects) {
        projectAttendance[p.projectId] = await firestoreService.getAttendanceByCompanyAndProject(widget.companyId, p.projectId);
      }
      final usersMap = {for (var u in _users) u.uid: u};
      final csv = _reportService.generateProjectCSV(_filteredProjects, projectAttendance, usersMap);
      final bytes = Uint8List.fromList(utf8.encode(csv));
      downloadFile(bytes, 'projects_${widget.companyId}_${DateTime.now().millisecondsSinceEpoch}.csv', 'text/csv');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV exported'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _exportPDF() async {
    setState(() => _isGenerating = true);
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final projectAttendance = <String, List<AttendanceModel>>{};
      for (final p in _filteredProjects) {
        projectAttendance[p.projectId] = await firestoreService.getAttendanceByCompanyAndProject(widget.companyId, p.projectId);
      }
      final usersMap = {for (var u in _users) u.uid: u};
      final pdf = await _reportService.generateProjectPDF(_filteredProjects, projectAttendance, usersMap);
      final bytes = await pdf.save();
      downloadFile(bytes, 'projects_${widget.companyId}_${DateTime.now().millisecondsSinceEpoch}.pdf', 'application/pdf');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF exported'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }
}

/// Employee report scoped to a company - with real data
class _CompanyEmployeeReport extends ConsumerStatefulWidget {
  final String companyId;
  const _CompanyEmployeeReport({required this.companyId});

  @override
  ConsumerState<_CompanyEmployeeReport> createState() => _CompanyEmployeeReportState();
}

class _CompanyEmployeeReportState extends ConsumerState<_CompanyEmployeeReport> {
  bool _isLoading = true;
  bool _isGenerating = false;
  bool _includeInactive = false;
  List<UserModel> _allUsers = [];
  final _reportService = ReportService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final users = await firestoreService.getUsersByCompanyId(widget.companyId);
      if (!mounted) return;
      setState(() {
        _allUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading employees: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<UserModel> get _employees {
    var emps = _allUsers.where((u) => u.role == 'employee').toList();
    if (!_includeInactive) {
      emps = emps.where((e) => e.isActive).toList();
    }
    return emps;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final employees = _employees;
    final supervisorMap = {for (var u in _allUsers.where((u) => u.role == 'supervisor')) u.uid: u};
    final totalEmployees = _allUsers.where((u) => u.role == 'employee').length;
    final activeCount = _allUsers.where((u) => u.role == 'employee' && u.isActive).length;
    final pendingCount = _allUsers.where((u) => u.role == 'employee' && u.status == 'pending').length;
    final supervisorCount = _allUsers.where((u) => u.role == 'supervisor').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Employee Report', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('${employees.length} employees shown', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 24),

          // Summary cards
          Row(
            children: [
              _buildStatCard('Total Employees', '$totalEmployees', Icons.people, Colors.blue),
              const SizedBox(width: 16),
              _buildStatCard('Active', '$activeCount', Icons.check_circle, Colors.green),
              const SizedBox(width: 16),
              _buildStatCard('Pending', '$pendingCount', Icons.hourglass_empty, Colors.orange),
              const SizedBox(width: 16),
              _buildStatCard('Supervisors', '$supervisorCount', Icons.supervisor_account, Colors.purple),
            ],
          ),
          const SizedBox(height: 24),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CheckboxListTile(
                title: const Text('Include Inactive Employees'),
                value: _includeInactive,
                onChanged: (v) => setState(() => _includeInactive = v ?? false),
              ),
            ),
          ),
          const SizedBox(height: 24),

          Card(
            child: employees.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(48),
                    child: Center(child: Text('No employees found.', style: TextStyle(color: Colors.grey.shade600))),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Employee ID')),
                        DataColumn(label: Text('Email')),
                        DataColumn(label: Text('Position')),
                        DataColumn(label: Text('Supervisor')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Created')),
                      ],
                      rows: employees.map((e) {
                        final supervisor = e.supervisorId != null ? supervisorMap[e.supervisorId] : null;
                        return DataRow(cells: [
                          DataCell(Text(e.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(e.employeeId ?? e.systemGeneratedId ?? 'N/A')),
                          DataCell(Text(e.email)),
                          DataCell(Text(e.position ?? 'N/A')),
                          DataCell(Text(supervisor?.name ?? 'None')),
                          DataCell(Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: e.isActive ? Colors.green.withOpacity(0.1) : e.status == 'pending' ? Colors.orange.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(e.status.toUpperCase(),
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                                    color: e.isActive ? Colors.green : e.status == 'pending' ? Colors.orange : Colors.red)),
                          )),
                          DataCell(Text(e.createdAt != null ? '${e.createdAt!.day}/${e.createdAt!.month}/${e.createdAt!.year}' : 'N/A')),
                        ]);
                      }).toList(),
                    ),
                  ),
          ),
          const SizedBox(height: 24),

          // Export
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Export', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isGenerating ? null : _exportCSV,
                          icon: const Icon(Icons.table_chart),
                          label: const Text('Export CSV'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isGenerating ? null : _exportPDF,
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Export PDF'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                        ),
                      ),
                    ],
                  ),
                  if (_isGenerating)
                    const Padding(padding: EdgeInsets.only(top: 16), child: Center(child: CircularProgressIndicator())),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportCSV() async {
    setState(() => _isGenerating = true);
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final employeeAttendance = <String, List<AttendanceModel>>{};
      for (final emp in _employees) {
        employeeAttendance[emp.uid] = await firestoreService.getAttendanceByEmployee(emp.uid);
      }
      final csv = _reportService.generateEmployeeCSV(_employees, employeeAttendance);
      final bytes = Uint8List.fromList(utf8.encode(csv));
      downloadFile(bytes, 'employees_${widget.companyId}_${DateTime.now().millisecondsSinceEpoch}.csv', 'text/csv');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV exported'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _exportPDF() async {
    setState(() => _isGenerating = true);
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final employeeAttendance = <String, List<AttendanceModel>>{};
      for (final emp in _employees) {
        employeeAttendance[emp.uid] = await firestoreService.getAttendanceByEmployee(emp.uid);
      }
      final pdf = await _reportService.generateEmployeePDF(_employees, employeeAttendance);
      final bytes = await pdf.save();
      downloadFile(bytes, 'employees_${widget.companyId}_${DateTime.now().millisecondsSinceEpoch}.pdf', 'application/pdf');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF exported'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }
}

// ============================================
// SA-6: Company Users Screen (for super admin troubleshooting)
// ============================================

class CompanyUsersScreen extends ConsumerStatefulWidget {
  final String companyId;
  final String companyName;

  const CompanyUsersScreen({
    Key? key,
    required this.companyId,
    required this.companyName,
  }) : super(key: key);

  @override
  ConsumerState<CompanyUsersScreen> createState() => _CompanyUsersScreenState();
}

class _CompanyUsersScreenState extends ConsumerState<CompanyUsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<UserModel> _allUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final users = await firestoreService.getUsersByCompanyId(widget.companyId);
      if (!mounted) return;
      setState(() {
        _allUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<UserModel> _filterByRole(String role) {
    return _allUsers.where((u) {
      final matchesRole = u.role == role;
      final matchesSearch = _searchQuery.isEmpty ||
          u.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          u.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (u.employeeId ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesRole && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final employees = _filterByRole('employee');
    final supervisors = _filterByRole('supervisor');
    final admins = _allUsers.where((u) {
      final matchesRole = u.role == 'companyadmin' || u.role == 'admin';
      final matchesSearch = _searchQuery.isEmpty ||
          u.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          u.email.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesRole && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.companyName} - Users'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Employees (${employees.length})'),
            Tab(text: 'Supervisors (${supervisors.length})'),
            Tab(text: 'Admins (${admins.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by name, email, or employee ID...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() => _searchQuery = ''),
                            )
                          : null,
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildUserTable(employees, 'employee'),
                      _buildUserTable(supervisors, 'supervisor'),
                      _buildUserTable(admins, 'admin'),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AddEmployeeDialog(companyId: widget.companyId),
          ).then((created) {
            if (created == true && mounted) {
              _loadUsers();
            }
          });
        },
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add User'),
      ),
    );
  }

  Widget _buildUserTable(List<UserModel> users, String roleType) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No ${roleType}s found',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: [
            const DataColumn(label: Text('Name')),
            const DataColumn(label: Text('Email')),
            if (roleType == 'employee') const DataColumn(label: Text('Employee ID')),
            const DataColumn(label: Text('Status')),
            const DataColumn(label: Text('Phone')),
            const DataColumn(label: Text('Position')),
            if (roleType == 'employee') const DataColumn(label: Text('Supervisor')),
            const DataColumn(label: Text('Created')),
          ],
          rows: users.map((user) {
            return DataRow(cells: [
              DataCell(Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Text(user.email)),
              if (roleType == 'employee')
                DataCell(Text(user.employeeId ?? user.systemGeneratedId ?? 'N/A')),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: user.status == 'approved' || user.status == 'active'
                        ? Colors.green.withOpacity(0.1)
                        : user.status == 'pending'
                            ? Colors.orange.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: user.status == 'approved' || user.status == 'active'
                          ? Colors.green
                          : user.status == 'pending'
                              ? Colors.orange
                              : Colors.red,
                    ),
                  ),
                ),
              ),
              DataCell(Text(user.phoneNumber ?? 'N/A')),
              DataCell(Text(user.position ?? 'N/A')),
              if (roleType == 'employee')
                DataCell(
                  FutureBuilder<UserModel?>(
                    future: user.supervisorId != null
                        ? ref.read(firestoreServiceProvider).getUser(user.supervisorId!)
                        : Future.value(null),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Text('Loading...');
                      }
                      return Text(snapshot.data?.name ?? 'None');
                    },
                  ),
                ),
              DataCell(Text(
                user.createdAt != null
                    ? '${user.createdAt!.day}/${user.createdAt!.month}/${user.createdAt!.year}'
                    : 'N/A',
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}


