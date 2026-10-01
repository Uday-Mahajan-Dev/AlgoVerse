import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/course_entity.dart';
import '../providers/course_provider.dart';

class CourseCatalogPage extends ConsumerWidget {
  const CourseCatalogPage({super.key});

  static const Color emeraldColor = Color(0xFF059669);

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toUpperCase()) {
      case 'BEGINNER':
        return emeraldColor;
      case 'INTERMEDIATE':
        return Colors.orange.shade700;
      case 'ADVANCED':
        return Colors.purple.shade700;
      default:
        return Colors.blueGrey;
    }
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(filteredCoursesListProvider);
    final currentFilter = ref.watch(courseCategoryFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Courses & Pathways',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(coursesListProvider);
            ref.invalidate(allStudentProgressProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header & Introduction
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.indigo.shade900,
                              Colors.indigo.shade600,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white24,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.auto_stories_rounded,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'DSA Mastery Hierarchy',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Course → Module → Lesson',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                          letterSpacing: 1.1,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Master core computational logic with step-by-step visualizations, interactive concept teardowns, and targeted practice problems.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Category Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterChip(
                              label: 'All Pathways',
                              isSelected: currentFilter == 'ALL',
                              onSelected: () => ref
                                  .read(courseCategoryFilterProvider.notifier)
                                  .setFilter('ALL'),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Data Structures',
                              isSelected: currentFilter == 'DATA STRUCTURES',
                              onSelected: () => ref
                                  .read(courseCategoryFilterProvider.notifier)
                                  .setFilter('DATA STRUCTURES'),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Algorithms',
                              isSelected: currentFilter == 'ALGORITHMS',
                              onSelected: () => ref
                                  .read(courseCategoryFilterProvider.notifier)
                                  .setFilter('ALGORITHMS'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Courses List / Grid
              coursesAsync.when(
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        const Text('Unable to load courses.'),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => ref.invalidate(coursesListProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (courses) {
                  if (courses.isEmpty) {
                    return const SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.menu_book_outlined,
                                size: 48, color: Colors.grey),
                            SizedBox(height: 12),
                            Text('No courses found in this category.'),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding:
                        const EdgeInsets.only(left: 20, right: 20, bottom: 30),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final course = courses[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _CourseCard(
                              course: course,
                              difficultyColor:
                                  _getDifficultyColor(course.difficulty),
                            ),
                          );
                        },
                        childCount: courses.length,
                      ),
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
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: Colors.indigo,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Colors.indigo : Colors.grey.shade300,
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final CourseSummaryEntity course;
  final Color difficultyColor;

  const _CourseCard({
    required this.course,
    required this.difficultyColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          context.push('/courses/${course.slug}');
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badges row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: difficultyColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      course.difficulty.toUpperCase(),
                      style: TextStyle(
                        color: difficultyColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
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
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      course.topicCategory,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (course.isEnrolled)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle,
                              size: 14, color: Colors.green.shade700),
                          const SizedBox(width: 4),
                          Text(
                            'Enrolled',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // Title
              Text(
                course.title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                course.description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 18),

              const Divider(height: 1),
              const SizedBox(height: 14),

              // Stats row
              Row(
                children: [
                  _StatBadge(
                    icon: Icons.folder_outlined,
                    label: '${course.moduleCount} modules',
                  ),
                  const SizedBox(width: 16),
                  _StatBadge(
                    icon: Icons.play_lesson_outlined,
                    label: '${course.totalLessons} lessons',
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: Colors.indigo,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

