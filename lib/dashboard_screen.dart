import 'package:flutter/material.dart' hide ErrorWidget;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:straights_psyroll/check_in_screen.dart';
import 'package:straights_psyroll/documents_screen.dart';
import 'package:straights_psyroll/profile_screen.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../widgets/loading_widget.dart';


class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) return const LoadingWidget();

        final List<Widget> screens = [
          _DashboardHome(userId: user.uid),
          CheckInScreen(userId: user.uid),
          DocumentsScreen(userId: user.uid),
          ProfileScreen(userId: user.uid),
        ];

        return Scaffold(
          body: screens[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.secondary,
            unselectedItemColor: AppColors.textSecondary,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.access_time_outlined),
                activeIcon: Icon(Icons.access_time),
                label: 'Attendance',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.folder_outlined),
                activeIcon: Icon(Icons.folder),
                label: 'Documents',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(body: LoadingWidget()),
      error: (error, _) => Scaffold(
        body: ErrorWidget(message: error.toString()),
      ),
    );
  }
}

class _DashboardHome extends ConsumerWidget {
  final String userId;

  const _DashboardHome({required this.userId});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final todayAttendanceAsync = ref.watch(todayAttendanceProvider(userId));
    final todayTotalHoursAsync = ref.watch(todayTotalWorkingHoursProvider(userId));
    final weeklyStatsAsync = ref.watch(weeklyStatsProvider(userId));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todayAttendanceProvider(userId));
          ref.invalidate(todayTotalWorkingHoursProvider(userId));
          ref.invalidate(weeklyStatsProvider(userId));
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Card
              userAsync.when(
                data: (user) => Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: user?.profileImageUrl != null
                            ? NetworkImage(user!.profileImageUrl!)
                            : null,
                        child: user?.profileImageUrl == null
                            ? const Icon(Icons.person, size: 32, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.name ?? 'User',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              user?.designation ?? '',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
              const SizedBox(height: 24),

              // Today's Status
              todayAttendanceAsync.when(
                data: (attendance) {
                  return todayTotalHoursAsync.when(
                    data: (totalHours) => _buildTodayStatusCard(context, attendance, totalHours),
                    loading: () => _buildTodayStatusCard(context, attendance, Duration.zero),
                    error: (_, __) => _buildTodayStatusCard(context, attendance, Duration.zero),
                  );
                },
                loading: () => const LoadingWidget(),
                error: (error, _) => _buildTodayStatusCard(context, null, Duration.zero),
              ),
              const SizedBox(height: 24),

              // Weekly Stats
              const Text(
                'Weekly Statistics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              weeklyStatsAsync.when(
                data: (stats) => _buildWeeklyStats(stats),
                loading: () => const LoadingWidget(),
                error: (error, _) => ErrorWidget(message: error.toString()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayStatusCard(BuildContext context, attendance, Duration totalWorkingHours) {
    final bool isCheckedIn = attendance?.isCheckedIn ?? false;
    final String checkInTime = attendance?.checkInTime != null
        ? DateFormat('hh:mm a').format(attendance!.checkInTime)
        : '--:--';
    
    // Format total working hours (all sessions today)
    final hours = totalWorkingHours.inHours;
    final minutes = totalWorkingHours.inMinutes.remainder(60);
    final String workingHours = totalWorkingHours.inMinutes > 0 
        ? '${hours}h ${minutes}m' 
        : '0h 0m';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Today\'s Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isCheckedIn
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isCheckedIn ? 'Checked In' : 'Not Checked In',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isCheckedIn ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatusItem(
                  icon: Icons.login,
                  label: 'Check In',
                  value: checkInTime,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatusItem(
                  icon: Icons.access_time,
                  label: 'Working Hours',
                  value: workingHours,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyStats(Map<String, dynamic> stats) {
    // Format total working time
    final totalMinutes = stats['totalWorkingMinutes'] ?? 0;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    final totalTimeStr = hours > 0 
        ? '$hours hrs ${minutes} min' 
        : '$minutes min';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildStatRow(
            'Total Days Present',
            '${stats['totalDays']} ${stats['totalDays'] == 1 ? 'day' : 'days'}',
            Icons.calendar_today,
            AppColors.secondary,
          ),
          const Divider(height: 24),
          _buildStatRow(
            'Total Working Time',
            totalTimeStr,
            Icons.schedule,
            AppColors.success,
          ),
          const Divider(height: 24),
          _buildStatRow(
            'Average Hours/Day',
            '${stats['averageHoursPerDay'].toStringAsFixed(1)} hrs',
            Icons.trending_up,
            AppColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}