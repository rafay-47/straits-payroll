import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/pin_reset_request_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/providers/pin_reset_provider.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/constants/app_colors.dart';

/// Screen for employees to request PIN reset
/// When [employeeId] is provided (e.g. from login screen), looks up the user
/// directly without requiring authentication.
class PinResetRequestScreen extends ConsumerStatefulWidget {
  final String? employeeId;

  const PinResetRequestScreen({Key? key, this.employeeId}) : super(key: key);

  @override
  ConsumerState<PinResetRequestScreen> createState() =>
      _PinResetRequestScreenState();
}

class _PinResetRequestScreenState extends ConsumerState<PinResetRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _detailsController = TextEditingController();
  String? _selectedReason;
  bool _isSubmitting = false;
  UserModel? _externalUser;
  bool _isLoadingExternal = false;
  String? _externalError;

  @override
  void initState() {
    super.initState();
    if (widget.employeeId != null) {
      _loadExternalUser();
    }
  }

  Future<void> _loadExternalUser() async {
    setState(() => _isLoadingExternal = true);
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final user = await firestoreService.getEmployeeById(
        employeeId: widget.employeeId!,
      );
      if (mounted) {
        setState(() {
          _externalUser = user;
          _isLoadingExternal = false;
          if (user == null) {
            _externalError = 'Employee not found for ID: ${widget.employeeId}';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingExternal = false;
          _externalError = 'Error looking up employee: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  UserModel? _resolveUser() {
    if (widget.employeeId != null) {
      return _externalUser;
    }
    return ref.read(currentUserProvider).value;
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _resolveUser();
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Employee not found')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ref.read(pinResetControllerProvider.notifier).requestPinReset(
            userId: user.uid,
            userName: user.name,
            employeeId: user.employeeId ?? user.displayId,
            companyId: user.companyId,
            reason: _selectedReason ?? _reasonController.text.trim(),
            additionalDetails: _detailsController.text.trim().isEmpty
                ? null
                : _detailsController.text.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN reset request submitted successfully'),
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
    final isExternal = widget.employeeId != null;
    final userAsync = isExternal ? null : ref.watch(currentUserProvider);

    final requestsAsync = userAsync != null
        ? userAsync.when<AsyncValue<List<PinResetRequestModel>>>(
            data: (user) => user != null
                ? ref.watch(userPinResetRequestsProvider(user.uid))
                : const AsyncValue<List<PinResetRequestModel>>.data(
                    <PinResetRequestModel>[]),
            loading: () =>
                const AsyncValue<List<PinResetRequestModel>>.loading(),
            error: (e, s) => AsyncValue<List<PinResetRequestModel>>.error(e, s),
          )
        : const AsyncValue<List<PinResetRequestModel>>.data(
            <PinResetRequestModel>[]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PIN Reset Request'),
        backgroundColor: AppColors.primary,
      ),
      body: isExternal
          ? _buildExternalBody(requestsAsync)
          : _buildAuthenticatedBody(userAsync!, requestsAsync),
    );
  }

  Widget _buildExternalBody(
      AsyncValue<List<PinResetRequestModel>> requestsAsync) {
    if (_isLoadingExternal) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_externalError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(_externalError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Request a PIN reset from your supervisor or company admin. '
                      'They will set a new PIN for you.',
                      style: TextStyle(color: Colors.blue.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_externalUser != null)
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Text(
                    (_externalUser!.name.isNotEmpty
                            ? _externalUser!.name[0]
                            : '?')
                        .toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(_externalUser!.name),
                subtitle: Text(_externalUser!.employeeId ?? ''),
              ),
            ),
          const SizedBox(height: 24),
          _buildRequestForm(),
        ],
      ),
    );
  }

  Widget _buildAuthenticatedBody(
    AsyncValue<dynamic> userAsync,
    AsyncValue<List<PinResetRequestModel>> requestsAsync,
  ) {
    return userAsync.when(
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
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Request a PIN reset from your supervisor or company admin. '
                          'They will set a new PIN for you.',
                          style: TextStyle(color: Colors.blue.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildRequestHistoryCard(requestsAsync),
              const SizedBox(height: 24),
              _buildRequestForm(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRequestHistoryCard(
      AsyncValue<List<PinResetRequestModel>> requestsAsync) {
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
                  'Request History',
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
                        backgroundColor:
                            _getStatusColor(request.status).withOpacity(0.2),
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

              // Reason Dropdown
              DropdownButtonFormField<String>(
                value: _selectedReason,
                decoration: const InputDecoration(
                  labelText: 'Reason for PIN Reset',
                  border: OutlineInputBorder(),
                ),
                items: PinResetRequestModel.availableReasons.map((reason) {
                  return DropdownMenuItem(
                    value: reason,
                    child: Text(reason),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedReason = value);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a reason';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Additional Details
              TextFormField(
                controller: _detailsController,
                decoration: const InputDecoration(
                  labelText: 'Additional Details (Optional)',
                  hintText: 'Provide any additional information...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
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
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
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
