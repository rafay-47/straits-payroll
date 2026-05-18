import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:straights_psyroll/shared/constants/app_colors.dart';
import 'package:straights_psyroll/shared/providers/auth_provider.dart';
import 'package:straights_psyroll/shared/models/audit_log_model.dart';

/// Provider for system settings
final systemSettingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final firestoreService = ref.read(firestoreServiceProvider);
  final settings = await firestoreService.getSystemSettings();
  return settings ?? {
    'maxCheckInsPerDay': 2,
    'maxCheckOutsPerDay': 2,
    'defaultCheckInRadiusMeters': 200,
    'maxDeviceResetsPerMonth': 1,
  };
});

/// Provider for audit logs
final auditLogsProvider = StreamProvider<List<AuditLogModel>>((ref) {
  final firestoreService = ref.read(firestoreServiceProvider);
  return firestoreService.getAuditLogsStream(limit: 50);
});

/// Web Admin Screen for System Settings
class SystemSettingsScreen extends ConsumerStatefulWidget {
  const SystemSettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SystemSettingsScreen> createState() =>
      _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends ConsumerState<SystemSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        title: const Text('System Settings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'General Settings'),
            Tab(text: 'Audit Logs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          GeneralSettingsTab(),
          AuditLogsTab(),
        ],
      ),
    );
  }
}

/// General Settings Tab
class GeneralSettingsTab extends ConsumerStatefulWidget {
  const GeneralSettingsTab({Key? key}) : super(key: key);

  @override
  ConsumerState<GeneralSettingsTab> createState() =>
      _GeneralSettingsTabState();
}

class _GeneralSettingsTabState extends ConsumerState<GeneralSettingsTab> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _maxCheckInsController;
  late TextEditingController _maxCheckOutsController;
  late TextEditingController _defaultRadiusController;
  late TextEditingController _maxDeviceResetsController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _maxCheckInsController = TextEditingController(text: '2');
    _maxCheckOutsController = TextEditingController(text: '2');
    _defaultRadiusController = TextEditingController(text: '200');
    _maxDeviceResetsController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _maxCheckInsController.dispose();
    _maxCheckOutsController.dispose();
    _defaultRadiusController.dispose();
    _maxDeviceResetsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(systemSettingsProvider);

    return settingsAsync.when(
      data: (settings) {
        // Update controllers with fetched values
        if (settings.isNotEmpty) {
          _maxCheckInsController.text =
              settings['maxCheckInsPerDay']?.toString() ?? '2';
          _maxCheckOutsController.text =
              settings['maxCheckOutsPerDay']?.toString() ?? '2';
          _defaultRadiusController.text =
              settings['defaultCheckInRadiusMeters']?.toString() ?? '200';
          _maxDeviceResetsController.text =
              settings['maxDeviceResetsPerMonth']?.toString() ?? '1';
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Attendance Settings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _maxCheckInsController,
                          decoration: const InputDecoration(
                            labelText: 'Max Check-Ins Per Day Per Project',
                            border: OutlineInputBorder(),
                            helperText:
                                'Maximum number of times an employee can check-in to a project per day',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a value';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Invalid number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _maxCheckOutsController,
                          decoration: const InputDecoration(
                            labelText: 'Max Check-Outs Per Day Per Project',
                            border: OutlineInputBorder(),
                            helperText:
                                'Maximum number of times an employee can check-out from a project per day',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a value';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Invalid number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _defaultRadiusController,
                          decoration: const InputDecoration(
                            labelText: 'Default Check-In Radius (meters)',
                            border: OutlineInputBorder(),
                            helperText:
                                'Default radius for GPS-based check-ins',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a value';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Invalid number';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Device Settings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextFormField(
                      controller: _maxDeviceResetsController,
                      decoration: const InputDecoration(
                        labelText: 'Max Device Resets Per Month',
                        border: OutlineInputBorder(),
                        helperText:
                            'Maximum number of device resets allowed per employee per month',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a value';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save Settings',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading settings: $error'),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final settingsData = {
        'maxCheckInsPerDay': int.parse(_maxCheckInsController.text),
        'maxCheckOutsPerDay': int.parse(_maxCheckOutsController.text),
        'defaultCheckInRadiusMeters': int.parse(_defaultRadiusController.text),
        'maxDeviceResetsPerMonth': int.parse(_maxDeviceResetsController.text),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await ref
          .read(firestoreServiceProvider)
          .updateSystemSettings(settingsData);

      ref.invalidate(systemSettingsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
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

/// Audit Logs Tab
class AuditLogsTab extends ConsumerWidget {
  const AuditLogsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(auditLogsProvider);

    return logsAsync.when(
      data: (logs) {
        if (logs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No audit logs yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(
                    AppColors.primary.withOpacity(0.1),
                  ),
                  columns: const [
                    DataColumn(label: Text('Timestamp')),
                    DataColumn(label: Text('Action')),
                    DataColumn(label: Text('User')),
                    DataColumn(label: Text('Target')),
                    DataColumn(label: Text('Details')),
                  ],
                  rows: logs.map((log) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(_formatDateTime(log.timestamp)),
                        ),
                        DataCell(
                          Chip(
                            label: Text(log.action),
                            backgroundColor: _getActionColor(log.action),
                          ),
                        ),
                        DataCell(
                          FutureBuilder<String>(
                            future: _getUserName(ref, log.userId),
                            builder: (context, snapshot) {
                              return Text(snapshot.data ?? 'Loading...');
                            },
                          ),
                        ),
                        DataCell(
                          Text(log.entityType),
                        ),
                        DataCell(
                          SizedBox(
                            width: 300,
                            child: Text(
                              log.details?.toString() ?? '-',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading audit logs: $error'),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Color _getActionColor(String action) {
    switch (action.toLowerCase()) {
      case 'create':
      case 'approve':
        return Colors.green.withOpacity(0.2);
      case 'update':
      case 'edit':
        return Colors.blue.withOpacity(0.2);
      case 'delete':
      case 'reject':
        return Colors.red.withOpacity(0.2);
      default:
        return Colors.grey.withOpacity(0.2);
    }
  }

  Future<String> _getUserName(WidgetRef ref, String userId) async {
    try {
      final user = await ref.read(firestoreServiceProvider).getUser(userId);
      return user?.name ?? 'Unknown User';
    } catch (e) {
      return 'Unknown User';
    }
  }
}

