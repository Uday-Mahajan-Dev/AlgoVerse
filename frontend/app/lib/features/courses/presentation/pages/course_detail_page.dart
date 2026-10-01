import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/course_provider.dart';


class CourseDetailPage extends ConsumerStatefulWidget {
  final String courseSlug;

  const CourseDetailPage({
    super.key,
    required this.courseSlug,
  });

  @override
  ConsumerState<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends ConsumerState<CourseDetailPage> {
  bool _isEnrolling = false;

  Future<void> _enroll(String slug) async {
    if (_isEnrolling) return;
    setState(() {
      _isEnrolling = true;
    });

    try {
      final repo = ref.read(courseRepositoryProvider);
      final result = await repo.enrollInCourse(slug);

      if (!mounted) return;

      ref.invalidate(courseDetailProvider(widget.courseSlug));
      ref.invalidate(coursesListProvider);
      ref.invalidate(allStudentProgressProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ?? 'Enrolled in course successfully!',
          ),
          backgroundColor: Colors.indigo,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isEnrolling = false;
        });
      }
    }
  }

  IconData _getContentTypeIcon(String contentType) {
    switch (contentType.toUpperCase()) {
      case 'VISUALIZATION':
        return Icons.insights_rounded;
      case 'PROBLEM':
        return Icons.code_rounded;
      case 'CONCEPT':
      default:
        return Icons.article_outlined;
    }
  }

  Color _getContentTypeColor(String contentType) {
    switch (contentType.toUpperCase()) {
      case 'VISUALIZATION':
        return Colors.purple;
      case 'PROBLEM':
        return Colors.orange.shade800;
      case 'CONCEPT':
      default:
        return Colors.indigo;
    }
  }

  @override
  Widget build(BuildContext context) {
    final courseAsync = ref.watch(courseDetailProvider(widget.courseSlug));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Syllabus'),
        elevation: 0,
      ),
      body: SafeArea(
        child: courseAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(
                  'Unable to load course detail.\n${err.toString().replaceAll('Exception: ', '')}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(courseDetailProvider(widget.courseSlug)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (course) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(courseDetailProvider(widget.courseSlug));
                ref.invalidate(allStudentProgressProvider);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Course Header Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade900,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  course.difficulty.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white12,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  course.topicCategory,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            course.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            course.description,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Progress or Enroll CTA Banner
                    if (course.isEnrolled) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: Colors.green.shade700,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'YOUR PROGRESS',
                                      style: TextStyle(
                                        color: Colors.green.shade900,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${course.completedLessons}/${course.totalLessons} Lessons (${course.completionPercentage.toStringAsFixed(0)}%)',
                                  style: TextStyle(
                                    color: Colors.green.shade900,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: (course.completionPercentage / 100.0)
                                    .clamp(0.0, 1.0),
                                minHeight: 8,
                                backgroundColor: Colors.green.shade100,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.green.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.preview_rounded,
                                    color: Colors.amber.shade900, size: 22),
                                const SizedBox(width: 8),
                                Text(
                                  'Course Syllabus Preview',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade900,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'You are previewing this course outline. Enroll below to access lessons and save your progress.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.amber.shade900,
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _isEnrolling
                                    ? null
                                    : () => _enroll(course.slug),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.indigo,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: _isEnrolling
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'ENROLL IN COURSE',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // Modules & Lessons Syllabus
                    Text(
                      'SYLLABUS (${course.moduleCount} MODULES)',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 14),

                    ...course.modules.map((module) {
                      return Container(

                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent,
                          ),
                          child: ExpansionTile(
                            initiallyExpanded: true,
                            title: Text(
                              module.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Text(
                              '${module.lessons.length} lessons',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            childrenPadding: const EdgeInsets.only(
                              bottom: 8,
                              left: 8,
                              right: 8,
                            ),
                            children: module.lessons.asMap().entries.map((lEntry) {
                              final lessonIndex = lEntry.key + 1;
                              final lesson = lEntry.value;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                decoration: BoxDecoration(
                                  color: lesson.isCompleted
                                      ? Colors.green.shade50.withValues(alpha: 0.5)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  onTap: () {
                                    context.push(
                                      '/courses/${widget.courseSlug}/lessons/${lesson.slug}',
                                    );
                                  },
                                  leading: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: _getContentTypeColor(
                                              lesson.contentType)
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      _getContentTypeIcon(lesson.contentType),
                                      size: 18,
                                      color: _getContentTypeColor(
                                          lesson.contentType),
                                    ),
                                  ),
                                  title: Text(
                                    '$lessonIndex. ${lesson.title}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      decoration: lesson.isCompleted
                                          ? TextDecoration.none
                                          : null,
                                    ),
                                  ),
                                  subtitle: Row(
                                    children: [
                                      Text(
                                        lesson.contentType,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: _getContentTypeColor(
                                              lesson.contentType),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '• ${lesson.estimatedMinutes} min',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: lesson.isCompleted
                                      ? Icon(
                                          Icons.check_circle_rounded,
                                          color: Colors.green.shade600,
                                          size: 22,
                                        )
                                      : Icon(
                                          Icons.chevron_right_rounded,
                                          color: Colors.grey.shade400,
                                        ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
