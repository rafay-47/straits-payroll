import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:straights_psyroll/shared/constants/app_colors.dart';
import 'package:straights_psyroll/web/screens/reports/widgets/attendance_report_widget.dart';
import 'package:straights_psyroll/web/screens/reports/widgets/project_report_widget.dart';
import 'package:straights_psyroll/web/screens/reports/widgets/employee_report_widget.dart';

/// Web Admin Screen for Reports & Export
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
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
        title: const Text('Reports & Export'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.calendar_today),
              text: 'Attendance',
            ),
            Tab(
              icon: Icon(Icons.business_center),
              text: 'Projects',
            ),
            Tab(
              icon: Icon(Icons.people),
              text: 'Employees',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          AttendanceReportWidget(),
          ProjectReportWidget(),
          EmployeeReportWidget(),
        ],
      ),
    );
  }
}

