import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/services/company_service.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/models/company_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/password_reset_request_model.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/company_logo_widget.dart';
import '../companies/create_company_screen.dart';
import '../companies/company_details_screen.dart';

/// Super Admin Dashboard - Platform management
class SuperAdminDashboardScreen extends ConsumerStatefulWidget {
  const SuperAdminDashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SuperAdminDashboardScreen> createState() =>
      _SuperAdminDashboardScreenState();
}

class _PasswordResetApprovalsDialog extends ConsumerStatefulWidget {
  final UserModel approver;

  const _PasswordResetApprovalsDialog({required this.approver});

  @override
  ConsumerState<_PasswordResetApprovalsDialog> createState() =>
      _PasswordResetApprovalsDialogState();
}

class _PasswordResetApprovalsDialogState
    extends ConsumerState<_PasswordResetApprovalsDialog> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Password Reset Approvals'),
      content: SizedBox(
        width: 640,
        child: FutureBuilder<List<PasswordResetRequestModel>>(
          future: ref
              .read(firestoreServiceProvider)
              .getPendingPasswordResetRequestsForApprover(
                approver: widget.approver,
              ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            final requests = snapshot.data ?? [];
            if (requests.isEmpty) {
              return const Text('No pending password reset requests.');
            }

            return ListView.separated(
              shrinkWrap: true,
              itemCount: requests.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final req = requests[index];
                return ListTile(
                  title: Text('${req.requesterName} (${req.requesterRole.toUpperCase()})'),
                  subtitle: Text(req.requesterEmail),
                  trailing: ElevatedButton(
                    onPressed: _isProcessing ? null : () => _approve(req),
                    child: const Text('Approve & Send'),
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Future<void> _approve(PasswordResetRequestModel req) async {
    setState(() {
      _isProcessing = true;
    });
    try {
      await ref.read(authServiceProvider).sendPasswordResetEmail(
            email: req.requesterEmail,
          );
      await ref.read(firestoreServiceProvider).markPasswordResetRequestApproved(
            requestId: req.requestId,
            approverId: widget.approver.uid,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reset email sent to ${req.requesterEmail}')),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}

class _SuperAdminDashboardScreenState
    extends ConsumerState<SuperAdminDashboardScreen> {
  final _companyService = CompanyService();
  final _authService = AuthService();

  Map<String, int>? _platformStats;
  bool _isLoadingStats = true;
  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all', 'active', 'suspended', 'inactive'

  @override
  void initState() {
    super.initState();
    _loadPlatformStats();
  }

  Future<void> _loadPlatformStats() async {
    try {
      final stats = await _companyService.getPlatformStats();
      if (!mounted) return;
      setState(() {
        _platformStats = stats;
        _isLoadingStats = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingStats = false;
      });
    }
  }

  Future<void> _refreshDashboard() async {
    if (!mounted) return;
    setState(() {});
    await _loadPlatformStats();
  }

  // SA-4: Change password dialog
  Future<void> _showChangePasswordDialog() async {
    final currentPwdController = TextEditingController();
    final newPwdController = TextEditingController();
    final confirmPwdController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;
    String? errorMessage;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change Password'),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: AppColors.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(errorMessage!, style: TextStyle(color: AppColors.error, fontSize: 13))),
                        ],
                      ),
                    ),
                  TextFormField(
                    controller: currentPwdController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Current Password',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: newPwdController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (v.length < 6) return 'At least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: confirmPwdController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v != newPwdController.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() {
                        isSaving = true;
                        errorMessage = null;
                      });
                      try {
                        await _authService.updatePassword(
                          currentPassword: currentPwdController.text,
                          newPassword: newPwdController.text,
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(content: Text('Password changed successfully')),
                          );
                        }
                      } catch (e) {
                        setDialogState(() {
                          isSaving = false;
                          errorMessage = e.toString();
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Change Password'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/super-admin-login');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  Future<void> _showPasswordResetApprovalsDialog() async {
    final approver = await ref.read(currentUserProvider.future);
    if (approver == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load current user')),
      );
      return;
    }

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => _PasswordResetApprovalsDialog(approver: approver),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.admin_panel_settings, size: 28),
            const SizedBox(width: 12),
            const Text('Super Admin Dashboard'),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadPlatformStats();
              setState(() {});
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.mark_email_read),
            onPressed: _showPasswordResetApprovalsDialog,
            tooltip: 'Password Reset Approvals',
          ),
          // SA-4: Change password
          IconButton(
            icon: const Icon(Icons.lock_reset),
            onPressed: _showChangePasswordDialog,
            tooltip: 'Change Password',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Stats Overview
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: _buildStatsOverview(),
          ),

          // Search & Filter (SA-1)
          Container(
            color: AppColors.backgroundLight,
            child: _buildSearchAndFilter(),
          ),

          // Companies List
          Expanded(
            child: Container(
              color: AppColors.backgroundLight,
              child: _buildCompaniesList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CreateCompanyScreen(
                onCompanyCreated: _refreshDashboard,
              ),
            ),
          );
          if (result == true) {
            await _refreshDashboard();
          }
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Create Company'),
      ),
    );
  }

  Widget _buildStatsOverview() {
    if (_isLoadingStats) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final stats = _platformStats ?? {};

    return Row(
      children: [
        _buildStatCard(
          'Companies',
          stats['companies'] ?? 0,
          Icons.business,
          Colors.white,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          'Total Users',
          stats['users'] ?? 0,
          Icons.people,
          Colors.white70,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          'Projects',
          stats['projects'] ?? 0,
          Icons.work,
          Colors.white70,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          'Check-ins',
          stats['attendance'] ?? 0,
          Icons.check_circle,
          Colors.white70,
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, int value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          // Search bar
          Expanded(
            flex: 3,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by company name, code, or email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.borderLight),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase().trim();
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          // Status filter
          Expanded(
            flex: 1,
            child: DropdownButtonFormField<String>(
              value: _statusFilter,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.borderLight),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Status')),
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'suspended', child: Text('Suspended')),
                DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
              ],
              onChanged: (value) {
                setState(() {
                  _statusFilter = value ?? 'all';
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  List<CompanyModel> _filterCompanies(List<CompanyModel> companies) {
    return companies.where((company) {
      // Status filter
      if (_statusFilter != 'all' && company.status != _statusFilter) {
        return false;
      }
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final matchesName = company.name.toLowerCase().contains(_searchQuery);
        final matchesCode = company.companyCode.toLowerCase().contains(_searchQuery);
        final matchesEmail = company.primaryContact.email.toLowerCase().contains(_searchQuery);
        final matchesContact = company.primaryContact.name.toLowerCase().contains(_searchQuery);
        final matchesRegNo = company.registrationNumber?.toLowerCase().contains(_searchQuery) ?? false;
        if (!matchesName && !matchesCode && !matchesEmail && !matchesContact && !matchesRegNo) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Widget _buildCompaniesList() {
    return StreamBuilder<List<CompanyModel>>(
      stream: _companyService.streamAllCompanies(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline,
                    size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Error loading companies: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final allCompanies = snapshot.data ?? [];

        if (allCompanies.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.business_outlined,
                    size: 80, color: AppColors.textLight),
                const SizedBox(height: 16),
                Text(
                  'No Companies Yet',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first company to get started',
                  style: TextStyle(color: AppColors.textLight),
                ),
              ],
            ),
          );
        }

        final filteredCompanies = _filterCompanies(allCompanies);

        if (filteredCompanies.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: AppColors.textLight),
                const SizedBox(height: 16),
                Text(
                  'No companies match your search',
                  style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          itemCount: filteredCompanies.length,
          itemBuilder: (context, index) {
            final company = filteredCompanies[index];
            return _buildCompanyCard(company);
          },
        );
      },
    );
  }

  Widget _buildCompanyCard(CompanyModel company) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  CompanyDetailsScreen(
                    companyId: company.id,
                    onCompanyChanged: _refreshDashboard,
                  ),
            ),
          );
          await _refreshDashboard();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
                    CompanyLogoWidget(
                      size: 60,
                      borderRadius: BorderRadius.circular(8),
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      iconColor: AppColors.primary,
                      imageUrl: company.logo,
                  
              ),
              const SizedBox(width: 16),

              // Company Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          company.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            company.companyCode,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      company.primaryContact.email,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Status Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: company.isActive
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  company.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color:
                        company.isActive ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Arrow icon
              Icon(Icons.arrow_forward_ios,
                  size: 16, color: AppColors.textLight),
            ],
          ),
        ),
      ),
    );
  }
}






