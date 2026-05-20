import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:straights_psyroll/shared/models/attendance_model.dart';
import 'package:straights_psyroll/shared/models/project_model.dart';
import 'package:straights_psyroll/shared/models/user_model.dart';

/// Service for generating reports in various formats
class ReportService {
  /// Generate attendance report as CSV
  String generateAttendanceCSV(List<AttendanceModel> attendanceList,
      Map<String, UserModel> users, Map<String, ProjectModel> projects) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln(
        'Employee ID,Employee Name,Project,Check-In Method,Check-In Time,Check-In Location,Check-Out Time,Check-Out Location,Duration (Hours),Device Info');

    // Data rows
    for (final attendance in attendanceList) {
      final user = users[attendance.userId];
      final project = projects[attendance.projectId];

      final employeeId = user?.systemGeneratedId ?? user?.customId ?? 'N/A';
      final employeeName = user?.name ?? 'Unknown';
      final projectName = project?.name ?? 'Unknown';
      final checkInMethod = attendance.checkInMethod.toUpperCase();
      final checkInTime = _formatDateTime(attendance.checkInTime);
      final checkInLocation = attendance.checkInLocation;
      final checkOutTime = attendance.checkOutTime != null
          ? _formatDateTime(attendance.checkOutTime!)
          : 'Not checked out';
      final checkOutLocation = attendance.checkOutLocation;
      final duration = (attendance.workingHours ?? 0).toStringAsFixed(2);
      final deviceInfo = attendance.deviceInfo?.deviceModel ?? '-';

      buffer.writeln(
          '"$employeeId","$employeeName","$projectName","$checkInMethod","$checkInTime","$checkInLocation","$checkOutTime","$checkOutLocation","$duration","$deviceInfo"');
    }

