import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/constants/app_colors.dart';
import 'add_employee_dialog.dart';

/// Provider for all users (employees, supervisors, admins)
final allUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  
  try {
    return await firestoreService.getAllUsers();
  } catch (e) {
    print('Error fetching all users: $e');
    return [];
  }
});

/// Web Admin Screen for Employee Management (Create, View, Edit)
class EmployeeManagementScreen extends ConsumerStatefulWidget {
  const EmployeeManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EmployeeManagementScreen> createState() =>
      _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState
    extends ConsumerState<EmployeeManagementScreen> with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  late TabController _tabController;

  String _getEmployeeIdText(UserModel user) {
    return user.employeeId ??
        user.employeeIdNumber ??
        user.systemGeneratedId ??
        user.customId ??
        'N/A';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allUsersAsync = ref.watch(allUsersProvider);
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Management'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(allUsersProvider);
            },
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'All Users'),
            Tab(text: 'Supervisors'),
            Tab(text: 'Employees'),
            Tab(text: 'Pending'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with search and add button
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by name, email, or ID...',
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
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _showAddEmployeeDialog(context),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add Employee/Supervisor'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Statistics Cards
            allUsersAsync.when(
              data: (users) {
                final scopedUsers = _applyUserScope(
                  users,
                  currentUserAsync.asData?.value,
                );
                final supervisors =
                    scopedUsers.where((u) => u.role == 'supervisor').length;
                final employees =
                    scopedUsers.where((u) => u.role == 'employee').length;
                final pending =
                    scopedUsers.where((u) => u.status == 'pending').length;

                return Row(
                  children: [
                    _buildStatCard(
                      'Total Users',
                      '${scopedUsers.length}',
                      Icons.people,
                      Colors.blue,
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      'Supervisors',
                      '$supervisors',
                      Icons.supervisor_account,
                      Colors.orange,
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      'Employees',
                      '$employees',
                      Icons.person,
                      Colors.green,
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      'Pending',
                      '$pending',
                      Icons.pending,
                      Colors.red,
                    ),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),

            // Users Table
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildUsersTable(allUsersAsync, 'all', currentUserAsync.asData?.value),
                  _buildUsersTable(allUsersAsync, 'supervisor', currentUserAsync.asData?.value),
                  _buildUsersTable(allUsersAsync, 'employee', currentUserAsync.asData?.value),
                  _buildUsersTable(allUsersAsync, 'pending', currentUserAsync.asData?.value),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
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

  Widget _buildUsersTable(
    AsyncValue<List<UserModel>> usersAsync,
    String filter,
    UserModel? currentUser,
  ) {
    return usersAsync.when(
      data: (users) {
        // Apply filters
        var filteredUsers = _applyUserScope(users, currentUser);

        // Filter by role/status
        if (filter == 'supervisor') {
          filteredUsers = filteredUsers.where((u) => u.role == 'supervisor').toList();
        } else if (filter == 'employee') {
          filteredUsers = filteredUsers.where((u) => u.role == 'employee').toList();
        } else if (filter == 'pending') {
          filteredUsers = filteredUsers.where((u) => u.status == 'pending').toList();
        }

        // Filter by search query
        if (_searchQuery.isNotEmpty) {
          filteredUsers = filteredUsers.where((user) {
            return user.name.toLowerCase().contains(_searchQuery) ||
                user.email.toLowerCase().contains(_searchQuery) ||
                (user.employeeId?.toLowerCase().contains(_searchQuery) ?? false) ||
                (user.employeeIdNumber?.toLowerCase().contains(_searchQuery) ?? false) ||
                (user.systemGeneratedId?.toLowerCase().contains(_searchQuery) ?? false) ||
                (user.customId?.toLowerCase().contains(_searchQuery) ?? false);
          }).toList();
        }

        if (filteredUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isEmpty
                      ? 'No users found'
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
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Role')),
                  DataColumn(label: Text('Employee ID')),
                  DataColumn(label: Text('System ID')),
                  DataColumn(label: Text('Custom ID')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Project')),
                  DataColumn(label: Text('Supervisor')),
                  DataColumn(label: Text('Date Added')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: filteredUsers.map((user) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: _getRoleColor(user.role).withOpacity(0.2),
                              child: Icon(
                                _getRoleIcon(user.role),
                                color: _getRoleColor(user.role),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              user.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(Text(user.email)),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getRoleColor(user.role).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            user.role.toUpperCase(),
                            style: TextStyle(
                              color: _getRoleColor(user.role),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      DataCell(Text(_getEmployeeIdText(user))),
                      DataCell(Text(user.systemGeneratedId ?? 'N/A')),
                      DataCell(Text(user.customId ?? 'N/A')),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(user.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            user.status.toUpperCase(),
                            style: TextStyle(
                              color: _getStatusColor(user.status),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        FutureBuilder<String>(
                          future: _getProjectNames(user),
                          builder: (context, snapshot) {
                            return Text(snapshot.data ?? 'N/A');
                          },
                        ),
                      ),
                      DataCell(
                        FutureBuilder<String>(
                          future: _getSupervisorName(user.supervisorId),
                          builder: (context, snapshot) {
                            return Text(snapshot.data ?? 'N/A');
                          },
                        ),
                      ),
                      DataCell(
                        Text(_formatDate(user.createdAt)),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility, size: 20),
                              onPressed: () => _showUserDetailsDialog(context, user),
                              tooltip: 'View Details',
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => _showEditUserDialog(context, user),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                              onPressed: _canDeleteTargetUser(user)
                                  ? () => _showDeleteConfirmDialog(context, user)
                                  : null,
                              tooltip: 'Delete',
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
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return AppColors.adminColor;
      case 'supervisor':
        return AppColors.supervisorColor;
      case 'employee':
        return AppColors.employeeColor;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'supervisor':
        return Icons.supervisor_account;
      case 'employee':
        return Icons.person;
      default:
        return Icons.person_outline;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
      case 'inactive':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<String> _getProjectNames(UserModel user) async {
    if (user.role == 'supervisor') {
      try {
        final projects = await ref.read(firestoreServiceProvider).getAllProjects();
        final supervised = projects.where((p) => p.supervisorId == user.uid).toList();
        if (supervised.isEmpty) return 'Unassigned';
        return supervised.map((p) => p.name).join(', ');
      } catch (e) {
        return 'Error loading';
      }
    }

    final projectIds = <String>{
      ...user.assignedProjectIds,
      if (user.assignedProjectId != null && user.assignedProjectId!.isNotEmpty)
        user.assignedProjectId!,
    };
    if (projectIds.isEmpty) return 'Unassigned';

    try {
      final allProjects = await ref.read(firestoreServiceProvider).getAllProjects();
      final projectMap = {for (final p in allProjects) p.projectId: p};
      final names = <String>[];
      for (final projectId in projectIds) {
        final project = projectMap[projectId];
        if (project != null) names.add(project.name);
      }
      return names.isEmpty ? 'Unknown Project' : names.join(', ');
    } catch (e) {
      return 'Error loading';
    }
  }

  Future<String> _getSupervisorName(String? supervisorId) async {
    if (supervisorId == null || supervisorId.isEmpty) return 'None';

    try {
      final supervisor = await ref.read(firestoreServiceProvider).getUser(supervisorId);
      return supervisor?.name ?? 'Unknown';
    } catch (e) {
      return 'Error loading';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAddEmployeeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddEmployeeDialog(),
    ).then((created) {
      if (created == true && mounted) {
        setState(() {
          _searchQuery = '';
        });
        _tabController.animateTo(0);
      }
      // Refresh list after dialog closes
      ref.invalidate(allUsersProvider);
    });
  }

  void _showEditUserDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AddEmployeeDialog(userToEdit: user),
    ).then((_) {
      ref.invalidate(allUsersProvider);
    });
  }

  void _showUserDetailsDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('User Details - ${user.name}'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Full Name', user.name),
                _buildDetailRow('Email', user.email),
                _buildDetailRow('Phone', user.phoneNumber ?? 'N/A'),
                _buildDetailRow('Role', user.role.toUpperCase()),
                _buildDetailRow('Employee ID', _getEmployeeIdText(user)),
                _buildDetailRow('System ID', user.systemGeneratedId ?? 'N/A'),
                _buildDetailRow('Custom ID', user.customId ?? 'N/A'),
                _buildDetailRow('Status', user.status.toUpperCase()),
                FutureBuilder<String>(
                  future: _getProjectNames(user),
                  builder: (context, snapshot) {
                    return _buildDetailRow('Assigned Project', snapshot.data ?? 'Loading...');
                  },
                ),
                FutureBuilder<String>(
                  future: _getSupervisorName(user.supervisorId),
                  builder: (context, snapshot) {
                    return _buildDetailRow('Supervisor', snapshot.data ?? 'Loading...');
                  },
                ),
                _buildDetailRow('Created', _formatDate(user.createdAt)),
                _buildDetailRow('Updated', _formatDate(user.updatedAt)),
                if (user.approvedAt != null)
                  _buildDetailRow('Approved', _formatDate(user.approvedAt)),
              ],
            ),
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
            width: 150,
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

  void _showDeleteConfirmDialog(BuildContext context, UserModel user) {
    if (!_canDeleteTargetUser(user)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You do not have permission to delete this account.'),
        ),
      );
      return;
    }

    if (user.role == 'supervisor') {
      _showSupervisorDeleteDialog(context, user);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Delete User'),
            content: Text(
              'Are you sure you want to delete ${user.name}? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: isDeleting ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isDeleting
                    ? null
                    : () async {
                        setDialogState(() {
                          isDeleting = true;
                        });
                        await _handleDelete(context, user);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: isDeleting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Delete'),
              ),
            ],
          ),
        );
      },
    );
  }

  List<UserModel> _applyUserScope(List<UserModel> users, UserModel? currentUser) {
    if (currentUser == null) return users;
    final currentRole = currentUser.role.toLowerCase();
    
    // Admins and superadmins see all users in their company (or all for superadmin)
    if (currentRole == 'admin' || currentRole == 'companyadmin' || currentRole == 'superadmin') {
      return users;
    }

    // Supervisors can only see:
    // 1. Themselves
    // 2. Other supervisors in the same company
    // 3. Employees assigned to them
    return users
        .where((u) {
          if (u.uid == currentUser.uid) return true;
          if (u.role.toLowerCase() == 'supervisor') return true;
          if (u.role.toLowerCase() == 'employee' && u.supervisorId == currentUser.uid) return true;
          return false;
        })
        .toList();
  }

  Future<void> _showSupervisorDeleteDialog(
      BuildContext context, UserModel user) async {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: SizedBox(
          width: 320,
          child: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Expanded(
                child: Text('Loading supervisor assignments...'),
              ),
            ],
          ),
        ),
      ),
    );

    final firestoreService = ref.read(firestoreServiceProvider);
    final projects = await firestoreService.getAllProjects();
    final employees = await firestoreService.getAllEmployees();
    final supervisors = await firestoreService.getUsersByRole('supervisor');

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    final assignedProjects =
        projects.where((p) => p.supervisorId == user.uid).toList();
    final assignedEmployees =
        employees.where((e) => e.supervisorId == user.uid).toList();
    final replacementOptions =
        supervisors.where((s) => s.uid != user.uid).toList();
    final mustReassign =
        assignedProjects.isNotEmpty || assignedEmployees.isNotEmpty;

    String? selectedReplacementId =
        replacementOptions.isNotEmpty ? replacementOptions.first.uid : null;
    bool isDeleting = false;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Delete Supervisor'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Supervisor: ${user.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text('Assigned Projects: ${assignedProjects.length}'),
                Text('Assigned Employees: ${assignedEmployees.length}'),
                if (mustReassign) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Select replacement supervisor:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedReplacementId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: replacementOptions
                        .map(
                          (s) => DropdownMenuItem<String>(
                            value: s.uid,
                            child: Text('${s.name} (${s.email})'),
                          ),
                        )
                        .toList(),
                    onChanged: isDeleting
                        ? null
                        : (value) {
                            setDialogState(() {
                              selectedReplacementId = value;
                            });
                          },
                  ),
                  if (replacementOptions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'No other supervisor available. Create one first to reassign projects and employees.',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isDeleting ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isDeleting ||
                      (mustReassign &&
                          (replacementOptions.isEmpty ||
                              selectedReplacementId == null))
                  ? null
                  : () async {
                      setDialogState(() {
                        isDeleting = true;
                      });
                      await _handleDelete(
                        context,
                        user,
                        replacementSupervisorId:
                            mustReassign ? selectedReplacementId : null,
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: isDeleting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDelete(
    BuildContext context,
    UserModel user, {
    String? replacementSupervisorId,
  }) async {
    if (!_canDeleteTargetUser(user)) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You do not have permission to delete this account.'),
          ),
        );
      }
      return;
    }

    try {
      await ref.read(firestoreServiceProvider).deleteUserAndCleanup(
            user,
            replacementSupervisorId: replacementSupervisorId,
          );
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.name} deleted successfully')),
        );
        ref.invalidate(allUsersProvider);
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

  bool _canDeleteTargetUser(UserModel target) {
    final currentUser = ref.read(currentUserProvider).value;
    final currentRole = currentUser?.role.toLowerCase();
    final targetRole = target.role.toLowerCase();

    // Never allow deleting platform super admin from this screen.
    if (targetRole == 'superadmin') return false;

    // Users cannot delete their own account.
    if (currentUser != null && target.uid == currentUser.uid) return false;

    // Supervisors cannot delete company admins/admins.
    if (currentRole == 'supervisor' &&
        (targetRole == 'companyadmin' || targetRole == 'admin')) {
      return false;
    }

    return true;
  }
}

