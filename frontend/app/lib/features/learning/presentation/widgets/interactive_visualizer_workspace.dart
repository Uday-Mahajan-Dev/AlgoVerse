import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String _selectedLanguage = 'python';

  int _currentStepIndex = 0;
  bool _isPlaying = false;
  double _playbackSpeed = 1.0;
  Timer? _playbackTimer;
  bool _showAITutor = false;

  @override
  void initState() {
    super.initState();
    _initAlgorithmState();
    _loadPreferredLanguage();
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

  Map<String, String> _getAvailableSnippets() {
    final rawSnippets = widget.contentJson['code_snippets'];
    if (rawSnippets is Map && rawSnippets.isNotEmpty) {
      final map = <String, String>{};
      rawSnippets.forEach((k, v) {
        if (v != null && v.toString().trim().isNotEmpty) {
          map[k.toString().toLowerCase()] = v.toString();
        }
      });
      if (map.containsKey(_selectedAlgorithm)) {
        return {'python': map[_selectedAlgorithm]!};
      }
      return map;
    }
    final single = widget.contentJson['code_snippet']?.toString();
    if (single != null && single.trim().isNotEmpty) {
      return {'python': single};
    }
    return {};
  }

  Future<void> _loadPreferredLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLang = prefs.getString('visualizer_preferred_language')?.toLowerCase();
      final snippets = _getAvailableSnippets();
      if (savedLang != null && snippets.containsKey(savedLang)) {
        if (mounted) setState(() => _selectedLanguage = savedLang);
      } else {
        final defLang = widget.contentJson['default_language']?.toString().toLowerCase() ?? 'python';
        if (snippets.containsKey(defLang)) {
          if (mounted) setState(() => _selectedLanguage = defLang);
        } else if (snippets.isNotEmpty) {
          if (mounted) setState(() => _selectedLanguage = snippets.keys.first);
        }
      }
    } catch (_) {}
  }

  Future<void> _switchLanguage(String lang) async {
    if (_selectedLanguage == lang) return;
    setState(() {
      _selectedLanguage = lang;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('visualizer_preferred_language', lang);
    } catch (_) {}
  }

  String _formatLanguageLabel(String lang) {
    switch (lang.toLowerCase()) {
      case 'python':
      case 'py':
        return 'Python';
      case 'java':
        return 'Java';
      case 'cpp':
      case 'c++':
        return 'C++';
      default:
        return lang.isEmpty ? '' : lang[0].toUpperCase() + lang.substring(1);
    }
  }

  int _getActiveSourceLine(int? baseLine) {
    if (baseLine == null || baseLine <= 0) return 0;
    final lineMaps = widget.contentJson['line_maps'];
    if (lineMaps is Map) {
      final langMap = lineMaps[_selectedLanguage];
      if (langMap is Map) {
        final mapped = langMap[baseLine.toString()] ?? langMap[baseLine];
        if (mapped is int) return mapped;
        return int.tryParse(mapped?.toString() ?? '') ?? 0;
      } else {
        // Fallback: if line_maps[selected] missing → disable line highlight for that language
        return 0;
      }
    }
    return _selectedLanguage == 'python' ? baseLine : 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = _trace.getStep(_currentStepIndex);
    final availableSnippets = _getAvailableSnippets();
    final showLanguageToggle = availableSnippets.length > 1;
    final activeSnippet = availableSnippets[_selectedLanguage] ??
        (availableSnippets.isNotEmpty ? availableSnippets.values.first : '');
    final activeLine = _getActiveSourceLine(currentStep?.sourceLine);
    final complexity = widget.contentJson['complexity'] is Map
        ? Map<String, dynamic>.from(widget.contentJson['complexity'] as Map)
        : null;
    final leetcodeRef = widget.contentJson['leetcode_ref']?.toString();
    final description = widget.contentJson['description']?.toString() ?? '';

    final hasDualAlgos = widget.contentJson['algorithm_names'] is List;
    final dualAlgoList = hasDualAlgos
        ? List<String>.from(widget.contentJson['algorithm_names'] as List)
        : <String>[];

    final headerSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Meta header row: Complexity & LeetCode Ref
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
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
              if (complexity['space'] != null)
                Chip(
                  avatar: const Icon(Icons.memory_outlined, size: 14),
                  label: Text('Space: ${complexity['space']}'),
                  labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  backgroundColor: Colors.purple.shade50,
                  side: BorderSide(color: Colors.purple.shade200),
                ),
            ],
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
      ],
    );

        // Visualizer Canvas + Controls + Variable State
        final visualizerPane = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ArrayVisualizerWidget(
              arrayState: currentStep?.arrayState ?? [],
              highlights: currentStep?.highlights ?? [],
              pointers: currentStep?.pointers ?? {},
              operation: currentStep?.operation ?? 'INIT',
            ),
            const SizedBox(height: 16),
            VariablePanelWidget(
              variables: currentStep?.variables ?? {},
              result: currentStep?.result,
            ),
            const SizedBox(height: 16),
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
          ],
        );

        // Code Viewer + Custom Input
        final codeAndInputPane = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showLanguageToggle) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Icon(Icons.code_rounded, size: 16, color: Color(0xFF64748B)),
                    const Text(
                      'Language:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    ...availableSnippets.keys.map((lang) {
                      final isSelected = lang == _selectedLanguage;
                      return ChoiceChip(
                        label: Text(_formatLanguageLabel(lang)),
                        selected: isSelected,
                        onSelected: (_) => _switchLanguage(lang),
                        selectedColor: const Color(0xFF6366F1),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF334155),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        backgroundColor: const Color(0xFFF1F5F9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFCBD5E1),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
            if (activeSnippet.isNotEmpty) ...[
              CodeViewerWidget(
                codeSnippet: activeSnippet,
                activeSourceLine: activeLine,
                explanation: currentStep?.explanation ?? '',
                operation: currentStep?.operation ?? 'INIT',
              ),
              const SizedBox(height: 20),
            ],
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
            final isDesktop = constraints.maxWidth >= 800;
            final isWideForAI = constraints.maxWidth > 920;

            final Widget interactiveBody;
            if (isDesktop) {
              interactiveBody = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: visualizerPane),
                  const SizedBox(width: 18),
                  Expanded(flex: 5, child: codeAndInputPane),
                ],
              );
            } else {
              interactiveBody = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  visualizerPane,
                  const SizedBox(height: 20),
                  codeAndInputPane,
                ],
              );
            }

            final mainWorkspace = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                headerSection,
                const SizedBox(height: 16),
                interactiveBody,
              ],
            );

            return Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: mainWorkspace),
                    if (_showAITutor && isWideForAI) ...[
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

                // Floating AI Tutor Trigger Button
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton.extended(
                    heroTag: 'ai_tutor_viz_fab',
                    onPressed: () {
                      if (!isWideForAI) {
                        AITutorPanel.showAsModalBottomSheet(
                          context,
                          lessonId: widget.lessonId ?? '',
                          getVisualizationState: () => currentStep?.toJson(
                            algorithmName: _selectedAlgorithm,
                          ),
                        );
                      } else {
                        setState(() {
                          _showAITutor = !_showAITutor;
                        });
                      }
                    },
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    elevation: 6,
                    icon: const Text('🤖', style: TextStyle(fontSize: 18)),
                    label: Text(
                      isWideForAI && _showAITutor
                          ? 'Hide AI Tutor'
                          : 'Ask AI Tutor',
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
  }
}
