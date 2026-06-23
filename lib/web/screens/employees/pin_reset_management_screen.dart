import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../../shared/models/pin_reset_request_model.dart';
import '../../../shared/providers/pin_reset_provider.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/constants/app_colors.dart';

/// Web Admin Screen for PIN Reset Management
class PinResetManagementScreen extends ConsumerStatefulWidget {
  const PinResetManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PinResetManagementScreen> createState() =>
      _PinResetManagementScreenState();
}

class _PinResetManagementScreenState
    extends ConsumerState<PinResetManagementScreen> {
  String _selectedFilter = 'all';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(allPinResetRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PIN Reset Management'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          // Filters and Search
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedFilter,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                          value: 'all', child: Text('All Requests')),
                      DropdownMenuItem(
                          value: 'pending', child: Text('Pending')),
                      DropdownMenuItem(
                          value: 'approved', child: Text('Approved')),
                      DropdownMenuItem(
                          value: 'rejected', child: Text('Rejected')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedFilter = value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by employee name or ID',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value.toLowerCase());
                    },
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.invalidate(allPinResetRequestsProvider);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                  ),
                ),
              ],
            ),
          ),

          // Data Table
          Expanded(
            child: requestsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 64),
                    const SizedBox(height: 16),
                    Text('Error: $error'),
                  ],
                ),
              ),
              data: (requests) {
                final filteredRequests = requests.where((request) {
                  if (_selectedFilter != 'all' &&
                      request.status.toLowerCase() != _selectedFilter) {
                    return false;
                  }
                  if (_searchQuery.isNotEmpty) {
                    return request.userName
                            .toLowerCase()
                            .contains(_searchQuery) ||
                        request.userId.toLowerCase().contains(_searchQuery);
                  }
                  return true;
                }).toList();

                if (filteredRequests.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inbox, color: Colors.grey, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          'No requests found',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return _buildDataTable(filteredRequests);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(List<PinResetRequestModel> requests) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: DataTable2(
        columnSpacing: 12,
        horizontalMargin: 12,
        minWidth: 1000,
        columns: const [
          DataColumn2(label: Text('Employee'), size: ColumnSize.L),
          DataColumn2(label: Text('Reason'), size: ColumnSize.L),
          DataColumn2(label: Text('Requested'), size: ColumnSize.M),
          DataColumn2(label: Text('Status'), size: ColumnSize.S),
          DataColumn2(
              label: Text('Actions'),
              size: ColumnSize.M,
              fixedWidth: 150),
        ],
        rows: requests.map((request) {
          return DataRow2(
            cells: [
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      request.userName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'ID: ${request.employeeId ?? request.userId.substring(0, 8)}',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              DataCell(
                Tooltip(
                  message: request.reason,
                  child: Text(
                    request.reason,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(Text(_formatDate(request.requestedAt))),
              DataCell(_buildStatusChip(request.status)),
              DataCell(
                request.status.toLowerCase() == 'pending'
                    ? Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            tooltip: 'Approve',
                            onPressed: () => _showApproveDialog(request),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            tooltip: 'Reject',
                            onPressed: () => _showRejectDialog(request),
                          ),
                        ],
                      )
                    : IconButton(
                        icon: Icon(Icons.info, color: AppColors.primary),
                        tooltip: 'View Details',
                        onPressed: () => _showDetailsDialog(request),
                      ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'approved':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'rejected':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      case 'pending':
      default:
        color = Colors.orange;
        icon = Icons.pending;
    }

    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(
        status.toUpperCase(),
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      ),
      backgroundColor: color.withOpacity(0.1),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _showApproveDialog(PinResetRequestModel request) async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    final pinController = TextEditingController();
    final confirmPinController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve PIN Reset'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Set a new PIN for ${request.userName}:'),
              const SizedBox(height: 16),
              TextField(
                controller: pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'New PIN (4-6 digits)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Confirm New PIN',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final pin = pinController.text.trim();
              final confirmPin = confirmPinController.text.trim();

              if (pin.length < 4 || pin.length > 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PIN must be 4-6 digits'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (!RegExp(r'^\d+$').hasMatch(pin)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PIN must contain only digits'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (pin != confirmPin) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PINs do not match'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(pinResetControllerProvider.notifier).approvePinResetRequest(
            userId: request.userId,
            requestId: request.requestId,
            approvedBy: currentUser.uid,
            newPin: pinController.text.trim(),
          );

      ref.invalidate(allPinResetRequestsProvider);
      ref.invalidate(pendingPinResetRequestsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN reset approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showRejectDialog(PinResetRequestModel request) async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    final reasonController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject PIN Reset Request'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'Are you sure you want to reject ${request.userName}\'s PIN reset request?'),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Rejection Reason',
                  hintText: 'Provide a reason for rejection',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(pinResetControllerProvider.notifier).rejectPinResetRequest(
            userId: request.userId,
            requestId: request.requestId,
            rejectedBy: currentUser.uid,
            rejectionReason: reasonController.text.trim().isEmpty
                ? null
                : reasonController.text.trim(),
          );

      ref.invalidate(allPinResetRequestsProvider);
      ref.invalidate(pendingPinResetRequestsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showDetailsDialog(PinResetRequestModel request) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Request Details'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailSection('Employee Information', [
                  _buildDetailRow('Name', request.userName),
                  _buildDetailRow('User ID', request.userId),
                  if (request.employeeId != null)
                    _buildDetailRow('Employee ID', request.employeeId!),
                ]),
                const Divider(),
                _buildDetailSection('Request Information', [
                  _buildDetailRow('Reason', request.reason),
                  if (request.additionalDetails != null)
                    _buildDetailRow('Details', request.additionalDetails!),
                  _buildDetailRow('Requested At', _formatDate(request.requestedAt)),
                  _buildDetailRow('Status', request.status.toUpperCase()),
                ]),
                if (request.approvedBy != null) ...[
                  const Divider(),
                  _buildDetailSection('Approval Information', [
                    _buildDetailRow('Approved By', request.approvedBy!),
                    if (request.newPin != null)
                      _buildDetailRow('New PIN', request.newPin!),
                    if (request.approvedAt != null)
                      _buildDetailRow(
                          'Approved At', _formatDate(request.approvedAt!)),
                  ]),
                ],
                if (request.rejectedBy != null) ...[
                  const Divider(),
                  _buildDetailSection('Rejection Information', [
                    _buildDetailRow('Rejected By', request.rejectedBy!),
                    if (request.rejectedAt != null)
                      _buildDetailRow(
                          'Rejected At', _formatDate(request.rejectedAt!)),
                    if (request.rejectionReason != null)
                      _buildDetailRow(
                          'Rejection Reason', request.rejectionReason!),
                  ]),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