    return buffer.toString();
  }

  /// Generate attendance report as PDF
  Future<pw.Document> generateAttendancePDF(
    List<AttendanceModel> attendanceList,
    Map<String, UserModel> users,
    Map<String, ProjectModel> projects,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final pdf = pw.Document();

    // Group attendance by employee
    final Map<String, List<AttendanceModel>> attendanceByEmployee = {};
    for (final attendance in attendanceList) {
      attendanceByEmployee.putIfAbsent(attendance.userId, () => []);
      attendanceByEmployee[attendance.userId]!.add(attendance);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Attendance Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Period: ${_formatDate(startDate)} to ${_formatDate(endDate)}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.Text(
                  'Generated: ${_formatDateTime(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.Divider(thickness: 2),
              ],
            ),
          ),

          // Summary
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey300,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                    'Total Records', attendanceList.length.toString()),
                _buildSummaryItem(
                    'Employees', attendanceByEmployee.length.toString()),
                _buildSummaryItem(
                  'Total Hours',
                  attendanceList
                      .fold<double>(0, (sum, a) => sum + (a.workingHours ?? 0))
                      .toStringAsFixed(2),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Data Table
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(1.5),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(1),
              4: const pw.FlexColumnWidth(1.5),
              5: const pw.FlexColumnWidth(1.5),
              6: const pw.FlexColumnWidth(0.8),
            },
            children: [
              // Header row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _buildTableCell('Employee ID', isHeader: true),
                  _buildTableCell('Name', isHeader: true),
                  _buildTableCell('Project', isHeader: true),
                  _buildTableCell('Method', isHeader: true),
                  _buildTableCell('Check-In', isHeader: true),
                  _buildTableCell('Check-Out', isHeader: true),
                  _buildTableCell('Hours', isHeader: true),
                ],
              ),
              // Data rows
              ...attendanceList.map((attendance) {
                final user = users[attendance.userId];
                final project = projects[attendance.projectId];

                return pw.TableRow(
                  children: [
                    _buildTableCell(
                        user?.systemGeneratedId ?? user?.customId ?? 'N/A'),
                    _buildTableCell(user?.name ?? 'Unknown'),
                    _buildTableCell(project?.name ?? 'Unknown'),
                    _buildTableCell(attendance.checkInMethod.toUpperCase()),
                    _buildTableCell(_formatDateTime(attendance.checkInTime)),
                    _buildTableCell(attendance.checkOutTime != null
                        ? _formatDateTime(attendance.checkOutTime!)
                        : 'Pending'),
                    _buildTableCell((attendance.workingHours ?? 0).toStringAsFixed(1)),
                  ],
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );

    return pdf;
  }

  /// Generate project report as CSV
  String generateProjectCSV(List<ProjectModel> projects,
      Map<String, List<AttendanceModel>> projectAttendance,
      Map<String, UserModel> users) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln(
        'Project ID,Project Name,Location,Supervisor,Assigned Employees,Check-In Methods,Total Check-Ins,Total Hours,Status');

    // Data rows
    for (final project in projects) {
      final attendance = projectAttendance[project.projectId] ?? [];
      final totalCheckIns = attendance.length;
      final totalHours =
          attendance.fold<double>(0, (sum, a) => sum + (a.workingHours ?? 0));
      final supervisor = users[project.supervisorId];

      buffer.writeln(
          '"${project.projectId}","${project.name}","${project.location!.address}","${supervisor?.name ?? "Unknown"}","${project.assignedEmployeeIds.length}","${project.checkInMethods.join(", ")}","$totalCheckIns","${totalHours.toStringAsFixed(2)}","${project.isActive ? "Active" : "Inactive"}"');
    }

    return buffer.toString();
  }

  /// Generate project report as PDF
  Future<pw.Document> generateProjectPDF(
    List<ProjectModel> projects,
    Map<String, List<AttendanceModel>> projectAttendance,
    Map<String, UserModel> users,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Project Summary Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Generated: ${_formatDateTime(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.Divider(thickness: 2),
              ],
            ),
          ),

          // Summary
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey300,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('Total Projects', projects.length.toString()),
                _buildSummaryItem(
                  'Active Projects',
                  projects.where((p) => p.isActive).length.toString(),
                ),
                _buildSummaryItem(
                  'Total Employees',
                  projects
                      .fold<Set<String>>(
                        <String>{},
                        (set, p) => set..addAll(p.assignedEmployeeIds),
                      )
                      .length
                      .toString(),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Projects Table
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(1.5),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1),
              4: const pw.FlexColumnWidth(1),
              5: const pw.FlexColumnWidth(0.8),
            },
            children: [
              // Header row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _buildTableCell('Project Name', isHeader: true),
                  _buildTableCell('Supervisor', isHeader: true),
                  _buildTableCell('Employees', isHeader: true),
                  _buildTableCell('Check-Ins', isHeader: true),
                  _buildTableCell('Total Hours', isHeader: true),
                  _buildTableCell('Status', isHeader: true),
                ],
              ),
              // Data rows
              ...projects.map((project) {
                final attendance = projectAttendance[project.projectId] ?? [];
                final totalHours =
                    attendance.fold<double>(0, (sum, a) => sum + (a.workingHours ?? 0));
                final supervisor = users[project.supervisorId];

                return pw.TableRow(
                  children: [
                    _buildTableCell(project.name),
                    _buildTableCell(supervisor?.name ?? 'Unknown'),
                    _buildTableCell(project.assignedEmployeeIds.length.toString()),
                    _buildTableCell(attendance.length.toString()),
                    _buildTableCell(totalHours.toStringAsFixed(1)),
                    _buildTableCell(project.isActive ? 'Active' : 'Inactive'),
                  ],
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );

    return pdf;
  }

  /// Generate employee report as CSV
  String generateEmployeeCSV(
    List<UserModel> employees,
    Map<String, List<AttendanceModel>> employeeAttendance,
  ) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln(
        'Employee ID,Employee Name,Email,Phone,Status,Total Check-Ins,Total Hours,Avg Hours/Day,Last Check-In');

    // Data rows
    for (final employee in employees) {
      final attendance = employeeAttendance[employee.uid] ?? [];
      final totalHours =
          attendance.fold<double>(0, (sum, a) => sum + (a.workingHours ?? 0));
      
      // Calculate unique days
      final uniqueDays = attendance
          .map((a) => DateTime(
                a.checkInTime.year,
                a.checkInTime.month,
                a.checkInTime.day,
              ))
          .toSet()
          .length;
      
      final avgHoursPerDay = uniqueDays > 0 ? totalHours / uniqueDays : 0;
      final lastCheckIn = attendance.isNotEmpty
          ? _formatDateTime(attendance.first.checkInTime)
          : 'Never';

      buffer.writeln(
          '"${employee.systemGeneratedId ?? employee.customId ?? "N/A"}","${employee.name}","${employee.email}","${employee.phoneNumber ?? "N/A"}","${employee.status}","${attendance.length}","${totalHours.toStringAsFixed(2)}","${avgHoursPerDay.toStringAsFixed(2)}","$lastCheckIn"');
    }

    return buffer.toString();
  }

  /// Generate employee report as PDF
  Future<pw.Document> generateEmployeePDF(
    List<UserModel> employees,
    Map<String, List<AttendanceModel>> employeeAttendance,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Employee Performance Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Generated: ${_formatDateTime(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.Divider(thickness: 2),
              ],
            ),
          ),

          // Summary
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey300,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('Total Employees', employees.length.toString()),
                _buildSummaryItem(
                  'Active',
                  employees
                      .where(
                        (e) =>
                            e.status.toLowerCase() == 'approved' ||
                            e.status.toLowerCase() == 'active',
                      )
                      .length
                      .toString(),
                ),
                _buildSummaryItem(
                  'Total Hours',
                  employeeAttendance.values
                      .expand((list) => list)
                      .fold<double>(0, (sum, a) => sum + (a.workingHours ?? 0))
                      .toStringAsFixed(2),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Employees Table
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1),
              4: const pw.FlexColumnWidth(1),
              5: const pw.FlexColumnWidth(1),
            },
            children: [
              // Header row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _buildTableCell('ID', isHeader: true),
                  _buildTableCell('Name', isHeader: true),
                  _buildTableCell('Status', isHeader: true),
                  _buildTableCell('Check-Ins', isHeader: true),
                  _buildTableCell('Total Hours', isHeader: true),
                  _buildTableCell('Avg/Day', isHeader: true),
                ],
              ),
              // Data rows
              ...employees.map((employee) {
                final attendance = employeeAttendance[employee.uid] ?? [];
                final totalHours =
                    attendance.fold<double>(0, (sum, a) => sum + (a.workingHours ?? 0));
                
                final uniqueDays = attendance
                    .map((a) => DateTime(
                          a.checkInTime.year,
                          a.checkInTime.month,
                          a.checkInTime.day,
                        ))
                    .toSet()
                    .length;
                
                final avgHoursPerDay = uniqueDays > 0 ? totalHours / uniqueDays : 0;

                return pw.TableRow(
                  children: [
                    _buildTableCell(
                        employee.systemGeneratedId ?? employee.customId ?? 'N/A'),
                    _buildTableCell(employee.name),
                    _buildTableCell(employee.status.toUpperCase()),
                    _buildTableCell(attendance.length.toString()),
                    _buildTableCell(totalHours.toStringAsFixed(1)),
                    _buildTableCell(avgHoursPerDay.toStringAsFixed(1)),
                  ],
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );

    return pdf;
  }

  // Helper methods
  pw.Widget _buildSummaryItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

