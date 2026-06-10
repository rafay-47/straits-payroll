import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:straights_psyroll/shared/models/project_model.dart';
import 'package:straights_psyroll/shared/models/user_model.dart';
import 'package:straights_psyroll/shared/providers/auth_provider.dart';
import 'package:straights_psyroll/shared/providers/project_provider.dart';
import 'package:straights_psyroll/shared/constants/app_colors.dart';
import 'package:straights_psyroll/shared/constants/app_constants.dart';
import 'package:straights_psyroll/shared/services/qr_service.dart';
import '../employees/employee_management_screen.dart';
import 'widgets/qr_clipboard_helper_stub.dart'
    if (dart.library.html) 'widgets/qr_clipboard_helper_web.dart';

/// Web Admin Screen for Project Management
class ProjectManagementScreen extends ConsumerStatefulWidget {
  const ProjectManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProjectManagementScreen> createState() =>
      _ProjectManagementScreenState();
}

class _ProjectManagementScreenState
    extends ConsumerState<ProjectManagementScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(allProjectsProvider);
    final currentUserAsync = ref.watch(currentUserProvider);
    final isSupervisor = currentUserAsync.asData?.value?.isSupervisor ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Management'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with search and add button
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search projects...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                if (!isSupervisor)
                  ElevatedButton.icon(
                    onPressed: () => _showAddProjectDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Project'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Projects Table
            Expanded(
              child: projectsAsync.when(
                data: (projects) {
                  final currentUser = currentUserAsync.asData?.value;
                  final scopedProjects = _applyProjectScope(projects, currentUser);
                  final filteredProjects = scopedProjects.where((project) {
                    final nameMatch = project.name.toLowerCase().contains(_searchQuery);
                    final locationMatch = project.location?.address
                        .toLowerCase()
                        .contains(_searchQuery) ?? false;
                    return nameMatch || locationMatch;
                  }).toList();

                  if (filteredProjects.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.business_center_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No projects yet'
                                : 'No projects found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Card(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(
                            AppColors.primary.withOpacity(0.1),
                          ),
                          columns: const [
                            DataColumn(label: Text('Project Name')),
                            DataColumn(label: Text('Location')),
                            DataColumn(label: Text('Supervisor')),
                            DataColumn(label: Text('Employees')),
                            DataColumn(label: Text('Check-In Methods')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: filteredProjects.map((project) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        project.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                        Text(
                                          'ID: ${project.projectId}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 200,
                                    child: Text(
                                      project.location?.address ?? 'No location',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  project.supervisorId != null
                                      ? FutureBuilder<UserModel?>(
                                          future: ref
                                              .read(firestoreServiceProvider)
                                              .getUser(project.supervisorId!),
                                          builder: (context, snapshot) {
                                            if (snapshot.hasData &&
                                                snapshot.data != null) {
                                              return Text(snapshot.data!.name);
                                            }
                                            return const Text('Loading...');
                                          },
                                        )
                                      : const Text('Unassigned'),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 200,
                                    child: FutureBuilder<String>(
                                      future: _getEmployeeNames(project),
                                      builder: (context, snapshot) {
                                        return Text(
                                          snapshot.data ?? 'Loading...',
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Wrap(
                                    spacing: 4,
                                    children: [
                                      if (project.checkInMethods
                                          .contains('gps'))
                                        Chip(
                                          label: const Text('GPS'),
                                          labelStyle:
                                              const TextStyle(fontSize: 10),
                                          backgroundColor:
                                              Colors.green.withOpacity(0.2),
                                        ),
                                      if (project.checkInMethods
                                          .contains('nfc'))
                                        Chip(
                                          label: const Text('NFC'),
                                          labelStyle:
                                              const TextStyle(fontSize: 10),
                                          backgroundColor:
                                              Colors.blue.withOpacity(0.2),
                                        ),
                                      if (project.checkInMethods
                                          .contains('qr'))
                                        Chip(
                                          label: const Text('QR'),
                                          labelStyle:
                                              const TextStyle(fontSize: 10),
                                          backgroundColor:
                                              Colors.orange.withOpacity(0.2),
                                        ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Chip(
                                    label: Text(
                                      project.isActive ? 'Active' : 'Inactive',
                                    ),
                                    backgroundColor: project.isActive
                                        ? Colors.green.withOpacity(0.2)
                                        : Colors.red.withOpacity(0.2),
                                    labelStyle: TextStyle(
                                      color: project.isActive
                                          ? Colors.green[700]
                                          : Colors.red[700],
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: _canEditProject(project) ? () =>
                                            _showEditProjectDialog(
                                          context,
                                          project,
                                        ) : null,
                                        tooltip: 'Edit Project',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.people),
                                        onPressed: _canAssignEmployees(project) ? () =>
                                            _showAssignEmployeesDialog(
                                          context,
                                          project,
                                        ) : null,
                                        tooltip: 'Assign Employees',
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          project.isActive
                                              ? Icons.toggle_on
                                              : Icons.toggle_off,
                                          color: project.isActive
                                              ? Colors.green
                                              : Colors.grey,
                                        ),
                                        onPressed: _canEditProject(project) ? () =>
                                            _toggleProjectStatus(project)
                                            : null,
                                        tooltip: 'Toggle Status',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text('Error: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProjectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddEditProjectDialog(),
    );
  }

  void _showEditProjectDialog(BuildContext context, ProjectModel project) {
    showDialog(
      context: context,
      builder: (context) => AddEditProjectDialog(project: project),
    );
  }

  void _showAssignEmployeesDialog(BuildContext context, ProjectModel project) {
    showDialog(
      context: context,
      builder: (context) => AssignEmployeesDialog(project: project),
    );
  }

  Future<void> _toggleProjectStatus(ProjectModel project) async {
    if (!_canEditProject(project)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You do not have permission to change this project.')),
        );
      }
      return;
    }

    try {
      await ref.read(firestoreServiceProvider).updateProject(
            project.projectId,
            {'isActive': !project.isActive},
          );
      // Invalidate all project providers to refresh UI
      ref.invalidate(allProjectsProvider);
      ref.invalidate(activeProjectsProvider);
      ref.invalidate(employeeProjectsProvider);
      ref.invalidate(supervisorProjectsProvider);
      ref.invalidate(supervisorProjectProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Project ${project.isActive ? 'deactivated' : 'activated'}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  List<ProjectModel> _applyProjectScope(
    List<ProjectModel> projects,
    UserModel? currentUser,
  ) {
    if (currentUser == null) return projects;
    if (currentUser.role.toLowerCase() != 'supervisor') return projects;
    return projects.where((p) => p.supervisorId == currentUser.uid).toList();
  }

  /// Edit / toggle project status: admins only. Supervisors cannot
  /// create, edit, or change the status of a project; they can only
  /// assign employees to projects they own.
  bool _canEditProject(ProjectModel project) {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return false;
    if (currentUser.isSupervisor) return false;
    return true;
  }

  /// Assign employees: admins can assign to any project in the
  /// company; supervisors can only assign to projects they own.
  bool _canAssignEmployees(ProjectModel project) {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return false;
    if (currentUser.isSupervisor) {
      return project.supervisorId == currentUser.uid;
    }
    return true;
  }

  Future<String> _getEmployeeNames(ProjectModel project) async {
    final employeeIds = project.assignedEmployeeIds;
    if (employeeIds.isEmpty) return 'No employees';

    try {
      final names = <String>[];
      for (final employeeId in employeeIds) {
        final employee = await ref.read(firestoreServiceProvider).getUser(employeeId);
        if (employee != null) names.add(employee.name);
      }
      return names.isEmpty ? 'Unknown' : names.join(', ');
    } catch (e) {
      return 'Error loading';
    }
  }
}

/// Dialog for Adding/Editing Projects
class AddEditProjectDialog extends ConsumerStatefulWidget {
  final ProjectModel? project;

  const AddEditProjectDialog({Key? key, this.project}) : super(key: key);

  @override
  ConsumerState<AddEditProjectDialog> createState() =>
      _AddEditProjectDialogState();
}

class _AddEditProjectDialogState extends ConsumerState<AddEditProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _addressController;
  late TextEditingController _latController;
  late TextEditingController _lngController;
  late TextEditingController _radiusController;
  late TextEditingController _nfcTagIdController;
  String? _selectedSupervisorId;
  final List<String> _selectedMethods = [];
  String _checkInRequirement = AppConstants.checkInRequirementAnyOne;
  final List<String> _generatedQRCodes = [];
  bool _isLoading = false;
  final QRService _qrService = QRService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.project?.description ?? '');
    _addressController =
        TextEditingController(text: widget.project?.location?.address ?? '');
    _latController = TextEditingController(
      text: widget.project?.location?.latitude.toString() ?? '',
    );
    _lngController = TextEditingController(
      text: widget.project?.location?.longitude.toString() ?? '',
    );
    _radiusController = TextEditingController(
      text: widget.project?.location?.radiusInMeters.toString() ?? '200',
    );
    _nfcTagIdController = TextEditingController(
      text: widget.project?.nfcTagId ?? '',
    );
    _selectedSupervisorId = widget.project?.supervisorId;
    final existingCodes = widget.project?.qrCodes ?? const <String>[];
    if (existingCodes.isNotEmpty) {
      _generatedQRCodes.addAll(existingCodes);
    } else if (widget.project?.qrCode != null && widget.project!.qrCode!.isNotEmpty) {
      _generatedQRCodes.add(widget.project!.qrCode!);
    }
    if (widget.project != null) {
      _selectedMethods.addAll(widget.project!.checkInMethods);
      _checkInRequirement = widget.project!.checkInRequirement;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _radiusController.dispose();
    _nfcTagIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final supervisorsAsync = ref.watch(allSupervisorsProvider);

    return AlertDialog(
      title: Text(widget.project == null ? 'Add Project' : 'Edit Project'),
      content: SizedBox(
        width: 600,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Project Name *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter project name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                supervisorsAsync.when(
                  data: (supervisors) {
                    return DropdownButtonFormField<String>(
                      value: _selectedSupervisorId,
                      decoration: const InputDecoration(
                        labelText: 'Assign Supervisor *',
                        border: OutlineInputBorder(),
                      ),
                      items: supervisors.map((supervisor) {
                        return DropdownMenuItem(
                          value: supervisor.uid,
                          child: Text(supervisor.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSupervisorId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a supervisor';
                        }
                        return null;
                      },
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (error, stack) => Text('Error loading supervisors'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latController,
                        decoration: const InputDecoration(
                          labelText: 'Latitude *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Invalid';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _lngController,
                        decoration: const InputDecoration(
                          labelText: 'Longitude *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Invalid';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _radiusController,
                  decoration: const InputDecoration(
                    labelText: 'Check-in Radius (meters) *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter radius';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Invalid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Check-In Requirement *',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _checkInRequirement,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: AppConstants.checkInRequirementAnyOne,
                      child: Text('Any One Method'),
                    ),
                    DropdownMenuItem(
                      value: AppConstants.checkInRequirementAllEnabled,
                      child: Text('All Enabled Methods'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _checkInRequirement = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                const Text('Allowed Check-In Methods *',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                CheckboxListTile(
                  title: const Text('GPS Location'),
                  value: _selectedMethods.contains('gps'),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedMethods.add('gps');
                      } else {
                        _selectedMethods.remove('gps');
                      }
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('NFC Tag'),
                  value: _selectedMethods.contains('nfc'),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedMethods.add('nfc');
                      } else {
                        _selectedMethods.remove('nfc');
                        _nfcTagIdController.clear();
                      }
                    });
                  },
                ),
                // NFC Tag ID input (shown when NFC is enabled)
                if (_selectedMethods.contains('nfc')) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _nfcTagIdController,
                          decoration: InputDecoration(
                            labelText: 'NFC Tag ID (Optional)',
                            hintText: 'Enter NFC tag ID or leave empty to accept any tag',
                            border: const OutlineInputBorder(),
                            helperText: 'If left empty, any NFC tag will be accepted',
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('NFC Tag Setup'),
                                content: const Text(
                                  'To configure NFC check-in:\n\n'
                                  '1. Scan an NFC tag with your phone\n'
                                  '2. Copy the tag ID shown\n'
                                  '3. Paste it in the NFC Tag ID field above\n\n'
                                  'If you leave it empty, any NFC tag will work for check-in.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Got it'),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.info_outline, size: 16),
                          label: const Text('How to get NFC Tag ID?'),
                        ),
                      ],
                    ),
                  ),
                ],
                CheckboxListTile(
                  title: const Text('QR Code'),
                  value: _selectedMethods.contains('qr'),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedMethods.add('qr');
                        // Auto-generate QR code if not exists
                        if (_generatedQRCodes.isEmpty && widget.project != null) {
                          _generateQRCode();
                        }
                      } else {
                        _selectedMethods.remove('qr');
                        _generatedQRCodes.clear();
                      }
                    });
                  },
                ),
                // QR Code generation and display (shown when QR is enabled)
                if (_selectedMethods.contains('qr')) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_generatedQRCodes.isEmpty)
                          ElevatedButton.icon(
                            onPressed: widget.project == null
                                ? null // Disable for new projects - QR will be auto-generated after creation
                                : _generateQRCode, // Enable for editing existing projects
                            icon: const Icon(Icons.qr_code),
                            label: Text(
                              widget.project == null
                                  ? 'QR Code will be auto-generated'
                                  : 'Generate QR Code',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                          )
                        else ...[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: ElevatedButton.icon(
                              onPressed: _generateQRCode,
                              icon: const Icon(Icons.add),
                              label: const Text('Generate Another QR'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          for (int index = _generatedQRCodes.length - 1; index >= 0; index--) ...[
                            _buildQRCodeCard(_generatedQRCodes[index], index + 1),
                            if (index != 0) const SizedBox(height: 12),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            'Active QR Codes: ${_generatedQRCodes.length}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSubmit,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.project == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMethods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one check-in method'),
        ),
      );
      return;
    }

    if (_checkInRequirement == AppConstants.checkInRequirementAllEnabled &&
        _selectedMethods.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All enabled methods requires at least 2 check-in methods'),
        ),
      );
      return;
    }

    if (_checkInRequirement == AppConstants.checkInRequirementAllEnabled &&
        _selectedMethods.contains(AppConstants.checkInMethodManual)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Manual method is only supported with "Any One Method" mode'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? projectId = widget.project?.projectId;
      String? oldSupervisorId = widget.project?.supervisorId;
      
      // Generate QR code if QR is enabled but not generated yet
      if (_selectedMethods.contains('qr') && _generatedQRCodes.isEmpty) {
        if (projectId != null) {
          _generateQRCodeWithProjectId(projectId);
        }
        // For new projects, QR will be generated after project creation
      }

      final projectData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'supervisorId': _selectedSupervisorId,
        'location': {
          'address': _addressController.text.trim(),
          'latitude': double.parse(_latController.text),
          'longitude': double.parse(_lngController.text),
          'radiusInMeters': double.parse(_radiusController.text),
        },
        'checkInMethods': _selectedMethods,
        'checkInRequirement': _checkInRequirement,
        'nfcTagId': _selectedMethods.contains('nfc') && _nfcTagIdController.text.trim().isNotEmpty
            ? _nfcTagIdController.text.trim()
            : null,
        'qrCode': _selectedMethods.contains('qr') && _generatedQRCodes.isNotEmpty
            ? _generatedQRCodes.last
            : null,
        'qrCodes': _selectedMethods.contains('qr') ? _generatedQRCodes : <String>[],
        'updatedAt': DateTime.now().toIso8601String(),
      };

      print('');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('💾 SAVING PROJECT CHECK-IN METHODS');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('Selected methods: $_selectedMethods');
      print('NFC Tag ID: ${projectData['nfcTagId'] ?? 'None'}');
      print('QR Codes: ${_generatedQRCodes.length}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('');
      
      if (widget.project == null) {
        // Add new project
        projectData['createdAt'] = DateTime.now().toIso8601String();
        projectData['isActive'] = true;
        projectData['assignedEmployeeIds'] = [];
        
        // IMPORTANT: For new projects, DO NOT include QR code yet
        // We'll generate it AFTER we have the actual project ID
        final qrCodeNeeded = _selectedMethods.contains('qr');
        if (qrCodeNeeded) {
          projectData['qrCode'] = null; // Temporarily null
          projectData['qrCodes'] = <String>[]; // Temporarily empty
        }
        
        await ref.read(firestoreServiceProvider).createProjectFromMap(projectData);
        // Get the projectId from the created project
        final createdProjectId = projectData['projectId'] as String?;
        
        print('✅ Project created with ID: $createdProjectId');
        
        // NOW generate QR code with actual project ID if QR is enabled
        if (qrCodeNeeded && createdProjectId != null) {
          _generateQRCodeWithProjectId(createdProjectId);
          
          print('✅ Generated QR Code: ${_generatedQRCodes.isNotEmpty ? _generatedQRCodes.last : "None"}');
          print('   Project ID in QR: $createdProjectId');
          
          // Update project with correct QR code
          await ref.read(firestoreServiceProvider).updateProject(
            createdProjectId,
            {
              'qrCode': _generatedQRCodes.isNotEmpty ? _generatedQRCodes.last : null,
              'qrCodes': _generatedQRCodes,
            },
          );
          
          print('✅ QR Code saved to project');
        }
        projectId = createdProjectId;
      } else {
        // Update existing project
        projectId = widget.project!.projectId;
        await ref.read(firestoreServiceProvider).updateProject(
              projectId,
              projectData,
            );
      }

      // Update supervisor assignment
      if (projectId != null &&
          _selectedSupervisorId != null &&
          _selectedSupervisorId != oldSupervisorId) {
        // If changing supervisors, remove old supervisor's assignment
        if (oldSupervisorId != null) {
          print('🔄 Removing project from old supervisor: $oldSupervisorId');
          await ref.read(firestoreServiceProvider).updateUser(
            oldSupervisorId,
            {
              'assignedProjectIds': FieldValue.arrayRemove([projectId]),
            },
          ).catchError((e) {
            print('⚠️ Could not update old supervisor (may be deleted): $e');
          });
        }
        
        // Assign project to new supervisor
        print('✅ Assigning project $projectId to supervisor: $_selectedSupervisorId');
        await ref.read(firestoreServiceProvider).updateUser(
          _selectedSupervisorId!,
          {
            'assignedProjectIds': FieldValue.arrayUnion([projectId]),
          },
        );
        print('✅ Supervisor assignment complete!');
      }

      // Invalidate all project providers to refresh dropdowns
      ref.invalidate(allProjectsProvider);
      ref.invalidate(activeProjectsProvider);
      ref.invalidate(employeeProjectsProvider);
      ref.invalidate(supervisorProjectsProvider);
      ref.invalidate(supervisorProjectProvider);
      ref.invalidate(allUsersProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.project == null
                  ? 'Project added successfully'
                  : 'Project updated successfully',
            ),
          ),
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
        setState(() => _isLoading = false);
      }
    }
  }

  void _generateQRCode() {
    final projectId = widget.project?.projectId ?? 'temp-${DateTime.now().millisecondsSinceEpoch}';
    _generateQRCodeWithProjectId(projectId);
  }

  void _generateQRCodeWithProjectId(String projectId) {
    final projectName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : 'Project';
    
    setState(() {
      _generatedQRCodes.add(_qrService.generateProjectQRCode(
        projectId: projectId,
        projectName: projectName,
      ));
    });
  }

  Widget _buildQRCodeCard(String qrData, int qrNumber) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _qrService.generateQRCodeWidget(
            data: qrData,
            size: 200,
          ),
          const SizedBox(height: 12),
          Text(
            'QR Code #$qrNumber',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            qrData,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
              fontFamily: 'monospace',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton.icon(
                onPressed: () => _copyQRData(qrData),
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy QR Data'),
              ),
              TextButton.icon(
                onPressed: () => _copyQRImageToClipboard(qrData),
                icon: const Icon(Icons.image, size: 16),
                label: const Text('Copy QR Image'),
              ),
              TextButton.icon(
                onPressed: () => _downloadQRImage(qrData),
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Download PNG'),
              ),
              TextButton.icon(
                onPressed: () => _removeQRCode(qrData),
                icon: const Icon(Icons.block, size: 16),
                label: const Text('Deactivate'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _copyQRData(String qrData) {
    Clipboard.setData(ClipboardData(text: qrData));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR data copied. Use "Download PNG" to share QR image.'),
      ),
    );
  }

  void _removeQRCode(String qrData) {
    setState(() {
      _generatedQRCodes.remove(qrData);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR code deactivated. Remember to save the project.'),
      ),
    );
  }

  Future<Uint8List?> _buildQRPngBytes(String data) async {
    try {
      final painter = QrPainter(
        data: data,
        version: QrVersions.auto,
        gapless: false,
        color: Colors.black,
        emptyColor: Colors.white,
      );
      final imageData = await painter.toImageData(
        1024,
        format: ui.ImageByteFormat.png,
      );
      return imageData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<void> _copyQRImageToClipboard(String qrData) async {
    final bytes = await _buildQRPngBytes(qrData);
    if (bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to render QR image')),
        );
      }
      return;
    }

    final copied = await copyImageToClipboard(bytes);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          copied
              ? 'QR image copied to clipboard'
              : 'Clipboard image copy blocked by browser. Use Download PNG.',
        ),
      ),
    );
  }

  Future<void> _downloadQRImage(String qrData) async {
    final bytes = await _buildQRPngBytes(qrData);
    if (bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to render QR image')),
        );
      }
      return;
    }

    final filename =
        'project-qr-${widget.project?.projectId ?? DateTime.now().millisecondsSinceEpoch}.png';
    try {
      downloadPng(bytes, filename);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR image download started')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download is only supported on web')),
        );
      }
    }
  }
}

