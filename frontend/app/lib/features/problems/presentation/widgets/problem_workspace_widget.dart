import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../learning/presentation/widgets/ai_tutor_panel.dart';
import '../../domain/entities/problem.dart';
import '../providers/problem_provider.dart';

class ProblemWorkspaceWidget extends ConsumerStatefulWidget {
  final String lessonSlug;
  final String? lessonId;
  final VoidCallback? onLessonCompleted;

  const ProblemWorkspaceWidget({
    super.key,
    required this.lessonSlug,
    this.lessonId,
    this.onLessonCompleted,
  });

  @override
  ConsumerState<ProblemWorkspaceWidget> createState() =>
      _ProblemWorkspaceWidgetState();
}

class _ProblemWorkspaceWidgetState
    extends ConsumerState<ProblemWorkspaceWidget> {
  late final TextEditingController _codeController;
  int _activeViewTab = 0; // 0 = Workspace, 1 = Submissions
  int _lineCount = 1;
  bool _showAITutor = false;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController();
    _codeController.addListener(_onCodeChanged);
  }

  @override
  void dispose() {
    _codeController.removeListener(_onCodeChanged);
    _codeController.dispose();
    super.dispose();
  }

  void _onCodeChanged() {
    final lines = _codeController.text.split('\n').length;
    if (lines != _lineCount) {
      setState(() {
        _lineCount = lines > 0 ? lines : 1;
      });
    }
  }

  void _syncCodeWithState(ProblemState state) {
    final currentText = state.currentCode;
    if (_codeController.text != currentText) {
      final selection = _codeController.selection;
      _codeController.text = currentText;
      if (selection.end <= currentText.length) {
        _codeController.selection = selection;
      }
      _lineCount = currentText.split('\n').length;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(problemProvider(widget.lessonSlug));
    final notifier = ref.read(problemProvider(widget.lessonSlug).notifier);

    // Keep text controller in sync if language swapped or reset
    if (state.problemDetail.hasValue) {
      _syncCodeWithState(state);
    }

    return state.problemDetail.when(
      loading: () => Container(
        padding: const EdgeInsets.all(40),
        alignment: Alignment.center,
        child: const Column(
          children: [
            CircularProgressIndicator(color: Colors.indigo),
            SizedBox(height: 16),
            Text(
              'Loading problem workspace and compiler sandbox...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
      error: (err, _) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline_rounded, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Text(
                  'Failed to load coding challenge',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              err.toString().replaceFirst('Exception: ', ''),
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () => notifier.loadProblem(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (problem) {
        final mainProblemWorkspace = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Navigation & Language Selector Bar
            _buildTopBar(context, problem, state, notifier),
            const SizedBox(height: 16),

            if (_activeViewTab == 0) ...[
              // Problem Statement & Instructions Card
              _buildProblemStatementCard(context, problem),
              const SizedBox(height: 20),

              // Code Editor
              _buildCodeEditor(context, problem, state, notifier),
              const SizedBox(height: 12),

              // Run / Submit Action Controls
              _buildActionControls(context, state, notifier),
              const SizedBox(height: 16),

              // Output Console & Test Results
              _buildOutputConsole(context, state, notifier),
            ] else ...[
              // Past Submissions History
              _buildSubmissionsHistory(context, state, notifier, problem.id),
            ],
          ],
        );

        final targetLessonId = widget.lessonId ?? problem.lessonId;
        final hasFailedSub = state.submissionResult != null &&
            state.submissionResult!.verdict != 'AC';

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 920;

            return Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: mainProblemWorkspace),
                    if (_showAITutor && isWide) ...[
                      const SizedBox(width: 16),
                      AITutorPanel(
                        lessonId: targetLessonId,
                        submissionId: state.submissionResult?.submissionId,
                        getCode: () => _codeController.text,
                        getErrorInfo: () {
                          if (state.submissionResult != null) {
                            return 'Verdict: ${state.submissionResult!.verdict}, Passed ${state.submissionResult!.passedCount}/${state.submissionResult!.totalCount} tests. Details: ${state.submissionResult!.message}';
                          }
                          return null;
                        },
                        onClose: () => setState(() => _showAITutor = false),
                      ),
                    ],
                  ],
                ),

                // Slide-over for smaller screens
                if (_showAITutor && !isWide)
                  Positioned(
                    top: 0,
                    bottom: 0,
                    right: 0,
                    child: AITutorPanel(
                      lessonId: targetLessonId,
                      submissionId: state.submissionResult?.submissionId,
                      getCode: () => _codeController.text,
                      getErrorInfo: () {
                        if (state.submissionResult != null) {
                          return 'Verdict: ${state.submissionResult!.verdict}, Passed ${state.submissionResult!.passedCount}/${state.submissionResult!.totalCount} tests. Details: ${state.submissionResult!.message}';
                        }
                        return null;
                      },
                      onClose: () => setState(() => _showAITutor = false),
                    ),
                  ),

                // Floating AI Tutor Action Button
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton.extended(
                    heroTag: 'ai_tutor_problem_fab',
                    onPressed: () {
                      setState(() {
                        _showAITutor = !_showAITutor;
                      });
                    },
                    backgroundColor: hasFailedSub
                        ? Colors.orange.shade700
                        : const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    elevation: 6,
                    icon: Text(
                      hasFailedSub ? '🔍' : '🤖',
                      style: const TextStyle(fontSize: 18),
                    ),
                    label: Text(
                      _showAITutor
                          ? 'Hide AI Tutor'
                          : (hasFailedSub
                              ? 'Explain Error (AI)'
                              : 'Ask AI Tutor'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    ProblemDetail problem,
    ProblemState state,
    ProblemNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Left: View Mode Tabs
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTabButton(
                icon: Icons.code_rounded,
                label: 'Code Editor',
                isSelected: _activeViewTab == 0,
                onTap: () => setState(() => _activeViewTab = 0),
              ),
              const SizedBox(width: 8),
              _buildTabButton(
                icon: Icons.history_rounded,
                label: 'Submissions',
                isSelected: _activeViewTab == 1,
                onTap: () {
                  setState(() => _activeViewTab = 1);
                  notifier.loadSubmissions(problem.id);
                },
              ),
            ],
          ),

          // Right: Language Selector
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Language:',
                style: TextStyle(
                  color: Color(0xFFA6ADC8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              _buildLanguageChip('Python', 'python', state.selectedLanguage, () {
                notifier.selectLanguage('python');
              }),
              const SizedBox(width: 6),
              _buildLanguageChip('Java', 'java', state.selectedLanguage, () {
                notifier.selectLanguage('java');
              }),
              const SizedBox(width: 6),
              _buildLanguageChip('C++', 'cpp', state.selectedLanguage, () {
                notifier.selectLanguage('cpp');
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF313244) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF89B4FA) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? const Color(0xFF89B4FA) : const Color(0xFFA6ADC8),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : const Color(0xFFA6ADC8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageChip(
    String label,
    String langKey,
    String selectedLang,
    VoidCallback onTap,
  ) {
    final isSelected = selectedLang == langKey;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF89B4FA) : const Color(0xFF313244),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? const Color(0xFF11111B) : const Color(0xFFCDD6F4),
          ),
        ),
      ),
    );
  }

  Widget _buildProblemStatementCard(
    BuildContext context,
    ProblemDetail problem,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  problem.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  '${problem.timeLimitMs}ms • ${problem.memoryLimitMb}MB',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            problem.description,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF334155),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          // Public Test Examples
          const Text(
            'SAMPLE TEST CASES (STDIN / STDOUT)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 8),
          ...problem.publicTestCases.map((tc) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Case ${tc.orderIndex}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              color: Color(0xFF334155),
                            ),
                            children: [
                              const TextSpan(
                                text: 'Input: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: tc.stdinInput.replaceAll('\n', ' ↵ '),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              color: Color(0xFF10B981),
                            ),
                            children: [
                              const TextSpan(
                                text: 'Expected: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF047857),
                                ),
                              ),
                              TextSpan(
                                text: tc.expectedStdout.replaceAll('\n', ' ↵ '),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCodeEditor(
    BuildContext context,
    ProblemDetail problem,
    ProblemState state,
    ProblemNotifier notifier,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF181825),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Editor Header with Language Title and Reset/Copy buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF11111B),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF38BA8),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9E2AF),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFFA6E3A1),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'solution.${_getFileExtension(state.selectedLanguage)}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Color(0xFFA6ADC8),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  tooltip: 'Reset to starter code',
                  color: const Color(0xFFA6ADC8),
                  onPressed: () {
                    notifier.resetCurrentCode();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  tooltip: 'Copy code',
                  color: const Color(0xFFA6ADC8),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: state.currentCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Code copied to clipboard'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Code Text Area with Line Numbers Gutter
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Line numbers gutter
                Container(
                  width: 44,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  color: const Color(0xFF11111B).withValues(alpha: 0.6),
                  child: Column(
                    children: List.generate(
                      _lineCount,
                      (index) => Text(
                        '${index + 1}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          color: Color(0xFF585B70),
                          height: 1.45,
                        ),
                      ),
                    ),
                  ),
                ),

                // Editor TextField
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: TextField(
                      controller: _codeController,
                      onChanged: (val) => notifier.updateCode(val),
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      autocorrect: false,
                      enableSuggestions: false,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: Color(0xFFCDD6F4),
                        height: 1.45,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getFileExtension(String lang) {
    switch (lang.toLowerCase()) {
      case 'java':
        return 'java';
      case 'cpp':
      case 'c++':
        return 'cpp';
      case 'python':
      default:
        return 'py';
    }
  }

  Widget _buildActionControls(
    BuildContext context,
    ProblemState state,
    ProblemNotifier notifier,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Run Trial Button (Public Cases Only)
        OutlinedButton.icon(
          onPressed: (state.isRunning || state.isSubmitting)
              ? null
              : () => notifier.runTrial(),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF1E293B),
            side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: state.isRunning
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.indigo,
                  ),
                )
              : const Icon(Icons.play_arrow_rounded, color: Colors.indigo, size: 20),
          label: Text(
            state.isRunning ? 'Running Trial...' : 'Run Code (Trial)',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),

        // Submit Solution Button (All Cases + DB Save + Auto Lesson Complete)
        FilledButton.icon(
          onPressed: (state.isRunning || state.isSubmitting)
              ? null
              : () {
                  notifier.submitSolution(
                    onAccepted: () {
                      widget.onLessonCompleted?.call();
                    },
                  );
                },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: state.isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.cloud_upload_rounded, size: 18),
          label: Text(
            state.isSubmitting ? 'Evaluating Solution...' : 'Submit Solution',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildOutputConsole(
    BuildContext context,
    ProblemState state,
    ProblemNotifier notifier,
  ) {
    if (state.activeErrorMessage != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Execution Error',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    state.activeErrorMessage!,
                    style: TextStyle(fontSize: 13, color: Colors.red.shade800),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Show Trial Result
    if (state.trialResult != null) {
      return _buildTrialResultView(context, state.trialResult!, state, notifier);
    }

    // Show Submission Result
    if (state.submissionResult != null) {
      return _buildSubmissionResultView(context, state.submissionResult!);
    }

    return const SizedBox.shrink();
  }

  Widget _buildTrialResultView(
    BuildContext context,
    TrialResult trial,
    ProblemState state,
    ProblemNotifier notifier,
  ) {
    final isAccepted = trial.isAccepted;
    final color = _getVerdictColor(trial.verdict);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Verdict Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAccepted ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: color,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getVerdictTitle(trial.verdict),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Passed: ${trial.passedCount}/${trial.totalCount} Test Cases',
                style: const TextStyle(
                  color: Color(0xFFCDD6F4),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '⏱ ${trial.executionTimeMs}ms • 💾 ${(trial.memoryUsedKb / 1024).toStringAsFixed(1)}MB',
                style: const TextStyle(
                  color: Color(0xFFA6ADC8),
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // If Compilation or Sandbox Error
          if (trial.compileOutput != null && trial.compileOutput!.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF313244),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade400),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'COMPILER / EXECUTION OUTPUT:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF38BA8),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    trial.compileOutput!,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Color(0xFFF38BA8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Test Cases Tabs Selector
          if (trial.testResults.isNotEmpty) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(trial.testResults.length, (i) {
                  final tc = trial.testResults[i];
                  final isSelected = state.selectedTestTabIndex == i;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => notifier.selectTestTab(i),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF45475A)
                              : const Color(0xFF313244),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? (tc.passed ? const Color(0xFFA6E3A1) : const Color(0xFFF38BA8))
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              tc.passed
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              size: 14,
                              color: tc.passed
                                  ? const Color(0xFFA6E3A1)
                                  : const Color(0xFFF38BA8),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Test ${tc.testIndex}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFFA6ADC8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 14),

            // Active Test Inspector
            if (state.selectedTestTabIndex < trial.testResults.length)
              _buildTestResultInspector(
                trial.testResults[state.selectedTestTabIndex],
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildTestResultInspector(TestCaseExecutionResult tc) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF11111B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF313244)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldBox('STDIN INPUT', tc.stdinInput ?? '(empty)', const Color(0xFF89B4FA)),
          const SizedBox(height: 10),
          _buildFieldBox('EXPECTED STDOUT', tc.expectedStdout ?? '(empty)', const Color(0xFFA6E3A1)),
          const SizedBox(height: 10),
          _buildFieldBox(
            'ACTUAL STDOUT',
            tc.actualOutput ?? '(no output)',
            tc.passed ? const Color(0xFFA6E3A1) : const Color(0xFFF38BA8),
          ),
          if (tc.errorMessage != null && tc.errorMessage!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildFieldBox('ERROR MESSAGE', tc.errorMessage!, const Color(0xFFF38BA8)),
          ],
        ],
      ),
    );
  }

  Widget _buildFieldBox(String label, String value, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: accentColor,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF181825),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: Color(0xFFCDD6F4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmissionResultView(
    BuildContext context,
    SubmissionResult sub,
  ) {
    final isAccepted = sub.isAccepted;
    final color = _getVerdictColor(sub.verdict);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isAccepted ? const Color(0xFF064E3B) : const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAccepted ? const Color(0xFF10B981) : color,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isAccepted ? Colors.green : Colors.black).withValues(alpha: 0.2),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAccepted ? Icons.celebration_rounded : Icons.highlight_off_rounded,
                color: isAccepted ? Colors.white : color,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAccepted
                          ? 'ACCEPTED — PROBLEM SOLVED!'
                          : 'VERDICT: ${_getVerdictTitle(sub.verdict).toUpperCase()}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isAccepted ? Colors.white : color,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sub.message,
                      style: TextStyle(
                        fontSize: 13,
                        color: isAccepted ? const Color(0xFFA7F3D0) : const Color(0xFFCDD6F4),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${sub.passedCount} / ${sub.totalCount} Passed',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),

          if (isAccepted && sub.isLessonCompleted) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.workspace_premium_rounded, color: Colors.amberAccent, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Lesson marked complete & +50 XP awarded to your profile!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmissionsHistory(
    BuildContext context,
    ProblemState state,
    ProblemNotifier notifier,
    String problemId,
  ) {
    return state.submissions.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(30),
        child: Center(child: CircularProgressIndicator(color: Colors.indigo)),
      ),
      error: (err, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('Failed to load past submissions: $err'),
      ),
      data: (list) {
        if (list.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Column(
              children: [
                Icon(Icons.code_off_rounded, size: 40, color: Colors.grey),
                SizedBox(height: 12),
                Text(
                  'No Submissions Yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF475569),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Submit your code solution to record evaluation attempts and earn XP.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            separatorBuilder: (context, index) => Divider(color: Colors.grey.shade200, height: 1),
            itemBuilder: (context, index) {
              final sub = list[index];
              final isAC = sub.isAccepted;
              final verdictColor = _getVerdictColor(sub.verdict);

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: verdictColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isAC ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: verdictColor,
                  ),
                ),
                title: Row(
                  children: [
                    Text(
                      _getVerdictTitle(sub.verdict),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: verdictColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        sub.language.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  'Passed ${sub.passedCount}/${sub.totalCount} cases • ${_formatDate(sub.createdAt)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                trailing: (sub.executionTimeMs != null)
                    ? Text(
                        '${sub.executionTimeMs}ms',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      )
                    : null,
              );
            },
          ),
        );
      },
    );
  }

  Color _getVerdictColor(String verdict) {
    switch (verdict.toUpperCase()) {
      case 'AC':
        return const Color(0xFFA6E3A1);
      case 'WA':
        return const Color(0xFFF38BA8);
      case 'TLE':
        return const Color(0xFFF9E2AF);
      case 'CE':
      case 'RE':
      case 'SE':
      default:
        return const Color(0xFFF38BA8);
    }
  }

  String _getVerdictTitle(String verdict) {
    switch (verdict.toUpperCase()) {
      case 'AC':
        return 'Accepted';
      case 'WA':
        return 'Wrong Answer';
      case 'TLE':
        return 'Time Limit Exceeded';
      case 'CE':
        return 'Compilation / Engine Error';
      case 'RE':
        return 'Runtime Error';
      case 'SE':
      default:
        return 'System Error';
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
