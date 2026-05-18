import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_strings.dart';
import '../../../shared/services/biometric_service.dart';
import '../../../shared/services/device_service.dart';
import '../../../shared/providers/auth_provider.dart';
import '../employee/employee_dashboard_screen.dart';

/// Employee login screen with ID and PIN input
class EmployeeLoginScreen extends ConsumerStatefulWidget {
  const EmployeeLoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EmployeeLoginScreen> createState() =>
      _EmployeeLoginScreenState();
}

class _EmployeeLoginScreenState extends ConsumerState<EmployeeLoginScreen> {
  final _employeeIdController = TextEditingController();
  final _pinController = TextEditingController();
  final _biometricService = BiometricService();
  final _deviceService = DeviceService();

  bool _isLoading = false;
  bool _showPinInput = false;
  bool _canUseBiometric = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  @override
  void dispose() {
    _employeeIdController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  /// Check if biometric is available
  Future<void> _checkBiometricAvailability() async {
    final canUse = await _biometricService.canUseBiometric();
    setState(() {
      _canUseBiometric = canUse;
    });
  }

  /// Handle employee ID submission
  Future<void> _handleIdSubmit() async {
    final employeeId = _employeeIdController.text.trim().toUpperCase();

    if (employeeId.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your Employee ID';
      });
      return;
    }

    if (!employeeId.contains('-')) {
      setState(() {
        _errorMessage =
            'Use full Employee ID format: CompanyCode-EmployeeID (example: ABC-0001)';
      });
      return;
    }

    setState(() {
      _employeeIdController.text = employeeId;
      _showPinInput = true;
      _errorMessage = null;
    });
  }

  /// Handle PIN login
  Future<void> _handlePinLogin() async {
    final employeeId = _employeeIdController.text.trim().toUpperCase();
    final pin = _pinController.text.trim();

    if (!employeeId.contains('-')) {
      setState(() {
        _errorMessage =
            'Use full Employee ID format: CompanyCode-EmployeeID (example: ABC-0001)';
      });
      return;
    }

    if (pin.length < 4 || pin.length > 6) {
      setState(() {
        _errorMessage = 'PIN must be 4-6 digits';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Attempt login with employee ID and PIN
      final success = await ref.read(authControllerProvider.notifier).signInWithEmployeeId(
        employeeId: employeeId,
        password: pin,
      );

      if (!mounted) return;

      if (success) {
        // Get user from auth controller state (Firestore user, not Firebase Auth)
        final authState = ref.read(authControllerProvider);
        final user = authState.user;

        if (user != null) {
          print('✅ Login successful, binding device...');
          // Check device binding
          await _checkAndBindDevice(user.uid);

          // Navigate to dashboard
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => const EmployeeDashboardScreen(),
            ),
            (route) => false,
          );
        } else {
          setState(() {
            _errorMessage = 'Login failed. Please try again.';
          });
        }
      } else {
        final error = ref.read(authControllerProvider).error;
        setState(() {
          _errorMessage = error ?? 'Invalid Employee ID or PIN';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Login error: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Handle biometric login
  Future<void> _handleBiometricLogin() async {
    final employeeId = _employeeIdController.text.trim();

    if (employeeId.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your Employee ID first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Authenticate with biometric
      final authenticated = await _biometricService.authenticate(
        reason: 'Authenticate to log in as $employeeId',
        useErrorDialogs: true,
      );

      if (authenticated) {
        // TODO: Retrieve stored PIN for this employee from secure storage
        // For now, show error
        setState(() {
          _errorMessage = 'Biometric login not yet enrolled. Please use PIN.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = _biometricService.getErrorMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Check and bind device on first login
  Future<void> _checkAndBindDevice(String userId) async {
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final user = await firestoreService.getUser(userId);

      if (user?.deviceInfo == null) {
        // First login - bind device
        final deviceInfo = await _deviceService.getDeviceInfo();

        if (deviceInfo != null) {
          await firestoreService.updateUser(userId, {
            'deviceInfo': deviceInfo.toMap(),
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Device registered successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        // Check if device matches
        final currentDeviceId = await _deviceService.getDeviceId();
        final registeredDeviceId = user!.deviceInfo!.deviceId;

        if (currentDeviceId != registeredDeviceId) {
          // Different device - show error
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'This account is registered to a different device. Please contact your supervisor for device reset.',
                ),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 5),
              ),
            );

            // Clear employee session + in-memory auth (PIN-only employees)
            await ref.read(authControllerProvider.notifier).signOut();

            // Go back to login
            if (mounted) {
              Navigator.of(context).pop();
            }
          }
        }
      }
    } catch (e) {
      print('Device binding error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.employeeLogin),
        backgroundColor: AppColors.employeeColor,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Employee Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.employeeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 60,
                    color: AppColors.employeeColor,
                  ),
                ),

                const SizedBox(height: 32),

                // Title
                const Text(
                  AppStrings.employeeLogin,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Enter CompanyCode-EmployeeID and PIN',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 40),

                // Employee ID Input
                TextField(
                  controller: _employeeIdController,
                  decoration: InputDecoration(
                    labelText: AppStrings.employeeId,
                    prefixIcon: const Icon(Icons.badge),
                    helperText: 'Example: COMPANY1-EMP001',
                    enabled: !_showPinInput,
                  ),
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.characters,
                  onSubmitted: (_) => _handleIdSubmit(),
                ),

                const SizedBox(height: 20),

                // PIN Input (shown after ID entry)
                if (_showPinInput) ...[
                  const Text(
                    'Enter your 4-6 digit PIN',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  PinCodeTextField(
                    appContext: context,
                    length: 6,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    controller: _pinController,
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(8),
                      fieldHeight: 60,
                      fieldWidth: 50,
                      activeColor: AppColors.employeeColor,
                      selectedColor: AppColors.employeeColor,
                      inactiveColor: AppColors.borderLight,
                    ),
                    onCompleted: (pin) {
                      _handlePinLogin();
                    },
                    onChanged: (value) {
                      setState(() {
                        _errorMessage = null;
                      });
                    },
                  ),
                ],

                const SizedBox(height: 20),

                // Error Message
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: AppColors.error, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Submit Button
                if (!_showPinInput)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleIdSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.employeeColor,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Continue'),
                    ),
                  ),

                if (_showPinInput)
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handlePinLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.employeeColor,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(AppStrings.loginButton),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Biometric Login Button
                      if (_canUseBiometric)
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _handleBiometricLogin,
                          icon: const Icon(Icons.fingerprint),
                          label: const Text('Use Biometric'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.employeeColor,
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Back Button
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _showPinInput = false;
                            _pinController.clear();
                            _errorMessage = null;
                          });
                        },
                        child: const Text('Change Employee ID'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