/// Dialog for Assigning Employees to a Project
class AssignEmployeesDialog extends ConsumerStatefulWidget {
  final ProjectModel project;

  const AssignEmployeesDialog({Key? key, required this.project})
      : super(key: key);

  @override
  ConsumerState<AssignEmployeesDialog> createState() =>
      _AssignEmployeesDialogState();
}

class _AssignEmployeesDialogState extends ConsumerState<AssignEmployeesDialog> {
  final List<String> _selectedEmployeeIds = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedEmployeeIds.addAll(widget.project.assignedEmployeeIds);
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(allApprovedEmployeesProvider);

    return AlertDialog(
      title: Text('Assign Employees - ${widget.project.name}'),
      content: SizedBox(
        width: 500,
        height: 400,
        child: employeesAsync.when(
          data: (employees) {
            if (employees.isEmpty) {
              return const Center(
                child: Text('No approved employees available'),
              );
            }

            return ListView.builder(
              itemCount: employees.length,
              itemBuilder: (context, index) {
                final employee = employees[index];
                final isAssigned =
                    _selectedEmployeeIds.contains(employee.uid);

                return CheckboxListTile(
                  title: Text(employee.name),
                  subtitle: Text(
                    'ID: ${employee.systemGeneratedId ?? employee.customId ?? "N/A"}',
                  ),
                  value: isAssigned,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedEmployeeIds.add(employee.uid);
                      } else {
                        _selectedEmployeeIds.remove(employee.uid);
                      }
                    });
                  },
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleAssign,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _handleAssign() async {
    setState(() => _isLoading = true);

    try {
      final previousEmployeeIds = widget.project.assignedEmployeeIds.toSet();
      final currentEmployeeIds = _selectedEmployeeIds.toSet();
      final removedEmployeeIds = previousEmployeeIds.difference(currentEmployeeIds);
      final addedEmployeeIds = currentEmployeeIds.difference(previousEmployeeIds);

      await ref.read(firestoreServiceProvider).updateProject(
        widget.project.projectId,
        {'assignedEmployeeIds': _selectedEmployeeIds},
      );

      for (final employeeId in addedEmployeeIds) {
        await ref.read(firestoreServiceProvider).addEmployeeToProjectAssignedList(
          widget.project.projectId,
          employeeId,
        );
        await ref.read(firestoreServiceProvider).updateUser(
          employeeId,
          {
            'assignedProjectIds': FieldValue.arrayUnion([widget.project.projectId]),
            'assignedProjectId': widget.project.projectId,
          },
        );
      }

      for (final employeeId in removedEmployeeIds) {
        await ref.read(firestoreServiceProvider).removeEmployeeFromProjectAssignedList(
          widget.project.projectId,
          employeeId,
        );
        await ref.read(firestoreServiceProvider).updateUser(
          employeeId,
          {
            'assignedProjectIds': FieldValue.arrayRemove([widget.project.projectId]),
            'assignedProjectId': null,
          },
        );
      }

      // Invalidate all project providers to refresh UI
      ref.invalidate(allProjectsProvider);
      ref.invalidate(activeProjectsProvider);
      ref.invalidate(employeeProjectsProvider);
      ref.invalidate(supervisorProjectsProvider);
      ref.invalidate(supervisorProjectProvider);
      ref.invalidate(allUsersProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Employees assigned successfully')),
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
        setState(() => _isLoading = false);
      }
    }
  }
}

