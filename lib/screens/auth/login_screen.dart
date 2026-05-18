import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:straights_psyroll/dashboard_screen.dart';
import 'package:straights_psyroll/providers/attendance_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/biometric_auth_provider.dart';
import '../../models/user_model.dart';
import 'profile_setup_screen.dart';

import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isBiometricAvailable = false;
  bool _isCreatingAccount = false; // Toggle between sign in and create account

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final biometricService = ref.read(biometricServiceProvider);
    final available = await biometricService.canCheckBiometrics();
    setState(() => _isBiometricAvailable = available);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleBiometricLogin() async {
    final biometricService = ref.read(biometricServiceProvider);
    final authenticated = await biometricService.authenticate(
      reason: 'Authenticate to sign in',
    );

    if (authenticated && mounted) {
      // In real app, you would retrieve saved credentials
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(
      //     content: Text('Please enter your credentials for first-time setup'),
      //     backgroundColor: AppColors.warning,
      //   ),
      // );
    }
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Sign in with Firebase
        await ref.read(authControllerProvider.notifier).signIn(
              _emailController.text.trim(),
              _passwordController.text,
            );

        if (!mounted) return;

        // Get current user
        final authState = ref.read(authStateProvider);
        final user = authState.value;

        if (user == null) {
          throw Exception('Sign in failed');
        }

        // Get user profile from Firestore
        final userProfile = await ref
            .read(firestoreServiceProvider)
            .getUserProfile(user.uid);

        if (!mounted) return;

        // Prompt for biometric enrollment if device supports it
        final biometricAvailable =
            await ref.read(biometricAvailableProvider.future);
        final biometricEnrolled =
            await ref.read(biometricEnrolledProvider.future);

        if (biometricAvailable && !biometricEnrolled) {
          _promptBiometricEnrollment(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            uid: user.uid,
            userProfile: userProfile,
          );
        } else {
          // Navigate based on profile completion
          _navigateAfterLogin(userProfile, user.uid);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  /// Prompt user to enroll biometric login
  Future<void> _promptBiometricEnrollment({
    required String email,
    required String password,
    required String uid,
    required UserModel? userProfile,
  }) async {
    final shouldEnroll = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable Biometric Login?'),
        content: const Text(
          'Would you like to enable biometric login for faster and more secure access?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Enable'),
          ),
        ],
      ),
    );

    if (shouldEnroll == true && mounted) {
      final controller = ref.read(biometricAuthControllerProvider.notifier);
      final success = await controller.enrollBiometric(
        email: email,
        password: password,
        uid: uid,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric login enabled successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to enable biometric login'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }

    if (mounted) {
      _navigateAfterLogin(userProfile, uid);
    }
  }

  /// Navigate to appropriate screen based on profile completion
  void _navigateAfterLogin(UserModel? userProfile, String uid) {
    if (userProfile == null || !userProfile.isProfileComplete) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ProfileSetupScreen(userId: uid),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  /// Handle account creation
  Future<void> _handleCreateAccount() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Create account with Firebase
        await ref.read(authControllerProvider.notifier).createAccount(
              _emailController.text.trim(),
              _passwordController.text,
            );

        if (!mounted) return;

        // Get current user
        final authState = ref.read(authStateProvider);
        final user = authState.value;

        if (user == null) {
          throw Exception('Account creation failed');
        }

        // User profile is automatically created in auth_provider.dart
        // with isProfileComplete = false, so we navigate to profile setup

        if (!mounted) return;

        // Prompt for biometric enrollment
        final biometricAvailable =
            await ref.read(biometricAvailableProvider.future);

        if (biometricAvailable) {
          _promptBiometricEnrollment(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            uid: user.uid,
            userProfile: null, // Profile not complete yet
          );
        } else {
          // Navigate to profile setup
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ProfileSetupScreen(userId: user.uid),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                // Logo
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.business,
                      size: 56,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  _isCreatingAccount ? 'Create Account' : 'Welcome Back',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isCreatingAccount
                      ? 'Sign up to get started'
                      : 'Sign in to continue',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 40),
                // Email Field
                CustomTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'Enter your email',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Password Field
                CustomTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Enter your password',
                  prefixIcon: Icons.lock_outlined,
                  suffixIcon: _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  onSuffixIconTap: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                // Login/Create Account Button
                CustomButton(
                  text: _isCreatingAccount ? 'Create Account' : 'Sign In',
                  onPressed:
                      _isCreatingAccount ? _handleCreateAccount : _handleLogin,
                  isLoading: authState.isLoading,
                ),
                const SizedBox(height: 16),
                // Toggle Sign In / Create Account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isCreatingAccount
                          ? 'Already have an account? '
                          : "Don't have an account? ",
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() => _isCreatingAccount = !_isCreatingAccount);
                      },
                      child: Text(
                        _isCreatingAccount ? 'Sign In' : 'Create Account',
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                // Biometric Login (only show for sign in mode)
                if (!_isCreatingAccount && _isBiometricAvailable) ...[
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Sign In with Biometric',
                    onPressed: _handleBiometricLogin,
                    isOutlined: true,
                    icon: Icons.fingerprint,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
