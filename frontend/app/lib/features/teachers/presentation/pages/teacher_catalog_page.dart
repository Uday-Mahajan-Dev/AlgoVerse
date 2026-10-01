import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../domain/entities/teacher_entity.dart';
import '../providers/teacher_provider.dart';

class TeacherCatalogPage extends ConsumerStatefulWidget {
  const TeacherCatalogPage({super.key});

  @override
  ConsumerState<TeacherCatalogPage> createState() => _TeacherCatalogPageState();
}

class _TeacherCatalogPageState extends ConsumerState<TeacherCatalogPage> {
  final _searchController = TextEditingController();
  bool _isSelecting = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectTeacher(TeacherEntity teacher) async {
    if (_isSelecting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Mentor Teacher'),
        content: Text(
          'Do you want to select ${teacher.displayName} as your mentor teacher? '
          'This will update your learning curriculum and mentor tracking.',
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

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response['message']?.toString() ??
                'Teacher selected successfully!',
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

  @override
  Widget build(BuildContext context) {
    final teachersAsync = ref.watch(teachersListProvider);
    final myTeacherAsync = ref.watch(myTeacherProvider);

    final selectedTeacherId = myTeacherAsync.asData?.value.teacher?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a Mentor Teacher'),
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
                  hintText: 'Search by teacher name, specialty, or topic...',
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
                ),
                onChanged: (value) {
                  ref
                      .read(teacherSearchQueryProvider.notifier)
                      .setQuery(value);
                },
              ),
            ),

            // Teachers List
            Expanded(
              child: teachersAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stackTrace) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 48),
                      const SizedBox(height: 12),
                      const Text('Failed to load teachers list.'),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => ref.invalidate(teachersListProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (teachers) {
                  if (teachers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.school_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isNotEmpty
                                ? 'No teachers found for "${_searchController.text}"'
                                : 'No teachers currently available.',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Check back soon or try another search.',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(teachersListProvider);
                      ref.invalidate(myTeacherProvider);
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
                        final isCurrentMentor = teacher.id == selectedTeacherId;

                        return TeacherCard(
                          teacher: teacher,
                          isCurrentMentor: isCurrentMentor,
                          isSelecting: _isSelecting,
                          onViewProfile: () {
                            context.push('/teachers/${teacher.id}');
                          },
                          onSelect: isCurrentMentor
                              ? null
                              : () => _selectTeacher(teacher),
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
  final bool isCurrentMentor;
  final bool isSelecting;
  final VoidCallback onViewProfile;
  final VoidCallback? onSelect;

  const TeacherCard({
    super.key,
    required this.teacher,
    required this.isCurrentMentor,
    required this.isSelecting,
    required this.onViewProfile,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isCurrentMentor
              ? Colors.indigo
              : Colors.grey.shade300,
          width: isCurrentMentor ? 2 : 1,
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
                              : 'T',
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
                          if (isCurrentMentor)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.indigo,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'CURRENT MENTOR',
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
                        '@${teacher.username}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
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
                  size: 18,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  '${teacher.studentCount} Students',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: onViewProfile,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('View Profile'),
                ),
                const SizedBox(width: 8),
                if (!isCurrentMentor)
                  FilledButton(
                    onPressed: isSelecting ? null : onSelect,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Select'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
