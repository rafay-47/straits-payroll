import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/models/attendance_model.dart';
import '../../../shared/providers/attendance_provider.dart';
import '../../../shared/providers/project_provider.dart';

/// Employee attendance history screen
class AttendanceHistoryScreen extends ConsumerStatefulWidget {
  const AttendanceHistoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState
    extends ConsumerState<AttendanceHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final history = ref.watch(attendanceHistoryProvider);
    final projects = ref.watch(employeeProjectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance History'),
        backgroundColor: AppColors.info,
      ),
      body: history.when(
        data: (records) {
          if (records.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: AppColors.textLight),
                  const SizedBox(height: 16),
                  Text(
                    'No attendance records yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your check-in history will appear here',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            );
          }

          // Resolve project names
          final projectNameMap = <String, String>{};
          projects.whenData((projectList) {
            for (final p in projectList) {
              projectNameMap[p.projectId] = p.name;
            }
          });

          // Group records by date
          final grouped = <String, List<AttendanceModel>>{};
          for (final record in records) {
            final dateKey =
                '${record.checkInTime.year}-${record.checkInTime.month.toString().padLeft(2, '0')}-${record.checkInTime.day.toString().padLeft(2, '0')}';
            grouped.putIfAbsent(dateKey, () => []).add(record);
          }

          final dateKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(attendanceHistoryProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: dateKeys.length,
              itemBuilder: (context, index) {
                final dateKey = dateKeys[index];
                final dayRecords = grouped[dateKey]!;
                final date = DateTime.parse(dateKey);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date header
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, top: 8),
                      child: Text(
                        _formatDate(date),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    // Records for this date
                    ...dayRecords.map((record) => _buildRecordCard(
                          record,
                          projectNameMap[record.projectId] ?? record.projectId,
                        )),
                    if (index < dateKeys.length - 1)
                      const SizedBox(height: 8),
                  ],
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading history: $error'),
        ),
      ),
    );
  }

  Widget _buildRecordCard(AttendanceModel record, String projectName) {
    final checkInTime = record.checkInTime;
    final checkOutTime = record.checkOutTime;
    final isCheckedIn = record.isCheckedIn;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project name + status badge
            Row(
              children: [
                Icon(Icons.folder, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    projectName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isCheckedIn
                        ? AppColors.checkedInColor.withOpacity(0.1)
                        : AppColors.checkedOutColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isCheckedIn ? 'Active' : 'Completed',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isCheckedIn
                          ? AppColors.checkedInColor
                          : AppColors.checkedOutColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Times row
            Row(
              children: [
                _buildTimeChip(
                  icon: Icons.login,
                  label: 'In',
                  time: _formatTime(checkInTime),
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 14, color: AppColors.textLight),
                const SizedBox(width: 8),
                _buildTimeChip(
                  icon: Icons.logout,
                  label: 'Out',
                  time: checkOutTime != null ? _formatTime(checkOutTime) : '--:--',
                  color: checkOutTime != null ? AppColors.error : AppColors.textLight,
                ),
                const Spacer(),
                if (record.workingHours != null)
                  Text(
                    record.formattedWorkingHours,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            // Method row
            Row(
              children: [
                Icon(_getMethodIcon(record.checkInMethod),
                    size: 14, color: _getMethodColor(record.checkInMethod)),
                const SizedBox(width: 4),
                Text(
                  _getMethodLabel(record.checkInMethod),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textLight,
                  ),
                ),
                if (record.verifiedBy != null) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.person, size: 12, color: AppColors.textLight),
                  const SizedBox(width: 2),
                  Text(
                    'Supervised',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeChip({
    required IconData icon,
    required String label,
    required String time,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 2),
        Text(
          '$label $time',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final recordDate = DateTime(date.year, date.month, date.day);
    final diff = today.difference(recordDate).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';

    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  IconData _getMethodIcon(String method) {
    switch (method) {
      case 'gps':
        return Icons.location_on;
      case 'nfc':
        return Icons.nfc;
      case 'qr':
        return Icons.qr_code_scanner;
      case 'manual':
        return Icons.edit_location;
      case 'multi':
        return Icons.verified_user;
      default:
        return Icons.check_circle;
    }
  }

  Color _getMethodColor(String method) {
    switch (method) {
      case 'gps':
        return AppColors.gpsColor;
      case 'nfc':
        return AppColors.nfcColor;
      case 'qr':
        return AppColors.qrColor;
      case 'manual':
        return AppColors.manualColor;
      case 'multi':
        return AppColors.success;
      default:
        return AppColors.textLight;
    }
  }

  String _getMethodLabel(String method) {
    switch (method) {
      case 'gps':
        return 'GPS';
      case 'nfc':
        return 'NFC';
      case 'qr':
        return 'QR Code';
      case 'manual':
        return 'Manual';
      case 'multi':
        return 'All Methods';
      default:
        return method.toUpperCase();
    }
  }
}
