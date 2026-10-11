import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/teacher_entity.dart';
import '../providers/teacher_provider.dart';
import '../widgets/professor_rating_sheet.dart';

class TeacherCatalogPage extends ConsumerStatefulWidget {
  const TeacherCatalogPage({super.key});

  @override
  ConsumerState<TeacherCatalogPage> createState() => _TeacherCatalogPageState();
}

class _TeacherCatalogPageState extends ConsumerState<TeacherCatalogPage> {
  final _searchController = TextEditingController();
  bool _isRequesting = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _requestToJoin(TeacherEntity teacher) async {
    if (_isRequesting) return;

    final messageController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.school, color: Colors.indigo),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Request Mentorship',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send a mentorship request to ${teacher.displayName} (${teacher.institutionName ?? 'Faculty'}). '
              'Once approved, you will join this professor\'s classroom.',
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.group, size: 18, color: Colors.indigo),
                  const SizedBox(width: 8),
                  Text(
                    'Classroom capacity: ${teacher.studentCount} / ${teacher.maxStudents} students',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              maxLines: 3,
              maxLength: 300,
              decoration: InputDecoration(
                hintText:
                    'Introduce yourself or share learning goals (optional)...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Send Request'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.indigo,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final studentNote = messageController.text.trim();

    setState(() => _isRequesting = true);

    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) throw Exception('Please log in first.');

      final res = await ApiClient.sendMentorshipRequest(
        accessToken: token,
        teacherId: teacher.id,
        message: studentNote.isNotEmpty ? studentNote : null,
      );

      ref.invalidate(studentMentorshipRequestsProvider);
      ref.invalidate(myMentorsListProvider);
      ref.invalidate(teachersListProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res['message']?.toString() ??
                'Mentorship request sent successfully! Awaiting faculty approval.',
          ),
          backgroundColor: const Color(0xFF10B981),
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
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final teachersAsync = ref.watch(teachersListProvider);
    final myMentorsAsync = ref.watch(myMentorsListProvider);
    final requestsAsync = ref.watch(studentMentorshipRequestsProvider);

    final approvedMentorIds = (myMentorsAsync.asData?.value ?? [])
        .map((m) => m.teacherId)
        .toSet();

    final pendingRequestTeacherIds = (requestsAsync.asData?.value ?? [])
        .where((r) => r.status.toUpperCase() == 'PENDING')
        .map((r) => r.teacherId)
        .toSet();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a Mentor Professor'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by professor name, specialty, or university...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(teacherSearchQueryProvider.notifier)
                                .setQuery('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
                onChanged: (value) {
                  ref
                      .read(teacherSearchQueryProvider.notifier)
                      .setQuery(value.trim());
                },
              ),
            ),

            // Directory List
            Expanded(
              child: teachersAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading professors: $error',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () {
                            ref.invalidate(teachersListProvider);
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (teachers) {
                  if (teachers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.school_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No educators found matching your query.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(teachersListProvider);
                      ref.invalidate(myMentorsListProvider);
                      ref.invalidate(studentMentorshipRequestsProvider);
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: teachers.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final teacher = teachers[index];
                        final isApproved =
                            approvedMentorIds.contains(teacher.id);
                        final isPending =
                            pendingRequestTeacherIds.contains(teacher.id);

                        return TeacherCard(
                          teacher: teacher,
                          isApproved: isApproved,
                          isPending: isPending,
                          isRequesting: _isRequesting,
                          onViewProfile: () {
                            context.push('/teachers/${teacher.id}');
                          },
                          onRequestToJoin: (isApproved || isPending || teacher.isAtCapacity || !teacher.isAcceptingRequests)
                              ? null
                              : () => _requestToJoin(teacher),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TeacherCard extends StatelessWidget {
  final TeacherEntity teacher;
  final bool isApproved;
  final bool isPending;
  final bool isRequesting;
  final VoidCallback onViewProfile;
  final VoidCallback? onRequestToJoin;

  const TeacherCard({
    super.key,
    required this.teacher,
    required this.isApproved,
    required this.isPending,
    required this.isRequesting,
    required this.onViewProfile,
    this.onRequestToJoin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFull = teacher.isAtCapacity || !teacher.isAcceptingRequests;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isApproved
              ? Colors.green.shade600
              : isPending
                  ? Colors.amber.shade600
                  : Colors.grey.shade300,
          width: (isApproved || isPending) ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.indigo.withValues(alpha: 0.1),
                  backgroundImage: teacher.avatarUrl != null
                      ? NetworkImage(teacher.avatarUrl!)
                      : null,
                  child: teacher.avatarUrl == null
                      ? Text(
                          teacher.displayName.isNotEmpty
                              ? teacher.displayName[0].toUpperCase()
                              : 'P',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              teacher.displayName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isApproved)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade700,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle,
                                      size: 13, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'APPROVED MENTOR',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (isPending)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade800,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.hourglass_top,
                                      size: 13, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'REQUEST PENDING',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (isFull)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade700,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'CLASSROOM FULL',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        teacher.institutionName != null
                            ? '${teacher.designation ?? 'Professor'} • ${teacher.institutionName}'
                            : '@${teacher.username}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          teacher.specialty,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (teacher.bio != null && teacher.bio!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                teacher.bio!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  Icons.people_outline,
                  size: 16,
                  color: isFull ? Colors.red.shade600 : Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  '${teacher.studentCount} / ${teacher.maxStudents} Students',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isFull ? Colors.red.shade700 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 15,
                        color: Color(0xFFD97706),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        teacher.ratingAvg > 0
                            ? '${teacher.ratingAvg.toStringAsFixed(1)} (${teacher.ratingCount} ${teacher.ratingCount == 1 ? 'rating' : 'ratings'})'
                            : 'No ratings yet',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isApproved) ...[
                  OutlinedButton.icon(
                    onPressed: () {
                      ProfessorRatingSheet.show(
                        context,
                        teacherId: teacher.id,
                        teacherName: teacher.displayName,
                      );
                    },
                    icon: const Icon(Icons.star_outline_rounded, size: 16, color: Color(0xFFD97706)),
                    label: const Text('Rate', style: TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFF59E0B)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                OutlinedButton(
                  onPressed: onViewProfile,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('View Profile'),
                ),
                if (!isApproved && !isPending) ...[
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: isRequesting ? null : onRequestToJoin,
                    icon: const Icon(Icons.person_add_alt_1, size: 16),
                    label: Text(isFull ? 'Full' : 'Request to Join'),
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          isFull ? Colors.grey.shade400 : Colors.indigo,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
