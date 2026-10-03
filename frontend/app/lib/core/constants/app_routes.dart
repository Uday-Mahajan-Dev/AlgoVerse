class AppRoutes {
  AppRoutes._();

  // ============================================================
  // AUTH
  // ============================================================

  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const verifyEmail = '/verify-email';

  // ============================================================
  // MAIN
  // ============================================================

  static const home = '/home';
  static const dashboard = '/dashboard';
  static const studentDashboard = '/student-dashboard';
  static const teacherDashboard = '/teacher-dashboard';
  static const admin = '/admin';
  static const stories = '/stories';
  static const problems = '/problems';
  static const contests = '/contests';
  static const leaderboard = '/leaderboard';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const teacher = '/teacher';
  static const teachers = '/teachers';
  static const becomeEducator = '/become-educator';
  static const courses = '/courses';
  static const educatorStudio = '/educator-studio';
  static const quizzes = '/quizzes';
  static const quizPlay = '/quizzes/:id/play';
  static const quizLeaderboard = '/quizzes/:id/leaderboard';
  static const customProblemView = '/custom-problems/:id';
  static const settings = '/settings';
}

