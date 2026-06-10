import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/project_model.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/project_provider.dart';
import '../../../shared/providers/attendance_provider.dart';
import '../../../shared/services/device_service.dart';
import 'employee_list_screen.dart';

/// Manual check-in screen for supervisors
class ManualCheckInScreen extends ConsumerStatefulWidget {
  const ManualCheckInScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ManualCheckInScreen> createState() =>
      _ManualCheckInScreenState();
}

class _ManualCheckInScreenState extends ConsumerState<ManualCheckInScreen> {
  final _reasonController = TextEditingController();
  final _deviceService = DeviceService();

  String? _selectedEmployeeId;
  String? _selectedProjectId;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  /// Handle manual check-in
  Future<void> _handleManualCheckIn() async {
    if (!mounted) return;

    final employeesAsync = ref.read(supervisorEmployeesProvider);
    final employees = employeesAsync.asData?.value ?? const <UserModel>[];

    final selectedEmployee = employees.cast<UserModel?>().firstWhere(
          (e) => e?.uid == _selectedEmployeeId,
          orElse: () => null,
        );

    if (selectedEmployee == null) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Please select an employee';
      });
      return;
    }

    if (_selectedProjectId == null) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Please select a project';
      });
      return;
    }

    if (_reasonController.text.trim().isEmpty) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Please enter a reason for manual check-in';
      });
      return;
    }

    // Validate employee is assigned to the selected project
    ProjectModel? selectedProject;
    try {
      final assignedProjects = await ref.read(
        employeeAssignedProjectsProvider(_selectedEmployeeId!).future,
      );
      final isAssigned = assignedProjects.any(
        (p) => p.projectId == _selectedProjectId,
      );
      if (!isAssigned) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'This employee is not assigned to the selected project';
        });
        return;
      }
      selectedProject = assignedProjects.firstWhere(
        (p) => p.projectId == _selectedProjectId,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to verify project assignment: $e';
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) {
        throw 'Supervisor not found';
      }

      // Get device info (supervisor's device for tracking)
      final deviceInfo = await _deviceService.getDeviceInfo();
      if (!mounted) return;

      // Perform manual check-in
      final success =
          await ref.read(attendanceControllerProvider.notifier).manualCheckIn(
                employeeId: selectedEmployee.uid,
                projectId: selectedProject.projectId,
                supervisorId: currentUser.uid,
                reason: _reasonController.text.trim(),
                deviceInfo: deviceInfo,
                notes:
                    'Manual check-in by ${currentUser.name}. Reason: ${_reasonController.text.trim()}',
              );
      if (!mounted) return;

      if (success) {
        _showSuccessDialog(selectedEmployee, selectedProject);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Show success dialog
  void _showSuccessDialog(UserModel selectedEmployee, ProjectModel selectedProject) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 32),
            SizedBox(width: 12),
            Text('Check-In Successful'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${selectedEmployee.name} has been checked in successfully.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Employee', selectedEmployee.name),
                  _buildInfoRow('Project', selectedProject.name),
                  _buildInfoRow('Time', _formatTime(DateTime.now())),
                  _buildInfoRow('Method', 'Manual (Supervisor)'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (!mounted) return;
              Navigator.of(context).pop(); // Close dialog
              if (!mounted) return;
              Navigator.of(context).pop(); // Go back
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  bool _isEligibleForManualCheckIn(UserModel user) {
    final status = user.status.trim().toLowerCase();
    return status == 'active' || status == 'approved';
  }

  @override
  Widget build(BuildContext context) {
    final employees = ref.watch(supervisorEmployeesProvider);
    final employeeProjects = _selectedEmployeeId != null
        ? ref.watch(employeeAssignedProjectsProvider(_selectedEmployeeId!))
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual Check-In'),
        backgroundColor: AppColors.supervisorColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            Card(
              color: AppColors.warning.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: AppColors.warning, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Use this for employees who cannot check-in via their smartphone.',
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

            // Select Employee
            const Text(
              'Select Employee',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 12),

            employees.when(
              data: (employeeList) {
                final eligibleEmployees =
                    employeeList.where(_isEligibleForManualCheckIn).toList();

                if (employeeList.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No employees available',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }

                if (eligibleEmployees.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No active or approved employees available for manual check-in',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: DropdownButtonFormField<String>(
                      value: _selectedEmployeeId,
                      decoration: const InputDecoration(
                        labelText: 'Employee',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      items: eligibleEmployees.map((employee) {
                        return DropdownMenuItem<String>(
                          value: employee.uid,
                          child: Text(
                            '${employee.name} (${employee.displayId})',
                          ),
                        );
                      }).toList(),
                      onChanged: (employeeId) {
                        setState(() {
                          _selectedEmployeeId = employeeId;
                          _selectedProjectId = null;
                          _errorMessage = null;
                        });
                        // Invalidate cached provider to force fresh fetch for new employee
                        if (employeeId != null) {
                          ref.invalidate(employeeAssignedProjectsProvider(employeeId));
                        }
                      },
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error loading employees: $error'),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Select Project
            const Text(
              'Select Project',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 12),

            if (_selectedEmployeeId == null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Please select an employee first',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              employeeProjects!.when(
                data: (projectList) {
                  if (projectList.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No projects assigned to this employee',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    );
                  }

                  // Validate that selected project is still in the list
                  if (_selectedProjectId != null &&
                      !projectList.any((p) => p.projectId == _selectedProjectId)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _selectedProjectId = null;
                        });
                      }
                    });
                  }

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: DropdownButtonFormField<String>(
                        value: _selectedProjectId,
                        decoration: const InputDecoration(
                          labelText: 'Project',
                          prefixIcon: Icon(Icons.folder),
                          border: OutlineInputBorder(),
                        ),
                        items: projectList.map((project) {
                          return DropdownMenuItem<String>(
                            value: project.projectId,
                            child: Text(project.name),
                          );
                        }).toList(),
                        onChanged: (projectId) {
                          setState(() {
                            _selectedProjectId = projectId;
                            _errorMessage = null;
                          });
                        },
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Error loading projects: $error'),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Reason
            const Text(
              'Reason for Manual Check-In',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                prefixIcon: Icon(Icons.note),
                hintText: 'e.g., Employee forgot phone, device issue',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
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

            // Check-In Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _handleManualCheckIn,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.check_circle),
                label: Text(_isLoading ? 'Checking In...' : 'Check In Employee'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

