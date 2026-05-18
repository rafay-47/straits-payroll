import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:straights_psyroll/shared/models/attendance_model.dart';
import 'package:straights_psyroll/shared/models/user_model.dart';
import 'package:straights_psyroll/shared/providers/auth_provider.dart';
import 'package:straights_psyroll/web/screens/reports/services/report_service.dart';

// Conditional import for web-only functionality
import 'download_helper_stub.dart'
    if (dart.library.html) 'download_helper_web.dart';

/// Widget for generating and exporting employee performance reports
class EmployeeReportWidget extends ConsumerStatefulWidget {
  const EmployeeReportWidget({Key? key}) : super(key: key);

  @override
  ConsumerState<EmployeeReportWidget> createState() =>
      _EmployeeReportWidgetState();
}

class _EmployeeReportWidgetState extends ConsumerState<EmployeeReportWidget> {
  bool _isGenerating = false;
  bool _includeInactive = false;

  final _reportService = ReportService();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Employee Performance Report',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Generate comprehensive employee attendance and performance reports',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),

          // Options Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Report Options',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Include Inactive Employees'),
                    value: _includeInactive,
                    onChanged: (value) {
                      setState(() => _includeInactive = value ?? false);
                    },
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToPDF() async {
    setState(() => _isGenerating = true);

    try {
      final employees = await _fetchEmployees();
      final employeeAttendance = await _fetchEmployeeAttendance(employees);

      final pdf = await _reportService.generateEmployeePDF(
        employees,
        employeeAttendance,
      );

      final bytes = await pdf.save();
      downloadFile(
        bytes,
        'employee_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
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
      final employees = await _fetchEmployees();
      final employeeAttendance = await _fetchEmployeeAttendance(employees);

      final csv = _reportService.generateEmployeeCSV(
        employees,
        employeeAttendance,
      );

      final bytes = Uint8List.fromList(utf8.encode(csv));
      downloadFile(
        bytes,
        'employee_report_${DateTime.now().millisecondsSinceEpoch}.csv',
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

  Future<List<UserModel>> _fetchEmployees() async {
    final firestoreService = ref.read(firestoreServiceProvider);
    final allEmployees = await firestoreService.getAllEmployees();

    if (_includeInactive) {
      return allEmployees;
    } else {
      return allEmployees
          .where((e) => e.status == 'approved' || e.status == 'active')
          .toList();
    }
  }

  Future<Map<String, List<AttendanceModel>>> _fetchEmployeeAttendance(
      List<UserModel> employees) async {
    final firestoreService = ref.read(firestoreServiceProvider);
    final Map<String, List<AttendanceModel>> result = {};

    for (final employee in employees) {
      final attendance =
          await firestoreService.getAttendanceByUser(employee.uid);
      result[employee.uid] = attendance;
    }

    return result;
  }
}

