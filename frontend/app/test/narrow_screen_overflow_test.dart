import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:algoverse/features/teacher_dashboard/presentation/pages/teacher_dashboard_page.dart';
import 'package:algoverse/features/teacher_dashboard/presentation/providers/teacher_analytics_provider.dart';
import 'package:algoverse/features/teacher_dashboard/domain/entities/teacher_analytics_entity.dart';
import 'package:algoverse/features/teachers/domain/entities/teacher_entity.dart';
import 'package:algoverse/features/teachers/presentation/providers/teacher_provider.dart';
import 'package:algoverse/features/courses/presentation/pages/course_detail_page.dart';
import 'package:algoverse/features/courses/presentation/providers/course_provider.dart';
import 'package:algoverse/features/courses/domain/entities/course_entity.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'teacher_dashboard_page renders Pending Mentorship Requests header without overflow on 360x800 screen',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final dummyOverview = TeacherOverviewEntity(
        totalStudents: 45,
        activeStudents: 40,
        avgCourseCompletion: 78.5,
        totalSubmissionsToday: 120,
        maxStudents: 50,
        isAcceptingRequests: true,
        isVerified: true,
        recentActivityFeed: const [],
      );

      final dummyPendingRequest = MentorshipRequestEntity(
        id: 'req-1',
        studentId: 'stud-1',
        teacherId: 'teach-1',
        status: 'PENDING',
        createdAt: DateTime.now(),
        studentName: 'Alex Student With A Long Name That Might Wrap',
        studentUsername: 'alexstudentlong',
        studentEmail: 'alex.student.long.email@example.com',
        teacherName: 'Prof. Turing',
        teacherUsername: 'profturing',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            teacherOverviewProvider.overrideWith((ref) => dummyOverview),
            teacherStudentsProvider.overrideWith((ref) => []),
            teacherBottlenecksProvider.overrideWith((ref) => []),
            teacherConceptsProvider.overrideWith((ref) => []),
            teacherAssignmentsProvider.overrideWith((ref) => []),
            teacherTARequestsProvider.overrideWith((ref) => []),
            teacherMentorshipRequestsProvider.overrideWith((ref) => [dummyPendingRequest]),
            teacherCreatedProblemsProvider.overrideWith((ref) => []),
            teacherCreatedQuizzesProvider.overrideWith((ref) => []),
            currentUserProfileProvider.overrideWith(
              (ref) => {
                'class_code': 'ALGO101',
                'is_verified': true,
              },
            ),
          ],
          child: const MaterialApp(
            home: TeacherDashboardPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Pending Mentorship Requests'), findsOneWidget);
      expect(find.text('Capacity: 45 / 50'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'course_detail_page renders Course Progress header without overflow on 360x800 screen',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const courseSlug = 'dsa-arrays';

      final dummyCourseDetail = CourseDetailEntity(
        id: 'c-1',
        title: 'Mastering Data Structures and Algorithms with Advanced Visualizations',
        slug: courseSlug,
        description: 'Comprehensive course on data structures and algorithms.',
        difficulty: 'Intermediate',
        topicCategory: 'Arrays',
        isPublished: true,
        moduleCount: 4,
        totalLessons: 16,
        completedLessons: 10,
        completionPercentage: 62.0,
        enrollmentCount: 1500,
        isEnrolled: true,
        modules: const [],
        createdAt: DateTime.now(),
      );

      const dummyCourseProgress = CourseProgressEntity(
        courseId: 'c-1',
        courseTitle: 'Mastering Data Structures',
        courseSlug: courseSlug,
        totalLessons: 16,
        completedLessons: 10,
        completionPercentage: 62.0,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            courseDetailProvider(courseSlug).overrideWith((ref) => dummyCourseDetail),
            courseProgressProvider(courseSlug).overrideWith((ref) => dummyCourseProgress),
          ],
          child: const MaterialApp(
            home: CourseDetailPage(courseSlug: courseSlug),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('COURSE PROGRESS'), findsOneWidget);
      expect(find.text('Enrolled'), findsOneWidget);
      expect(find.text('10/16 Lessons (62%)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
