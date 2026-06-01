import 'widgets/document_download_stub.dart'
    if (dart.library.html) 'widgets/document_download_web.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:straights_psyroll/shared/models/document_model.dart';
import 'package:straights_psyroll/shared/models/user_model.dart';
import 'package:straights_psyroll/shared/providers/auth_provider.dart';
import 'package:straights_psyroll/shared/providers/document_provider.dart';
import 'package:straights_psyroll/shared/constants/app_colors.dart';

/// Web Admin Screen for Document Management
class DocumentManagementScreen extends ConsumerStatefulWidget {
  const DocumentManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DocumentManagementScreen> createState() =>
      _DocumentManagementScreenState();
}

class _DocumentManagementScreenState
    extends ConsumerState<DocumentManagementScreen> {
  String _searchQuery = '';
  String _filterType = 'all'; // 'all', 'id_proof', 'bank_statement', 'other'
  String _filterStatus = 'all'; // 'all', 'pending', 'approved', 'rejected'

  @override
  Widget build(BuildContext context) {
    final documentsAsync = ref.watch(companyDocumentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Management'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(companyDocumentsProvider);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search and Filters
            Row(
              children: [
                // Search
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by employee name...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),

                // Document Type Filter
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filterType,
                    decoration: InputDecoration(
                      labelText: 'Document Type',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Types')),
                      DropdownMenuItem(
                          value: 'id_proof', child: Text('ID Proof')),
                      DropdownMenuItem(
                          value: 'bank_statement',
                          child: Text('Bank Statement')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filterType = value ?? 'all';
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),

                // Status Filter
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filterStatus,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Status')),
                      DropdownMenuItem(
                          value: 'pending', child: Text('Pending')),
                      DropdownMenuItem(
                          value: 'approved', child: Text('Approved')),
                      DropdownMenuItem(
                          value: 'rejected', child: Text('Rejected')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filterStatus = value ?? 'all';
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Documents Table
            Expanded(
              child: documentsAsync.when(
                data: (documents) {
                  // Apply filters
                  var filteredDocuments = documents.where((doc) {
                    // Search filter
                    bool matchesSearch = _searchQuery.isEmpty;
                    if (!matchesSearch) {
                      // We'll need to fetch employee name, for now just filter by ID
                      matchesSearch = doc.userId
                          .toLowerCase()
                          .contains(_searchQuery);
                    }

                    // Type filter
                    bool matchesType = _filterType == 'all' ||
                        doc.type == _filterType;

                    // Status filter
                    bool matchesStatus = _filterStatus == 'all' ||
                        doc.status == _filterStatus;

                    return matchesSearch && matchesType && matchesStatus;
                  }).toList();

                  if (filteredDocuments.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_open,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty &&
                                    _filterType == 'all' &&
                                    _filterStatus == 'all'
                                ? 'No documents yet'
                                : 'No documents found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Card(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(
                            AppColors.primary.withOpacity(0.1),
                          ),
                          columns: const [
                            DataColumn(label: Text('Employee')),
                            DataColumn(label: Text('Document Type')),
                            DataColumn(label: Text('File Name')),
                            DataColumn(label: Text('Uploaded By')),
                            DataColumn(label: Text('Upload Date')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: filteredDocuments.map((document) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  FutureBuilder<UserModel?>(
                                    future: ref
                                        .read(firestoreServiceProvider)
                                        .getUser(document.userId),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData &&
                                          snapshot.data != null) {
                                        final user = snapshot.data!;
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              user.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              'ID: ${user.systemGeneratedId ?? user.customId ?? "N/A"}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        );
                                      }
                                      return const Text('Loading...');
                                    },
                                  ),
                                ),
                                DataCell(
                                  Chip(
                                    label: Text(_formatDocumentType(
                                        document.type)),
                                    backgroundColor:
                                        _getDocumentTypeColor(document.type),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 200,
                                    child: Text(
                                      document.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  FutureBuilder<UserModel?>(
                                    future: ref
                                        .read(firestoreServiceProvider)
                                        .getUser(document.uploadedBy),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData &&
                                          snapshot.data != null) {
                                        return Text(snapshot.data!.name);
                                      }
                                      return const Text('-');
                                    },
                                  ),
                                ),
                                DataCell(
                                  Text(_formatDate(document.uploadedAt)),
                                ),
                                DataCell(
                                  Chip(
                                    label: Text(
                                      document.status.toUpperCase(),
                                    ),
                                    backgroundColor:
                                        _getStatusColor(document.status),
                                    labelStyle: TextStyle(
                                      color: _getStatusTextColor(
                                          document.status),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.download),
                                        onPressed: () =>
                                            _downloadDocument(context, document),
                                        tooltip: 'Download',
                                      ),
                                      if (document.status == 'pending')
                                        IconButton(
                                          icon: const Icon(Icons.check_circle,
                                              color: Colors.green),
                                          onPressed: () =>
                                              _approveDocument(document),
                                          tooltip: 'Approve',
                                        ),
                                      if (document.status == 'pending')
                                        IconButton(
                                          icon: const Icon(Icons.cancel,
                                              color: Colors.red),
                                          onPressed: () =>
                                              _rejectDocument(document),
                                          tooltip: 'Reject',
                                        ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () =>
                                            _showDeleteDialog(context, document),
                                        tooltip: 'Delete',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text('Error: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDocumentType(String type) {
    switch (type) {
      case 'id_proof':
        return 'ID Proof';
      case 'bank_statement':
        return 'Bank Statement';
      default:
        return type.replaceAll('_', ' ').toUpperCase();
    }
  }

  Color _getDocumentTypeColor(String type) {
    switch (type) {
      case 'id_proof':
        return Colors.blue.withOpacity(0.2);
      case 'bank_statement':
        return Colors.green.withOpacity(0.2);
      default:
        return Colors.grey.withOpacity(0.2);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green.withOpacity(0.2);
      case 'pending':
        return Colors.orange.withOpacity(0.2);
      case 'rejected':
        return Colors.red.withOpacity(0.2);
      default:
        return Colors.grey.withOpacity(0.2);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green[700]!;
      case 'pending':
        return Colors.orange[700]!;
      case 'rejected':
        return Colors.red[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _downloadDocument(
      BuildContext context, DocumentModel document) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preparing secure download...')),
      );

      triggerBrowserDownload(document.url, filename: document.name);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _approveDocument(DocumentModel document) async {
    try {
      await ref.read(firestoreServiceProvider).updateDocument(
        document.userId,
        document.documentId,
        {'status': 'approved'},
      );
      ref.invalidate(companyDocumentsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document approved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _rejectDocument(DocumentModel document) async {
    try {
      await ref.read(firestoreServiceProvider).updateDocument(
        document.userId,
        document.documentId,
        {'status': 'rejected'},
      );
      ref.invalidate(companyDocumentsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document rejected')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showDeleteDialog(BuildContext context, DocumentModel document) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text(
          'Are you sure you want to delete "${document.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteDocument(document);
            },
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

  Future<void> _deleteDocument(DocumentModel document) async {
    try {
      // Delete from storage
      await ref.read(storageServiceProvider).deleteFile(document.url);
      
      // Delete from Firestore
      await ref.read(firestoreServiceProvider).deleteDocument(
        userId: document.userId,
        documentId: document.documentId,
      );
      
      ref.invalidate(companyDocumentsProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

