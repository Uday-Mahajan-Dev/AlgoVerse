import 'package:flutter/material.dart';

import '../../domain/entities/teacher_dashboard_entity.dart';

class WeakConceptsCard extends StatelessWidget {
  final List<WeakConcept> concepts;

  const WeakConceptsCard({
    super.key,
    required this.concepts,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weak Concepts',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Concepts that may require additional revision',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          ...concepts.map(
            (concept) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor:
                    theme.colorScheme.error.withValues(alpha: 0.10),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: theme.colorScheme.error,
                  size: 20,
                ),
              ),
              title: Text(
                concept.concept,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                '${concept.affectedStudents} students need revision',
              ),
              trailing: Text(
                '${(concept.mastery * 100).round()}%',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}