import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import '../models/project_model.dart';
import 'auth_provider.dart';

// ============================================
// PROJECT PROVIDERS
// ============================================

/// All projects provider (includes active and inactive)
final allProjectsProvider = FutureProvider<List<ProjectModel>>((ref) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  
  try {
    return await firestoreService.getAllProjects();
  } catch (e) {
    print('Error fetching all projects: $e');
    return [];
  }
});

/// All active projects provider
final activeProjectsProvider = FutureProvider<List<ProjectModel>>((ref) async {
  final currentUser = ref.watch(currentUserProvider).value;
  final firestoreService = ref.watch(firestoreServiceProvider);
  
  try {
    if (currentUser != null && currentUser.isSupervisor) {
      final assignedProjects = await ref.watch(supervisorProjectsProvider.future);
      return assignedProjects.where((project) => project.isActive).toList();
    }

    return await firestoreService.getActiveProjects();
  } catch (e) {
    print('Error fetching active projects: $e');
    return [];
  }
});

/// Employee's assigned projects provider
final employeeProjectsProvider = FutureProvider<List<ProjectModel>>((ref) async {
  // Use AsyncValue (not .future): .future completes once and can stay null after employee login.
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.asData?.value;
  if (user == null) return [];

  final firestoreService = ref.watch(firestoreServiceProvider);
  
  try {
    return await firestoreService.getEmployeeProjects(user.uid);
  } catch (e) {
    print('Error fetching employee projects: $e');
    return [];
  }
});

/// Supervisor's assigned projects provider
final supervisorProjectsProvider = FutureProvider<List<ProjectModel>>((ref) async {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.asData?.value;
  if (user == null) return [];

  final firestoreService = ref.watch(firestoreServiceProvider);
  
  try {
    final assignedIds = user.assignedProjectIds.isNotEmpty
        ? user.assignedProjectIds
        : (user.assignedProjectId != null ? [user.assignedProjectId!] : <String>[]);
    if (assignedIds.isEmpty) return [];

    final projects = <ProjectModel>[];
    for (final projectId in assignedIds) {
      final project = await firestoreService.getProject(projectId);
      if (project != null) {
        projects.add(project);
      }
    }
    return projects;
  } catch (e) {
    print('Error fetching supervisor projects: $e');
    return [];
  }
});

/// Backward compatible single supervisor project (first assignment)
final supervisorProjectProvider = FutureProvider<ProjectModel?>((ref) async {
  final projects = await ref.watch(supervisorProjectsProvider.future);
  return projects.isEmpty ? null : projects.first;
});

/// Single project provider
final projectProvider = FutureProvider.family<ProjectModel?, String>((ref, projectId) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  
  try {
    return await firestoreService.getProject(projectId);
  } catch (e) {
    print('Error fetching project: $e');
    return null;
  }
});

// ============================================
// PROJECT CONTROLLER
// ============================================

/// Project management state
class ProjectState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const ProjectState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  ProjectState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return ProjectState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

/// Project controller
class ProjectController extends StateNotifier<ProjectState> {
  final FirestoreService _firestoreService;
  final Ref _ref;

  ProjectController(this._firestoreService, this._ref)
      : super(const ProjectState());

  /// Create new project
  Future<bool> createProject(ProjectModel project) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _firestoreService.createProject(project);

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Project created successfully',
      );

      // Refresh projects list
      _ref.invalidate(activeProjectsProvider);

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Assign employee to project
  Future<bool> assignEmployeeToProject({
    required String projectId,
    required String employeeId,
    required String employeeName,
    required String assignedBy,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _firestoreService.assignEmployeeToProject(
        projectId: projectId,
        employeeId: employeeId,
        employeeName: employeeName,
        assignedBy: assignedBy,
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Employee assigned successfully',
      );

      // Refresh employee projects
      _ref.invalidate(employeeProjectsProvider);

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Clear messages
  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}

/// Project controller provider
final projectControllerProvider =
    StateNotifierProvider<ProjectController, ProjectState>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return ProjectController(firestoreService, ref);
});

