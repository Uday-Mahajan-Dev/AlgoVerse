import 'package:flutter/material.dart';

import '../../domain/entities/teacher_dashboard_entity.dart';

class ConceptPerformanceCard extends StatelessWidget {
  final List<ConceptPerformance> concepts;

  const ConceptPerformanceCard({super.key, required this.concepts});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Concept Performance',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Average mastery across DSA concepts',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          if (concepts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No concept performance data available yet.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            )
          else
            ...concepts.map((concept) => _ConceptRow(concept: concept)),
        ],
      ),
    );
  }
}

class _ConceptRow extends StatelessWidget {
  final ConceptPerformance concept;

  const _ConceptRow({required this.concept});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = (concept.mastery * 100).round();

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  concept.concept,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$percentage%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: concept.mastery,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
