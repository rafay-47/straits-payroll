import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_strings.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/services/company_service.dart';
import '../../../shared/models/company_model.dart';
import '../../../shared/widgets/company_logo_widget.dart';
import '../supervisor/supervisor_dashboard_screen.dart';

/// Supervisor login screen with company code validation
class SupervisorLoginScreen extends ConsumerStatefulWidget {
  const SupervisorLoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SupervisorLoginScreen> createState() =>
      _SupervisorLoginScreenState();
}

class _SupervisorLoginScreenState
    extends ConsumerState<SupervisorLoginScreen> {
  final _companyCodeController = TextEditingController();
  final _loginIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  final _companyService = CompanyService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _showLoginFields = false;
  String? _errorMessage;
  CompanyModel? _validatedCompany;

  @override
  void dispose() {
    _companyCodeController.dispose();
    _loginIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Validate company code
  Future<void> _validateCompanyCode() async {
    final code = _companyCodeController.text.trim().toUpperCase();
    
    if (code.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter company code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final company = await _companyService.getCompanyByCode(code);
      
      if (company == null) {
        setState(() {
          _errorMessage = 'Invalid company code: $code';
          _isLoading = false;
        });
        return;
      }

      if (!company.isActive) {
        setState(() {
          _errorMessage = 'Company is suspended. Please contact support.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _validatedCompany = company;
        _showLoginFields = true;
        _errorMessage = null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error validating company code: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  /// Handle login with company validation
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_validatedCompany == null) {
      setState(() {
        _errorMessage = 'Please validate company code first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔑 SUPERVISOR LOGIN ATTEMPT');
    print('Company: ${_validatedCompany!.name} (${_validatedCompany!.companyCode})');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final authEmail = await firestoreService.resolveSupervisorOrAdminLoginEmail(
        companyId: _validatedCompany!.id,
        companyCode: _validatedCompany!.companyCode,
        identifier: _loginIdController.text,
      );

      final authService = ref.read(authServiceProvider);
      await authService.signInWithCompany(
        companyCode: _validatedCompany!.companyCode,
        email: authEmail,
        password: _passwordController.text,
      );

      print('✅ Login successful with company validation!');

      if (!mounted) return;

      setState(() => _isLoading = false);

      // Navigate to supervisor dashboard
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const SupervisorDashboardScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      print('❌ EXCEPTION during login: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      
      // Sign out on error
      try {
        await ref.read(authServiceProvider).signOut();
      } catch (_) {}
    }
  }

  /// Reset to company code entry
  void _resetToCompanyCode() {
    setState(() {
      _showLoginFields = false;
      _validatedCompany = null;
      _loginIdController.clear();
      _passwordController.clear();
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.supervisorLogin),
        backgroundColor: AppColors.supervisorColor,
        actions: [
          if (_showLoginFields)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _resetToCompanyCode,
              tooltip: 'Change company',
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Company Logo or Supervisor Icon
                  CompanyLogoWidget(
                    size: 100,
                    borderRadius: BorderRadius.circular(20),
                    backgroundColor: AppColors.supervisorColor.withOpacity(0.1),
                    iconColor: AppColors.supervisorColor,
                    imageUrl: _validatedCompany?.logo,
                    fallbackIcon: Icons.supervisor_account,
                    ),

                  const SizedBox(height: 32),

                  // Title
                  Text(
                    _validatedCompany?.name ?? AppStrings.supervisorLogin,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    _showLoginFields 
                        ? 'Enter your credentials'
                        : 'Manage employees and projects',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

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
                          const Icon(Icons.error,
                              color: AppColors.error, size: 20),
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

                  // Company Code Input (Step 1)
                  if (!_showLoginFields) ...[
                    TextFormField(
                      controller: _companyCodeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Company Code',
                        hintText: 'e.g., ABC',
                        prefixIcon: Icon(Icons.business),
                      ),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _validateCompanyCode(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter company code';
                        }
                        if (value.length < 2) {
                          return 'Company code must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _validateCompanyCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.supervisorColor,
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
                  ],

                  // Email & Password Inputs (Step 2)
                  if (_showLoginFields) ...[
                    // Email or CompanyCode-CustomID (company already validated in step 1)
                    TextFormField(
                      controller: _loginIdController,
                      decoration: const InputDecoration(
                        labelText: 'Email or supervisor ID',
                        hintText: 'you@company.com or SUP001 or ABC-SUP001',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.none,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        final v = value?.trim() ?? '';
                        if (v.isEmpty) {
                          return 'Please enter your email or supervisor ID';
                        }
                        if (v.contains('@')) {
                          final parts = v.split('@');
                          if (parts.length != 2 ||
                              parts[0].isEmpty ||
                              parts[1].isEmpty) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        }
                        if (v.length < 3) {
                          return 'ID too short (use e.g. SUP001)';
                        }
                        final idPattern = RegExp(r'^[A-Za-z0-9_.@-]+$');
                        if (!idPattern.hasMatch(v)) {
                          return 'Use letters, numbers, or dash (e.g. ABC-SUP001)';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Password Input
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleLogin(),
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

                    const SizedBox(height: 12),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Forgot password - Coming soon'),
                            ),
                          );
                        },
                        child: Text(AppStrings.forgotPassword),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.supervisorColor,
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
                  ],

                  const SizedBox(height: 60),

                  // Footer
                  Text(
                    'Supervisor access only',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

