import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:straights_psyroll/shared/models/attendance_model.dart';
import 'package:straights_psyroll/shared/models/user_model.dart';
import 'package:straights_psyroll/shared/models/project_model.dart';
import 'package:straights_psyroll/shared/providers/auth_provider.dart';
import 'package:straights_psyroll/shared/providers/project_provider.dart';
import 'package:straights_psyroll/web/screens/reports/services/report_service.dart';

// Conditional import for web-only functionality
import 'download_helper_stub.dart'
    if (dart.library.html) 'download_helper_web.dart';

/// Widget for generating and exporting attendance reports
class AttendanceReportWidget extends ConsumerStatefulWidget {
  const AttendanceReportWidget({Key? key}) : super(key: key);

  @override
  ConsumerState<AttendanceReportWidget> createState() =>
      _AttendanceReportWidgetState();
}

class _AttendanceReportWidgetState
    extends ConsumerState<AttendanceReportWidget> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String? _selectedProjectId;
  String? _selectedEmployeeId;
  bool _isGenerating = false;

  final _reportService = ReportService();

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(allProjectsProvider);
    final employeesAsync = ref.watch(allApprovedEmployeesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Text(
            'Attendance Report',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Generate detailed attendance reports with customizable filters',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),

          // Filters Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Report Filters',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Date Range
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateField(
                          'Start Date',
                          _startDate,
                          (date) => setState(() => _startDate = date),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDateField(
                          'End Date',
                          _endDate,
                          (date) => setState(() => _endDate = date),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Project Filter
                  projectsAsync.when(
                    data: (projects) => DropdownButtonFormField<String?>(
                      value: _selectedProjectId,
                      decoration: const InputDecoration(
                        labelText: 'Filter by Project (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Projects'),
                        ),
                        ...projects.map((project) => DropdownMenuItem(
                              value: project.projectId,
                              child: Text(project.name),
                            )),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedProjectId = value);
                      },
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const Text('Error loading projects'),
                  ),

                  const SizedBox(height: 16),

                  // Employee Filter
                  employeesAsync.when(
                    data: (employees) => DropdownButtonFormField<String?>(
                      value: _selectedEmployeeId,
                      decoration: const InputDecoration(
                        labelText: 'Filter by Employee (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Employees'),
                        ),
                        ...employees.map((employee) => DropdownMenuItem(
                              value: employee.uid,
                              child: Text(
                                  '${employee.name} (${employee.systemGeneratedId ?? employee.customId})'),
                            )),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedEmployeeId = value);
                      },
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const Text('Error loading employees'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Export Buttons
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Export Report',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isGenerating ? null : _exportToPDF,
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Export to PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isGenerating ? null : _exportToCSV,
                          icon: const Icon(Icons.table_chart),
                          label: const Text('Export to CSV'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_isGenerating)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(
      String label, DateTime date, Function(DateTime) onChanged) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          '${date.day}/${date.month}/${date.year}',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Future<void> _exportToPDF() async {
    setState(() => _isGenerating = true);

    try {
      // Fetch data
      final attendance = await _fetchAttendanceData();
      final users = await _fetchUsersMap();
      final projects = await _fetchProjectsMap();

      // Generate PDF
      final pdf = await _reportService.generateAttendancePDF(
        attendance,
        users,
        projects,
        _startDate,
        _endDate,
      );

      // Save PDF
      final bytes = await pdf.save();
      downloadFile(
        bytes,
        'attendance_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
        'application/pdf',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _exportToCSV() async {
    setState(() => _isGenerating = true);

    try {
      // Fetch data
      final attendance = await _fetchAttendanceData();
      final users = await _fetchUsersMap();
      final projects = await _fetchProjectsMap();

      // Generate CSV
      final csv = _reportService.generateAttendanceCSV(
        attendance,
        users,
        projects,
      );

      // Save CSV
      final bytes = Uint8List.fromList(utf8.encode(csv));
      downloadFile(
        bytes,
        'attendance_report_${DateTime.now().millisecondsSinceEpoch}.csv',
        'text/csv',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<List<AttendanceModel>> _fetchAttendanceData() async {
    final firestoreService = ref.read(firestoreServiceProvider);
    
    // Fetch all attendance in date range
    final allAttendance = await firestoreService.getAttendanceByDateRange(
      _startDate,
      _endDate,
    );

    // Apply filters
    var filtered = allAttendance;

    if (_selectedProjectId != null) {
      filtered = filtered
          .where((a) => a.projectId == _selectedProjectId)
          .toList();
    }

    if (_selectedEmployeeId != null) {
      filtered = filtered
          .where((a) => a.userId == _selectedEmployeeId)
          .toList();
    }

    return filtered;
  }

  Future<Map<String, UserModel>> _fetchUsersMap() async {
    final firestoreService = ref.read(firestoreServiceProvider);
    final users = await firestoreService.getAllEmployees();
    return {for (var user in users) user.uid: user};
  }

  Future<Map<String, ProjectModel>> _fetchProjectsMap() async {
    final firestoreService = ref.read(firestoreServiceProvider);
    final projects = await firestoreService.getAllProjects();
    return {for (var project in projects) project.projectId: project};
  }
}

