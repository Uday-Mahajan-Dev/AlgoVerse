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
import '../../../teachers/domain/entities/teacher_entity.dart';
import '../../../teachers/presentation/providers/teacher_provider.dart';

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

  Future<void> _respondToMentorshipRequest(String requestId, bool approve) async {
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null || token.isEmpty) return;

      final res = approve
          ? await ApiClient.approveMentorshipRequest(
              accessToken: token, requestId: requestId)
          : await ApiClient.rejectMentorshipRequest(
              accessToken: token, requestId: requestId);

      if (!mounted) return;

      ref.invalidate(teacherMentorshipRequestsProvider);
      ref.invalidate(classroomStatsProvider);
      ref.invalidate(classroomSettingsProvider);
      ref.invalidate(teacherStudentsProvider);
      ref.invalidate(teacherOverviewProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ??
              (approve
                  ? 'Student mentorship request approved!'
                  : 'Mentorship request rejected.')),
          backgroundColor:
              approve ? const Color(0xFF10B981) : Colors.red.shade700,
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

  void _showClassroomSettingsDialog(
      BuildContext context, int currentMax, bool currentAccepting) {
    int maxStudents = currentMax;
    bool isAccepting = currentAccepting;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.tune_rounded, color: Colors.indigo),
                  SizedBox(width: 10),
                  Text('Classroom Settings',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Control how students join your classroom and manage capacity limits.',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Text(
                                  'Max Classroom Capacity:',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600, fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.indigo.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Colors.indigo.shade200),
                                ),
                                child: Text(
                                  '$maxStudents students',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.indigo.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Slider(
                            value: maxStudents.toDouble(),
                            min: 10,
                            max: 500,
                            divisions: 49,
                            activeColor: Colors.indigo,
                            label: '$maxStudents',
                            onChanged: (val) {
                              setDialogState(() {
                                maxStudents = val.round();
                              });
                            },
                          ),
                          Text(
                            'When this limit is reached, new student requests will be blocked automatically.',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Accept New Requests',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        subtitle: Text(
                          'Toggle off if you wish to temporarily pause new student applications.',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500),
                        ),
                        value: isAccepting,
                        activeThumbColor: const Color(0xFF10B981),
                        onChanged: (val) {
                          setDialogState(() {
                            isAccepting = val;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style:
                      FilledButton.styleFrom(backgroundColor: Colors.indigo),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.of(ctx).pop();
                    try {
                      final token = await TokenStorage.getAccessToken();
                      if (token == null) return;
                      await ApiClient.updateClassroomSettings(
                        accessToken: token,
                        maxStudents: maxStudents,
                        isAcceptingRequests: isAccepting,
                      );
                      ref.invalidate(classroomSettingsProvider);
                      ref.invalidate(teacherOverviewProvider);
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Classroom settings updated successfully!'),
                          backgroundColor: Color(0xFF10B981),
                        ),
                      );
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(e
                              .toString()
                              .replaceAll('Exception: ', '')
                              .trim()),
                          backgroundColor: Colors.red.shade700,
                        ),
                      );
                    }
                  },
                  child: const Text('Save Settings'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final overviewAsync = ref.watch(teacherOverviewProvider);
    final studentsAsync = ref.watch(teacherStudentsProvider);
    final bottlenecksAsync = ref.watch(teacherBottlenecksProvider);
    final conceptsAsync = ref.watch(teacherConceptsProvider);
    final assignmentsAsync = ref.watch(teacherAssignmentsProvider);
    final taRequestsAsync = ref.watch(teacherTARequestsProvider);
    final mentorshipRequestsAsync =
        ref.watch(teacherMentorshipRequestsProvider);
    final createdProblemsAsync = ref.watch(teacherCreatedProblemsProvider);
    final createdQuizzesAsync = ref.watch(teacherCreatedQuizzesProvider);

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
                            // Header & Action Bar (includes Class Joining Code & Mentorship Inbox)
                            _buildHeader(context, overviewAsync.value, mentorshipRequestsAsync),
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

                            // My Created Content (Custom Problems & Live Quizzes)
                            _buildCreatedContentCard(
                              context,
                              createdProblemsAsync.value ?? [],
                              createdQuizzesAsync.value ?? [],
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

  Widget _buildMentorshipRequestsCard(
    BuildContext context,
    List<MentorshipRequestEntity> requests,
    int currentEnrolled,
    int maxCapacity, {
    bool isVerified = true,
  }) {
    final pending = requests
        .where((r) => r.status.trim().toUpperCase() == 'PENDING')
        .toList();
    if (pending.isEmpty) return const SizedBox.shrink();

    final isAtCapacity = currentEnrolled >= maxCapacity;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isAtCapacity ? Colors.red.shade300 : Colors.indigo.shade300,
            width: 1.5,
          ),
        ),
        color: isAtCapacity
            ? Colors.red.shade50.withValues(alpha: 0.5)
            : Colors.indigo.shade50.withValues(alpha: 0.5),
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
                      color: isAtCapacity
                          ? Colors.red.shade100
                          : Colors.indigo.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.person_add_alt_1_rounded,
                      color: isAtCapacity
                          ? Colors.red.shade900
                          : Colors.indigo.shade900,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Pending Mentorship Requests (${pending.length})',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isAtCapacity
                                    ? Colors.red.shade900
                                    : const Color(0xFF1E1B4B),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isAtCapacity
                                    ? Colors.red.shade100
                                    : Colors.indigo.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Capacity: $currentEnrolled / $maxCapacity',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isAtCapacity
                                      ? Colors.red.shade900
                                      : Colors.indigo.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          isAtCapacity
                              ? 'Classroom capacity is full ($currentEnrolled/$maxCapacity). Adjust capacity or reject requests to enroll new students.'
                              : 'Students who requested to join your classroom roster via class code or professor directory.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isAtCapacity
                                ? Colors.red.shade800
                                : Colors.indigo.shade800,
                          ),
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
                  final name = req.studentName.isNotEmpty
                      ? req.studentName
                      : req.studentUsername;

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.indigo.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.indigo.shade100,
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : 'S',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo.shade900,
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
                                    '${req.studentEmail != null && req.studentEmail!.isNotEmpty ? "${req.studentEmail} • " : ""}@${req.studentUsername}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (req.classCodeAttempted != null &&
                                req.classCodeAttempted!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: Colors.purple.shade200),
                                ),
                                child: Text(
                                  'Code: ${req.classCodeAttempted}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.purple.shade900,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (req.message != null && req.message!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '"${req.message}"',
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              onPressed: !isVerified
                                  ? null
                                  : () =>
                                      _respondToMentorshipRequest(req.id, false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red.shade700,
                                side: BorderSide(color: Colors.red.shade300),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.close_rounded, size: 16),
                              label: const Text('Reject',
                                  style: TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            FilledButton.icon(
                              onPressed: (isAtCapacity || !isVerified)
                                  ? null
                                  : () => _respondToMentorshipRequest(
                                      req.id, true),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.check_rounded, size: 16),
                              label: Text(
                                !isVerified
                                    ? 'Verify Req'
                                    : (isAtCapacity ? 'Roster Full' : 'Approve'),
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.bold),
                              ),
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

  Widget _buildHeader(
      BuildContext context,
      TeacherOverviewEntity? overview,
      AsyncValue<List<MentorshipRequestEntity>> mentorshipRequestsAsync) {
    final userProfileAsync = ref.watch(currentUserProfileProvider);
    final classCode =
        userProfileAsync.value?['class_code']?.toString() ?? '';
    final isVerified = overview?.isVerified ??
        (userProfileAsync.value?['is_verified'] as bool? ?? true);
    final maxCapacity = overview?.maxStudents ?? 100;
    final totalEnrolled = overview?.totalStudents ?? 0;
    final isAccepting = overview?.isAcceptingRequests ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isVerified) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_moon_rounded,
                    color: Colors.amber.shade900, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Faculty Account Pending Verification',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF78350F),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Your educator profile is awaiting administrator verification. Mentorship approvals and public features are guarded until verified.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showClassroomSettingsDialog(
                    context,
                    maxCapacity,
                    isAccepting,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: const Text(
                    'Classroom Settings',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
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
          ],
        ),
        if (classCode.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                        runSpacing: 4,
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: totalEnrolled >= maxCapacity
                                  ? Colors.red.shade100
                                  : Colors.indigo.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Enrolled: $totalEnrolled / $maxCapacity students',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: totalEnrolled >= maxCapacity
                                    ? Colors.red.shade900
                                    : Colors.indigo.shade900,
                              ),
                            ),
                          ),
                          if (!isAccepting)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Requests Paused',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Share this code with students. Entering it sends a request to your inbox for approval.',
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
        const SizedBox(height: 16),
        mentorshipRequestsAsync.when(
          data: (requests) => _buildMentorshipRequestsCard(
            context,
            requests,
            totalEnrolled,
            maxCapacity,
            isVerified: isVerified,
          ),
          loading: () => const SizedBox.shrink(),
          error: (e, s) => const SizedBox.shrink(),
        ),
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
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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

          if (bottlenecks.isEmpty || !bottlenecks.any((b) => b.completionRate > 0 || b.failureRate > 0 || b.avgAttempts > 0))
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bar_chart_rounded, size: 44, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'Not enough student data yet. Share your Class Code for students to join and generate analytics!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
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

          if (concepts.isEmpty || !concepts.any((c) => c.avgCompletionRate > 0))
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.hub_outlined, size: 44, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'Not enough student data yet. Share your Class Code for students to join and generate analytics!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
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

  Widget _buildCreatedContentCard(
    BuildContext context,
    List<dynamic> problems,
    List<dynamic> quizzes,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.auto_awesome_rounded,
                    color: Colors.teal.shade700, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Created Content',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Custom coding problems & Kahoot live quizzes',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => context.push('/educator-studio'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.teal.shade800,
                  side: BorderSide(color: Colors.teal.shade300),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text(
                  'Educator Studio',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          if (problems.isEmpty && quizzes.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 36, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  Text(
                    'No custom content created yet.',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Create custom coding problems or interactive live quizzes in the Educator Studio.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            )
          else ...[
            if (problems.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.code_rounded, size: 16, color: Colors.teal.shade800),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Custom Coding Problems (${problems.length})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: problems.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final prob = problems[index];
                  final isPublic = prob['visibility'] == 'PUBLIC';
                  final title = prob['title']?.toString() ?? 'Custom Problem';

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.terminal_rounded, size: 18, color: Colors.teal.shade900),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isPublic ? Colors.blue.shade50 : Colors.purple.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isPublic ? 'PUBLIC' : 'CLASS ONLY',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isPublic ? Colors.blue.shade700 : Colors.purple.shade700,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Created ${_formatDate(DateTime.tryParse(prob['created_at']?.toString() ?? '') ?? DateTime.now())}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonal(
                          onPressed: () => _showProblemStats(context, prob),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.teal.shade50,
                            foregroundColor: Colors.teal.shade800,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.analytics_outlined, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'View Stats',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
            if (quizzes.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.quiz_rounded, size: 16, color: Colors.amber.shade900),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Kahoot Live Quizzes (${quizzes.length})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: quizzes.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final quiz = quizzes[index];
                  final isPublic = quiz['visibility'] == 'PUBLIC';
                  final title = quiz['title']?.toString() ?? 'Live Quiz';
                  final questionsCount = (quiz['questions'] as List?)?.length ?? 0;
                  final timePerQ = quiz['time_per_question_seconds'] ?? 30;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.flash_on_rounded, size: 18, color: Colors.amber.shade900),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isPublic ? Colors.blue.shade50 : Colors.purple.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isPublic ? 'PUBLIC' : 'CLASS ONLY',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isPublic ? Colors.blue.shade700 : Colors.purple.shade700,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '$questionsCount Qs • ${timePerQ}s/q',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonal(
                          onPressed: () => _showQuizStats(context, quiz),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.amber.shade50,
                            foregroundColor: Colors.amber.shade900,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bar_chart_rounded, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'View Stats',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
          ],
        ],
      ),
    );
  }

  void _showProblemStats(BuildContext context, dynamic problem) {
    final problemId = problem['id']?.toString() ?? '';
    final title = problem['title']?.toString() ?? 'Custom Problem Stats';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProblemStatsSheet(problemId: problemId, title: title),
    );
  }

  void _showQuizStats(BuildContext context, dynamic quiz) {
    final quizId = quiz['id']?.toString() ?? '';
    final title = quiz['title']?.toString() ?? 'Quiz Stats';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _QuizStatsSheet(quizId: quizId, title: title),
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
                            a.lessonTitle ?? a.title,
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

class _ProblemStatsSheet extends StatefulWidget {
  final String problemId;
  final String title;

  const _ProblemStatsSheet({
    required this.problemId,
    required this.title,
  });

  @override
  State<_ProblemStatsSheet> createState() => _ProblemStatsSheetState();
}

class _ProblemStatsSheetState extends State<_ProblemStatsSheet> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }
      final data = await ApiClient.getCustomProblemStats(
        accessToken: token,
        problemId: widget.problemId,
      );
      setState(() {
        _stats = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '').trim();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.analytics_rounded, color: Colors.teal.shade800),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Detailed Student Performance & Pass Rates',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const Divider(height: 24),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(
                            child: Text(
                              'Failed to load stats: $_error',
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          )
                        : _buildStatsContent(scrollCtrl),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsContent(ScrollController scrollCtrl) {
    final stats = _stats!;
    final totalAttempts = stats['total_attempts'] ?? 0;
    final successful = stats['successful_submissions'] ?? 0;
    final passRate = (stats['pass_rate'] ?? 0.0).toStringAsFixed(1);
    final visibility = stats['visibility']?.toString() ?? 'CLASS_ONLY';
    final classStudents = (stats['class_students'] as List?) ?? [];

    return ListView(
      controller: scrollCtrl,
      children: [
        // KPI Cards Row
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                label: 'Total Attempts',
                value: '$totalAttempts',
                icon: Icons.refresh_rounded,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                label: 'Successful (AC)',
                value: '$successful',
                icon: Icons.check_circle_rounded,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                label: 'Pass Rate',
                value: '$passRate%',
                icon: Icons.trending_up_rounded,
                color: Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        if (visibility == 'PUBLIC') ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.public_rounded, color: Colors.blue.shade800, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This is a Public Problem. Total attempts include all AlgoVerse students globally. Individual breakdown below displays your paired classroom students.',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        Text(
          'Classroom Student Roster (${classStudents.length})',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),

        if (classStudents.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'No students in your class roster yet.',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: classStudents.length,
            separatorBuilder: (ctx, i) => const Divider(height: 14),
            itemBuilder: (ctx, i) {
              final student = classStudents[i];
              final hasSolved = student['has_solved'] == true;
              final attempts = student['total_attempts'] ?? 0;
              final name = student['student_name']?.toString() ?? 'Student';
              final email = student['student_email']?.toString() ?? '';

              return Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: hasSolved ? Colors.green.shade100 : Colors.grey.shade200,
                    child: Icon(
                      hasSolved ? Icons.check_rounded : (attempts > 0 ? Icons.timelapse_rounded : Icons.person_outline),
                      size: 16,
                      color: hasSolved ? Colors.green.shade800 : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          email,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: hasSolved
                          ? Colors.green.shade50
                          : (attempts > 0 ? Colors.amber.shade50 : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      hasSolved
                          ? 'SOLVED ($attempts ${attempts == 1 ? 'try' : 'tries'})'
                          : (attempts > 0 ? '$attempts ATTEMPTS' : 'NOT STARTED'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: hasSolved
                            ? Colors.green.shade800
                            : (attempts > 0 ? Colors.amber.shade900 : Colors.grey.shade600),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

        const SizedBox(height: 24),
        Text(
          'Student Submissions (${((stats['submissions'] as List?) ?? []).length})',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),

        if (((stats['submissions'] as List?) ?? []).isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'No student code submissions recorded yet.',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: ((stats['submissions'] as List?) ?? []).length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final sub = (stats['submissions'] as List)[i];
              final studentName = sub['student_name']?.toString() ?? 'Student';
              final studentEmail = sub['student_email']?.toString() ?? '';
              final verdict = (sub['verdict']?.toString() ?? 'PENDING').toUpperCase();
              final lang = (sub['language']?.toString() ?? 'python').toUpperCase();
              final runtimeMs = sub['runtime_ms'];
              final code = sub['code']?.toString() ?? '';
              final createdAtStr = sub['created_at']?.toString();
              DateTime? createdAt;
              if (createdAtStr != null) {
                createdAt = DateTime.tryParse(createdAtStr);
              }
              final isAC = verdict == 'AC' || verdict == 'ACCEPTED';

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: isAC ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                      child: Icon(
                        isAC ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        size: 18,
                        color: isAC ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  studentName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: isAC ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  verdict,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isAC ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEDE9FE),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  lang,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF7C3AED),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              if (studentEmail.isNotEmpty) ...[
                                Flexible(
                                  child: Text(
                                    studentEmail,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              if (runtimeMs != null) ...[
                                Text(
                                  '${runtimeMs}ms',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(width: 8),
                              ],
                              if (createdAt != null)
                                Text(
                                  '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      onPressed: () => _showCodeViewerModal(
                        context,
                        studentName: studentName,
                        verdict: verdict,
                        language: lang,
                        code: code,
                        runtimeMs: runtimeMs?.toString(),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.code_rounded, size: 14),
                      label: const Text('View Code', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  void _showCodeViewerModal(
    BuildContext context, {
    required String studentName,
    required String verdict,
    required String language,
    required String code,
    String? runtimeMs,
  }) {
    showDialog(
      context: context,
      builder: (ctx) {
        final isAC = verdict == 'AC' || verdict == 'ACCEPTED';
        return Dialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 700, maxHeight: 650),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.code_rounded, color: Colors.cyanAccent, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Submission by $studentName',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isAC
                                      ? const Color(0x4D16A34A)
                                      : const Color(0x4DDC2626),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: isAC ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  verdict,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isAC ? const Color(0xFF4ADE80) : const Color(0xFFF87171),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                language,
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                              if (runtimeMs != null) ...[
                                const SizedBox(width: 6),
                                Text(
                                  '• ${runtimeMs}ms',
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, color: Colors.white70, size: 18),
                      tooltip: 'Copy Code',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Code copied to clipboard'),
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(color: Color(0xFF334155), height: 1),
                const SizedBox(height: 14),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF030712),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF1E293B)),
                    ),
                    child: SingleChildScrollView(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SelectableText(
                          code.isEmpty ? '// No code recorded for this attempt' : code,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            color: Color(0xFFE2E8F0),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData icon,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color.shade800, size: 20),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color.shade900,
              ),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: color.shade800),
          ),
        ],
      ),
    );
  }
}

class _QuizStatsSheet extends StatefulWidget {
  final String quizId;
  final String title;

  const _QuizStatsSheet({
    required this.quizId,
    required this.title,
  });

  @override
  State<_QuizStatsSheet> createState() => _QuizStatsSheetState();
}

class _QuizStatsSheetState extends State<_QuizStatsSheet> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }
      final data = await ApiClient.getQuizStats(
        accessToken: token,
        quizId: widget.quizId,
      );
      setState(() {
        _stats = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '').trim();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.flash_on_rounded, color: Colors.amber.shade900),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Live Quiz Leaderboard & Completion Stats',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const Divider(height: 24),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(
                            child: Text(
                              'Failed to load quiz stats: $_error',
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          )
                        : _buildStatsContent(scrollCtrl),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsContent(ScrollController scrollCtrl) {
    final stats = _stats!;
    final totalAttempts = stats['total_attempts'] ?? 0;
    final avgScore = (stats['avg_score'] ?? 0.0).toStringAsFixed(1);
    final highScore = stats['high_score'] ?? 0;
    final visibility = stats['visibility']?.toString() ?? 'CLASS_ONLY';
    final classStudents = (stats['class_students'] as List?) ?? [];

    return ListView(
      controller: scrollCtrl,
      children: [
        // KPI Cards Row
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                label: 'Total Plays',
                value: '$totalAttempts',
                icon: Icons.play_arrow_rounded,
                color: Colors.amber,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                label: 'Avg Score',
                value: '$avgScore pts',
                icon: Icons.score_rounded,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                label: 'High Score',
                value: '$highScore pts',
                icon: Icons.emoji_events_rounded,
                color: Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        if (visibility == 'PUBLIC') ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.public_rounded, color: Colors.blue.shade800, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This is a Public Quiz. Total plays and average scores include all AlgoVerse students globally. Below displays scores for your paired classroom students.',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        Text(
          'Classroom Quiz Leaderboard (${classStudents.length})',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),

        if (classStudents.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'No student scores recorded yet.',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: classStudents.length,
            separatorBuilder: (ctx, i) => const Divider(height: 14),
            itemBuilder: (ctx, i) {
              final student = classStudents[i];
              final hasParticipated = student['has_participated'] == true;
              final score = student['score'] ?? 0;
              final timeSeconds = student['total_time_seconds'] ?? 0;
              final name = student['student_name']?.toString() ?? 'Student';
              final email = student['student_email']?.toString() ?? '';

              return Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: hasParticipated ? Colors.amber.shade100 : Colors.grey.shade200,
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: hasParticipated ? Colors.amber.shade900 : Colors.grey.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          email,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (hasParticipated)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$score pts',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${timeSeconds}s',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'NOT PLAYED',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData icon,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color.shade800, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color.shade900,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color.shade800),
          ),
        ],
      ),
    );
  }
}