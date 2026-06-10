import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_strings.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../shared/models/project_model.dart';
import '../../../shared/models/attendance_model.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/project_provider.dart';
import '../../../shared/providers/attendance_provider.dart';
import '../../../shared/services/location_service.dart';
import '../../../shared/services/nfc_service.dart';
import '../../../shared/services/device_service.dart';

/// Check-in screen with multiple check-in methods
class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  final _locationService = LocationService();
  final _nfcService = NFCService();
  final _deviceService = DeviceService();

  ProjectModel? _selectedProject;
  bool _isLoading = false;
  String? _errorMessage;

  bool get _requiresAllEnabledMethods =>
      _selectedProject?.checkInRequirement ==
      AppConstants.checkInRequirementAllEnabled;

  List<String> get _enabledCheckInMethods {
    final project = _selectedProject;
    if (project == null) return const [];
    return <String>[
      if (project.supportsGPS) AppConstants.checkInMethodGPS,
      if (project.supportsNFC) AppConstants.checkInMethodNFC,
      if (project.supportsQR) AppConstants.checkInMethodQR,
      if (project.supportsManual) AppConstants.checkInMethodManual,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(employeeProjectsProvider);
    final activeAttendances = ref.watch(todayAllActiveAttendancesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Check In'),
        backgroundColor: AppColors.success,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Status - show all active attendances
            activeAttendances.when(
              data: (attendanceList) {
                if (attendanceList.isNotEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active Check-ins (${attendanceList.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...attendanceList.map((attendance) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _buildActiveAttendanceCard(attendance),
                          )),
                    ],
                  );
                }

                return _buildStatusCard(
                  icon: Icons.info_outline,
                  title: 'Ready to Check In',
                  subtitle: 'Select a project and check-in method below',
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildStatusCard(
                icon: Icons.error,
                title: 'Error',
                subtitle: 'Failed to load status',
              ),
            ),

            const SizedBox(height: 24),

            // Project Selection
            const Text(
              'Select Project',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 12),

            projects.when(
              data: (projectList) {
                if (projectList.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No projects assigned',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  );
                }

                // Keep selection in sync with latest assigned projects.
                // Auto-select first project so check-in methods are immediately enabled.
                final hasSelectedProject = _selectedProject != null &&
                    projectList.any((p) => p.projectId == _selectedProject!.projectId);
                if (!hasSelectedProject) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    setState(() {
                      _selectedProject = projectList.first;
                    });
                  });
                }

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: DropdownButtonFormField<ProjectModel>(
                      value: hasSelectedProject ? _selectedProject : projectList.first,
                      decoration: const InputDecoration(
                        labelText: 'Project',
                        prefixIcon: Icon(Icons.folder),
                        border: OutlineInputBorder(),
                      ),
                      items: projectList.map((project) {
                        return DropdownMenuItem(
                          value: project,
                          child: Text(project.name),
                        );
                      }).toList(),
                      onChanged: (project) {
                        setState(() {
                          _selectedProject = project;
                          _errorMessage = null;
                        });
                      },
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error loading projects: $error'),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Check-in Methods
            const Text(
              'Check-In Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 12),

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
              const SizedBox(height: 12),
            ],

            // Combined all-method check-in when project requires all enabled methods
            if (_requiresAllEnabledMethods) ...[
              _buildCheckInMethodCard(
                icon: Icons.verified_user,
                title: 'All Methods Required',
                subtitle: 'Complete all enabled checks to check in',
                color: AppColors.success,
                onTap: () => _handleAllRequiredCheckIn(),
                enabled: _selectedProject != null && !_isLoading,
              ),
              const SizedBox(height: 12),
            ],

            // GPS Check-in (only for any-one mode)
            if ((_selectedProject?.supportsGPS ?? false) && !_requiresAllEnabledMethods) ...[
              _buildCheckInMethodCard(
                icon: Icons.location_on,
                title: AppStrings.checkInMethodGPS,
                subtitle: 'Use your location to check in',
                color: AppColors.gpsColor,
                onTap: () => _handleGPSCheckIn(),
                enabled: _selectedProject != null && !_isLoading,
              ),
              const SizedBox(height: 12),
            ],

            // NFC Check-in (only for any-one mode)
            if ((_selectedProject?.supportsNFC ?? false) && !_requiresAllEnabledMethods) ...[
              _buildCheckInMethodCard(
                icon: Icons.nfc,
                title: AppStrings.checkInMethodNFC,
                subtitle: 'Tap your phone to NFC tag',
                color: AppColors.nfcColor,
                onTap: () => _handleNFCCheckIn(),
                enabled: _selectedProject != null && !_isLoading,
              ),
              const SizedBox(height: 12),
            ],

            // QR Code Check-in (only for any-one mode)
            if ((_selectedProject?.supportsQR ?? false) && !_requiresAllEnabledMethods) ...[
              _buildCheckInMethodCard(
                icon: Icons.qr_code_scanner,
                title: AppStrings.checkInMethodQR,
                subtitle: 'Scan project QR code',
                color: AppColors.qrColor,
                onTap: () => _handleQRCheckIn(),
                enabled: _selectedProject != null && !_isLoading,
              ),
              const SizedBox(height: 12),
            ],

            // Manual Check-in (only for any-one mode)
            if ((_selectedProject?.supportsManual ?? false) && !_requiresAllEnabledMethods) ...[
              _buildCheckInMethodCard(
                icon: Icons.edit_location,
                title: 'Manual Check-in',
                subtitle: 'Check in manually (requires approval)',
                color: AppColors.manualColor,
                onTap: () => _handleManualCheckIn(),
                enabled: _selectedProject != null && !_isLoading,
              ),
              const SizedBox(height: 12),
            ],

            // Show message if no check-in methods available
            if (_selectedProject != null && 
                !(_selectedProject!.supportsGPS || 
                  _selectedProject!.supportsNFC || 
                  _selectedProject!.supportsQR || 
                  _selectedProject!.supportsManual)) ...[
              Card(
                color: AppColors.warning.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: AppColors.warning),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No check-in methods enabled for this project. Please contact your supervisor.',
                          style: TextStyle(color: AppColors.warning),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Info Card
            Card(
              color: AppColors.info.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: AppColors.info, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Maximum ${AppConstants.maxCheckInsPerDay} check-ins per project per day',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.success),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildActiveAttendanceCard(AttendanceModel attendance) {
    final checkInTime = attendance.checkInTime;
    final timeStr = '${checkInTime.hour.toString().padLeft(2, '0')}:${checkInTime.minute.toString().padLeft(2, '0')}';
    
    // Try to find project name
    String projectName = attendance.projectId;
    final projects = ref.read(employeeProjectsProvider);
    projects.whenData((projectList) {
      final match = projectList.where((p) => p.projectId == attendance.projectId);
      if (match.isNotEmpty) {
        projectName = match.first.name;
      }
    });

    return Card(
      color: AppColors.success.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check_circle, color: AppColors.success, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    projectName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Checked in at $timeStr',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => _handleCheckOut(attendance.attendanceId),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              child: const Text('Check Out', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckInMethodCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    return Card(
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: enabled ? 1.0 : 0.5,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 32, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 20,
                  color: enabled ? color : AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleGPSCheckIn() async {
    if (!mounted) return;
    if (_selectedProject == null) {
      setState(() {
        _errorMessage = 'Please select a project first';
      });
      return;
    }

    // Check if project has a location configured
    if (_selectedProject!.location == null) {
      setState(() {
        _errorMessage = 'This project has no GPS location configured. Please contact your supervisor to set the project location.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final projectLocation = _selectedProject!.location!;
      
      // Validate location
      final locationData = await _locationService.getValidatedLocation(
        projectLat: projectLocation.latitude,
        projectLon: projectLocation.longitude,
        projectRadius: projectLocation.radiusInMeters,
      );
      if (!mounted) return;

      if (!locationData['withinRadius']) {
        throw 'You are ${locationData['distanceFormatted']} away from the project site. Please move closer.';
      }

      // Get device info
      final deviceInfo = await _deviceService.getDeviceInfo();

      // Perform check-in
      final user = ref.read(currentUserProvider).value;
      if (user == null) throw 'User not logged in';

      final success = await ref.read(attendanceControllerProvider.notifier).checkIn(
            userId: user.uid,
            projectId: _selectedProject!.projectId,
            checkInMethod: AppConstants.checkInMethodGPS,
            deviceInfo: deviceInfo,
          );

      if (success && mounted) {
        await Future.delayed(const Duration(milliseconds: 800));
        _showSuccessDialog('GPS Check-in Successful', 
            'Checked in at ${locationData['address']}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleAllRequiredCheckIn() async {
    if (!mounted) return;
    if (_selectedProject == null) {
      setState(() {
        _errorMessage = 'Please select a project first';
      });
      return;
    }

    final methods = _enabledCheckInMethods;
    if (methods.isEmpty) {
      setState(() {
        _errorMessage = 'No check-in methods enabled for this project';
      });
      return;
    }
    if (methods.contains(AppConstants.checkInMethodManual)) {
      setState(() {
        _errorMessage =
            'Project configuration is invalid: "All Enabled Methods" cannot include Manual. Please contact your supervisor.';
      });
      return;
    }
    if (methods.length < 2) {
      setState(() {
        _errorMessage =
            'Project configuration is invalid: "All Enabled Methods" requires at least 2 check-in methods.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? validatedQrCode;
      if (methods.contains(AppConstants.checkInMethodGPS)) {
        if (_selectedProject!.location == null) {
          throw 'This project has no GPS location configured. Please contact your supervisor to set the project location.';
        }
        final projectLocation = _selectedProject!.location!;
        final locationData = await _locationService.getValidatedLocation(
          projectLat: projectLocation.latitude,
          projectLon: projectLocation.longitude,
          projectRadius: projectLocation.radiusInMeters,
        );
        if (!mounted) return;
        if (!locationData['withinRadius']) {
          throw 'You are ${locationData['distanceFormatted']} away from the project site. Please move closer.';
        }
      }

      if (methods.contains(AppConstants.checkInMethodNFC)) {
        final nfcAvailable = await _nfcService.isNFCAvailable();
        if (!mounted) return;
        if (!nfcAvailable) {
          throw 'NFC is not available on this device. Please enable NFC in your phone Settings.';
        }
        final tagId = await _nfcService.readNFCTagWithMessage(
          message: 'Hold your phone near the NFC tag at the project site',
        );
        if (!mounted) return;
        if (tagId == null || tagId.isEmpty) {
          throw 'Could not read NFC tag. Please try again and hold your phone steady.';
        }
        final expectedTagId = _selectedProject!.nfcTagId;
        if (expectedTagId != null &&
            expectedTagId.isNotEmpty &&
            expectedTagId.toUpperCase().trim() != tagId.toUpperCase().trim()) {
          throw 'NFC tag does not match this project.\nExpected: $expectedTagId\nScanned: $tagId';
        }
      }

      if (methods.contains(AppConstants.checkInMethodQR)) {
        final qrCode = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (context) => QRScannerScreen(
              projectId: _selectedProject!.projectId,
              expectedQRCode: _selectedProject!.qrCode,
            ),
          ),
        );
        if (!mounted) return;
        if (qrCode == null) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
          return;
        }
        _validateProjectQRCode(qrCode);
        validatedQrCode = qrCode;
      }

      final deviceInfo = await _deviceService.getDeviceInfo();
      if (!mounted) return;
      if (!mounted) return;
      final user = ref.read(currentUserProvider).value;
      if (user == null) throw 'User not logged in';

      final success = await ref.read(attendanceControllerProvider.notifier).checkIn(
            userId: user.uid,
            projectId: _selectedProject!.projectId,
            checkInMethod: AppConstants.checkInMethodMulti,
            deviceInfo: deviceInfo,
            notes: 'All-method check-in verified. Methods: ${methods.join(", ")}${validatedQrCode != null ? ". QR: $validatedQrCode" : ""}',
          );
      if (!mounted) return;

      if (success && mounted) {
        await Future.delayed(const Duration(milliseconds: 1000));
        _showSuccessDialog(
          'All-Methods Check-in Successful',
          'Checked in after completing all enabled verification methods',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleNFCCheckIn() async {
    if (!mounted) return;
    if (_selectedProject == null) {
      setState(() {
        _errorMessage = 'Please select a project first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check NFC availability first
      final nfcAvailable = await _nfcService.isNFCAvailable();
      if (!mounted) return;
      if (!nfcAvailable) {
        throw 'NFC is not available on this device. Please enable NFC in your phone Settings.';
      }

      // Read NFC tag (now properly waits for tag discovery via Completer)
      final tagId = await _nfcService.readNFCTagWithMessage(
        message: 'Hold your phone near the NFC tag at the project site',
      );
      if (!mounted) return;

      if (tagId == null || tagId.isEmpty) {
        throw 'Could not read NFC tag. Please try again and hold your phone steady.';
      }

      // Validate tag if project has a registered NFC tag ID
      final expectedTagId = _selectedProject!.nfcTagId;
      if (expectedTagId != null && expectedTagId.isNotEmpty) {
        // Case-insensitive comparison (NTAG UIDs are hex strings)
        if (expectedTagId.toUpperCase().trim() != tagId.toUpperCase().trim()) {
          throw 'NFC tag does not match this project.\nExpected: $expectedTagId\nScanned: $tagId\n\nPlease use the correct NFC tag for this project.';
        }
      }
      // If no tag ID is configured, accept any tag (setup flexibility)

      // Get device info
      final deviceInfo = await _deviceService.getDeviceInfo();
      if (!mounted) return;

      // Perform check-in
      final user = ref.read(currentUserProvider).value;
      if (user == null) throw 'User not logged in';

      final success = await ref.read(attendanceControllerProvider.notifier).checkIn(
            userId: user.uid,
            projectId: _selectedProject!.projectId,
            checkInMethod: AppConstants.checkInMethodNFC,
            deviceInfo: deviceInfo,
            notes: 'NFC Tag: $tagId',
          );

      if (success && mounted) {
        await Future.delayed(const Duration(milliseconds: 800));
        _showSuccessDialog('NFC Check-in Successful',
            'Checked in using NFC tag ($tagId)');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleQRCheckIn() async {
    if (!mounted) return;
    if (_selectedProject == null) {
      setState(() {
        _errorMessage = 'Please select a project first';
      });
      return;
    }

    if (!_selectedProject!.supportsQR) {
      setState(() {
        _errorMessage = 'QR code check-in is not enabled for this project';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Navigate to QR scanner screen
      final qrCode = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => QRScannerScreen(
            projectId: _selectedProject!.projectId,
            expectedQRCode: _selectedProject!.qrCode,
          ),
        ),
      );
      if (!mounted) return;

      if (qrCode == null) {
        // User cancelled scanning
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Verify QR code matches one of the project's active QR codes
      _validateProjectQRCode(qrCode);

      // Get device info
      final deviceInfo = await _deviceService.getDeviceInfo();
      if (!mounted) return;

      // Perform check-in
      final user = ref.read(currentUserProvider).value;
      if (user == null) throw 'User not logged in';

      final success = await ref.read(attendanceControllerProvider.notifier).checkIn(
            userId: user.uid,
            projectId: _selectedProject!.projectId,
            checkInMethod: AppConstants.checkInMethodQR,
            deviceInfo: deviceInfo,
            notes: 'QR Code: $qrCode',
          );

      if (success && mounted) {
        print('');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('✅ QR CHECK-IN SUCCESSFUL');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('Waiting for Firestore write to complete...');
        
        // Wait longer for Firestore write to complete and propagate
        await Future.delayed(const Duration(milliseconds: 1200));
        
        print('✅ Firestore write should be complete');
        print('Showing success dialog...');
        
        // Show success dialog (it will handle provider refresh and navigation)
        _showSuccessDialog('QR Check-in Successful',
            'Checked in using QR code');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _validateProjectQRCode(String qrCode) {
    print('🔍 QR Code Validation:');
    print('   Expected QRs: ${_selectedProject!.qrCodes.isNotEmpty ? _selectedProject!.qrCodes : [_selectedProject!.qrCode]}');
    print('   Scanned QR: $qrCode');

    final expectedQRCodes = _selectedProject!.qrCodes.isNotEmpty
        ? _selectedProject!.qrCodes
        : (_selectedProject!.qrCode != null ? [_selectedProject!.qrCode!] : <String>[]);

    if (expectedQRCodes.isNotEmpty && !expectedQRCodes.contains(qrCode)) {
      final scannedParts = qrCode.split(':');
      final scannedProjectId = scannedParts.length >= 2 ? scannedParts[1] : null;
      final matchesByProjectId = expectedQRCodes.any((expected) {
        final expectedParts = expected.split(':');
        return expectedParts.length >= 2 &&
            scannedProjectId != null &&
            expectedParts[1] == scannedProjectId;
      });
      if (!matchesByProjectId) {
        throw 'QR code does not match this project.';
      }
    }
  }

  Future<void> _handleManualCheckIn() async {
    if (!mounted) return;
    if (_selectedProject == null) {
      setState(() {
        _errorMessage = 'Please select a project first';
      });
      return;
    }

    if (!_selectedProject!.supportsManual) {
      setState(() {
        _errorMessage = 'Manual check-in is not enabled for this project';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get device info
      final deviceInfo = await _deviceService.getDeviceInfo();
      if (!mounted) return;

      // Perform check-in
      final user = ref.read(currentUserProvider).value;
      if (user == null) throw 'User not logged in';

      final success = await ref.read(attendanceControllerProvider.notifier).checkIn(
            userId: user.uid,
            projectId: _selectedProject!.projectId,
            checkInMethod: AppConstants.checkInMethodManual,
            deviceInfo: deviceInfo,
            notes: 'Manual check-in - requires supervisor approval',
          );

      if (success && mounted) {
        // Wait for Firestore write to complete
        await Future.delayed(const Duration(milliseconds: 800));
        
        // Show success dialog (it will handle provider refresh)
        _showSuccessDialog('Manual Check-in Requested',
            'Your check-in request has been submitted. Waiting for supervisor approval.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleCheckOut(String attendanceId) async {
    print('');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔵 CHECK-OUT BUTTON CLICKED');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('Attendance ID from button: $attendanceId');
    
    final user = ref.read(currentUserProvider).value;
    if (user == null) {
      print('❌ No user found');
      return;
    }
    print('✅ User: ${user.uid}');

    // Get all active attendances to find the specific one
    final allActiveAttendances = ref.read(todayAllActiveAttendancesProvider);
    final attendanceList = allActiveAttendances.value ?? [];
    
    final attendance = attendanceList.where((a) => a.attendanceId == attendanceId).firstOrNull;
    if (attendance == null) {
      print('❌ No active attendance found for ID: $attendanceId');
      setState(() {
        _errorMessage = 'No active check-in found';
      });
      return;
    }
    
    print('✅ Attendance found:');
    print('   Attendance ID: ${attendance.attendanceId}');
    print('   Project ID: ${attendance.projectId}');
    print('   Check-in time: ${attendance.checkInTime}');
    print('   Status: ${attendance.status}');

    // Get project details to check which check-out methods are required
    final projects = ref.read(employeeProjectsProvider);
    final projectList = projects.value ?? [];
    
    ProjectModel? project;
    try {
      project = projectList.firstWhere(
        (p) => p.projectId == attendance.projectId,
      );
      print('✅ Project found: ${project.name}');
      print('   Supports GPS: ${project.supportsGPS}');
      print('   Supports NFC: ${project.supportsNFC}');
      print('   Supports QR: ${project.supportsQR}');
      print('   Supports Manual: ${project.supportsManual}');
    } catch (e) {
      print('❌ Project not found: ${attendance.projectId}');
      print('   Available projects:');
      for (var p in projectList) {
        print('   - ${p.projectId}: ${p.name}');
      }
      setState(() {
        _errorMessage = 'Project not found';
      });
      return;
    }

    // Show check-out method selection dialog
    final nonNullProject = project;
    
    final checkOutMethod = await _showCheckOutMethodDialog(nonNullProject);
    if (checkOutMethod == null) {
      print('❌ User cancelled method selection');
      return; // User cancelled
    }
    print('✅ Method selected: $checkOutMethod');

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Validate based on selected method
      String? validationNote;
      
      if (checkOutMethod == AppConstants.checkInMethodNFC) {
        final tagId = await _nfcService.readNFCTagWithMessage(
          message: 'Hold your phone near the NFC tag to check out',
        );

        if (tagId == null || tagId.isEmpty) {
          throw 'Could not read NFC tag. Please try again.';
        }

        // Validate tag if project has a registered NFC tag ID
        final expectedTagId = nonNullProject.nfcTagId;
        if (expectedTagId != null && expectedTagId.isNotEmpty) {
          if (expectedTagId.toUpperCase().trim() != tagId.toUpperCase().trim()) {
            throw 'NFC tag does not match this project.\nExpected: $expectedTagId\nScanned: $tagId';
          }
        }
        validationNote = 'NFC Tag: $tagId';
      } else if (checkOutMethod == AppConstants.checkInMethodQR) {
        // Scan and validate QR code
        final qrCode = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (context) => QRScannerScreen(
              projectId: nonNullProject.projectId,
              expectedQRCode: nonNullProject.qrCode ?? '',
            ),
          ),
        );

        if (qrCode == null) {
          setState(() {
            _isLoading = false;
          });
          return; // User cancelled
        }

        // STRICT VALIDATION: QR code MUST match one of project's active QR codes
        if (nonNullProject.supportsQR) {
          final expectedQRCodes = nonNullProject.qrCodes.isNotEmpty
              ? nonNullProject.qrCodes
              : (nonNullProject.qrCode != null && nonNullProject.qrCode!.isNotEmpty
                  ? [nonNullProject.qrCode!]
                  : <String>[]);
          if (expectedQRCodes.isEmpty) {
            // QR enabled but no code set - accept any QR
          } else {
            final directMatch = expectedQRCodes.contains(qrCode);
            final scannedParts = qrCode.split(':');
            final scannedProjectId = scannedParts.length >= 2 ? scannedParts[1] : null;
            final projectIdMatch = expectedQRCodes.any((expected) {
              final expectedParts = expected.split(':');
              return expectedParts.length >= 2 &&
                  scannedProjectId != null &&
                  expectedParts[1] == scannedProjectId;
            });
            if (!directMatch && !projectIdMatch) {
              throw 'QR code does not match this project';
            }
          }
        }
        validationNote = 'QR Code: $qrCode';
      }

      // Perform check-out with method
      print('🔄 Calling attendanceController.checkOut()...');
      print('   Attendance ID to update: $attendanceId');
      
      final success = await ref.read(attendanceControllerProvider.notifier).checkOut(
            userId: user.uid,
            attendanceId: attendanceId,
            checkOutMethod: checkOutMethod,
            notes: validationNote,
          );

      if (success && mounted) {
        print('✅ Check-out successful!');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        
        // Invalidate providers immediately
        ref.invalidate(todayActiveAttendanceProvider);
        ref.invalidate(todayAllActiveAttendancesProvider);
        ref.read(attendanceRefreshTriggerProvider.notifier).state++;
        
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          _showSuccessDialog('Check-out Successful',
              'Your working hours have been recorded');
        }
      } else {
        print('❌ Check-out failed: success=$success, mounted=$mounted');
      }
    } catch (e, stackTrace) {
      print('ERROR during check-out: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<String?> _showCheckOutMethodDialog(ProjectModel project) async {
    final availableMethods = <String>[];
    
    // Add methods based on project configuration
    if (project.supportsGPS) availableMethods.add(AppConstants.checkInMethodGPS);
    if (project.supportsNFC) availableMethods.add(AppConstants.checkInMethodNFC);
    if (project.supportsQR) availableMethods.add(AppConstants.checkInMethodQR);
    if (project.supportsManual) availableMethods.add(AppConstants.checkInMethodManual);

    if (availableMethods.isEmpty) {
      // No methods available, allow simple check-out
      return 'manual';
    }

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Check-Out Method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: availableMethods.map((method) {
            String title;
            IconData icon;
            Color color;

            switch (method) {
              case AppConstants.checkInMethodGPS:
                title = 'GPS Location';
                icon = Icons.location_on;
                color = AppColors.gpsColor;
                break;
              case AppConstants.checkInMethodNFC:
                title = 'NFC Tag';
                icon = Icons.nfc;
                color = AppColors.nfcColor;
                break;
              case AppConstants.checkInMethodQR:
                title = 'QR Code';
                icon = Icons.qr_code_scanner;
                color = AppColors.qrColor;
                break;
              default:
                title = 'Manual';
                icon = Icons.edit_location;
                color = AppColors.manualColor;
            }

            return ListTile(
              leading: Icon(icon, color: color),
              title: Text(title),
              onTap: () => Navigator.pop(context, method),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String title, String message) {
    final widgetNavigator = Navigator.of(context);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await Future.delayed(const Duration(milliseconds: 200));
              
              if (!mounted) return;
              
              // Invalidate providers BEFORE popping the screen
              ref.invalidate(todayActiveAttendanceProvider);
              ref.invalidate(todayAllActiveAttendancesProvider);
              ref.invalidate(currentUserProvider);
              ref.read(attendanceRefreshTriggerProvider.notifier).state++;
              await Future.delayed(const Duration(milliseconds: 800));
              
              if (mounted) {
                widgetNavigator.pop();
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// QR Scanner Screen for scanning project QR codes
class QRScannerScreen extends StatefulWidget {
  final String projectId;
  final String? expectedQRCode;

  const QRScannerScreen({
    Key? key,
    required this.projectId,
    this.expectedQRCode,
  }) : super(key: key);

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: AppColors.qrColor,
      ),
      body: Stack(
        children: [
          // QR Scanner Camera View
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final barcode = barcodes.first;
                if (barcode.rawValue != null) {
                  // Stop scanning
                  _controller.stop();
                  
                  // Return scanned QR code
                  Navigator.pop(context, barcode.rawValue);
                }
              }
            },
          ),
          
          // Overlay with instructions
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Position QR code within the frame',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Project ID: ${widget.projectId}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Scanning frame overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.qrColor,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          
          // Bottom instructions
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Scan the QR code at the project location',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                    label: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}



