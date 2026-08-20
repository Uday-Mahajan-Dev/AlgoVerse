import 'package:go_router/go_router.dart';

import '../core/constants/app_routes.dart';
import '../core/storage/token_storage.dart';

import '../features/splash/presentation/pages/splash_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/auth/presentation/pages/verify_email_page.dart';
import '../features/student/presentation/pages/student_dashboard_page.dart';
import '../features/teacher_dashboard/presentation/pages/teacher_dashboard_page.dart';

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
      redirect: (context, state) async {
        final role = await TokenStorage.getUserRole();
        if (role == 'TEACHER') {
          return AppRoutes.teacher;
        }
        return null;
      },
      builder: (context, state) => const StudentDashboardPage(),
    ),

    GoRoute(
      path: AppRoutes.teacher,
      redirect: (context, state) async {
        final role = await TokenStorage.getUserRole();
        if (role == 'STUDENT') {
          return AppRoutes.home;
        }
        return null;
      },
      builder: (context, state) => const TeacherDashboardPage(),
    ),
  ],
);
