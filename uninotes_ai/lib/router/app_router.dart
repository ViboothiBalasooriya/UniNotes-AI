import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/courses/screens/university_list_screen.dart';
import '../features/courses/screens/faculty_department_course_screens.dart';
import '../features/notes/screens/notes_list_screen.dart';
import '../features/notes/screens/pdf_viewer_screen.dart';
import '../features/notes/screens/upload_screen.dart';
import '../features/bookmarks/screens/saved_notes_screen.dart';
import '../features/admin/screens/admin_dashboard_screen.dart';
import '../features/admin/screens/course_editor_screen.dart';
import '../features/admin/screens/moderation_screen.dart';
import '../features/admin/screens/role_management_screen.dart';
import '../shared/models/note.dart';

// ─── Router Provider ──────────────────────────────────────────────────────────
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final isAuthenticated = authState.valueOrNull != null;
      final currentPath = state.uri.path;

      if (isLoading && currentPath == '/splash') return null;

      final publicRoutes = ['/splash', '/login', '/register'];
      if (!isAuthenticated && !publicRoutes.contains(currentPath)) {
        return '/login';
      }
      if (isAuthenticated && publicRoutes.contains(currentPath)) {
        return '/universities';
      }
      return null;
    },
    routes: [
      // ─── Auth Routes ─────────────────────────────────────────────────────────
      GoRoute(path: '/splash', builder: (ctx, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (ctx, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (ctx, state) => const RegisterScreen()),

      // ─── Student Routes ───────────────────────────────────────────────────────
      GoRoute(
        path: '/universities',
        builder: (ctx, state) => const UniversityListScreen(),
      ),
      GoRoute(
        path: '/universities/:universityId/faculties',
        builder: (ctx, state) {
          final uniId = state.pathParameters['universityId']!;
          final uniName = state.uri.queryParameters['uniName'] ?? '';
          return FacultyScreen(universityId: uniId, universityName: uniName);
        },
      ),
      GoRoute(
        path: '/universities/:universityId/faculties/:facultyId/departments',
        builder: (ctx, state) {
          final uniId = state.pathParameters['universityId']!;
          final facId = state.pathParameters['facultyId']!;
          final facName = state.uri.queryParameters['facName'] ?? '';
          return DepartmentScreen(universityId: uniId, facultyId: facId, facultyName: facName);
        },
      ),
      GoRoute(
        path: '/universities/:universityId/faculties/:facultyId/departments/:departmentId/courses',
        builder: (ctx, state) {
          final uniId = state.pathParameters['universityId']!;
          final facId = state.pathParameters['facultyId']!;
          final deptId = state.pathParameters['departmentId']!;
          final deptName = state.uri.queryParameters['deptName'] ?? '';
          return CourseScreen(
            universityId: uniId,
            facultyId: facId,
            departmentId: deptId,
            departmentName: deptName,
          );
        },
      ),
      GoRoute(
        path: '/courses/:courseId/notes',
        builder: (ctx, state) {
          final courseId = state.pathParameters['courseId']!;
          final courseName = state.uri.queryParameters['courseName'] ?? '';
          return NotesListScreen(courseId: courseId, courseName: courseName);
        },
      ),
      GoRoute(
        path: '/notes/upload',
        builder: (ctx, state) {
          final courseId = state.uri.queryParameters['courseId'] ?? '';
          final courseName = state.uri.queryParameters['courseName'] ?? '';
          return UploadScreen(courseId: courseId, courseName: courseName);
        },
      ),
      GoRoute(
        path: '/pdf-viewer',
        builder: (ctx, state) {
          final note = state.extra as Note;
          return PdfViewerScreen(note: note);
        },
      ),
      GoRoute(
        path: '/bookmarks',
        builder: (ctx, state) => const SavedNotesScreen(),
      ),

      // ─── Admin Routes ─────────────────────────────────────────────────────────
      GoRoute(
        path: '/admin',
        builder: (ctx, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/course-editor',
        builder: (ctx, state) => const CourseEditorScreen(),
      ),
      GoRoute(
        path: '/admin/moderation',
        builder: (ctx, state) => const ModerationScreen(),
      ),
      GoRoute(
        path: '/admin/roles',
        builder: (ctx, state) => const RoleManagementScreen(),
      ),
    ],
  );
});
