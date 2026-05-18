import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_strings.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/document_provider.dart';
import 'employee_list_screen.dart';

/// Screen for supervisors to upload employee documents
class UploadDocumentScreen extends ConsumerStatefulWidget {
  const UploadDocumentScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<UploadDocumentScreen> createState() =>
      _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends ConsumerState<UploadDocumentScreen> {
  final _imagePicker = ImagePicker();

  UserModel? _selectedEmployee;
  String? _selectedDocumentType;
  File? _selectedFile;
  bool _isUploading = false;
  String? _errorMessage;

  final List<Map<String, String>> _documentTypes = [
    {'value': 'id_proof', 'label': 'ID Proof'},
    {'value': 'bank_statement', 'label': 'Bank Statement'},
    {'value': 'contract', 'label': 'Employment Contract'},
    {'value': 'other', 'label': 'Other Document'},
  ];

  /// Take photo with camera
  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (photo != null) {
        setState(() {
          _selectedFile = File(photo.path);
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to take photo: ${e.toString()}';
      });
    }
  }

  /// Choose file from gallery/storage
  Future<void> _chooseFile() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to choose file: ${e.toString()}';
      });
    }
  }

  /// Handle document upload
  Future<void> _handleUpload() async {
    if (_selectedEmployee == null) {
      setState(() {
        _errorMessage = 'Please select an employee';
      });
      return;
    }

    if (_selectedDocumentType == null) {
      setState(() {
        _errorMessage = 'Please select document type';
      });
      return;
    }

    if (_selectedFile == null) {
      setState(() {
        _errorMessage = 'Please select a file to upload';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) {
        throw 'Supervisor not found';
      }

      final success =
          await ref.read(documentControllerProvider.notifier).uploadDocument(
                userId: _selectedEmployee!.uid,
                file: _selectedFile!,
                documentType: _selectedDocumentType!,
                uploadedBy: currentUser.uid,
              );

      if (success && mounted) {
        _showSuccessDialog();
      } else {
        final error = ref.read(documentControllerProvider).error;
        setState(() {
          _errorMessage = error ?? 'Failed to upload document';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  /// Show success dialog
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 32),
            SizedBox(width: 12),
            Text('Upload Successful'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Document has been uploaded successfully for ${_selectedEmployee!.name}.',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Employee', _selectedEmployee!.name),
                  _buildInfoRow('Document Type',
                      _getDocumentTypeLabel(_selectedDocumentType!)),
                  _buildInfoRow('File', _selectedFile!.path.split('/').last),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back
            },
            child: const Text('Done'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              // Reset form for next upload
              setState(() {
                _selectedFile = null;
                _selectedDocumentType = null;
                _selectedEmployee = null;
              });
            },
            child: const Text('Upload Another'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDocumentTypeLabel(String value) {
    return _documentTypes.firstWhere((type) => type['value'] == value)['label']!;
  }

  @override
  Widget build(BuildContext context) {
    final employees = ref.watch(supervisorEmployeesProvider);
    final uploadProgress = ref.watch(documentControllerProvider).uploadProgress;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.uploadDocument),
        backgroundColor: AppColors.supervisorColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                        'Upload employee documents like ID proof, bank statements, or contracts.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Select Employee
            const Text(
              'Select Employee',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 12),

            employees.when(
              data: (employeeList) {
                if (employeeList.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No employees available',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: DropdownButtonFormField<UserModel>(
                      value: _selectedEmployee,
                      decoration: const InputDecoration(
                        labelText: 'Employee',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      items: employeeList.map((employee) {
                        return DropdownMenuItem(
                          value: employee,
                          child: Text(
                            '${employee.name} (${employee.displayId})',
                          ),
                        );
                      }).toList(),
                      onChanged: (employee) {
                        setState(() {
                          _selectedEmployee = employee;
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
                  child: Text('Error loading employees: $error'),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Select Document Type
            const Text(
              'Document Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<String>(
                  value: _selectedDocumentType,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    prefixIcon: Icon(Icons.folder),
                    border: OutlineInputBorder(),
                  ),
                  items: _documentTypes.map((type) {
                    return DropdownMenuItem(
                      value: type['value'],
                      child: Text(type['label']!),
                    );
                  }).toList(),
                  onChanged: (type) {
                    setState(() {
                      _selectedDocumentType = type;
                      _errorMessage = null;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Select File
            const Text(
              'Choose File',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isUploading ? null : _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isUploading ? null : _chooseFile,
                    icon: const Icon(Icons.file_upload),
                    label: const Text('Choose File'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Selected File Preview
            if (_selectedFile != null) ...[
              Card(
                color: AppColors.success.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file,
                          color: AppColors.success),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'File Selected',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedFile!.path.split('/').last,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.error),
                        onPressed: () {
                          setState(() {
                            _selectedFile = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Upload Progress
            if (_isUploading && uploadProgress > 0) ...[
              LinearProgressIndicator(value: uploadProgress),
              const SizedBox(height: 8),
              Text(
                'Uploading: ${(uploadProgress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
            ],

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
              const SizedBox(height: 16),
            ],

            // Upload Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _handleUpload,
                icon: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.cloud_upload),
                label: Text(_isUploading ? 'Uploading...' : 'Upload Document'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.supervisorColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

