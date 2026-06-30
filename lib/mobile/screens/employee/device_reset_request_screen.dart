import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/device_reset_request_model.dart';
import '../../../shared/providers/device_reset_provider.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_constants.dart';

/// Screen for employees to request device reset
class DeviceResetRequestScreen extends ConsumerStatefulWidget {
  const DeviceResetRequestScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DeviceResetRequestScreen> createState() => _DeviceResetRequestScreenState();
}

class _DeviceResetRequestScreenState extends ConsumerState<DeviceResetRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found')),
      );
      return;
    }

    // Check device info
    if (user.deviceInfo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No device registered')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ref.read(deviceResetControllerProvider.notifier).requestDeviceReset(
            userId: user.uid,
            userName: user.name,
            currentDeviceInfo: user.deviceInfo!,
            reason: _reasonController.text.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Device reset request submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final requestsAsync = userAsync.when<AsyncValue<List<DeviceResetRequestModel>>>(
      data: (user) => user != null
          ? ref.watch(userDeviceResetRequestsProvider(user.uid))
          : const AsyncValue<List<DeviceResetRequestModel>>.data(<DeviceResetRequestModel>[]),
      loading: () => const AsyncValue<List<DeviceResetRequestModel>>.loading(),
      error: (e, s) => AsyncValue<List<DeviceResetRequestModel>>.error(e, s),
    );
    final canRequestAsync = userAsync.when(
      data: (user) => user != null
          ? ref.watch(canRequestDeviceResetProvider(user.uid))
          : const AsyncValue.data(false),
      loading: () => const AsyncValue.loading(),
      error: (e, s) => AsyncValue.error(e, s),
    );
    final companySettingsAsync = ref.watch(currentUserCompanySettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Reset Request'),
        backgroundColor: AppColors.primary,
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('User not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current Device Info Card
                _buildCurrentDeviceCard(user.deviceInfo),
                const SizedBox(height: 24),

                // Reset History Card
                _buildResetHistoryCard(requestsAsync),
                const SizedBox(height: 24),

                // Request Form
                canRequestAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Text('Error: $error'),
                  data: (canRequest) {
                    if (!canRequest) {
                      final limit = companySettingsAsync.value?.maxDeviceResetsPerMonth ?? AppConstants.maxDeviceResetsPerMonth;
                      return Card(
                        color: Colors.orange.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Icon(Icons.warning, color: Colors.orange, size: 48),
                              const SizedBox(height: 8),
                              Text(
                                'Monthly Limit Reached',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'You have reached the maximum number of device reset requests for this month ($limit).',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return _buildRequestForm();
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentDeviceCard(deviceInfo) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.phone_android, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Current Device',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(),
            if (deviceInfo != null) ...[
              _buildInfoRow('Model', deviceInfo.deviceModel ?? 'Unknown'),
              _buildInfoRow('OS', '${deviceInfo.platform ?? 'Unknown'} ${deviceInfo.osVersion ?? ''}'),
              _buildInfoRow('Registered', deviceInfo.registeredAt != null
                  ? _formatDate(deviceInfo.registeredAt!)
                  : 'Unknown'),
            ] else ...[
              const Text('No device registered'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResetHistoryCard(AsyncValue<List<DeviceResetRequestModel>> requestsAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Reset History',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(),
            requestsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text('Error: $error'),
              data: (requests) {
                if (requests.isEmpty) {
                  return const Text('No previous requests');
                }

                return Column(
                  children: requests.take(5).map((request) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        _getStatusIcon(request.status),
                        color: _getStatusColor(request.status),
                      ),
                      title: Text(_formatDate(request.requestedAt)),
                      subtitle: Text(request.reason),
                      trailing: Chip(
                        label: Text(
                          request.status.toUpperCase(),
                          style: const TextStyle(fontSize: 10),
                        ),
                        backgroundColor: _getStatusColor(request.status).withOpacity(0.2),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.send, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'New Request',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason for Reset',
                  hintText: 'e.g., Lost phone, New device, etc.',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide a reason';
                  }
                  if (value.trim().length < 10) {
                    return 'Reason must be at least 10 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Submit Request',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
      default:
        return Icons.pending;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }
}

