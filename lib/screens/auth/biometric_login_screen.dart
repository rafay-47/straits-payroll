import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/biometric_auth_provider.dart';
import '../../dashboard_screen.dart';
import 'profile_setup_screen.dart';

/// First screen shown on app launch
/// Handles biometric authentication and automatic account creation
class BiometricLoginScreen extends ConsumerStatefulWidget {
  const BiometricLoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BiometricLoginScreen> createState() =>
      _BiometricLoginScreenState();
}

class _BiometricLoginScreenState extends ConsumerState<BiometricLoginScreen> {
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    // Automatically trigger biometric auth
    _autoAuthenticate();
  }

  /// Automatically trigger biometric authentication
  Future<void> _autoAuthenticate() async {
    // Small delay to ensure UI is ready
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // Check if biometric is available on device
    final isAvailable = await ref.read(biometricAvailableProvider.future);
    
    if (isAvailable) {
      final isEnrolled = await ref.read(biometricEnrolledProvider.future);
      if (isEnrolled && mounted) {
        // User has enrolled biometric - authenticate
        _handleBiometricAuth();
      } else if (mounted) {
        // User hasn't enrolled yet - show prompt to set up
        _showBiometricSetupPrompt();
      }
    } else {
      // Device doesn't support biometric
      _showDeviceNotSupportedMessage();
    }
  }

  /// Show prompt for first-time biometric setup
  void _showBiometricSetupPrompt() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Biometric Authentication Required'),
        content: const Text(
          'This app uses biometric authentication for secure access. Please authenticate to continue.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleBiometricAuth();
            },
            child: const Text('Authenticate'),
          ),
        ],
      ),
    );
  }

  /// Show message when device doesn't support biometric
  void _showDeviceNotSupportedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'This device does not support biometric authentication. Please use a device with Face ID, Touch ID, or Fingerprint.',
        ),
        duration: Duration(seconds: 5),
        backgroundColor: AppColors.error,
      ),
    );
  }

  /// Handle biometric authentication flow
  Future<void> _handleBiometricAuth() async {
    if (_isAuthenticating) return;

    setState(() => _isAuthenticating = true);

    final controller = ref.read(biometricAuthControllerProvider.notifier);
    final success = await controller.authenticateWithBiometric();

    if (!mounted) return;

    if (success) {
      // Get authentication state
      var authState = ref.read(biometricAuthControllerProvider);

      // iOS Fix: If userProfile is null, wait a bit and try again
      if (authState.userProfile == null && authState.user != null) {
        await Future.delayed(const Duration(milliseconds: 500));
        authState = ref.read(biometricAuthControllerProvider);
      }

      if (authState.userProfile != null) {
        // Navigate based on profile completion
        if (authState.userProfile!.isProfileComplete) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
            );
          }
        } else {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => ProfileSetupScreen(
                  userId: authState.user!.uid,
                ),
              ),
            );
          }
        }
      } else if (authState.user != null) {
        // Fallback: If still no profile but we have a user, navigate to profile setup
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ProfileSetupScreen(
                userId: authState.user!.uid,
              ),
            ),
          );
        }
      } else {
        // Something went wrong - show error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Authentication successful but could not load profile. Please try again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } else {
      // Authentication failed - show error
      final authState = ref.read(biometricAuthControllerProvider);
      if (authState.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authState.error!),
            backgroundColor: AppColors.error,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _handleBiometricAuth,
            ),
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isAuthenticating = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final biometricType = ref.watch(biometricTypeProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              // Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.business,
                  size: 64,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 32),

              // App Title
              const Text(
                'Employee Management',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              const Text(
                'Secure. Simple. Smart.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 60),

              // Biometric Authentication Section
              biometricType.when(
                data: (typeName) => Icon(
                  typeName == 'Face ID' ? Icons.face : Icons.fingerprint,
                  size: 100,
                  color: AppColors.secondary,
                ),
                loading: () => const Icon(
                  Icons.fingerprint,
                  size: 100,
                  color: AppColors.secondary,
                ),
                error: (_, __) => const Icon(
                  Icons.fingerprint,
                  size: 100,
                  color: AppColors.secondary,
                ),
              ),

              const SizedBox(height: 32),

              // Authentication Status Text
              Text(
                _isAuthenticating
                    ? 'Authenticating...'
                    : 'Tap to authenticate',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              biometricType.when(
                data: (typeName) => Text(
                  'Use $typeName to securely access your account',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                loading: () => const Text(
                  'Preparing biometric authentication...',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                error: (_, __) => const Text(
                  'Use biometric to securely access your account',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 48),

              // Biometric Authentication Button
              _isAuthenticating
                  ? const CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.secondary),
                    )
                  : ElevatedButton.icon(
                      onPressed: _handleBiometricAuth,
                      icon: biometricType.when(
                        data: (typeName) => Icon(
                          typeName == 'Face ID' ? Icons.face : Icons.fingerprint,
                        ),
                        loading: () => const Icon(Icons.fingerprint),
                        error: (_, __) => const Icon(Icons.fingerprint),
                      ),
                      label: const Text('Authenticate Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                    ),

              const Spacer(),

              // Footer
              Text(
                'Secure authentication powered by\ndevice biometrics',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

