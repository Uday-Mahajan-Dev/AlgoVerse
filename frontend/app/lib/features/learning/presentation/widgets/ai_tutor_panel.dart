import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/ai_tutor_entity.dart';
import '../providers/ai_tutor_provider.dart';

class AITutorPanel extends ConsumerStatefulWidget {
  final String lessonId;
  final String? submissionId;
  final Map<String, dynamic>? Function()? getVisualizationState;
  final String? Function()? getCode;
  final String? Function()? getErrorInfo;
  final VoidCallback? onClose;

  const AITutorPanel({
    super.key,
    required this.lessonId,
    this.submissionId,
    this.getVisualizationState,
    this.getCode,
    this.getErrorInfo,
    this.onClose,
  });

  @override
  ConsumerState<AITutorPanel> createState() => _AITutorPanelState();
}

class _AITutorPanelState extends ConsumerState<AITutorPanel> {
  int _selectedHintLevel = 1;

  void _requestHint(int level) {
    setState(() => _selectedHintLevel = level);
    final vizState = widget.getVisualizationState?.call();
    final code = widget.getCode?.call();
    final errorInfo = widget.getErrorInfo?.call();

    ref.read(aiTutorNotifierProvider.notifier).requestHint(
          lessonId: widget.lessonId,
          hintLevel: level,
          visualizationState: vizState,
          code: code,
          errorInfo: errorInfo,
        );
  }

  void _explainError() {
    if (widget.submissionId != null && widget.submissionId!.isNotEmpty) {
      ref.read(aiTutorNotifierProvider.notifier).explainError(
            submissionId: widget.submissionId!,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final aiStatusAsync = ref.watch(aiStatusProvider);
    final aiState = ref.watch(aiTutorNotifierProvider);
    final recommendationsAsync = ref.watch(aiRecommendationsProvider);

    return Container(
      width: 420,
      constraints: const BoxConstraints(maxWidth: 460),
      decoration: BoxDecoration(
        color: const Color(0xFF141926),
        border: const Border(
          left: BorderSide(color: Color(0xFF2D3748), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          _buildHeader(context),
          const Divider(color: Color(0xFF2D3748), height: 1),

          // Content scrollable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AI Status notice if not configured
                  aiStatusAsync.when(
                    data: (status) {
                      if (!status.configured) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Colors.amber,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  status.message.isNotEmpty
                                      ? status.message
                                      : 'AI tutor is not configured. Ask your teacher for help!',
                                  style: const TextStyle(
                                    color: Colors.amberAccent,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),

                  // Hint Level Selection
                  const Text(
                    '💡 Need a hint?',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Select how much guidance you need right now:',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      _buildHintChip(
                        level: 1,
                        label: 'L1: Nudge',
                        tooltip: 'Guiding question grounded in visualization',
                        isLoading: aiState.isLoading,
                      ),
                      const SizedBox(width: 8),
                      _buildHintChip(
                        level: 2,
                        label: 'L2: Guide',
                        tooltip: 'Point out specific line or logic direction',
                        isLoading: aiState.isLoading,
                      ),
                      const SizedBox(width: 8),
                      _buildHintChip(
                        level: 3,
                        label: 'L3: Approach',
                        tooltip: 'Reveal full approach concept without code',
                        isLoading: aiState.isLoading,
                      ),
                    ],
                  ),

                  // Explain Error Button (if submission failed)
                  if (widget.submissionId != null &&
                      widget.submissionId!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: aiState.isLoading ? null : _explainError,
                      icon: const Icon(Icons.bug_report_outlined, size: 18),
                      label: const Text('🔍 Explain My Submission Error'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orangeAccent,
                        side: const BorderSide(color: Colors.orangeAccent),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Loading State
                  if (aiState.isLoading) ...[
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: const [
                            CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 3,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'AlgoVerse AI Tutor is thinking...',
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Error Message
                  if (aiState.errorMessage != null) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.redAccent, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              aiState.errorMessage!,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // AI Response (Hint or Error Explanation)
                  if (aiState.currentHint != null)
                    _buildHintResponseCard(aiState.currentHint!, aiState.hintsRemaining),

                  if (aiState.currentExplanation != null)
                    _buildExplanationCard(aiState.currentExplanation!),

                  const SizedBox(height: 24),

                  // Recommended For You Section
                  const Divider(color: Color(0xFF2D3748)),
                  const SizedBox(height: 12),
                  const Text(
                    '📚 Recommended For You',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),

                  recommendationsAsync.when(
                    data: (recs) {
                      if (recs.isEmpty) {
                        return const Text(
                          'No recommendations at this time.',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        );
                      }
                      return Column(
                        children: recs.map(_buildRecommendationTile).toList(),
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    error: (_, _) => const Text(
                      'Unable to load recommendations.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Text(
                '🤖',
                style: TextStyle(fontSize: 20),
              ),
              SizedBox(width: 8),
              Text(
                'AlgoVerse AI Tutor',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey, size: 20),
            tooltip: 'Close panel',
            onPressed: widget.onClose ?? () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }

  Widget _buildHintChip({
    required int level,
    required String label,
    required String tooltip,
    required bool isLoading,
  }) {
    final isSelected = _selectedHintLevel == level;
    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: ElevatedButton(
          onPressed: isLoading ? null : () => _requestHint(level),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected
                ? AppColors.primary
                : const Color(0xFF1E293B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: isSelected
                    ? AppColors.primary
                    : const Color(0xFF334155),
              ),
            ),
            elevation: 0,
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildHintResponseCard(AIHintEntity hint, int hintsRemaining) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Level ${hint.hintLevel} Hint',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              Text(
                'Hints remaining: $hintsRemaining/10',
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MarkdownBody(
            data: hint.hintText,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(
                color: Color(0xFFE2E8F0),
                fontSize: 13,
                height: 1.45,
              ),
              code: const TextStyle(
                backgroundColor: Color(0xFF1E293B),
                color: Colors.amberAccent,
                fontFamily: 'monospace',
                fontSize: 12,
              ),
              codeblockDecoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationCard(AIErrorExplanationEntity explanation) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Error Analysis',
                  style: TextStyle(
                    color: Colors.orangeAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          if (explanation.failedTestSummary != null) ...[
            const SizedBox(height: 8),
            Text(
              explanation.failedTestSummary!,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 12),
          MarkdownBody(
            data: explanation.explanation,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(
                color: Color(0xFFE2E8F0),
                fontSize: 13,
                height: 1.45,
              ),
              code: const TextStyle(
                backgroundColor: Color(0xFF1E293B),
                color: Colors.amberAccent,
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationTile(AIRecommendationEntity rec) {
    Color priorityColor;
    switch (rec.priority.toLowerCase()) {
      case 'high':
        priorityColor = Colors.redAccent;
        break;
      case 'medium':
        priorityColor = Colors.amberAccent;
        break;
      default:
        priorityColor = Colors.blueAccent;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rec.lessonTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  rec.reason,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: priorityColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              rec.priority.toUpperCase(),
              style: TextStyle(
                color: priorityColor,
                fontWeight: FontWeight.bold,
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
