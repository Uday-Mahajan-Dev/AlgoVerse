import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../courses/domain/entities/course_entity.dart';
import '../../../courses/presentation/providers/course_provider.dart';
import '../providers/teacher_analytics_provider.dart';

class AssignHomeworkDialog extends ConsumerStatefulWidget {
  const AssignHomeworkDialog({super.key});

  @override
  ConsumerState<AssignHomeworkDialog> createState() =>
      _AssignHomeworkDialogState();
}

class _AssignHomeworkDialogState extends ConsumerState<AssignHomeworkDialog> {
  final Set<String> _selectedStudentIds = {};
  String? _selectedCourseSlug;
  String? _selectedLessonId;
  DateTime? _selectedDueDate;
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedStudentIds.isEmpty) {
      setState(() => _errorMessage = 'Please select at least one student.');
      return;
    }
    if (_selectedLessonId == null) {
      setState(() => _errorMessage = 'Please select a lesson to assign.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(teacherAnalyticsRepositoryProvider);
      await repo.createAssignment(
        studentIds: _selectedStudentIds.toList(),
        lessonId: _selectedLessonId!,
        dueDate: _selectedDueDate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (!mounted) return;

      ref.invalidate(teacherAssignmentsProvider);
      ref.invalidate(teacherOverviewProvider);

      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Homework successfully assigned to ${_selectedStudentIds.length} student(s)!',
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(teacherStudentsProvider);
    final coursesAsync = ref.watch(coursesListProvider);
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 18 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.assignment_add,
                      color: Colors.indigo,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Assign Homework',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          'Assign visualizer exercises or coding problems',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Dialog Body
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Select Students
                      const Text(
                        '1. SELECT STUDENTS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(height: 8),
                      studentsAsync.when(
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (err, _) => Text(
                          'Error loading students: $err',
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                        data: (students) {
                          if (students.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.purple.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.people_outline_rounded,
                                          color: Colors.purple.shade700, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'No students enrolled yet',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.purple.shade900,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Share your Class Joining Code with your students so they can join your classroom.',
                                    style: TextStyle(
                                      color: Colors.purple.shade900,
                                      fontSize: 12,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final allSelected =
                              _selectedStudentIds.length == students.length;

                          return Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                CheckboxListTile(
                                  value: allSelected,
                                  dense: true,
                                  title: const Text(
                                    'Select All Students',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        _selectedStudentIds.addAll(
                                          students.map((s) => s.studentId),
                                        );
                                      } else {
                                        _selectedStudentIds.clear();
                                      }
                                    });
                                  },
                                ),
                                const Divider(height: 1),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxHeight: 140),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: students.length,
                                    itemBuilder: (context, i) {
                                      final s = students[i];
                                      final isSelected =
                                          _selectedStudentIds.contains(s.studentId);
                                      return CheckboxListTile(
                                        value: isSelected,
                                        dense: true,
                                        title: Text(
                                          s.studentName,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                        subtitle: Text(
                                          'Streak: ${s.currentStreak}d • ${s.overallCompletionPct.toStringAsFixed(0)}% completion',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        onChanged: (val) {
                                          setState(() {
                                            if (val == true) {
                                              _selectedStudentIds.add(s.studentId);
                                            } else {
                                              _selectedStudentIds.remove(s.studentId);
                                            }
                                          });
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 18),

                      // 2. Select Lesson
                      const Text(
                        '2. SELECT TARGET LESSON',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(height: 8),
                      coursesAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Text('Error loading courses: $e'),
                        data: (courses) {
                          if (_selectedCourseSlug == null && courses.isNotEmpty) {
                            _selectedCourseSlug = courses.first.slug;
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue: _selectedCourseSlug,
                                decoration: InputDecoration(
                                  labelText: 'Course',
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                items: courses.map((c) {
                                  return DropdownMenuItem(
                                    value: c.slug,
                                    child: Text(
                                      c.title,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedCourseSlug = val;
                                    _selectedLessonId = null;
                                  });
                                },
                              ),
                              if (_selectedCourseSlug != null) ...[
                                const SizedBox(height: 10),
                                _CourseLessonsDropdown(
                                  courseSlug: _selectedCourseSlug!,
                                  selectedLessonId: _selectedLessonId,
                                  onLessonSelected: (id) {
                                    setState(() {
                                      _selectedLessonId = id;
                                    });
                                  },
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 18),

                      // 3. Due Date & Notes
                      const Text(
                        '3. DUE DATE & INSTRUCTIONS (OPTIONAL)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final now = DateTime.now();
                          final date = await showDatePicker(
                            context: context,
                            initialDate: now.add(const Duration(days: 3)),
                            firstDate: now,
                            lastDate: now.add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() {
                              _selectedDueDate = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                23,
                                59,
                              );
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 18,
                                color: Colors.indigo,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _selectedDueDate != null
                                      ? 'Due: ${_selectedDueDate!.month}/${_selectedDueDate!.day}/${_selectedDueDate!.year}'
                                      : 'Select due date (optional)',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: _selectedDueDate != null
                                        ? const Color(0xFF1E293B)
                                        : Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              if (_selectedDueDate != null)
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () =>
                                      setState(() => _selectedDueDate = null),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText:
                              'Add homework notes or instructions for students...',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    FilledButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 16),
                      label: Text(
                        _isSubmitting ? 'Assigning...' : 'Assign Homework',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseLessonsDropdown extends ConsumerWidget {
  final String courseSlug;
  final String? selectedLessonId;
  final void Function(String lessonId) onLessonSelected;

  const _CourseLessonsDropdown({
    required this.courseSlug,
    required this.selectedLessonId,
    required this.onLessonSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(courseDetailProvider(courseSlug));

    return detailAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(8),
        child: LinearProgressIndicator(),
      ),
      error: (e, _) => Text('Error loading lessons: $e'),
      data: (course) {
        final lessons = <LessonEntity>[];
        for (final m in course.modules) {
          lessons.addAll(m.lessons);
        }

        if (lessons.isEmpty) {
          return const Text('No lessons found in this course.');
        }

        return DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: selectedLessonId,
          decoration: InputDecoration(
            labelText: 'Lesson Exercise',
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          items: lessons.map((l) {
            return DropdownMenuItem(
              value: l.id,
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: l.contentType == 'PROBLEM'
                          ? Colors.orange.shade50
                          : (l.contentType == 'VISUALIZATION'
                              ? Colors.purple.shade50
                              : Colors.blue.shade50),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      l.contentType,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: l.contentType == 'PROBLEM'
                            ? Colors.orange.shade800
                            : (l.contentType == 'VISUALIZATION'
                                ? Colors.purple.shade800
                                : Colors.blue.shade800),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.title,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              onLessonSelected(val);
            }
          },
        );
      },
    );
  }
}
