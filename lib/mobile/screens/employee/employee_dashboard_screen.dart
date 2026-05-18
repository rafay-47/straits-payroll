import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_strings.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/project_provider.dart';
import '../../../shared/providers/attendance_provider.dart';
import 'check_in_screen.dart';
import 'device_reset_request_screen.dart';

/// Employee dashboard screen
class EmployeeDashboardScreen extends ConsumerStatefulWidget {
  const EmployeeDashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EmployeeDashboardScreen> createState() => _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends ConsumerState<EmployeeDashboardScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    print('');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🏠 EMPLOYEE DASHBOARD - initState()');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    // Refresh attendance when screen is first shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🔄 Dashboard: Initial refresh triggered');
      ref.invalidate(todayActiveAttendanceProvider);
      ref.invalidate(employeeProjectsProvider);
      ref.read(attendanceRefreshTriggerProvider.notifier).state++;
      print('   Trigger incremented to: ${ref.read(attendanceRefreshTriggerProvider)}');
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔄 EMPLOYEE DASHBOARD - didChangeDependencies()');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    // Refresh when coming back to this screen
    _refreshTimer?.cancel();
    _refreshTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        print('🔄 Dashboard: Delayed refresh triggered (500ms after didChangeDependencies)');
        ref.invalidate(todayActiveAttendanceProvider);
        ref.invalidate(employeeProjectsProvider);
        ref.read(attendanceRefreshTriggerProvider.notifier).state++;
        print('   Trigger incremented to: ${ref.read(attendanceRefreshTriggerProvider)}');
        
        // Extra aggressive refresh
        Timer(const Duration(milliseconds: 500), () {
          if (mounted) {
            print('🔄 Dashboard: Extra aggressive refresh (1000ms total)');
            ref.invalidate(todayActiveAttendanceProvider);
            ref.read(attendanceRefreshTriggerProvider.notifier).state++;
            print('   Trigger incremented to: ${ref.read(attendanceRefreshTriggerProvider)}');
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('🏗️ Dashboard: build() called');
    
    final user = ref.watch(currentUserProvider);
    final projects = ref.watch(employeeProjectsProvider);
    final todayAttendance = ref.watch(todayActiveAttendanceProvider);
    
    // Debug log attendance state
    todayAttendance.whenData((attendance) {
      if (attendance != null) {
        print('📊 Dashboard: Attendance data loaded');
        print('   Status: ${attendance.status}');
        print('   Check-in: ${attendance.checkInTime}');
      } else {
        print('📊 Dashboard: No active attendance found');
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.employeeDashboard),
        backgroundColor: AppColors.employeeColor,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _showLogoutDialog(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(employeeProjectsProvider);
          ref.invalidate(todayActiveAttendanceProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              user.when(
                data: (userData) {
                  if (userData == null) {
                    return const SizedBox();
                  }

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor:
                                AppColors.employeeColor.withOpacity(0.2),
                            child: const Icon(
                              Icons.person,
                              size: 32,
                              color: AppColors.employeeColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  userData.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'ID: ${userData.systemGeneratedId ?? userData.customId ?? "N/A"}',
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
                    ),
                  );
                },
                loading: () => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Error loading user: $error'),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Today's Status
              const Text(
                'Today\'s Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 12),

              todayAttendance.when(
                data: (attendance) {
                  if (attendance == null) {
                    return _buildStatusCard(
                      icon: Icons.info_outline,
                      title: 'Not Checked In',
                      subtitle: 'Tap below to check in to a project',
                      color: AppColors.info,
                    );
                  }

                  return _buildStatusCard(
                    icon: Icons.check_circle,
                    title: 'Checked In',
                    subtitle: 'Project: ${attendance.projectId}',
                    color: AppColors.success,
                  );
                },
                loading: () => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (error, stack) => _buildStatusCard(
                  icon: Icons.error,
                  title: 'Error',
                  subtitle: 'Failed to load status',
                  color: AppColors.error,
                ),
              ),

              const SizedBox(height: 20),

              // Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      context,
                      icon: Icons.location_on,
                      label: 'Check In',
                      color: AppColors.success,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CheckInScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      context,
                      icon: Icons.history,
                      label: 'Attendance',
                      color: AppColors.info,
                      onTap: () {
                        // TODO: Navigate to attendance history
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Attendance history - Coming soon')),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      context,
                      icon: Icons.phone_android,
                      label: 'Device Reset',
                      color: AppColors.warning,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DeviceResetRequestScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const Expanded(child: SizedBox()),
                ],
              ),

              const SizedBox(height: 20),

              // Assigned Projects
              const Text(
                'Assigned Projects',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 12),

              projects.when(
                data: (projectList) {
                  if (projectList.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.work_outline,
                                size: 48,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No projects assigned yet',
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

                  return Column(
                    children: projectList.map((project) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.folder,
                              color: AppColors.primary,
                            ),
                          ),
                          title: Text(
                            project.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            project.location!.address,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            // TODO: Show project details
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Project: ${project.name}')),
                            );
                          },
                        ),
                      );
                    }).toList(),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
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
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to logout?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              
              // Sign out
              try {
                await ref.read(authControllerProvider.notifier).signOut();
              } catch (e) {
                // Ignore errors, just continue with logout
              }

              if (context.mounted) {
                // Navigate to login screen and clear navigation stack
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/employee-login',
                  (route) => false, // Remove all previous routes
                );
              }
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
