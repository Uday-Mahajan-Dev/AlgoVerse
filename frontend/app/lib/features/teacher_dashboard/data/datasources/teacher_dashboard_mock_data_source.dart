import '../models/teacher_dashboard_model.dart';
import '../../domain/entities/teacher_dashboard_entity.dart';

class TeacherDashboardMockDataSource {
  Future<TeacherDashboardModel> getDashboardData() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    return const TeacherDashboardModel(
      stats: TeacherDashboardStats(
        totalStudents: 120,
        activeStudents: 87,
        averageMastery: 0.72,
        problemsSolved: 1842,
      ),
      conceptPerformance: [
        ConceptPerformance(
          concept: 'Arrays',
          mastery: 0.84,
          studentsAttempted: 112,
        ),
        ConceptPerformance(
          concept: 'Linked Lists',
          mastery: 0.71,
          studentsAttempted: 104,
        ),
        ConceptPerformance(
          concept: 'Stacks & Queues',
          mastery: 0.67,
          studentsAttempted: 98,
        ),
        ConceptPerformance(
          concept: 'Trees',
          mastery: 0.58,
          studentsAttempted: 91,
        ),
        ConceptPerformance(
          concept: 'Graphs',
          mastery: 0.49,
          studentsAttempted: 83,
        ),
        ConceptPerformance(
          concept: 'Dynamic Programming',
          mastery: 0.43,
          studentsAttempted: 76,
        ),
      ],
      weakConcepts: [
        WeakConcept(
          concept: 'Dynamic Programming',
          mastery: 0.43,
          affectedStudents: 76,
        ),
        WeakConcept(concept: 'Graphs', mastery: 0.49, affectedStudents: 83),
        WeakConcept(concept: 'Trees', mastery: 0.58, affectedStudents: 91),
        WeakConcept(concept: 'Recursion', mastery: 0.61, affectedStudents: 68),
      ],
      recentActivities: [
        RecentActivity(
          studentName: 'Rahul Sharma',
          activity: 'Solved a problem',
          topic: 'Binary Search',
          time: '5 min ago',
        ),
        RecentActivity(
          studentName: 'Priya Patil',
          activity: 'Completed a story',
          topic: 'Stack',
          time: '18 min ago',
        ),
        RecentActivity(
          studentName: 'Aman Joshi',
          activity: 'Attempted a problem',
          topic: 'Graphs',
          time: '32 min ago',
        ),
        RecentActivity(
          studentName: 'Sneha Kulkarni',
          activity: 'Completed a lesson',
          topic: 'Linked Lists',
          time: '1 hour ago',
        ),
        RecentActivity(
          studentName: 'Arjun Deshmukh',
          activity: 'Won a DSA challenge',
          topic: 'Queues',
          time: '2 hours ago',
        ),
      ],
    );
  }
}
