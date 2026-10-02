import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/teacher_analytics_entity.dart';
import '../providers/teacher_analytics_provider.dart';
import '../widgets/assign_homework_dialog.dart';
import '../widgets/teacher_sidebar.dart';
import '../widgets/teacher_top_bar.dart';

class TeacherDashboardPage extends ConsumerStatefulWidget {
  const TeacherDashboardPage({super.key});

  @override
  ConsumerState<TeacherDashboardPage> createState() =>
      _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends ConsumerState<TeacherDashboardPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedTab = 0; // 0 = Analytics, 1 = Assignments, 2 = Students

  Future<void> _respondToTARequest(String requestId, String action) async {
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null || token.isEmpty) return;

      final res = await ApiClient.respondToTARequest(
        accessToken: token,
        requestId: requestId,
        action: action,
      );

      if (!mounted) return;

      ref.invalidate(teacherTARequestsProvider);
      ref.invalidate(teacherStudentsProvider);
      ref.invalidate(teacherOverviewProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? 'Request updated successfully.'),
          backgroundColor: action == 'APPROVE' ? const Color(0xFF10B981) : Colors.red.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '').trim()),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final overviewAsync = ref.watch(teacherOverviewProvider);
    final studentsAsync = ref.watch(teacherStudentsProvider);
    final bottlenecksAsync = ref.watch(teacherBottlenecksProvider);
    final conceptsAsync = ref.watch(teacherConceptsProvider);
    final assignmentsAsync = ref.watch(teacherAssignmentsProvider);
    final taRequestsAsync = ref.watch(teacherTARequestsProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: MediaQuery.sizeOf(context).width < 900
          ? Drawer(
              child: TeacherSidebar(
                selectedIndex: _selectedTab,
                onItemSelected: (index) {
                  setState(() => _selectedTab = index);
                  Navigator.of(context).pop();
                },
              ),
            )
          : null,
      body: Row(
        children: [
          if (MediaQuery.sizeOf(context).width >= 900)
            TeacherSidebar(
              selectedIndex: _selectedTab,
              onItemSelected: (index) {
                setState(() => _selectedTab = index);
              },
            ),
          Expanded(
            child: Column(
              children: [
                TeacherTopBar(
                  onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1400),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header & Action Bar
                            _buildHeader(context),
                            const SizedBox(height: 24),

                            // TA Approval Requests (if any)
                            taRequestsAsync.when(
                              data: (requests) => _buildTARequestsCard(context, requests),
                              loading: () => const SizedBox.shrink(),
                              error: (e, s) => const SizedBox.shrink(),
                            ),

                            // KPI Cards Grid
                            overviewAsync.when(
                              loading: () => const _LoadingStatsGrid(),
                              error: (e, _) => _buildErrorBanner('overview stats', e),
                              data: (overview) => _buildStatsGrid(context, overview),
                            ),
                            const SizedBox(height: 28),

                            // Main Analytics Split (Bottlenecks + Concept Mastery)
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isWide = constraints.maxWidth >= 1000;
                                if (isWide) {
                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 6,
                                        child: bottlenecksAsync.when(
                                          loading: () => const _LoadingCard(title: 'Bottleneck Lessons'),
                                          error: (e, _) => _buildErrorBanner('bottlenecks', e),
                                          data: (bottlenecks) => _buildBottlenecksCard(context, bottlenecks),
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      Expanded(
                                        flex: 5,
                                        child: conceptsAsync.when(
                                          loading: () => const _LoadingCard(title: 'Concept Performance'),
                                          error: (e, _) => _buildErrorBanner('concept performance', e),
                                          data: (concepts) => _buildConceptsCard(context, concepts),
                                        ),
                                      ),
                                    ],
                                  );
                                } else {
                                  return Column(
                                    children: [
                                      bottlenecksAsync.when(
                                        loading: () => const _LoadingCard(title: 'Bottleneck Lessons'),
                                        error: (e, _) => _buildErrorBanner('bottlenecks', e),
                                        data: (bottlenecks) => _buildBottlenecksCard(context, bottlenecks),
                                      ),
                                      const SizedBox(height: 24),
                                      conceptsAsync.when(
                                        loading: () => const _LoadingCard(title: 'Concept Performance'),
                                        error: (e, _) => _buildErrorBanner('concept performance', e),
                                        data: (concepts) => _buildConceptsCard(context, concepts),
                                      ),
                                    ],
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 28),

                            // Student Progress Roster
                            studentsAsync.when(
                              loading: () => const _LoadingCard(title: 'Student Roster'),
                              error: (e, _) => _buildErrorBanner('students roster', e),
                              data: (students) => _buildStudentsRosterCard(context, students),
                            ),
                            const SizedBox(height: 28),

                            // Lower Split (Recent Activity + Active Homework Assignments)
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isWide = constraints.maxWidth >= 1000;
                                if (isWide) {
                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 5,
                                        child: overviewAsync.when(
                                          loading: () => const _LoadingCard(title: 'Recent Activity'),
                                          error: (e, _) => _buildErrorBanner('activity feed', e),
                                          data: (overview) => _buildActivityFeedCard(context, overview.recentActivityFeed),
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      Expanded(
                                        flex: 6,
                                        child: assignmentsAsync.when(
                                          loading: () => const _LoadingCard(title: 'Active Assignments'),
                                          error: (e, _) => _buildErrorBanner('assignments', e),
                                          data: (assignments) => _buildAssignmentsCard(context, assignments),
                                        ),
                                      ),
                                    ],
                                  );
                                } else {
                                  return Column(
                                    children: [
                                      overviewAsync.when(
                                        loading: () => const _LoadingCard(title: 'Recent Activity'),
                                        error: (e, _) => _buildErrorBanner('activity feed', e),
                                        data: (overview) => _buildActivityFeedCard(context, overview.recentActivityFeed),
                                      ),
                                      const SizedBox(height: 24),
                                      assignmentsAsync.when(
                                        loading: () => const _LoadingCard(title: 'Active Assignments'),
                                        error: (e, _) => _buildErrorBanner('assignments', e),
                                        data: (assignments) => _buildAssignmentsCard(context, assignments),
                                      ),
                                    ],
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTARequestsCard(BuildContext context, List<dynamic> requests) {
    final pending = requests.where((r) => r['status'] == 'PENDING').toList();
    if (pending.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.amber.shade300, width: 1.5),
        ),
        color: Colors.amber.shade50.withValues(alpha: 0.5),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.how_to_reg_rounded, color: Colors.amber.shade900),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pending Teaching Assistant Applications (${pending.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF78350F),
                          ),
                        ),
                        Text(
                          'Students requesting to join as Teaching Assistants under your supervision',
                          style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pending.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final req = pending[index];
                  final reqId = req['id']?.toString() ?? '';
                  final name = req['applicant_name']?.toString() ?? 'Applicant';
                  final email = req['applicant_email']?.toString() ?? '';
                  final inst = req['institution_name']?.toString() ?? '';
                  final expertise = req['subject_expertise']?.toString() ?? '';
                  final bio = req['bio']?.toString() ?? '';

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.purple.shade100,
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : 'T',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '$email • $inst',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (expertise.isNotEmpty || bio.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            expertise.isNotEmpty ? 'Expertise: $expertise' : bio,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _respondToTARequest(reqId, 'REJECT'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red.shade700,
                                side: BorderSide(color: Colors.red.shade300),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              icon: const Icon(Icons.close_rounded, size: 16),
                              label: const Text('Reject', style: TextStyle(fontSize: 12)),
                            ),
                            const SizedBox(width: 10),
                            FilledButton.icon(
                              onPressed: () => _respondToTARequest(reqId, 'APPROVE'),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              icon: const Icon(Icons.check_rounded, size: 16),
                              label: const Text('Approve TA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final userProfileAsync = ref.watch(currentUserProfileProvider);
    final classCode =
        userProfileAsync.value?['class_code']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 12,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Classroom Analytics',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Real-time student mastery, bottleneck detection, and homework management.',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
            FilledButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => const AssignHomeworkDialog(),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.indigo,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.assignment_add, size: 18),
              label: const Text(
                'Assign Homework',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        if (classCode.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.purple.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.vpn_key_rounded,
                    color: Colors.purple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          const Text(
                            'Your Class Joining Code:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade700,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              classCode,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Share this code with your students to automatically link them to your dashboard roster.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.purple.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded,
                      color: Colors.purple, size: 20),
                  tooltip: 'Copy Class Code',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: classCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Class Code ($classCode) copied to clipboard!'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, TeacherOverviewEntity overview) {
    final activeRate = overview.totalStudents > 0
        ? ((overview.activeStudents / overview.totalStudents) * 100).toStringAsFixed(0)
        : '0';

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900
            ? 4
            : (constraints.maxWidth > 550 ? 2 : 1);

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: crossAxisCount == 4 ? 1.8 : 2.2,
          children: [
            _buildStatCard(
              icon: Icons.people_alt_rounded,
              iconColor: Colors.blue.shade600,
              iconBg: Colors.blue.shade50,
              title: 'Total Students',
              value: '${overview.totalStudents}',
              subtitle: 'Classroom roster size',
            ),
            _buildStatCard(
              icon: Icons.local_fire_department_rounded,
              iconColor: Colors.orange.shade600,
              iconBg: Colors.orange.shade50,
              title: 'Active This Week',
              value: '${overview.activeStudents}',
              subtitle: '$activeRate% participation rate',
            ),
            _buildStatCard(
              icon: Icons.analytics_rounded,
              iconColor: Colors.purple.shade600,
              iconBg: Colors.purple.shade50,
              title: 'Avg Course Progress',
              value: '${overview.avgCourseCompletion.toStringAsFixed(1)}%',
              subtitle: 'Across enrolled courses',
            ),
            _buildStatCard(
              icon: Icons.code_rounded,
              iconColor: Colors.green.shade600,
              iconBg: Colors.green.shade50,
              title: 'Submissions Today',
              value: '${overview.totalSubmissionsToday}',
              subtitle: 'Coding problem attempts',
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const Spacer(),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottlenecksCard(
    BuildContext context,
    List<BottleneckLessonEntity> bottlenecks,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bottleneck Lessons',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Lessons with lowest completion & highest failure rates',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          if (bottlenecks.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: Text(
                'No bottlenecks detected! Students are progressing smoothly.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: bottlenecks.length,
              separatorBuilder: (context, index) => const Divider(height: 20),
              itemBuilder: (context, index) {
                final b = bottlenecks[index];
                final completionPct = (b.completionRate * 100).toStringAsFixed(0);
                final failurePct = (b.failureRate * 100).toStringAsFixed(0);

                return InkWell(
                  onTap: () {
                    context.push('/courses/${b.courseSlug}/lessons/${b.lessonSlug}');
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '${index + 1}.',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade400,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                b.lessonTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: b.completionRate < 0.3
                                    ? Colors.red.shade50
                                    : (b.completionRate < 0.6
                                        ? Colors.amber.shade50
                                        : Colors.green.shade50),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$completionPct% complete',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: b.completionRate < 0.3
                                      ? Colors.red.shade700
                                      : (b.completionRate < 0.6
                                          ? Colors.amber.shade800
                                          : Colors.green.shade700),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${b.courseTitle} • ${b.moduleTitle}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade500),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (b.contentType == 'PROBLEM')
                              Text(
                                'Failure: $failurePct% (${b.avgAttempts} attempts)',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.red.shade600),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: b.completionRate,
                            minHeight: 6,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation(
                              b.completionRate < 0.3
                                  ? Colors.red.shade400
                                  : (b.completionRate < 0.6
                                      ? Colors.amber.shade400
                                      : Colors.green.shade400),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildConceptsCard(
    BuildContext context,
    List<ConceptPerformanceEntity> concepts,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.hub_rounded, color: Colors.purple.shade700, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Concept Performance Matrix',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Module-level mastery across students',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          if (concepts.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: Text(
                'No module data available yet.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: concepts.length,
              separatorBuilder: (context, index) => const Divider(height: 20),
              itemBuilder: (context, index) {
                final c = concepts[index];
                final pct = (c.avgCompletionRate * 100).toStringAsFixed(0);

                Color statusColor;
                String statusLabel;
                if (c.isStrong) {
                  statusColor = const Color(0xFF10B981);
                  statusLabel = 'Strong';
                } else if (c.isModerate) {
                  statusColor = const Color(0xFFF59E0B);
                  statusLabel = 'Moderate';
                } else {
                  statusColor = const Color(0xFFEF4444);
                  statusLabel = 'Weak';
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            c.moduleTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$pct% • $statusLabel',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${c.courseTitle} • ${c.totalLessons} lessons (${c.weakLessonCount} weak)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: c.avgCompletionRate,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(statusColor),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStudentsRosterCard(
    BuildContext context,
    List<StudentProgressEntity> students,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.school_rounded, color: Colors.blue.shade700, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Student Progress Roster',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Individual activity, daily streaks, and completion rates',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          if (students.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: Text(
                'No students currently paired with your mentorship profile.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: students.length,
              separatorBuilder: (context, index) => const Divider(height: 20),
              itemBuilder: (context, index) {
                final s = students[index];
                Color statusColor;
                String statusText;
                if (s.isActive) {
                  statusColor = const Color(0xFF10B981);
                  statusText = 'Active';
                } else if (s.isAtRisk) {
                  statusColor = const Color(0xFFF59E0B);
                  statusText = 'At Risk';
                } else {
                  statusColor = const Color(0xFFEF4444);
                  statusText = 'Inactive';
                }

                return Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.indigo.shade50,
                        child: Text(
                          s.studentName.isNotEmpty
                              ? s.studentName.substring(0, 1).toUpperCase()
                              : 'S',
                          style: TextStyle(
                            color: Colors.indigo.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              s.studentName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              s.studentEmail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 130,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: statusColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.local_fire_department,
                                    size: 14, color: Colors.orange),
                                const SizedBox(width: 2),
                                Text(
                                  '${s.currentStreak}d',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  '${s.overallCompletionPct.toStringAsFixed(0)}% (${s.lessonsCompleted} done)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: s.overallCompletionPct / 100.0,
                                minHeight: 5,
                                backgroundColor: Colors.grey.shade200,
                                valueColor:
                                    const AlwaysStoppedAnimation(Colors.indigo),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildActivityFeedCard(
    BuildContext context,
    List<RecentActivityItemEntity> feed,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history_rounded, color: Colors.indigo, size: 20),
              SizedBox(width: 8),
              Text(
                'Recent Student Activity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (feed.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No recent student actions logged yet.',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: feed.length,
              separatorBuilder: (context, index) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final item = feed[index];
                final isAC = item.actionType.contains('AC');
                final isComp = item.actionType == 'COMPLETED_LESSON';

                IconData actIcon;
                Color actColor;
                if (isComp) {
                  actIcon = Icons.task_alt_rounded;
                  actColor = const Color(0xFF10B981);
                } else if (isAC) {
                  actIcon = Icons.check_circle_rounded;
                  actColor = const Color(0xFF10B981);
                } else {
                  actIcon = Icons.cancel_rounded;
                  actColor = const Color(0xFFEF4444);
                }

                return Row(
                  children: [
                    Icon(actIcon, size: 16, color: actColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RichText(
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1E293B),
                          ),
                          children: [
                            TextSpan(
                              text: item.studentName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: isComp
                                  ? ' completed '
                                  : ' submitted solution for ',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            TextSpan(
                              text: '"${item.itemTitle}"',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatAgo(item.timestamp),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAssignmentsCard(
    BuildContext context,
    List<AssignmentEntity> assignments,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_turned_in_rounded, color: Colors.indigo, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Assigned Homework',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              Text(
                '${assignments.length} total',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (assignments.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No homework assigned yet. Click "Assign Homework" to send targeted exercises.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: assignments.length > 5 ? 5 : assignments.length,
              separatorBuilder: (context, index) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final a = assignments[index];
                Color statusColor;
                if (a.isCompleted) {
                  statusColor = const Color(0xFF10B981);
                } else if (a.isOverdue) {
                  statusColor = const Color(0xFFEF4444);
                } else {
                  statusColor = const Color(0xFF3B82F6);
                }

                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        a.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.lessonTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            'Assigned to ${a.studentName}${a.dueDate != null ? ' • Due ${_formatDate(a.dueDate!)}' : ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String section, Object error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(
        'Failed to load $section: $error',
        style: TextStyle(color: Colors.red.shade800, fontSize: 13),
      ),
    );
  }

  String _formatAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}

class _LoadingStatsGrid extends StatelessWidget {
  const _LoadingStatsGrid();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  final String title;

  const _LoadingCard({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text('Loading $title...', style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}