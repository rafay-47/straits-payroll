import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_strings.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/project_provider.dart';
import '../../../shared/models/user_model.dart';
import '../../../mobile/screens/supervisor/employee_list_screen.dart'
    show supervisorEmployeesProvider;
import '../projects/project_management_screen.dart';
import '../employees/employee_approval_screen.dart';
import '../employees/employee_management_screen.dart';
import '../settings/system_settings_screen.dart';
import '../documents/document_management_screen.dart';
import '../reports/reports_screen.dart';
import '../devices/device_reset_management_screen.dart';
import '../employees/pin_reset_management_screen.dart';

/// Provider for all employees (admin view, real-time)
final allEmployeesProvider = StreamProvider<List<UserModel>>((ref) async* {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final currentUser = ref.watch(currentUserProvider).value;
  
  try {
    if (currentUser == null) {
      yield [];
      return;
    }
    if (currentUser.role == 'superadmin') {
      yield* firestoreService.streamAllUsers();
    } else if (currentUser.companyId != null) {
      yield* firestoreService.streamAllUsersForCompany(currentUser.companyId!);
    } else {
      yield [];
    }
  } catch (e) {
    print('Error fetching all employees stream: $e');
    yield [];
  }
});

/// Admin dashboard screen for web
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final currentUser = user.asData?.value;
    final isSupervisor = currentUser != null && currentUser.isSupervisor;

    // For supervisors, only watch their assigned projects
    // For admins, watch all company projects
    final projects = isSupervisor
        ? ref.watch(supervisorProjectsProvider)
        : ref.watch(activeProjectsProvider);

    // For supervisors, only watch their assigned employees
    // For admins, watch all company employees
    final employeesProviderValue = isSupervisor
        ? ref.watch(supervisorEmployeesProvider)
        : ref.watch(allEmployeesProvider);
    final allEmployees = employeesProviderValue;
    final pendingEmployees = ref.watch(allPendingEmployeesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isSupervisor
            ? AppStrings.supervisorDashboard
            : AppStrings.adminDashboard),
        backgroundColor: isSupervisor
            ? AppColors.supervisorColor
            : AppColors.adminColor,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(activeProjectsProvider);
              ref.invalidate(allEmployeesProvider);
              ref.invalidate(allPendingEmployeesProvider);
              if (isSupervisor) {
                ref.invalidate(supervisorProjectsProvider);
                ref.invalidate(supervisorEmployeesProvider);
              }
            },
            tooltip: 'Refresh',
          ),
          // Only show Settings for company admins and super admins
          if (!isSupervisor)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SystemSettingsScreen(),
                  ),
                );
              },
              tooltip: 'Settings',
            ),
          IconButton(
            icon: const Icon(Icons.lock_reset),
            onPressed: () => _showChangePasswordDialog(context, ref),
            tooltip: 'Change Password',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                await ref.read(authControllerProvider.notifier).signOut();
                if (!context.mounted) return;
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/admin-login',
                  (route) => false,
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Logout failed: $e')),
                );
              }
            },
            tooltip: 'Logout',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activeProjectsProvider);
          ref.invalidate(allEmployeesProvider);
          ref.invalidate(allPendingEmployeesProvider);
          if (isSupervisor) {
            ref.invalidate(supervisorProjectsProvider);
            ref.invalidate(supervisorEmployeesProvider);
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              user.when(
                data: (userData) {
                  if (userData == null) return const SizedBox();

                  return Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back, ${userData.name}!',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isSupervisor
                                  ? 'Supervisor Dashboard Overview'
                                  : 'Admin Dashboard Overview',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (error, stack) => Text('Error: $error'),
              ),

              const SizedBox(height: 32),

              // Statistics Cards - Restricted for supervisors
              if (isSupervisor) ...[
                // Supervisor view: only their project and employees
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        title: 'My Projects',
                        value: projects.when(
                          data: (list) => list.length.toString(),
                          loading: () => '...',
                          error: (_, __) => '0',
                        ),
                        icon: Icons.folder,
                        color: AppColors.supervisorColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        title: 'My Employees',
                        value: allEmployees.when(
                          data: (list) => list.length.toString(),
                          loading: () => '...',
                          error: (_, __) => '0',
                        ),
                        icon: Icons.people,
                        color: AppColors.employeeColor,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Admin view: all stats
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        title: 'Total Projects',
                        value: projects.when(
                          data: (list) => list.length.toString(),
                          loading: () => '...',
                          error: (_, __) => '0',
                        ),
                        icon: Icons.folder,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        title: 'Total Employees',
                        value: allEmployees.when(
                          data: (list) => list.length.toString(),
                          loading: () => '...',
                          error: (_, __) => '0',
                        ),
                        icon: Icons.people,
                        color: AppColors.employeeColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        title: 'Pending Approvals',
                        value: pendingEmployees.when(
                          data: (list) => list.length.toString(),
                          loading: () => '...',
                          error: (_, __) => '0',
                        ),
                        icon: Icons.pending_actions,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        title: 'Active Today',
                        value: '0', // TODO: Implement active today count
                        icon: Icons.check_circle,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 32),

              // Quick Actions - Restricted for supervisors
              Text(
                isSupervisor ? 'My Actions' : 'Quick Actions',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 16),

              if (isSupervisor) ...[
                // Supervisor view: Manage Employees + Manage My Projects
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        context,
                        icon: Icons.people,
                        title: 'Manage Employees',
                        subtitle: 'View your assigned employees',
                        color: AppColors.supervisorColor,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const EmployeeManagementScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionCard(
                        context,
                        icon: Icons.add_business,
                        title: 'Manage My Projects',
                        subtitle: 'View and assign employees',
                        color: AppColors.supervisorColor,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ProjectManagementScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Admin view: all quick actions
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        context,
                        icon: Icons.add_business,
                        title: 'Manage Projects',
                        subtitle: 'Create and manage projects',
                        color: AppColors.primary,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ProjectManagementScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionCard(
                        context,
                        icon: Icons.people,
                        title: 'Manage Employees',
                        subtitle: 'Create supervisors & employees',
                        color: AppColors.supervisorColor,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const EmployeeManagementScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionCard(
                        context,
                        icon: Icons.folder,
                        title: 'Manage Documents',
                        subtitle: 'View & approve documents',
                        color: Colors.purple,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const DocumentManagementScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Second row of quick actions (admin only)
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        context,
                        icon: Icons.assessment,
                        title: 'View Reports',
                        subtitle: 'Attendance & analytics',
                        color: AppColors.info,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ReportsScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionCard(
                        context,
                        icon: Icons.phone_android,
                        title: 'Device Requests',
                        subtitle: 'Manage device resets',
                        color: Colors.teal,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const DeviceResetManagementScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionCard(
                        context,
                        icon: Icons.lock_reset,
                        title: 'PIN Reset Requests',
                        subtitle: 'Manage employee PIN resets',
                        color: Colors.indigo,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const PinResetManagementScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 32),

              // Recent Activity Section
              // For supervisors, only show their assigned projects
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pending Approvals (admin only)
                  if (!isSupervisor)
                    Expanded(
                      flex: 2,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.pending_actions,
                                    color: AppColors.warning,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Pending Employee Approvals',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              pendingEmployees.when(
                                data: (users) {
                                  if (users.isEmpty) {
                                    return Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Center(
                                        child: Text(
                                          'No pending approvals',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  return ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: users.length > 5
                                        ? 5
                                        : users.length,
                                    separatorBuilder: (_, __) =>
                                        const Divider(),
                                    itemBuilder: (context, index) {
                                      final u = users[index];
                                      final isUserSupervisor =
                                          u.role.toLowerCase() == 'supervisor';
                                      return ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: (isUserSupervisor
                                                  ? AppColors.supervisorColor
                                                  : AppColors.employeeColor)
                                              .withOpacity(0.1),
                                          child: Icon(
                                            isUserSupervisor
                                                ? Icons.supervisor_account
                                                : Icons.person,
                                            color: isUserSupervisor
                                                ? AppColors.supervisorColor
                                                : AppColors.employeeColor,
                                          ),
                                        ),
                                        title: Text(
                                            '${u.name} (${u.roleDisplayName})'),
                                        subtitle: Text(
                                            'ID: ${u.displayId ?? "N/A"}'),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.check,
                                                  color: AppColors.success),
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (dialogContext) =>
                                                      ApproveEmployeeDialog(
                                                          employee: u),
                                                );
                                              },
                                              tooltip: 'Approve',
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.close,
                                                  color: AppColors.error),
                                              onPressed: () {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content:
                                                        Text('Reject ${u.name}'),
                                                  ),
                                                );
                                              },
                                              tooltip: 'Reject',
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                                loading: () => const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(24),
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                error: (error, stack) => Center(
                                  child: Text('Error: $error'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  if (!isSupervisor) const SizedBox(width: 16),

                  // Active Projects (supervisor sees only their projects)
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.folder,
                                  color: isSupervisor
                                      ? AppColors.supervisorColor
                                      : AppColors.primary,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  isSupervisor
                                      ? 'My Assigned Projects'
                                      : 'Active Projects',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            projects.when(
                              data: (projectList) {
                                if (projectList.isEmpty) {
                                  return Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Center(
                                      child: Text(
                                        isSupervisor
                                            ? 'No projects assigned to you'
                                            : 'No active projects',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                return ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: projectList.length > 5
                                      ? 5
                                      : projectList.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(),
                                  itemBuilder: (context, index) {
                                    final project = projectList[index];
                                    return ListTile(
                                      leading: Icon(
                                        Icons.folder,
                                        color: isSupervisor
                                            ? AppColors.supervisorColor
                                            : AppColors.primary,
                                      ),
                                      title: Text(project.name),
                                      subtitle: Text(project.location?.address ??
                                          'No location'),
                                      trailing: const Icon(
                                          Icons.arrow_forward_ios,
                                          size: 16),
                                      onTap: () {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Project: ${project.name}')),
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                              loading: () => const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              error: (error, stack) => Center(
                                child: Text('Error: $error'),
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showChangePasswordDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await showDialog(
      context: context,
      builder: (_) => const _AdminChangePasswordDialog(),
    );
  }

}

class _AdminChangePasswordDialog extends ConsumerStatefulWidget {
  const _AdminChangePasswordDialog();

  @override
  ConsumerState<_AdminChangePasswordDialog> createState() =>
      _AdminChangePasswordDialogState();
}

class _AdminChangePasswordDialogState
    extends ConsumerState<_AdminChangePasswordDialog> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Password'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                prefixIcon: Icon(Icons.lock_reset),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _handleSubmit,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }
    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New password must be at least 6 characters')),
      );
      return;
    }
    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New password and confirm password do not match')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ref.read(authServiceProvider).updatePassword(
            currentPassword: currentPassword,
            newPassword: newPassword,
          );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}


