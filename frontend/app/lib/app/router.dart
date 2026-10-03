import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_routes.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/auth/presentation/pages/verify_email_page.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/courses/presentation/pages/course_catalog_page.dart';
import '../features/courses/presentation/pages/course_detail_page.dart';
import '../features/courses/presentation/pages/lesson_view_page.dart';
import '../features/educator_studio/presentation/pages/educator_studio_page.dart';
import '../features/problems/presentation/pages/custom_problem_workspace_page.dart';
import '../features/profile/presentation/pages/edit_profile_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/quizzes/presentation/pages/quiz_hub_page.dart';
import '../features/quizzes/presentation/pages/quiz_leaderboard_page.dart';
import '../features/quizzes/presentation/pages/quiz_play_page.dart';
import '../features/splash/presentation/pages/splash_page.dart';
import '../features/student_dashboard/presentation/pages/student_dashboard_page.dart';
import '../features/teacher_dashboard/presentation/pages/teacher_dashboard_page.dart';
import '../features/teacher_onboarding/presentation/pages/become_educator_page.dart';
import '../features/teachers/presentation/pages/teacher_catalog_page.dart';
import '../features/teachers/presentation/pages/teacher_profile_page.dart';

List<RouteBase> _buildRoutes() {
  return [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashPage(),
    ),

    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginPage(),
    ),

    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => const RegisterPage(),
    ),

    GoRoute(
      path: AppRoutes.verifyEmail,
      builder: (context, state) {
        final email = state.uri.queryParameters['email'] ?? '';
        return VerifyEmailPage(email: email);
      },
    ),

    GoRoute(
      path: AppRoutes.dashboard,
      builder: (context, state) => const StudentDashboardPage(),
    ),

    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const StudentDashboardPage(),
    ),

    GoRoute(
      path: AppRoutes.studentDashboard,
      builder: (context, state) => const StudentDashboardPage(),
    ),

    GoRoute(
      path: AppRoutes.teacherDashboard,
      builder: (context, state) => const TeacherDashboardPage(),
    ),

    GoRoute(
      path: AppRoutes.teacher,
      builder: (context, state) => const TeacherDashboardPage(),
    ),

    GoRoute(
      path: AppRoutes.educatorStudio,
      builder: (context, state) => const EducatorStudioPage(),
    ),

    GoRoute(
      path: AppRoutes.quizzes,
      builder: (context, state) => const QuizHubPage(),
    ),

    GoRoute(
      path: '/quizzes/:id/play',
      builder: (context, state) {
        final quizId = state.pathParameters['id'] ?? '';
        return QuizPlayPage(quizId: quizId);
      },
    ),

    GoRoute(
      path: '/quizzes/:id/leaderboard',
      builder: (context, state) {
        final quizId = state.pathParameters['id'] ?? '';
        return QuizLeaderboardPage(quizId: quizId);
      },
    ),

    GoRoute(
      path: '/custom-problems/:id',
      builder: (context, state) {
        final problemId = state.pathParameters['id'] ?? '';
        return CustomProblemWorkspacePage(problemId: problemId);
      },
    ),

    GoRoute(
      path: '/custom-problem/:id',
      builder: (context, state) {
        final problemId = state.pathParameters['id'] ?? '';
        return CustomProblemWorkspacePage(problemId: problemId);
      },
    ),

    GoRoute(
      path: AppRoutes.admin,
      builder: (context, state) => const StudentDashboardPage(),
    ),

    GoRoute(
      path: AppRoutes.becomeEducator,
      builder: (context, state) => const BecomeEducatorPage(),
    ),

    GoRoute(
      path: AppRoutes.profile,
      builder: (context, state) => const ProfilePage(),
    ),

    GoRoute(
      path: AppRoutes.editProfile,
      builder: (context, state) {
        final initialData = state.extra as Map<String, dynamic>?;
        return EditProfilePage(initialUserData: initialData);
      },
    ),

    GoRoute(
      path: AppRoutes.teachers,
      builder: (context, state) => const TeacherCatalogPage(),
    ),

    GoRoute(
      path: '/teachers/:id',
      builder: (context, state) {
        final teacherId = state.pathParameters['id'] ?? '';
        return TeacherProfilePage(teacherId: teacherId);
      },
    ),

    GoRoute(
      path: AppRoutes.courses,
      builder: (context, state) => const CourseCatalogPage(),
    ),

    GoRoute(
      path: '/courses/:slug',
      builder: (context, state) {
        final slug = state.pathParameters['slug'] ?? '';
        return CourseDetailPage(courseSlug: slug);
      },
    ),

    GoRoute(
      path: '/courses/:slug/lessons/:lessonSlug',
      builder: (context, state) {
        final slug = state.pathParameters['slug'] ?? '';
        final lessonSlug = state.pathParameters['lessonSlug'] ?? '';
        return LessonViewPage(courseSlug: slug, lessonSlug: lessonSlug);
      },
    ),
  ];
}

String? _handleRedirect(BuildContext context, GoRouterState state, AuthState authState) {
  final loc = state.matchedLocation;

  // Let splash screen perform its initial bootstrap
  if (loc == AppRoutes.splash || authState.status == AuthStatus.initial) {
    return null;
  }

  final isAuthRoute = loc == AppRoutes.login ||
      loc == AppRoutes.register ||
      loc == AppRoutes.verifyEmail;

  // Unauthenticated user trying to access protected screen
  if (!authState.isAuthenticated) {
    if (!isAuthRoute) {
      return AppRoutes.login;
    }
    return null;
  }

  // Authenticated user trying to access login / register
  if (isAuthRoute) {
    final role = (authState.role ?? 'STUDENT').toUpperCase();
    if (role == 'TEACHER') {
      return AppRoutes.teacherDashboard;
    } else if (role == 'ADMIN') {
      return AppRoutes.admin;
    }
    return AppRoutes.studentDashboard;
  }

  // Alias routes /dashboard and /home to specific role dashboards
  if (loc == AppRoutes.dashboard || loc == AppRoutes.home) {
    final role = (authState.role ?? 'STUDENT').toUpperCase();
    if (role == 'TEACHER') {
      return AppRoutes.teacherDashboard;
    } else if (role == 'ADMIN') {
      return AppRoutes.admin;
    }
    return AppRoutes.studentDashboard;
  }

  return null;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authListenable = ref.watch(authListenableProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: authListenable,
    routes: _buildRoutes(),
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      return _handleRedirect(context, state, authState);
    },
  );
});

// Singleton fallback router instance
final appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: _buildRoutes(),
);
