import 'dart:async';
import 'package:flutter/material.dart';

import '../../domain/entities/execution_trace.dart';
import '../../engine/array_algorithm_executor.dart';
import 'ai_tutor_panel.dart';
import 'array_visualizer_widget.dart';
import 'code_viewer_widget.dart';
import 'input_customizer.dart';
import 'variable_panel_widget.dart';
import 'visualizer_controls.dart';

class InteractiveVisualizerWorkspace extends StatefulWidget {
  final Map<String, dynamic> contentJson;
  final String? lessonId;

  const InteractiveVisualizerWorkspace({
    super.key,
    required this.contentJson,
    this.lessonId,
  });

  @override
  State<InteractiveVisualizerWorkspace> createState() =>
      _InteractiveVisualizerWorkspaceState();
}

class _InteractiveVisualizerWorkspaceState
    extends State<InteractiveVisualizerWorkspace> {
  late String _selectedAlgorithm;
  late Map<String, dynamic> _currentInput;
  late ExecutionTrace _trace;

  int _currentStepIndex = 0;
  bool _isPlaying = false;
  double _playbackSpeed = 1.0;
  Timer? _playbackTimer;
  bool _showAITutor = false;

  @override
  void initState() {
    super.initState();
    _initAlgorithmState();
  }

  @override
  void didUpdateWidget(covariant InteractiveVisualizerWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contentJson != widget.contentJson) {
      _stopPlayback();
      _initAlgorithmState();
    }
  }

  void _initAlgorithmState() {
    // 1. Determine active algorithm (handling single vs dual algorithms)
    if (widget.contentJson['algorithm_names'] is List) {
      final names = List<String>.from(widget.contentJson['algorithm_names'] as List);
      _selectedAlgorithm = names.isNotEmpty ? names.first : 'findMaximum';
    } else {
      _selectedAlgorithm =
          widget.contentJson['algorithm_name']?.toString() ?? 'arrayTraversal';
    }

    // 2. Default input
    final rawDefault = widget.contentJson['default_input'];
    if (rawDefault is Map) {
      _currentInput = Map<String, dynamic>.from(rawDefault);
    } else {
      _currentInput = {'array': [5, 3, 8, 1, 9]};
    }

    _generateTrace();
  }

  void _generateTrace() {
    _trace = ArrayAlgorithmExecutor.execute(
      _selectedAlgorithm,
      _currentInput,
    );
    _currentStepIndex = 0;
  }

  void _switchAlgorithm(String algoName) {
    if (_selectedAlgorithm == algoName) return;
    _stopPlayback();
    setState(() {
      _selectedAlgorithm = algoName;
      _generateTrace();
    });
  }

  void _handleCustomInput(Map<String, dynamic> newInput) {
    _stopPlayback();
    setState(() {
      _currentInput = newInput;
      _generateTrace();
    });
  }

  // ===========================================================================
  // PLAYBACK TIMING LOOP
  // ===========================================================================

  void _startPlayback() {
    _playbackTimer?.cancel();
    final intervalMs = (_getSpeedDurationMs() / _playbackSpeed).round();

    _playbackTimer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      if (_currentStepIndex < _trace.totalSteps - 1) {
        setState(() {
          _currentStepIndex++;
        });
      } else {
        _stopPlayback();
      }
    });

    setState(() {
      _isPlaying = true;
    });
  }

  void _stopPlayback() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    if (_isPlaying) {
      setState(() {
        _isPlaying = false;
      });
    }
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _stopPlayback();
    } else {
      if (_currentStepIndex >= _trace.totalSteps - 1) {
        _currentStepIndex = 0;
      }
      _startPlayback();
    }
  }

  int _getSpeedDurationMs() {
    return 750; // base 1.0x interval
  }

  void _changeSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
    });
    if (_isPlaying) {
      _startPlayback();
    }
  }

  void _nextStep() {
    _stopPlayback();
    if (_currentStepIndex < _trace.totalSteps - 1) {
      setState(() {
        _currentStepIndex++;
      });
    }
  }

  void _prevStep() {
    _stopPlayback();
    if (_currentStepIndex > 0) {
      setState(() {
        _currentStepIndex--;
      });
    }
  }

  void _reset() {
    _stopPlayback();
    setState(() {
      _currentStepIndex = 0;
    });
  }

  void _seek(int step) {
    _stopPlayback();
    setState(() {
      _currentStepIndex = step.clamp(0, _trace.totalSteps - 1);
    });
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  String _getActiveCodeSnippet() {
    if (widget.contentJson['code_snippets'] is Map) {
      final snippets = Map<String, dynamic>.from(
        widget.contentJson['code_snippets'] as Map,
      );
      return snippets[_selectedAlgorithm]?.toString() ?? '';
    }
    return widget.contentJson['code_snippet']?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = _trace.getStep(_currentStepIndex);
    final codeSnippet = _getActiveCodeSnippet();
    final complexity = widget.contentJson['complexity'] is Map
        ? Map<String, dynamic>.from(widget.contentJson['complexity'] as Map)
        : null;
    final leetcodeRef = widget.contentJson['leetcode_ref']?.toString();
    final description = widget.contentJson['description']?.toString() ?? '';

    final hasDualAlgos = widget.contentJson['algorithm_names'] is List;
    final dualAlgoList = hasDualAlgos
        ? List<String>.from(widget.contentJson['algorithm_names'] as List)
        : <String>[];

    final mainWorkspace = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Meta header row: Complexity & LeetCode Ref
        Row(
          children: [
            if (complexity != null) ...[
              if (complexity['time'] != null)
                Chip(
                  avatar: const Icon(Icons.timer_outlined, size: 14),
                  label: Text('Time: ${complexity['time']}'),
                  labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  backgroundColor: Colors.purple.shade50,
                  side: BorderSide(color: Colors.purple.shade200),
                ),
              const SizedBox(width: 8),
              if (complexity['space'] != null)
                Chip(
                  avatar: const Icon(Icons.memory_outlined, size: 14),
                  label: Text('Space: ${complexity['space']}'),
                  labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  backgroundColor: Colors.purple.shade50,
                  side: BorderSide(color: Colors.purple.shade200),
                ),
            ],
            const Spacer(),
            if (leetcodeRef != null && leetcodeRef.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'LeetCode $leetcodeRef',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),

        // Dual Algorithm Selector (For Lesson 8: Find Maximum & Minimum)
        if (hasDualAlgos && dualAlgoList.length > 1) ...[
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: dualAlgoList.map((algo) {
                final isSelected = _selectedAlgorithm == algo;
                final displayName = algo == 'findMaximum'
                    ? 'Find Maximum'
                    : (algo == 'findMinimum' ? 'Find Minimum' : algo);

                return Expanded(
                  child: GestureDetector(
                    onTap: () => _switchAlgorithm(algo),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.indigo : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.indigo.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : [],
                      ),
                      child: Center(
                        child: Text(
                          displayName,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Overview explanation
        if (description.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              description,
              style: const TextStyle(fontSize: 13.5, height: 1.5),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Visualizer Canvas
        ArrayVisualizerWidget(
          arrayState: currentStep?.arrayState ?? [],
          highlights: currentStep?.highlights ?? [],
          pointers: currentStep?.pointers ?? {},
          operation: currentStep?.operation ?? 'INIT',
        ),
        const SizedBox(height: 16),

        // Variable State Inspector
        VariablePanelWidget(
          variables: currentStep?.variables ?? {},
          result: currentStep?.result,
        ),
        const SizedBox(height: 16),

        // Controls (Play/Pause, Slider, Speeds)
        VisualizerControls(
          currentStep: _currentStepIndex,
          totalSteps: _trace.totalSteps,
          isPlaying: _isPlaying,
          playbackSpeed: _playbackSpeed,
          onPlayPause: _togglePlayPause,
          onNext: _nextStep,
          onPrev: _prevStep,
          onReset: _reset,
          onSeek: _seek,
          onSpeedChange: _changeSpeed,
        ),
        const SizedBox(height: 20),

        // Code Viewer with Live Line Highlight
        if (codeSnippet.isNotEmpty) ...[
          CodeViewerWidget(
            codeSnippet: codeSnippet,
            activeSourceLine: currentStep?.sourceLine ?? 1,
            explanation: currentStep?.explanation ?? '',
            operation: currentStep?.operation ?? 'INIT',
          ),
          const SizedBox(height: 20),
        ],

        // Custom Input Editor
        InputCustomizer(
          algorithmName: _selectedAlgorithm,
          defaultInput: (widget.contentJson['default_input'] is Map)
              ? Map<String, dynamic>.from(
                  widget.contentJson['default_input'] as Map,
                )
              : {'array': [5, 3, 8, 1, 9]},
          onApply: _handleCustomInput,
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 920;

        return Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: mainWorkspace),
                if (_showAITutor && isWide) ...[
                  const SizedBox(width: 16),
                  AITutorPanel(
                    lessonId: widget.lessonId ?? '',
                    getVisualizationState: () => currentStep?.toJson(
                      algorithmName: _selectedAlgorithm,
                    ),
                    onClose: () => setState(() => _showAITutor = false),
                  ),
                ],
              ],
            ),

            // Slide-over on smaller screens
            if (_showAITutor && !isWide)
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                child: AITutorPanel(
                  lessonId: widget.lessonId ?? '',
                  getVisualizationState: () => currentStep?.toJson(
                    algorithmName: _selectedAlgorithm,
                  ),
                  onClose: () => setState(() => _showAITutor = false),
                ),
              ),

            // Floating AI Tutor Trigger Button
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.extended(
                heroTag: 'ai_tutor_viz_fab',
                onPressed: () {
                  setState(() {
                    _showAITutor = !_showAITutor;
                  });
                },
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                elevation: 6,
                icon: const Text('🤖', style: TextStyle(fontSize: 18)),
                label: Text(
                  _showAITutor ? 'Hide AI Tutor' : 'Ask AI Tutor',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
