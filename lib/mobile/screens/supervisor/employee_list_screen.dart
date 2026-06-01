import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_strings.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/providers/auth_provider.dart';

/// Provider for employees under current supervisor (real-time)
final supervisorEmployeesProvider = StreamProvider<List<UserModel>>((ref) async* {
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser == null) {
    yield [];
    return;
  }

  final firestoreService = ref.watch(firestoreServiceProvider);
  
  try {
    yield* firestoreService.streamEmployeesBySupervisor(currentUser.uid);
  } catch (e) {
    print('Error fetching employees stream: $e');
    yield [];
  }
});

/// Screen to view all employees under supervisor
class EmployeeListScreen extends ConsumerWidget {
  const EmployeeListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employees = ref.watch(supervisorEmployeesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.myEmployees),
        backgroundColor: AppColors.supervisorColor,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(supervisorEmployeesProvider);
        },
        child: employees.when(
          data: (employeeList) {
            if (employeeList.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.people_outline,
                      size: 80,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No employees yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add employees using the dashboard',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: employeeList.length,
              itemBuilder: (context, index) {
                final employee = employeeList[index];
                return _EmployeeCard(employee: employee);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  'Error loading employees',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Employee card widget
class _EmployeeCard extends StatelessWidget {
  final UserModel employee;

  const _EmployeeCard({required this.employee});

  Color _getStatusColor() {
    switch (employee.status) {
      case 'active':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'suspended':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusText() {
    switch (employee.status) {
      case 'active':
        return 'Active';
      case 'pending':
        return 'Pending';
      case 'approved':
        return 'Approved';
      case 'suspended':
        return 'Suspended';
      default:
        return employee.status;
    }
  }

  String _getEmployeeIdText() {
    return employee.employeeId ??
        employee.employeeIdNumber ??
        employee.systemGeneratedId ??
        employee.customId ??
        'N/A';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          _showEmployeeDetails(context);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.employeeColor.withOpacity(0.1),
                    child: const Icon(
                      Icons.person,
                      size: 32,
                      color: AppColors.employeeColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Name & ID
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Employee ID: ${_getEmployeeIdText()}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Details
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      Icons.email,
                      employee.email,
                    ),
                  ),
                ],
              ),

              if (employee.phoneNumber != null) ...[
                const SizedBox(height: 8),
                _buildDetailItem(
                  Icons.phone,
                  employee.phoneNumber!,
                ),
              ],

              if (employee.deviceInfo != null) ...[
                const SizedBox(height: 8),
                _buildDetailItem(
                  Icons.phone_android,
                  'Device: ${employee.deviceInfo!.brand ?? 'Unknown'} ${employee.deviceInfo!.deviceModel}',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showEmployeeDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.employeeColor.withOpacity(0.1),
                    child: const Icon(
                      Icons.person,
                      size: 36,
                      color: AppColors.employeeColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Employee ID: ${_getEmployeeIdText()}',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // Details
              _buildDetailSection('Contact Information', [
                _buildDetailRow('Email', employee.email),
                if (employee.phoneNumber != null)
                  _buildDetailRow('Phone', employee.phoneNumber!),
              ]),

              const SizedBox(height: 16),

              _buildDetailSection('Employment Details', [
                _buildDetailRow('Employee ID', _getEmployeeIdText()),
                _buildDetailRow('Status', _getStatusText()),
                _buildDetailRow('Role', 'Employee'),
                if (employee.systemGeneratedId != null)
                  _buildDetailRow('System ID', employee.systemGeneratedId!),
                if (employee.customId != null)
                  _buildDetailRow('Custom ID', employee.customId!),
              ]),

              if (employee.deviceInfo != null) ...[
                const SizedBox(height: 16),
                _buildDetailSection('Device Information', [
                  _buildDetailRow('Brand', employee.deviceInfo!.brand ?? 'Unknown'),
                  _buildDetailRow('Model', employee.deviceInfo!.deviceModel),
                  _buildDetailRow('OS', employee.deviceInfo!.osVersion ?? 'Unknown'),
                  _buildDetailRow(
                    'Registered',
                    _formatDate(employee.deviceInfo!.registeredAt),
                  ),
                ]),
              ],

              const SizedBox(height: 16),

              _buildDetailSection('Account Information', [
                _buildDetailRow('Created', _formatDate(employee.createdAt)),
                _buildDetailRow(
                  'Biometric',
                  employee.biometricEnabled ? 'Enabled' : 'Disabled',
                ),
              ]),

              const SizedBox(height: 24),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('View attendance - Coming soon'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.history),
                      label: const Text('Attendance'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('View documents - Coming soon'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.folder),
                      label: const Text('Documents'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
              style: const TextStyle(
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }
}

