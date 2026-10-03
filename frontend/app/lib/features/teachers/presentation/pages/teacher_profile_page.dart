import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/teacher_entity.dart';
import '../providers/teacher_provider.dart';

class TeacherProfilePage extends ConsumerStatefulWidget {
  final String teacherId;

  const TeacherProfilePage({
    super.key,
    required this.teacherId,
  });

  @override
  ConsumerState<TeacherProfilePage> createState() => _TeacherProfilePageState();
}

class _TeacherProfilePageState extends ConsumerState<TeacherProfilePage> {
  bool _isSelecting = false;
  bool _isLoadingChallenges = true;
  List<dynamic> _customProblems = [];
  List<dynamic> _quizzes = [];

  @override
  void initState() {
    super.initState();
    _loadMentorAssets();
  }

  Future<void> _loadMentorAssets() async {
    try {
      final token = await TokenStorage.getAccessToken();
      final problems = await ApiClient.getTeacherPublishedCustomProblems(
        accessToken: token,
        teacherId: widget.teacherId,
      );
      final quizzes = await ApiClient.getTeacherPublishedQuizzes(
        accessToken: token,
        teacherId: widget.teacherId,
      );

      if (mounted) {
        setState(() {
          _customProblems = problems;
          _quizzes = quizzes;
          _isLoadingChallenges = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingChallenges = false;
        });
      }
    }
  }

