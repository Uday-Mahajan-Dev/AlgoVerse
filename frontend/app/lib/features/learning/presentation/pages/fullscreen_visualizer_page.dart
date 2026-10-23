import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/execution_trace.dart';
import '../widgets/array_visualizer_widget.dart';
import '../widgets/variable_panel_widget.dart';

class FullscreenVisualizerPage extends StatefulWidget {
  final ExecutionTrace trace;
  final String algorithm;
  final Map<String, dynamic> input;
  final String selectedLanguage;
  final Map<String, dynamic> contentJson;
  final String? lessonId;
  final VoidCallback? onLessonCompleted;
  final bool? isLessonCompleted;
  final int initialStepIndex;

  const FullscreenVisualizerPage({
    super.key,
    required this.trace,
    required this.algorithm,
    required this.input,
    this.selectedLanguage = 'python',
    this.contentJson = const {},
    this.lessonId,
    this.onLessonCompleted,
    this.isLessonCompleted,
    this.initialStepIndex = 0,
  });

  @override
  State<FullscreenVisualizerPage> createState() =>
      _FullscreenVisualizerPageState();
}

class _FullscreenVisualizerPageState extends State<FullscreenVisualizerPage> {
  int _currentStepIndex = 0;
  bool _isPlaying = false;
  double _playbackSpeed = 1.0;
  Timer? _playbackTimer;
  bool _hasTriggeredCompletion = false;

  static const List<double> _allowedSpeeds = [0.25, 0.5, 1.0, 1.5, 2.0, 4.0];

  @override
  void initState() {
    super.initState();
    _currentStepIndex = widget.initialStepIndex.clamp(
      0,
      widget.trace.totalSteps > 0 ? widget.trace.totalSteps - 1 : 0,
    );

    // B2: Allow landscape in this route only
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _loadSavedSpeed();
  }

