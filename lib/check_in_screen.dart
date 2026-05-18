import 'package:flutter/material.dart' hide ErrorWidget;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/attendance_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_widget.dart';

class CheckInScreen extends ConsumerWidget {
  final String userId;

  const CheckInScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAttendanceAsync = ref.watch(todayAttendanceProvider(userId));
    final attendanceController = ref.watch(attendanceControllerProvider(userId));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Attendance'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Force refresh all attendance data from server
          ref.invalidate(todayAttendanceProvider(userId));
          ref.invalidate(todayTotalWorkingHoursProvider(userId));
          ref.invalidate(attendanceHistoryProvider(userId));
          ref.invalidate(weeklyStatsProvider(userId));
          await Future.delayed(const Duration(milliseconds: 100));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Current Time Card
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.backgroundWhite,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 64,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder(
                      stream: Stream.periodic(const Duration(seconds: 1)),
                      builder: (context, snapshot) {
                        return Text(
                          DateFormat('hh:mm:ss a').format(DateTime.now()),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Check In/Out Button
              todayAttendanceAsync.when(
                data: (attendance) {
                  final isCheckedIn = attendance?.isCheckedIn ?? false;

                  return Column(
                    children: [
                      if (isCheckedIn && attendance != null) ...[
                        _buildAttendanceInfo(attendance),
                        const SizedBox(height: 24),
                      ],
                      CustomButton(
                        text: isCheckedIn ? 'Check Out' : 'Check In',
                        onPressed: attendanceController.isLoading
                            ? null
                            : () async {
                          try {
                            if (isCheckedIn && attendance != null) {
                              await ref
                                  .read(attendanceControllerProvider(userId).notifier)
                                  .checkOut(attendance.id);
                            } else {
                              await ref
                                  .read(attendanceControllerProvider(userId).notifier)
                                  .checkIn();
                            }

                            // Wait for Firebase to write
                            await Future.delayed(const Duration(milliseconds: 1000));

                            if (context.mounted) {
                              // Invalidate providers to force refetch from server
                              ref.invalidate(todayAttendanceProvider(userId));
                              ref.invalidate(todayTotalWorkingHoursProvider(userId));
                              ref.invalidate(attendanceHistoryProvider(userId));
                              ref.invalidate(weeklyStatsProvider(userId));
                              
                              // Wait for providers to reload from server
                              await Future.delayed(const Duration(milliseconds: 800));
                              
                              // Show success message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isCheckedIn
                                        ? 'Checked out successfully!'
                                        : 'Checked in successfully!',
                                  ),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (error) {
                            // Show error message
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(error.toString()),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                        isLoading: attendanceController.isLoading,
                        backgroundColor: isCheckedIn ? AppColors.error : AppColors.success,
                        icon: isCheckedIn ? Icons.logout : Icons.login,
                      ),
                    ],
                  );
                },
                loading: () => const LoadingWidget(),
                error: (error, _) => const ErrorWidget(message: 'Failed to load attendance data'),
              ),
              const SizedBox(height: 32),

              // Recent Attendance
              _buildRecentAttendance(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceInfo(attendance) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.success, size: 24),
              const SizedBox(width: 12),
              const Text(
                'You are checked in',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Check In Time',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('hh:mm a').format(attendance.checkInTime),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (attendance.checkInLocation != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Location',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        attendance.checkInLocation!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAttendance(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(attendanceHistoryProvider(userId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Attendance',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        historyAsync.when(
          data: (attendanceList) {
            if (attendanceList.isEmpty) {
              return const EmptyWidget(
                message: 'No attendance records yet',
                icon: Icons.event_busy,
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: attendanceList.length > 5 ? 5 : attendanceList.length,
              itemBuilder: (context, index) {
                final attendance = attendanceList[index];
                return _buildAttendanceCard(attendance);
              },
            );
          },
          loading: () => const LoadingWidget(),
          error: (error, _) => const ErrorWidget(message: 'Failed to load attendance history'),
        ),
      ],
    );
  }

  Widget _buildAttendanceCard(attendance) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.calendar_today,
              color: AppColors.secondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, MMM d').format(attendance.checkInTime),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${DateFormat('hh:mm a').format(attendance.checkInTime)} - ${attendance.checkOutTime != null ? DateFormat('hh:mm a').format(attendance.checkOutTime!) : 'Not checked out'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (attendance.workingHoursFormatted != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                attendance.workingHoursFormatted!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ),
        ],
      ),
    );
  }
}