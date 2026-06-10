import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import '../models/project_model.dart';
import 'auth_provider.dart';

// ============================================
// PROJECT PROVIDERS (Real-time streams)
// ============================================

/// All projects provider with real-time updates
final allProjectsProvider = StreamProvider<List<ProjectModel>>((ref) async* {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final currentUser = ref.watch(currentUserProvider).value;
  
  try {
    if (currentUser == null) {
      yield [];
      return;
    }
    if (currentUser.role == 'superadmin') {
      yield* firestoreService.streamAllProjects();
    } else if (currentUser.companyId != null) {
      yield* firestoreService.streamProjectsForCompany(currentUser.companyId!);
    } else {
      yield [];
    }
  } catch (e) {
    print('Error fetching all projects stream: $e');
    yield [];
  }
});

/// All active projects provider with real-time updates
final activeProjectsProvider = StreamProvider<List<ProjectModel>>((ref) async* {
  final currentUser = ref.watch(currentUserProvider).value;
  final firestoreService = ref.watch(firestoreServiceProvider);
  
  try {
    if (currentUser == null) {
      yield [];
      return;
    }
    if (currentUser.isSupervisor) {
      // Supervisors see only their assigned projects (filtered to active)
      final assignedProjects = await ref.watch(supervisorProjectsProvider.future);
      yield assignedProjects.where((project) => project.isActive).toList();
      return;
    }

    // For admins: stream all company projects, filter to active
    Stream<List<ProjectModel>> sourceStream;
    if (currentUser.role == 'superadmin') {
      sourceStream = firestoreService.streamAllProjects();
    } else if (currentUser.companyId != null) {
      sourceStream = firestoreService.streamProjectsForCompany(currentUser.companyId!);
    } else {
      yield [];
      return;
    }
    await for (final projects in sourceStream) {
      yield projects.where((p) => p.isActive).toList();
    }
  } catch (e) {
    print('Error fetching active projects stream: $e');
    yield [];
  }
});

/// Employee's assigned projects provider with real-time updates
final employeeProjectsProvider = StreamProvider<List<ProjectModel>>((ref) async* {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.asData?.value;
  if (user == null) {
    yield [];
    return;
  }

  final firestoreService = ref.watch(firestoreServiceProvider);
  
  try {
    // For employees: stream all company projects and filter to assigned
    if (user.companyId == null) {
      yield [];
      return;
    }
    await for (final allProjects
        in firestoreService.streamProjectsForCompany(user.companyId!)) {
      final assignedProjects = allProjects.where((p) {
        if (p.assignedEmployeeIds.contains(user.uid)) return true;
        return false;
      }).toList();
      yield assignedProjects;
    }
  } catch (e) {
    print('Error fetching employee projects stream: $e');
    yield [];
  }
});

/// Supervisor's assigned projects provider (queries projects by supervisorId - matches web dashboard)
final supervisorProjectsProvider = FutureProvider<List<ProjectModel>>((ref) async {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.asData?.value;
  if (user == null) {
    yield [];
    return;
  }

  final firestoreService = ref.watch(firestoreServiceProvider);
  
  try {
    return await firestoreService.getSupervisorProjects(user.uid);
  } catch (e) {
    print('Error fetching supervisor projects stream: $e');
    yield [];
  }
});

/// Backward compatible single supervisor project (first assignment)
final supervisorProjectProvider = Provider<ProjectModel?>((ref) {
  final projects = ref.watch(supervisorProjectsProvider).asData?.value ?? [];
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

/// Projects assigned to a specific employee (used by supervisor manual check-in)
final employeeAssignedProjectsProvider =
    FutureProvider.family<List<ProjectModel>, String>((ref, employeeId) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  
  try {
    return await firestoreService.getEmployeeProjects(employeeId);
  } catch (e) {
    print('Error fetching employee projects for $employeeId: $e');
    return [];
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