  @override
  void dispose() {
    _stopPlayback(notifyState: false);
    // B2: Restore previous portrait-locked orientation on exit
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  Future<void> _loadSavedSpeed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getDouble('visualizer_speed');
      if (saved != null && _allowedSpeeds.contains(saved) && mounted) {
        setState(() => _playbackSpeed = saved);
      }
    } catch (_) {}
  }

  Future<void> _changeSpeed(double speed) async {
    setState(() => _playbackSpeed = speed);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('visualizer_speed', speed);
    } catch (_) {}

    // B4: Changing speed while playing takes effect from the next step without restarting
    if (_isPlaying) {
      _startPlayback();
    }
  }

  int _getBaseIntervalMs() => 750;

  void _startPlayback() {
    _playbackTimer?.cancel();
    final intervalMs = (_getBaseIntervalMs() / _playbackSpeed).round();

    _playbackTimer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      if (!mounted) return;
      if (_currentStepIndex < widget.trace.totalSteps - 1) {
        setState(() => _currentStepIndex++);
        if (_currentStepIndex >= widget.trace.totalSteps - 1) {
          _checkAutoComplete();
        }
      } else {
        _checkAutoComplete();
        _stopPlayback();
      }
    });

    if (mounted) setState(() => _isPlaying = true);
  }

  void _stopPlayback({bool notifyState = true}) {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    if (notifyState && mounted && _isPlaying) {
      setState(() => _isPlaying = false);
    } else {
      _isPlaying = false;
    }
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _stopPlayback();
    } else {
      if (_currentStepIndex >= widget.trace.totalSteps - 1) {
        _currentStepIndex = 0;
      }
      _startPlayback();
    }
  }

  void _nextStep() {
    _stopPlayback();
    if (_currentStepIndex < widget.trace.totalSteps - 1) {
      setState(() => _currentStepIndex++);
      if (_currentStepIndex >= widget.trace.totalSteps - 1) {
        _checkAutoComplete();
      }
    }
  }

  void _prevStep() {
    _stopPlayback();
    if (_currentStepIndex > 0) {
      setState(() => _currentStepIndex--);
    }
  }

  void _reset() {
    _stopPlayback();
    setState(() => _currentStepIndex = 0);
  }

  void _seek(int step) {
    _stopPlayback();
    final target = step.clamp(0, widget.trace.totalSteps - 1);
    setState(() => _currentStepIndex = target);
    if (target >= widget.trace.totalSteps - 1) {
      _checkAutoComplete();
    }
  }

  void _checkAutoComplete() {
    if (_currentStepIndex >= widget.trace.totalSteps - 1 &&
        !_hasTriggeredCompletion &&
        !(widget.isLessonCompleted ?? false)) {
      _hasTriggeredCompletion = true;
      if (widget.onLessonCompleted != null) {
        widget.onLessonCompleted!();
      } else if (widget.lessonId != null && widget.lessonId!.isNotEmpty) {
        ApiClient.completeLesson(lessonId: widget.lessonId!)
            .catchError((_) => <String, dynamic>{});
      }
    }
  }

  int _getActiveSourceLine(int? baseLine) {
    if (baseLine == null || baseLine <= 0) return 0;
    final lineMaps = widget.contentJson['line_maps'];
    if (lineMaps is Map) {
      final langMap = lineMaps[widget.selectedLanguage.toLowerCase()];
      if (langMap is Map) {
        final mapped = langMap[baseLine.toString()] ?? langMap[baseLine];
        if (mapped is int && mapped > 0) return mapped;
        final parsed = int.tryParse(mapped?.toString() ?? '');
        if (parsed != null && parsed > 0) return parsed;
      }
    }
    return baseLine;
  }

  String _getCurrentCodeLine(int activeLine) {
    if (activeLine <= 0) return '';
    final rawSnippets = widget.contentJson['code_snippets'];
    String? snippet;
    if (rawSnippets is Map) {
      snippet = rawSnippets[widget.selectedLanguage.toLowerCase()]?.toString();
      if (snippet == null && rawSnippets.containsKey(widget.algorithm)) {
        snippet = rawSnippets[widget.algorithm]?.toString();
      }
    }
    snippet ??= widget.contentJson['code_snippet']?.toString();
    if (snippet == null || snippet.trim().isEmpty) return '';

    final lines = snippet.split('\n');
    final lineIdx = activeLine - 1;
    if (lineIdx >= 0 && lineIdx < lines.length) {
      return lines[lineIdx];
    }
    return '';
  }

  String _formatAlgoTitle(String algo) {
    switch (algo) {
      case 'findMaximum':
        return 'Find Maximum';
      case 'findMinimum':
        return 'Find Minimum';
      case 'arrayTraversal':
        return 'Array Traversal';
      case 'linearSearch':
        return 'Linear Search';
      case 'binarySearch':
        return 'Binary Search';
      case 'reverseArray':
        return 'Reverse Array';
      default:
        if (algo.isEmpty) return 'Algorithm Visualization';
        // CamelCase to Words
        return algo.replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => ' ${match.group(0)}',
        ).trim().replaceFirstMapped(
          RegExp(r'^[a-z]'),
          (match) => match.group(0)!.toUpperCase(),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = widget.trace.getStep(_currentStepIndex);
    final activeLine = _getActiveSourceLine(currentStep?.sourceLine);
    final currentCodeLine = _getCurrentCodeLine(activeLine);
    final totalSteps = widget.trace.totalSteps;
    final maxSteps = totalSteps > 1 ? totalSteps - 1 : 1;
    final sliderVal = _currentStepIndex.clamp(0, maxSteps).toDouble();
    final intervalMs = (_getBaseIntervalMs() / _playbackSpeed).round();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark slate aesthetic
      body: SafeArea(
        child: Column(
          children: [
            // ============================================================
            // TOP SLIM BAR: Back, Algorithm Title, Step Counter (B2)
            // ============================================================
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                border: Border(
                  bottom: BorderSide(color: Color(0xFF334155), width: 1),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    tooltip: 'Back to Lesson',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatAlgoTitle(widget.algorithm),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF6366F1)),
                    ),
                    child: Text(
                      'Step ${_currentStepIndex + 1} / $totalSteps',
                      style: const TextStyle(
                        color: Color(0xFF818CF8),
                        fontSize: 12,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ============================================================
            // CENTER: Large Data-Structure Visualization with Camera Follow (B2, B3)
            // ============================================================
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ArrayVisualizerWidget(
                          arrayState: currentStep?.arrayState ?? [],
                          highlights: currentStep?.highlights ?? [],
                          pointers: currentStep?.pointers ?? {},
                          operation: currentStep?.operation ?? 'INIT',
                          isLarge: true,
                          stepIntervalMs: intervalMs,
                          isPlaying: _isPlaying,
                        ),
                        if (currentStep?.variables != null &&
                            currentStep!.variables.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          VariablePanelWidget(
                            variables: currentStep.variables,
                            result: currentStep.result,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ============================================================
            // BOTTOM: Active Code Line Box (B2)
            // ============================================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            activeLine > 0 ? 'Line $activeLine' : 'Line -',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.selectedLanguage.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const Spacer(),
                        if (currentStep?.explanation != null &&
                            currentStep!.explanation.isNotEmpty)
                          Flexible(
                            child: Text(
                              currentStep.explanation,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFCBD5E1),
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(
                        currentCodeLine.isNotEmpty
                            ? currentCodeLine
                            : (activeLine > 0
                                ? '// Executing step line $activeLine'
                                : '// Ready to execute'),
                        style: const TextStyle(
                          color: Color(0xFF38BDF8), // Cyan/Sky monospace highlight
                          fontFamily: 'monospace',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ============================================================
            // CONTROLS ROW: Restart, Step Back, Play/Pause, Step Forward, Speed (B2, B4)
            // ============================================================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                border: Border(
                  top: BorderSide(color: Color(0xFF334155), width: 1),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress seek slider
                  SizedBox(
                    height: 24,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 12,
                        ),
                        activeTrackColor: const Color(0xFF6366F1),
                        inactiveTrackColor: const Color(0xFF334155),
                        thumbColor: const Color(0xFF818CF8),
                      ),
                      child: Slider(
                        value: sliderVal,
                        min: 0,
                        max: maxSteps.toDouble(),
                        divisions: maxSteps > 0 ? maxSteps : 1,
                        onChanged: (val) => _seek(val.toInt()),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Restart
                        IconButton(
                          tooltip: 'Restart',
                          onPressed: _reset,
                          icon: const Icon(Icons.replay_rounded, color: Colors.white70),
                        ),
                        const SizedBox(width: 8),

                        // Step Back
                        IconButton.filledTonal(
                          tooltip: 'Step Back',
                          onPressed: _currentStepIndex > 0 ? _prevStep : null,
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF334155),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.skip_previous_rounded),
                        ),
                        const SizedBox(width: 8),

                        // Large Play/Pause button
                        FilledButton(
                          onPressed: _togglePlayPause,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: 24,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isPlaying ? 'PAUSE' : 'PLAY',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Step Forward
                        IconButton.filledTonal(
                          tooltip: 'Step Forward',
                          onPressed: _currentStepIndex < totalSteps - 1
                              ? _nextStep
                              : null,
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF334155),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.skip_next_rounded),
                        ),
                        const SizedBox(width: 8),

                        // Speed Menu / Chip (0.25x to 4x)
                        PopupMenuButton<double>(
                          tooltip: 'Playback Speed',
                          initialValue: _playbackSpeed,
                          onSelected: _changeSpeed,
                          color: const Color(0xFF1E293B),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF334155),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF475569)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${_playbackSpeed}x',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF818CF8),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.speed_rounded,
                                  size: 16,
                                  color: Color(0xFF818CF8),
                                ),
                              ],
                            ),
                          ),
                          itemBuilder: (context) => _allowedSpeeds.map((s) {
                            return PopupMenuItem<double>(
                              value: s,
                              child: Text(
                                '${s}x Speed',
                                style: TextStyle(
                                  color: s == _playbackSpeed
                                      ? const Color(0xFF818CF8)
                                      : Colors.white,
                                  fontWeight: s == _playbackSpeed
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
