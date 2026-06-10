import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:straights_psyroll/shared/models/document_model.dart';
import 'package:straights_psyroll/shared/models/user_model.dart';
import 'package:straights_psyroll/shared/providers/auth_provider.dart';
import 'package:straights_psyroll/shared/providers/document_provider.dart';
import 'package:straights_psyroll/shared/constants/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

/// Screen for viewing and managing an employee's documents
class EmployeeDocumentsScreen extends ConsumerWidget {
  final UserModel employee;

  const EmployeeDocumentsScreen({
    Key? key,
    required this.employee,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(employeeDocumentsProvider(employee.uid));

    return Scaffold(
      appBar: AppBar(
        title: Text('${employee.name} - Documents'),
        backgroundColor: AppColors.supervisorColor,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(employeeDocumentsProvider(employee.uid));
        },
        child: documentsAsync.when(
          data: (documents) {
            if (documents.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.folder_open,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No documents yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload documents to get started',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: documents.length,
              itemBuilder: (context, index) {
                final document = documents[index];
                return _DocumentCard(
                  document: document,
                  onDelete: () async {
                    final confirm = await _showDeleteConfirmation(context);
                    if (confirm == true) {
                      await _deleteDocument(context, ref, document);
                    }
                  },
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text('Error: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(employeeDocumentsProvider(employee.uid));
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/supervisor/upload-document',
            arguments: employee,
          );
        },
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload Document'),
        backgroundColor: AppColors.supervisorColor,
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: const Text(
          'Are you sure you want to delete this document? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDocument(
    BuildContext context,
    WidgetRef ref,
    DocumentModel document,
  ) async {
    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deleting document...')),
      );

      // Delete from storage
      await ref.read(storageServiceProvider).deleteFile(document.url);

      // Delete from Firestore
      await ref.read(firestoreServiceProvider).deleteDocument(
            userId: document.userId,
            documentId: document.documentId,
          );

      // Refresh the list
      ref.invalidate(employeeDocumentsProvider(employee.uid));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document deleted successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

/// Card widget for displaying a document
class _DocumentCard extends StatelessWidget {
  final DocumentModel document;
  final VoidCallback onDelete;

  const _DocumentCard({
    required this.document,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _viewDocument(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getDocumentTypeColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getDocumentIcon(),
                      color: _getDocumentTypeColor(),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          document.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDocumentType(document.type),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'view') {
                        _viewDocument(context);
                      } else if (value == 'download') {
                        _downloadDocument(context);
                      } else if (value == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility, size: 20),
                            SizedBox(width: 12),
                            Text('View'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'download',
                        child: Row(
                          children: [
                            Icon(Icons.download, size: 20),
                            SizedBox(width: 12),
                            Text('Download'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 12),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Uploaded: ${_formatDate(document.uploadedAt)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  _buildStatusChip(document.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'approved':
        backgroundColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green[700]!;
        icon = Icons.check_circle;
        break;
      case 'pending':
        backgroundColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange[700]!;
        icon = Icons.pending;
        break;
      case 'rejected':
        backgroundColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red[700]!;
        icon = Icons.cancel;
        break;
      default:
        backgroundColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey[700]!;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getDocumentIcon() {
    switch (document.type.toLowerCase()) {
      case 'id_proof':
        return Icons.badge;
      case 'bank_statement':
        return Icons.account_balance;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getDocumentTypeColor() {
    switch (document.type.toLowerCase()) {
      case 'id_proof':
        return Colors.blue;
      case 'bank_statement':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDocumentType(String type) {
    switch (type.toLowerCase()) {
      case 'id_proof':
        return 'ID Proof';
      case 'bank_statement':
        return 'Bank Statement';
      default:
        return type.replaceAll('_', ' ').toUpperCase();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _viewDocument(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Opening document...')),
      );

      final uri = Uri.parse(document.url);
      if (await canLaunchUrl(uri)) {
        final launched =
            await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to open document')),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot open this document')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _downloadDocument(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloading document...')),
      );

      // Get storage service from provider scope
      final container = ProviderScope.containerOf(context);
      final storageService = container.read(storageServiceProvider);

      // Fetch file bytes through Firebase Auth (requires authentication)
      final bytes = await storageService.downloadFileAsBytes(document.url);

      // Get app documents directory for saving
      final dir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${dir.path}/downloads');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      // Save file with original name (prepend timestamp to avoid conflicts)
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeName = document.name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final filePath = '${downloadsDir.path}/${timestamp}_$safeName';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to: $filePath'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () async {
                final uri = Uri.file(filePath);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    }
  }
}

