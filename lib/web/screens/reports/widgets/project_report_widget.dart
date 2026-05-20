import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:straights_psyroll/shared/models/attendance_model.dart';
import 'package:straights_psyroll/shared/models/user_model.dart';
import 'package:straights_psyroll/shared/models/project_model.dart';
import 'package:straights_psyroll/shared/providers/auth_provider.dart';
import 'package:straights_psyroll/web/screens/reports/services/report_service.dart';

// Conditional import for web-only functionality
import 'download_helper_stub.dart'
    if (dart.library.html) 'download_helper_web.dart';

/// Widget for generating and exporting project reports
class ProjectReportWidget extends ConsumerStatefulWidget {
  const ProjectReportWidget({Key? key}) : super(key: key);

  @override
  ConsumerState<ProjectReportWidget> createState() =>
      _ProjectReportWidgetState();
}

class _ProjectReportWidgetState extends ConsumerState<ProjectReportWidget> {
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
            'Project Summary Report',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Generate comprehensive project performance reports',
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
                    title: const Text('Include Inactive Projects'),
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
      final projects = await _fetchProjects();
      final projectAttendance = await _fetchProjectAttendance(projects);
      final users = await _fetchUsersMap();

      final pdf = await _reportService.generateProjectPDF(
        projects,
        projectAttendance,
        users,
      );

      final bytes = await pdf.save();
      downloadFile(
        bytes,
        'project_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
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
      final projects = await _fetchProjects();
      final projectAttendance = await _fetchProjectAttendance(projects);
      final users = await _fetchUsersMap();

      final csv = _reportService.generateProjectCSV(
        projects,
        projectAttendance,
        users,
      );

      final bytes = Uint8List.fromList(utf8.encode(csv));
      downloadFile(
        bytes,
        'project_report_${DateTime.now().millisecondsSinceEpoch}.csv',
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

  Future<List<ProjectModel>> _fetchProjects() async {
    final firestoreService = ref.read(firestoreServiceProvider);
    final allProjects = await firestoreService.getAllProjects();

    if (_includeInactive) {
      return allProjects;
    } else {
      return allProjects.where((p) => p.isActive).toList();
    }
  }

  Future<Map<String, List<AttendanceModel>>> _fetchProjectAttendance(
      List<ProjectModel> projects) async {
    final firestoreService = ref.read(firestoreServiceProvider);
    final Map<String, List<AttendanceModel>> result = {};

    for (final project in projects) {
      final attendance =
          await firestoreService.getAttendanceByProject(project.projectId);
      result[project.projectId] = attendance;
    }

    return result;
  }

  Future<Map<String, UserModel>> _fetchUsersMap() async {
    final firestoreService = ref.read(firestoreServiceProvider);
    final users = await firestoreService.getAllUsers();
    return {for (var user in users) user.uid: user};
  }
}

