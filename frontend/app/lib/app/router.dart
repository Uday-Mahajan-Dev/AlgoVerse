import 'package:go_router/go_router.dart';

import '../core/constants/app_routes.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/auth/presentation/pages/verify_email_page.dart';
import '../features/courses/presentation/pages/course_catalog_page.dart';
import '../features/courses/presentation/pages/course_detail_page.dart';
import '../features/courses/presentation/pages/lesson_view_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/profile/presentation/pages/edit_profile_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/splash/presentation/pages/splash_page.dart';
import '../features/student_dashboard/presentation/pages/student_dashboard_page.dart';
import '../features/teacher_dashboard/presentation/pages/teacher_dashboard_page.dart';
import '../features/teacher_onboarding/presentation/pages/become_educator_page.dart';
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
      path: '/teacher-dashboard',
      builder: (context, state) => const TeacherDashboardPage(),
    ),

    GoRoute(
      path: AppRoutes.teacher,
      builder: (context, state) => const TeacherDashboardPage(),
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
  ],
);
