import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../../shared/models/device_reset_request_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/providers/device_reset_provider.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/constants/app_colors.dart';

/// Web Admin Screen for Device Reset Management
class DeviceResetManagementScreen extends ConsumerStatefulWidget {
  const DeviceResetManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DeviceResetManagementScreen> createState() => _DeviceResetManagementScreenState();
}

class _DeviceResetManagementScreenState extends ConsumerState<DeviceResetManagementScreen> {
  String _selectedFilter = 'all'; // all, pending, approved, rejected
  String _searchQuery = '';
  String _deviceSearchQuery = '';
  int _activeTab = 0; // 0 = requests, 1 = active devices

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(allDeviceResetRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Reset Management'),
        backgroundColor: AppColors.primary,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(
            children: [
              _buildTabButton(
                index: 0,
                label: 'Reset Requests',
                icon: Icons.pending_actions,
              ),
              _buildTabButton(
                index: 1,
                label: 'Active Devices',
                icon: Icons.phone_android,
              ),
            ],
          ),
        ),
      ),
      body: _activeTab == 0
          ? _buildRequestsTab(requestsAsync)
          : _buildActiveDevicesTab(),
    );
  }

  Widget _buildTabButton({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final selected = _activeTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? Colors.white : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestsTab(AsyncValue<List<DeviceResetRequestModel>> requestsAsync) {
    return Column(
      children: [
        // Filters and Search
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade100,
          child: Row(
            children: [
              // Filter Dropdown
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
                    DropdownMenuItem(value: 'all', child: Text('All Requests')),
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'approved', child: Text('Approved')),
                    DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedFilter = value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),

              // Search
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

              // Refresh Button
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(allDeviceResetRequestsProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                  Icon(Icons.error, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  Text('Error: $error'),
                ],
              ),
            ),
            data: (requests) {
              // Filter requests
              final filteredRequests = requests.where((request) {
                // Filter by status
                if (_selectedFilter != 'all' && request.status.toLowerCase() != _selectedFilter) {
                  return false;
                }

                // Filter by search query
                if (_searchQuery.isNotEmpty) {
                  return request.userName.toLowerCase().contains(_searchQuery) ||
                      request.userId.toLowerCase().contains(_searchQuery);
                }

                return true;
              }).toList();

              if (filteredRequests.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, color: Colors.grey, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        'No requests found',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
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
    );
  }

  Widget _buildActiveDevicesTab() {
    final boundDevicesAsync = ref.watch(boundDevicesForCompanyProvider);

    return Column(
      children: [
        // Search and Refresh
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade100,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by employee name or ID...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() => _deviceSearchQuery = value.toLowerCase());
                  },
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(boundDevicesForCompanyProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: boundDevicesAsync.when(
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
            data: (employees) {
              final filtered = employees.where((u) {
                if (_deviceSearchQuery.isEmpty) return true;
                return u.name.toLowerCase().contains(_deviceSearchQuery) ||
                    u.uid.toLowerCase().contains(_deviceSearchQuery) ||
                    (u.employeeId ?? '')
                        .toLowerCase()
                        .contains(_deviceSearchQuery);
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.phone_android,
                        color: Colors.grey,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No active device bindings',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              return _buildActiveDevicesTable(filtered);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActiveDevicesTable(List<UserModel> employees) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: DataTable2(
        columnSpacing: 12,
        horizontalMargin: 12,
        minWidth: 1000,
        columns: const [
          DataColumn2(label: Text('Employee'), size: ColumnSize.L),
          DataColumn2(label: Text('Employee ID'), size: ColumnSize.M),
          DataColumn2(label: Text('Device Model'), size: ColumnSize.M),
          DataColumn2(label: Text('Platform'), size: ColumnSize.S),
          DataColumn2(label: Text('Device ID'), size: ColumnSize.M),
          DataColumn2(label: Text('Registered'), size: ColumnSize.S),
          DataColumn2(label: Text('Actions'), size: ColumnSize.S, fixedWidth: 180),
        ],
        rows: employees.map((user) {
          final device = user.deviceInfo!;
          return DataRow2(
            cells: [
              DataCell(
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          AppColors.supervisorColor.withOpacity(0.2),
                      child: Text(
                        user.name.isNotEmpty
                            ? user.name.substring(0, 1).toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppColors.supervisorColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          user.email,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              DataCell(Text(
                user.employeeId ??
                    user.employeeIdNumber ??
                    user.systemGeneratedId ??
                    'N/A',
              )),
              DataCell(Text(device.deviceModel)),
              DataCell(Text(
                device.platform ?? 'Unknown',
                style: TextStyle(
                  color: device.platform?.toLowerCase() == 'ios'
                      ? Colors.blueGrey
                      : Colors.green.shade700,
                ),
              )),
              DataCell(
                Tooltip(
                  message: device.deviceId,
                  child: Text(
                    device.deviceId.length > 12
                        ? '${device.deviceId.substring(0, 12)}...'
                        : device.deviceId,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
              DataCell(Text(_formatDate(device.registeredAt))),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.orange),
                      tooltip: 'Reset Device',
                      onPressed: () => _confirmAdminResetDevice(user),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Future<void> _confirmAdminResetDevice(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('Reset Device?'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'You are about to reset the device binding for:',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              Text(
                user.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(user.email),
              const SizedBox(height: 12),
              Text(
                'Device: ${user.deviceInfo?.deviceModel ?? 'Unknown'}',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const Divider(height: 24),
              const Text(
                'The employee will be required to register a new device on their next login. '
                'This action is logged in the audit trail.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.refresh),
            label: const Text('Reset Device'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    final admin = ref.read(currentUserProvider).value;
    if (admin == null) return;

    try {
      await ref
          .read(deviceResetControllerProvider.notifier)
          .adminResetEmployeeDevice(userId: user.uid, adminId: admin.uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Device reset for ${user.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reset device: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildDataTable(List<DeviceResetRequestModel> requests) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: DataTable2(
        columnSpacing: 12,
        horizontalMargin: 12,
        minWidth: 1200,
        columns: const [
          DataColumn2(label: Text('Employee'), size: ColumnSize.L),
          DataColumn2(label: Text('Device Model'), size: ColumnSize.M),
          DataColumn2(label: Text('Reason'), size: ColumnSize.L),
          DataColumn2(label: Text('Requested'), size: ColumnSize.M),
          DataColumn2(label: Text('Status'), size: ColumnSize.S),
          DataColumn2(label: Text('Actions'), size: ColumnSize.M, fixedWidth: 150),
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
                      'ID: ${request.userId.substring(0, 8)}...',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(request.currentDeviceInfo.deviceModel),
                    Text(
                      '${request.currentDeviceInfo.platform ?? 'Unknown'}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
                            onPressed: () => _approveRequest(request),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            tooltip: 'Reject',
                            onPressed: () => _showRejectDialog(request),
                          ),
                          IconButton(
                            icon: Icon(Icons.info, color: AppColors.primary),
                            tooltip: 'View Details',
                            onPressed: () => _showDetailsDialog(request),
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

  Future<void> _approveRequest(DeviceResetRequestModel request) async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Device Reset Request'),
        content: Text(
          'Are you sure you want to approve ${request.userName}\'s device reset request?\n\n'
          'This will clear their current device binding and allow them to register a new device.',
        ),
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
        title: const Text('Reject Device Reset Request'),
        content: SizedBox(
          width: 400,
          child: Column(
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

  Future<void> _showDetailsDialog(DeviceResetRequestModel request) async {
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
                ]),
                const Divider(),
                _buildDetailSection('Device Information', [
                  _buildDetailRow('Model', request.currentDeviceInfo.deviceModel),
                  _buildDetailRow(
                    'Platform',
                    '${request.currentDeviceInfo.platform ?? 'Unknown'} ${request.currentDeviceInfo.osVersion ?? ''}',
                  ),
                  _buildDetailRow('Device ID', request.currentDeviceInfo.deviceId),
                  _buildDetailRow(
                    'Registered At',
                    _formatDate(request.currentDeviceInfo.registeredAt),
                  ),
                ]),
                const Divider(),
                _buildDetailSection('Request Information', [
                  _buildDetailRow('Reason', request.reason),
                  _buildDetailRow('Requested At', _formatDate(request.requestedAt)),
                  _buildDetailRow('Status', request.status.toUpperCase()),
                ]),
                if (request.approvedBy != null) ...[
                  const Divider(),
                  _buildDetailSection('Approval Information', [
                    _buildDetailRow('Approved By', request.approvedBy!),
                    if (request.approvedAt != null)
                      _buildDetailRow('Approved At', _formatDate(request.approvedAt!)),
                  ]),
                ],
                if (request.rejectedBy != null) ...[
                  const Divider(),
                  _buildDetailSection('Rejection Information', [
                    _buildDetailRow('Rejected By', request.rejectedBy!),
                    if (request.rejectedAt != null)
                      _buildDetailRow('Rejected At', _formatDate(request.rejectedAt!)),
                    if (request.rejectionReason != null)
                      _buildDetailRow('Rejection Reason', request.rejectionReason!),
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
            width: 150,
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

