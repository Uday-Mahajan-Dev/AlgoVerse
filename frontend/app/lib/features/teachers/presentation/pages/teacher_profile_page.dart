import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
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

  @override
  Widget build(BuildContext context) {
    final teacherAsync = ref.watch(teacherProfileProvider(widget.teacherId));
    final myTeacherAsync = ref.watch(myTeacherProvider);

    final isCurrentMentor =
        myTeacherAsync.asData?.value.teacher?.id == widget.teacherId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Profile'),
        centerTitle: true,
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
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 54,
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
                                  fontSize: 44,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 18),

                      // Name
                      Text(
                        teacher.displayName,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),

                      // Username & Country
                      Text(
                        '@${teacher.username}${teacher.country != null ? ' • ${teacher.country}' : ''}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Specialty Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          teacher.specialty,
                          style: const TextStyle(
                            color: Colors.indigo,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Stats Row
                      Row(
                        children: [
                          Expanded(
                            child: _StatTile(
                              icon: Icons.people_outline,
                              value: '${teacher.studentCount}',
                              label: 'STUDENTS',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _StatTile(
                              icon: Icons.verified_user_outlined,
                              value: 'VERIFIED',
                              label: 'MENTOR STATUS',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Bio Section
                      if (teacher.bio != null && teacher.bio!.isNotEmpty) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'ABOUT THE MENTOR',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Text(
                            teacher.bio!,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],

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
                                Icons.check_circle,
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
                          height: 54,
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
                                : const Icon(Icons.person_add_alt_1),
                            label: Text(
                              _isSelecting
                                  ? 'Selecting...'
                                  : 'Select as My Mentor Teacher',
                              style: const TextStyle(
                                fontSize: 16,
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
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(icon, color: Colors.indigo),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
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
      ),
    );
  }
}
