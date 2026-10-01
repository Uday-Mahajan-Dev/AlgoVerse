import 'package:go_router/go_router.dart';
import '../features/student_dashboard/presentation/pages/student_dashboard_page.dart';

import '../core/constants/app_routes.dart';

import '../features/splash/presentation/pages/splash_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/auth/presentation/pages/verify_email_page.dart';
import '../features/home/presentation/pages/home_page.dart';

import '../features/teachers/presentation/pages/teacher_catalog_page.dart';
import '../features/teachers/presentation/pages/teacher_profile_page.dart';

final appRouter = GoRouter(
  initialLocation: AppRoutes.splash,

  routes: [
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
      path: AppRoutes.home,
      builder: (context, state) => const HomePage(),
    ),

    GoRoute(
      path: AppRoutes.studentDashboard,
      builder: (context, state) => const StudentDashboardPage(),
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
  ],
);
