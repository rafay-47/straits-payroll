import 'dart:io';
import 'package:flutter/material.dart' hide ErrorWidget;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/biometric_auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../screens/auth/biometric_login_screen.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/loading_widget.dart';


class ProfileScreen extends ConsumerStatefulWidget {
  final String userId;

  const ProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _designationController;
  File? _newProfileImage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _designationController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _designationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() => _newProfileImage = File(pickedFile.path));
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        await ref
            .read(userProfileControllerProvider(widget.userId).notifier)
            .updateProfile(
              name: _nameController.text.trim(),
              phone: _phoneController.text.trim(),
              designation: _designationController.text.trim(),
              profileImage: _newProfileImage,
            );

        // Update success
        if (mounted) {
          setState(() {
            _isEditing = false;
            _newProfileImage = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (error) {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString()),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleLogout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to logout?\n\nThis will sign you out and clear your biometric authentication.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Sign out from Firebase and clear biometric credentials
              try {
                await ref.read(authControllerProvider.notifier).signOut();
                await ref.read(biometricAuthControllerProvider.notifier).signOutAndClearBiometric();
              } catch (e) {
                // Ignore errors, just continue with logout
              }

              if (mounted) {
                // Navigate to BiometricLoginScreen (will show as new user)
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const BiometricLoginScreen()),
                  (route) => false, // Remove all previous routes
                );
              }
            },
            child:
                const Text('Logout', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final profileState =
        ref.watch(userProfileControllerProvider(widget.userId));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() => _isEditing = true);
              },
            ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const LoadingWidget();

          // Initialize controllers with current data
          if (_nameController.text.isEmpty) {
            _nameController.text = user.name ?? '';
            _phoneController.text = user.phone ?? '';
            _designationController.text = user.designation ?? '';
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Profile Image
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: AppColors.backgroundWhite,
                      backgroundImage: _newProfileImage != null
                          ? FileImage(_newProfileImage!)
                          : (user.profileImageUrl != null
                              ? NetworkImage(user.profileImageUrl!)
                              : null) as ImageProvider?,
                      child: user.profileImageUrl == null &&
                              _newProfileImage == null
                          ? const Icon(Icons.person,
                              size: 60, color: AppColors.textLight)
                          : null,
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.secondary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // Profile Info or Edit Form
                if (_isEditing)
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        CustomTextField(
                          controller: _nameController,
                          label: 'Full Name',
                          prefixIcon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          controller: _designationController,
                          label: 'Designation',
                          prefixIcon: Icons.work_outline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your designation';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                text: 'Cancel',
                                onPressed: () {
                                  setState(() {
                                    _isEditing = false;
                                    _newProfileImage = null;
                                    _nameController.text = user.name ?? '';
                                    _phoneController.text = user.phone ?? '';
                                    _designationController.text =
                                        user.designation ?? '';
                                  });
                                },
                                isOutlined: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomButton(
                                text: 'Save',
                                onPressed: _saveProfile,
                                isLoading: profileState.isLoading,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: [
                      _buildInfoCard(
                        icon: Icons.person,
                        label: 'Name',
                        value: user.name ?? 'Not set',
                      ),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        icon: Icons.email,
                        label: 'Email',
                        value: user.email,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        icon: Icons.phone,
                        label: 'Phone',
                        value: user.phone ?? 'Not set',
                      ),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        icon: Icons.work,
                        label: 'Designation',
                        value: user.designation ?? 'Not set',
                      ),
                    ],
                  ),
                const SizedBox(height: 32),

                // Settings Section
                if (!_isEditing) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.backgroundWhite,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildSettingsItem(
                          icon: Icons.lock_outline,
                          title: 'Change Password',
                          onTap: () {
                            // TODO: Implement change password
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Feature coming soon')),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        _buildSettingsItem(
                          icon: Icons.logout,
                          title: 'Logout',
                          onTap: _handleLogout,
                          isDestructive: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const LoadingWidget(),
        error: (error, _) => ErrorWidget(message: error.toString()),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.secondary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? AppColors.error : AppColors.textPrimary,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDestructive ? AppColors.error : AppColors.textPrimary,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: isDestructive ? AppColors.error : AppColors.textSecondary,
      ),
      onTap: onTap,
    );
  }
}
