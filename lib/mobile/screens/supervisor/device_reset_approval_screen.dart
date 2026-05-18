import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/device_reset_request_model.dart';
import '../../../shared/providers/device_reset_provider.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/constants/app_colors.dart';

/// Screen for supervisors to approve/reject device reset requests
class DeviceResetApprovalScreen extends ConsumerStatefulWidget {
  const DeviceResetApprovalScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DeviceResetApprovalScreen> createState() => _DeviceResetApprovalScreenState();
}

class _DeviceResetApprovalScreenState extends ConsumerState<DeviceResetApprovalScreen> {
  String _selectedFilter = 'all'; // all, pending, approved, rejected

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(allDeviceResetRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Reset Requests'),
        backgroundColor: AppColors.primary,
        actions: [
          PopupMenuButton<String>(
            initialValue: _selectedFilter,
            onSelected: (value) {
              setState(() => _selectedFilter = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Requests')),
              const PopupMenuItem(value: 'pending', child: Text('Pending Only')),
              const PopupMenuItem(value: 'approved', child: Text('Approved Only')),
              const PopupMenuItem(value: 'rejected', child: Text('Rejected Only')),
            ],
          ),
        ],
      ),
      body: requestsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text('Error: $error'),
            ],
          ),
        ),
        data: (requests) {
          // Filter requests
          final filteredRequests = requests.where((request) {
            if (_selectedFilter == 'all') return true;
            return request.status.toLowerCase() == _selectedFilter;
          }).toList();

          if (filteredRequests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, color: Colors.grey, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'No ${_selectedFilter == 'all' ? '' : _selectedFilter} requests',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(allDeviceResetRequestsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredRequests.length,
              itemBuilder: (context, index) {
                return _buildRequestCard(filteredRequests[index]);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(DeviceResetRequestModel request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getStatusColor(request.status).withOpacity(0.2),
                  child: Icon(
                    _getStatusIcon(request.status),
                    color: _getStatusColor(request.status),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.userName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ID: ${request.userId.substring(0, 8)}...',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    request.status.toUpperCase(),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: _getStatusColor(request.status).withOpacity(0.2),
                ),
              ],
            ),
            const Divider(height: 24),

            // Device Info
            _buildInfoSection(
              'Device Information',
              Icons.phone_android,
              [
                _buildInfoRow('Model', request.currentDeviceInfo.deviceModel),
                _buildInfoRow(
                  'OS',
                  '${request.currentDeviceInfo.platform ?? 'Unknown'} ${request.currentDeviceInfo.osVersion ?? ''}',
                ),
                _buildInfoRow('Device ID', request.currentDeviceInfo.deviceId.substring(0, 16)),
              ],
            ),
            const SizedBox(height: 12),

            // Reason
            _buildInfoSection(
              'Reason',
              Icons.description,
              [
                Text(
                  request.reason,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Request Date
            _buildInfoRow('Requested', _formatDate(request.requestedAt)),

            // Approval/Rejection Info
            if (request.approvedBy != null) ...[
              _buildInfoRow('Approved By', request.approvedBy!),
              if (request.approvedAt != null)
                _buildInfoRow('Approved On', _formatDate(request.approvedAt!)),
            ] else if (request.rejectedBy != null) ...[
              _buildInfoRow('Rejected By', request.rejectedBy!),
              if (request.rejectedAt != null)
                _buildInfoRow('Rejected On', _formatDate(request.rejectedAt!)),
              if (request.rejectionReason != null)
                _buildInfoRow('Rejection Reason', request.rejectionReason!),
            ],

            // Action Buttons (only for pending requests)
            if (request.status.toLowerCase() == 'pending') ...[
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRejectDialog(request),
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text(
                        'Reject',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveRequest(request),
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
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

  Future<void> _approveRequest(DeviceResetRequestModel request) async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Request'),
        content: Text('Are you sure you want to approve ${request.userName}\'s device reset request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(deviceResetControllerProvider.notifier).approveDeviceResetRequest(
            userId: request.userId,
            requestId: request.requestId,
            approvedBy: currentUser.uid,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request approved successfully'),
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

  Future<void> _showRejectDialog(DeviceResetRequestModel request) async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    final reasonController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to reject ${request.userName}\'s device reset request?'),
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
      await ref.read(deviceResetControllerProvider.notifier).rejectDeviceResetRequest(
            userId: request.userId,
            requestId: request.requestId,
            rejectedBy: currentUser.uid,
            rejectionReason: reasonController.text.trim().isEmpty ? null : reasonController.text.trim(),
          );

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
}

