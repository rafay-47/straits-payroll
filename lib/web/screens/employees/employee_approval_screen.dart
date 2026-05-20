import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:straights_psyroll/shared/models/user_model.dart';
import 'package:straights_psyroll/shared/providers/auth_provider.dart';
import 'package:straights_psyroll/shared/constants/app_colors.dart';

/// Web Admin Screen for Employee Approval
class EmployeeApprovalScreen extends ConsumerStatefulWidget {
  const EmployeeApprovalScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EmployeeApprovalScreen> createState() =>
      _EmployeeApprovalScreenState();
}

class _EmployeeApprovalScreenState
    extends ConsumerState<EmployeeApprovalScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final pendingUsersAsync = ref.watch(allPendingEmployeesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Approvals'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with search
            TextField(
              decoration: InputDecoration(
                hintText: 'Search pending users...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
            const SizedBox(height: 24),

            // Pending Users Table
            Expanded(
              child: pendingUsersAsync.when(
                data: (users) {
                  final filteredUsers = users.where((user) {
                    return user.name
                            .toLowerCase()
                            .contains(_searchQuery) ||
                        (user.systemGeneratedId
                                ?.toLowerCase()
                                .contains(_searchQuery) ??
                            false) ||
                        (user.email.toLowerCase().contains(_searchQuery));
                  }).toList();

                  if (filteredUsers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No pending approvals'
                                : 'No matching users found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Card(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(
                            AppColors.primary.withOpacity(0.1),
                          ),
                          columns: const [
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('Role')),
                            DataColumn(label: Text('System ID')),
                            DataColumn(label: Text('Email')),
                            DataColumn(label: Text('Phone')),
                            DataColumn(label: Text('Added By')),
                            DataColumn(label: Text('Date Added')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: filteredUsers.map((user) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    user.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (user.role.toLowerCase() == 'supervisor'
                                              ? AppColors.supervisorColor
                                              : AppColors.employeeColor)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      user.role.toUpperCase(),
                                      style: TextStyle(
                                        color: user.role.toLowerCase() == 'supervisor'
                                            ? AppColors.supervisorColor
                                            : AppColors.employeeColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(user.systemGeneratedId ?? user.customId ?? 'N/A'),
                                ),
                                DataCell(
                                  Text(user.email),
                                ),
                                DataCell(
                                  Text(user.phoneNumber ?? 'N/A'),
                                ),
                                DataCell(
                                  const Text('-'), // TODO: Add createdBy tracking
                                ),
                                DataCell(
                                  Text(
                                    _formatDate(user.createdAt),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.visibility),
                                        onPressed: () =>
                                            _showEmployeeDetailsDialog(
                                          context,
                                          user,
                                        ),
                                        tooltip: 'View Details',
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: () => _showApproveDialog(
                                          context,
                                          user,
                                        ),
                                        icon: const Icon(Icons.check,
                                            size: 16),
                                        label: const Text('Approve'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        onPressed: () => _showRejectDialog(
                                          context,
                                          user,
                                        ),
                                        icon:
                                            const Icon(Icons.close, size: 16),
                                        label: const Text('Reject'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text('Error: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showEmployeeDetailsDialog(BuildContext context, UserModel employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Employee Details - ${employee.name}'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Full Name', employee.name),
              _buildDetailRow(
                  'System ID', employee.systemGeneratedId ?? 'N/A'),
              _buildDetailRow('Email', employee.email),
              _buildDetailRow('Phone', employee.phoneNumber ?? 'N/A'),
              _buildDetailRow('Role', employee.role),
              _buildDetailRow('Status', employee.isApproved ? 'Approved' : 'Pending'),
              _buildDetailRow('Created', _formatDate(employee.createdAt)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showApproveDialog(BuildContext context, UserModel employee) {
    showDialog(
      context: context,
      builder: (context) => ApproveEmployeeDialog(employee: employee),
    );
  }

  void _showRejectDialog(BuildContext context, UserModel employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Employee'),
        content: Text(
          'Are you sure you want to reject ${employee.name}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _handleReject(context, employee),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleReject(BuildContext context, UserModel employee) async {
    try {
      // Update user status to rejected
      await ref.read(firestoreServiceProvider).updateUser(
        employee.uid,
        {'status': 'rejected'},
      );
      ref.invalidate(allPendingEmployeesProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Employee rejected successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

/// Dialog for Approving an Employee
class ApproveEmployeeDialog extends ConsumerStatefulWidget {
  final UserModel employee;

  const ApproveEmployeeDialog({Key? key, required this.employee})
      : super(key: key);

  @override
  ConsumerState<ApproveEmployeeDialog> createState() =>
      _ApproveEmployeeDialogState();
}

class _ApproveEmployeeDialogState extends ConsumerState<ApproveEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _customIdController;
  late TextEditingController _pinController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _customIdController = TextEditingController();
    _pinController = TextEditingController();
  }

  @override
  void dispose() {
    _customIdController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Approve Employee - ${widget.employee.name}'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'System Generated ID: ${widget.employee.systemGeneratedId ?? "N/A"}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _customIdController,
                decoration: const InputDecoration(
                  labelText: 'Custom Employee ID (Optional)',
                  hintText: 'e.g., EMP123',
                  border: OutlineInputBorder(),
                  helperText: 'Letters, numbers, dash, underscore only',
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  final customId = value?.trim() ?? '';
                  if (customId.isEmpty) return null;
                  final validPattern = RegExp(r'^[A-Za-z0-9_-]{3,30}$');
                  if (!validPattern.hasMatch(customId)) {
                    return 'Use 3-30 chars: letters, numbers, - or _';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pinController,
                decoration: const InputDecoration(
                  labelText: 'Set Login PIN *',
                  hintText: '4-6 digit PIN',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a PIN';
                  }
                  if (value.length < 4) {
                    return 'PIN must be at least 4 digits';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleApprove,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Approve'),
        ),
      ],
    );
  }

  Future<void> _handleApprove() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Get current admin user
      final currentUser = ref.read(currentUserProvider).value;
      final adminUid = currentUser?.uid ?? 'system';

      final customId = _customIdController.text.trim().toUpperCase();
      if (customId.isNotEmpty) {
        final companyId = widget.employee.companyId;
        if (companyId == null || companyId.isEmpty) {
          throw 'Employee company is missing. Cannot validate custom ID.';
        }

        final isAvailable = await ref.read(firestoreServiceProvider).isCustomIdAvailable(
              companyId: companyId,
              customId: customId,
              excludeUserId: widget.employee.uid,
            );
        if (!isAvailable) {
          throw 'Custom ID "$customId" already exists in this company. Use a unique ID.';
        }
      }

      final updateData = <String, dynamic>{
        'status': 'approved', // ✅ Fix: Use status field, not isApproved
        'pin': _pinController.text.trim(),
        'approvedBy': adminUid,
        'approvedAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Add custom ID if provided
      if (customId.isNotEmpty) {
        updateData['customId'] = customId;
        // Keep login globally unique by including company code/prefix in employeeId.
        final companyPrefix = widget.employee.companyId?.trim().toUpperCase();
        updateData['employeeId'] = (companyPrefix != null && companyPrefix.isNotEmpty)
            ? '$companyPrefix-$customId'
            : customId;
      }

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('✅ APPROVING EMPLOYEE');
      print('  Employee: ${widget.employee.name}');
      print('  UID: ${widget.employee.uid}');
      print('  Status: ${widget.employee.status} → approved');
      print('  PIN: ${_pinController.text.trim()}');
      print('  Approved By: $adminUid');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      await ref.read(firestoreServiceProvider).updateUser(
            widget.employee.uid,
            updateData,
          );

      print('✅ Employee approved successfully!');

      // Invalidate providers to refresh lists
      ref.invalidate(allPendingEmployeesProvider);
      ref.invalidate(allApprovedEmployeesProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.employee.name} approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ ERROR approving employee: $e');
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
}