  Future<void> _selectTeacher(TeacherEntity teacher) async {
    if (_isSelecting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Mentor Teacher'),
        content: Text(
          'Confirm selecting ${teacher.displayName} as your mentor teacher?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isSelecting = true;
    });

    try {
      final repository = ref.read(teacherRepositoryProvider);
      final response = await repository.selectTeacher(teacher.id);

      ref.invalidate(myTeacherProvider);
      ref.invalidate(teachersListProvider);
      ref.invalidate(teacherProfileProvider(widget.teacherId));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response['message']?.toString() ??
                'Mentor teacher selected successfully!',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );

      context.go(AppRoutes.studentDashboard);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSelecting = false;
        });
      }
    }
  }

  void _copyLink(String label, String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard: $url'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teacherAsync = ref.watch(teacherProfileProvider(widget.teacherId));
    final myTeacherAsync = ref.watch(myTeacherProvider);

    final isCurrentMentor =
        myTeacherAsync.asData?.value.teacher?.id == widget.teacherId;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Teacher Profile'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: teacherAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stackTrace) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48),
                const SizedBox(height: 12),
                const Text('Failed to load teacher profile.'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    ref.invalidate(teacherProfileProvider(widget.teacherId));
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (teacher) {
            final institution = teacher.institutionName;
            final designation = teacher.designation;
            final bioText = teacher.professionalBio ?? teacher.bio;
            final hasInstagram = teacher.instagramUrl != null && teacher.instagramUrl!.isNotEmpty;
            final hasLinkedIn = teacher.linkedinUrl != null && teacher.linkedinUrl!.isNotEmpty;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Header Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Avatar
                            CircleAvatar(
                              radius: 52,
                              backgroundColor: Colors.indigo.withValues(alpha: 0.1),
                              backgroundImage: teacher.avatarUrl != null
                                  ? NetworkImage(teacher.avatarUrl!)
                                  : null,
                              child: teacher.avatarUrl == null
                                  ? Text(
                                      teacher.displayName.isNotEmpty
                                          ? teacher.displayName[0].toUpperCase()
                                          : 'T',
                                      style: const TextStyle(
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.indigo,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            // Name
                            Text(
                              teacher.displayName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),

                            // Username & Country
                            Text(
                              '@${teacher.username}${teacher.country != null ? ' • ${teacher.country}' : ''}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Institution & Designation
                            if (institution != null && institution.isNotEmpty) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.school_rounded, size: 16, color: Colors.purple.shade700),
                                  const SizedBox(width: 6),
                                  Text(
                                    designation != null && designation.isNotEmpty
                                        ? '$designation • $institution'
                                        : institution,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.purple.shade900,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                            ],

                            // Specialty Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.indigo.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                teacher.specialty,
                                style: const TextStyle(
                                  color: Colors.indigo,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),

                            // Social Links Row
                            if (hasInstagram || hasLinkedIn) ...[
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (hasLinkedIn)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: OutlinedButton.icon(
                                        onPressed: () => _copyLink('LinkedIn', teacher.linkedinUrl!),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          side: BorderSide(color: Colors.blue.shade300),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        icon: const Icon(Icons.link_rounded, size: 16, color: Color(0xFF0A66C2)),
                                        label: const Text('LinkedIn', style: TextStyle(fontSize: 12, color: Color(0xFF0A66C2), fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  if (hasInstagram)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: OutlinedButton.icon(
                                        onPressed: () => _copyLink('Instagram', teacher.instagramUrl!),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          side: BorderSide(color: Colors.pink.shade300),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        icon: const Icon(Icons.camera_alt_outlined, size: 16, color: Color(0xFFE4405F)),
                                        label: const Text('Instagram', style: TextStyle(fontSize: 12, color: Color(0xFFE4405F), fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Stats Row
                      Row(
                        children: [
                          Expanded(
                            child: _StatTile(
                              icon: Icons.people_outline_rounded,
                              value: '${teacher.studentCount}',
                              label: 'STUDENTS',
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: _StatTile(
                              icon: Icons.verified_user_rounded,
                              value: 'VERIFIED',
                              label: 'MENTOR STATUS',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Bio Section
                      if (bioText != null && bioText.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline_rounded, size: 18, color: Colors.grey.shade700),
                                  const SizedBox(width: 8),
                                  Text(
                                    'ABOUT THE MENTOR',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.1,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                bioText,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Mentor's Challenges & Quizzes Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.code_rounded, size: 18, color: Colors.purple.shade700),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'Mentor\'s Challenges & Quizzes',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            if (_isLoadingChallenges)
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: CircularProgressIndicator()),
                              )
                            else if (_customProblems.isEmpty && _quizzes.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'This mentor has not published any public coding challenges or quizzes yet.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                ),
                              )
                            else ...[
                              if (_customProblems.isNotEmpty) ...[
                                Text(
                                  'CODING CHALLENGES (${_customProblems.length})',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _customProblems.length,
                                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                                  itemBuilder: (context, idx) {
                                    final p = _customProblems[idx];
                                    final pId = p['id']?.toString() ?? '';
                                    final pTitle = p['title']?.toString() ?? 'Challenge';
                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.terminal_rounded, size: 20, color: Color(0xFF0D9488)),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              pTitle,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                          ),
                                          FilledButton.icon(
                                            onPressed: () {
                                              context.push('/custom-problem/$pId');
                                            },
                                            style: FilledButton.styleFrom(
                                              backgroundColor: const Color(0xFF0D9488),
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            icon: const Icon(Icons.play_arrow_rounded, size: 14),
                                            label: const Text('Solve', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 14),
                              ],

                              if (_quizzes.isNotEmpty) ...[
                                Text(
                                  'LIVE QUIZZES (${_quizzes.length})',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _quizzes.length,
                                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                                  itemBuilder: (context, idx) {
                                    final q = _quizzes[idx];
                                    final qId = q['id']?.toString() ?? '';
                                    final qTitle = q['title']?.toString() ?? 'Quiz';
                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.sports_esports_rounded, size: 20, color: Color(0xFFD97706)),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              qTitle,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                          ),
                                          FilledButton.icon(
                                            onPressed: () {
                                              context.push('/quizzes/$qId/play');
                                            },
                                            style: FilledButton.styleFrom(
                                              backgroundColor: const Color(0xFFD97706),
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            icon: const Icon(Icons.play_arrow_rounded, size: 14),
                                            label: const Text('Play', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
                      ),
                      const SizedBox(height: 24),

                      // Action Button
                      if (isCurrentMentor)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'This is your current mentor teacher',
                                style: TextStyle(
                                  color: Colors.green.shade800,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton.icon(
                            onPressed:
                                _isSelecting ? null : () => _selectTeacher(teacher),
                            icon: _isSelecting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.person_add_alt_1_rounded),
                            label: Text(
                              _isSelecting
                                  ? 'Selecting...'
                                  : 'Select as My Mentor Teacher',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.indigo),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
