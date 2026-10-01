import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../learning/presentation/widgets/interactive_visualizer_workspace.dart';
import '../../domain/entities/course_entity.dart';
import '../providers/course_provider.dart';


class LessonViewPage extends ConsumerStatefulWidget {
  final String courseSlug;
  final String lessonSlug;

  const LessonViewPage({
    super.key,
    required this.courseSlug,
    required this.lessonSlug,
  });

  @override
  ConsumerState<LessonViewPage> createState() => _LessonViewPageState();
}

class _LessonViewPageState extends ConsumerState<LessonViewPage> {
  bool _isEnrolling = false;
  bool _isCompleting = false;

  Future<void> _enroll() async {
    if (_isEnrolling) return;
    setState(() {
      _isEnrolling = true;
    });

    try {
      final repo = ref.read(courseRepositoryProvider);
      final res = await repo.enrollInCourse(widget.courseSlug);

      if (!mounted) return;

      ref.invalidate(courseDetailProvider(widget.courseSlug));
      ref.invalidate(allStudentProgressProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? 'Enrolled successfully!'),
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

  Future<void> _completeLesson(String lessonId) async {
    if (_isCompleting) return;
    setState(() {
      _isCompleting = true;
    });

    try {
      final repo = ref.read(courseRepositoryProvider);
      final res = await repo.completeLesson(lessonId);

      if (!mounted) return;

      ref.invalidate(courseDetailProvider(widget.courseSlug));
      ref.invalidate(allStudentProgressProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res['message']?.toString() ?? 'Lesson completed! +50 XP awarded.',
          ),
          backgroundColor: Colors.green.shade700,
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
          _isCompleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final courseAsync = ref.watch(courseDetailProvider(widget.courseSlug));

    return courseAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Loading Lesson...')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                'Failed to load lesson.\n${err.toString().replaceAll('Exception: ', '')}',
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
      ),
      data: (course) {
        // Find the lesson across all modules
        LessonEntity? targetLesson;
        CourseModuleEntity? targetModule;
        LessonEntity? prevLesson;
        LessonEntity? nextLesson;

        final allLessons = <LessonEntity>[];
        for (final m in course.modules) {
          for (final l in m.lessons) {
            allLessons.add(l);
            if (l.slug == widget.lessonSlug) {
              targetLesson = l;
              targetModule = m;
            }
          }
        }

        if (targetLesson != null) {
          final targetIndex = allLessons.indexOf(targetLesson);
          if (targetIndex > 0) {
            prevLesson = allLessons[targetIndex - 1];
          }
          if (targetIndex < allLessons.length - 1) {
            nextLesson = allLessons[targetIndex + 1];
          }
        }

        if (targetLesson == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Lesson Not Found')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.search_off_rounded,
                      size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text("Lesson '${widget.lessonSlug}' was not found."),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.pop(),
                    child: const Text('Back to Course'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(targetModule?.title ?? course.title),
            elevation: 0,
            actions: [
              if (course.isEnrolled && targetLesson.isCompleted)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Chip(
                    avatar: const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                      size: 18,
                    ),
                    label: const Text(
                      'Completed',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    backgroundColor: Colors.green.shade50,
                    side: BorderSide(color: Colors.green.shade300),
                  ),
                ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            _ContentTypeBadge(
                                contentType: targetLesson.contentType),
                            const SizedBox(width: 8),
                            Text(
                              '• ${targetLesson.estimatedMinutes} min read',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Text(
                          targetLesson.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Adjustment 2: If NOT enrolled, show Lesson Title + Enroll CTA
                        if (!course.isEnrolled) ...[
                          _EnrollToAccessCta(
                            courseTitle: course.title,
                            isEnrolling: _isEnrolling,
                            onEnroll: _enroll,
                          ),
                        ] else ...[
                          // Render content_json based on contentType
                          _LessonContentRenderer(
                            contentType: targetLesson.contentType,
                            contentJson: targetLesson.contentJson,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Bottom Action Bar (Complete & Prev/Next)
                if (course.isEnrolled)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (prevLesson != null)
                          IconButton.outlined(
                            tooltip: 'Previous Lesson',
                            onPressed: () {
                              context.pushReplacement(
                                '/courses/${widget.courseSlug}/lessons/${prevLesson!.slug}',
                              );
                            },
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                        if (prevLesson != null) const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _isCompleting
                                ? null
                                : () => _completeLesson(targetLesson!.id),
                            style: FilledButton.styleFrom(
                              backgroundColor: targetLesson.isCompleted
                                  ? Colors.green.shade700
                                  : Colors.indigo,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: _isCompleting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    targetLesson.isCompleted
                                        ? Icons.check_circle_outline
                                        : Icons.task_alt_rounded,
                                  ),
                            label: Text(
                              targetLesson.isCompleted
                                  ? 'LESSON COMPLETED'
                                  : 'MARK AS COMPLETED (+50 XP)',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),
                        if (nextLesson != null) const SizedBox(width: 10),
                        if (nextLesson != null)
                          IconButton.filledTonal(
                            tooltip: 'Next Lesson',
                            onPressed: () {
                              context.pushReplacement(
                                '/courses/${widget.courseSlug}/lessons/${nextLesson!.slug}',
                              );
                            },
                            icon: const Icon(Icons.arrow_forward_rounded),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ContentTypeBadge extends StatelessWidget {
  final String contentType;

  const _ContentTypeBadge({required this.contentType});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;

    switch (contentType.toUpperCase()) {
      case 'VISUALIZATION':
        bg = Colors.purple.shade50;
        fg = Colors.purple.shade800;
        icon = Icons.insights_rounded;
        break;
      case 'PROBLEM':
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade900;
        icon = Icons.code_rounded;
        break;
      case 'CONCEPT':
      default:
        bg = Colors.indigo.shade50;
        fg = Colors.indigo.shade800;
        icon = Icons.article_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            contentType.toUpperCase(),
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _EnrollToAccessCta extends StatelessWidget {
  final String courseTitle;
  final bool isEnrolling;
  final VoidCallback onEnroll;

  const _EnrollToAccessCta({
    required this.courseTitle,
    required this.isEnrolling,
    required this.onEnroll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_outline_rounded,
              size: 36,
              color: Colors.amber.shade900,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Enroll to Access This Lesson',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.amber.shade900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This lesson is part of the $courseTitle course. Enroll now for free to unlock all step-by-step visualizations, code exercises, and track your progress.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.amber.shade900,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isEnrolling ? null : onEnroll,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.indigo,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: isEnrolling
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'ENROLL IN COURSE TO ACCESS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonContentRenderer extends StatelessWidget {
  final String contentType;
  final Map<String, dynamic> contentJson;

  const _LessonContentRenderer({
    required this.contentType,
    required this.contentJson,
  });

  @override
  Widget build(BuildContext context) {
    switch (contentType.toUpperCase()) {
      case 'VISUALIZATION':
        return InteractiveVisualizerWorkspace(contentJson: contentJson);
      case 'PROBLEM':
        return _ProblemContent(contentJson: contentJson);
      case 'CONCEPT':
      default:
        return _ConceptContent(contentJson: contentJson);
    }
  }
}

//
// CONCEPT RENDERER
//
class _ConceptContent extends StatelessWidget {
  final Map<String, dynamic> contentJson;

  const _ConceptContent({required this.contentJson});

  @override
  Widget build(BuildContext context) {
    final overview = contentJson['overview']?.toString() ?? '';
    final rawKeyPoints = contentJson['key_points'] as List<dynamic>? ?? [];
    final codeExample = contentJson['code_example']?.toString();
    final complexity = contentJson['complexity'] is Map
        ? Map<String, dynamic>.from(contentJson['complexity'] as Map)
        : null;
    final analogy = contentJson['real_world_analogy']?.toString();
    final advantages = contentJson['advantages'] as List<dynamic>? ?? [];
    final disadvantages = contentJson['disadvantages'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (overview.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              overview,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        if (analogy != null && analogy.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline_rounded,
                    color: Colors.amber.shade900, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'REAL-WORLD ANALOGY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: Colors.amber.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        analogy,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.amber.shade900,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        if (rawKeyPoints.isNotEmpty) ...[
          const Text(
            'KEY CONCEPTS & MECHANICS',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 10),
          ...rawKeyPoints.map((point) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(
                      Icons.check_circle_outline_rounded,
                      size: 16,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      point.toString(),
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),
        ],

        if (codeExample != null && codeExample.isNotEmpty) ...[
          const Text(
            'CODE IMPLEMENTATION',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              codeExample,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: Color(0xFFCDD6F4),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        if (complexity != null) ...[
          const Text(
            'COMPLEXITY ANALYSIS',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: complexity.entries.map((entry) {
              return Chip(
                avatar: const Icon(Icons.speed_rounded, size: 16),
                label: Text('${entry.key}: ${entry.value}'),
                backgroundColor: Colors.grey.shade100,
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],

        if (advantages.isNotEmpty || disadvantages.isNotEmpty) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (advantages.isNotEmpty)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ADVANTAGES',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...advantages.map((a) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '• $a',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade900,
                                ),
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
              if (advantages.isNotEmpty && disadvantages.isNotEmpty)
                const SizedBox(width: 12),
              if (disadvantages.isNotEmpty)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DISADVANTAGES',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...disadvantages.map((d) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '• $d',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red.shade900,
                                ),
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

//
// PROBLEM RENDERER
//
class _ProblemContent extends StatelessWidget {
  final Map<String, dynamic> contentJson;

  const _ProblemContent({required this.contentJson});

  @override
  Widget build(BuildContext context) {
    final problemStatement =
        contentJson['problem_statement']?.toString() ?? '';
    final rawExamples = contentJson['examples'] as List<dynamic>? ?? [];
    final rawConstraints = contentJson['constraints'] as List<dynamic>? ?? [];
    final starterCode = contentJson['starter_code']?.toString();
    final hint = contentJson['hint']?.toString() ??
        (contentJson['hints'] is List && (contentJson['hints'] as List).isNotEmpty
            ? (contentJson['hints'] as List).first.toString()
            : null);
    final difficulty = contentJson['difficulty']?.toString() ?? 'MEDIUM';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Difficulty badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'DIFFICULTY: $difficulty',
            style: TextStyle(
              color: Colors.orange.shade900,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Statement
        if (problemStatement.isNotEmpty) ...[
          const Text(
            'PROBLEM STATEMENT',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            problemStatement,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Examples
        if (rawExamples.isNotEmpty) ...[
          const Text(
            'EXAMPLES & TESTCASES',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 10),
          ...rawExamples.map((ex) {
            final exMap = ex is Map ? ex : {};
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (exMap['input'] != null)
                    Text(
                      'Input: ${exMap['input']}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  if (exMap['output'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Output: ${exMap['output']}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  if (exMap['explanation'] != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Explanation: ${exMap['explanation']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
          const SizedBox(height: 20),
        ],

        // Constraints
        if (rawConstraints.isNotEmpty) ...[
          const Text(
            'CONSTRAINTS',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 8),
          ...rawConstraints.map((c) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '• ${c.toString()}',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: Colors.grey.shade800,
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
        ],

        // Starter Code
        if (starterCode != null && starterCode.isNotEmpty) ...[
          const Text(
            'STARTER CODE TEMPLATE',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              starterCode,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: Color(0xFFCDD6F4),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Hint Box
        if (hint != null && hint.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.help_outline_rounded,
                    color: Colors.blue.shade800, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HINT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hint,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade900,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
