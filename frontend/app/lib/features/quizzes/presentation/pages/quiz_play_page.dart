import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';

class QuizPlayPage extends StatefulWidget {
  final String quizId;

  const QuizPlayPage({super.key, required this.quizId});

  @override
  State<QuizPlayPage> createState() => _QuizPlayPageState();
}

class _QuizPlayPageState extends State<QuizPlayPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _questions = [];
  int _currentIndex = 0;
  int _timePerQuestion = 30;
  int _secondsRemaining = 30;
  Timer? _timer;

  // Question State
  int? _selectedOptionIndex;
  bool _isAnswerLocked = false;
  final List<Map<String, dynamic>> _answersSubmitted = [];

  // Finish State
  bool _isFinished = false;
  bool _isSubmitting = false;
  Map<String, dynamic>? _resultData;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadQuiz() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) throw Exception('Authentication required');
      final res = await ApiClient.getQuizDetails(
        accessToken: token,
        quizId: widget.quizId,
        isPlaying: true,
      );
      if (mounted) {
        setState(() {
          _questions = (res['questions'] as List<dynamic>?) ?? [];
          _timePerQuestion = res['time_per_question_seconds'] ?? 30;
          _secondsRemaining = _timePerQuestion;
          _isLoading = false;
        });
        if (_questions.isNotEmpty) {
          _startQuestionTimer();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _startQuestionTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = _timePerQuestion;
      _selectedOptionIndex = null;
      _isAnswerLocked = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsRemaining > 1) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
        _onTimeExpired();
      }
    });
  }

  void _onTimeExpired() {
    if (_isAnswerLocked) return;
    _selectOption(-1); // -1 signifies no answer chosen in time
  }

  void _selectOption(int optionIndex) {
    if (_isAnswerLocked) return;
    _timer?.cancel();

    final timeTaken = _timePerQuestion - _secondsRemaining;
    final q = _questions[_currentIndex];
    final qId = q['id']?.toString() ?? '';

    setState(() {
      _selectedOptionIndex = optionIndex;
      _isAnswerLocked = true;
    });

    _answersSubmitted.add({
      'question_id': qId,
      'selected_index': optionIndex,
      'time_taken_seconds': timeTaken,
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _startQuestionTimer();
    } else {
      _submitAllAnswers();
    }
  }

  Future<void> _submitAllAnswers() async {
    setState(() {
      _isFinished = true;
      _isSubmitting = true;
    });

    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) throw Exception('Authentication required');

      final res = await ApiClient.submitQuizAttempt(
        accessToken: token,
        quizId: widget.quizId,
        answers: _answersSubmitted,
      );

      if (mounted) {
        setState(() {
          _resultData = res;
          _isSubmitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.amber),
              SizedBox(height: 16),
              Text(
                'Loading Kahoot Arena...',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null && !_isFinished) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade400),
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.white, fontSize: 15)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadQuiz, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_isFinished) {
      return _buildResultScreen();
    }

    return _buildGameplayScreen();
  }

  Widget _buildGameplayScreen() {
    final q = _questions[_currentIndex];
    final qText = q['question_text']?.toString() ?? '';
    final options = (q['options'] as List<dynamic>?) ?? [];
    final timerRatio = _secondsRemaining / _timePerQuestion;

    final optionColors = [
      const Color(0xFFEF4444), // Red Triangle
      const Color(0xFF3B82F6), // Blue Diamond
      const Color(0xFFF59E0B), // Yellow Circle
      const Color(0xFF10B981), // Green Square
    ];

    final optionIcons = [
      Icons.change_history_rounded, // Triangle
      Icons.diamond_outlined, // Diamond
      Icons.circle_outlined, // Circle
      Icons.square_outlined, // Square
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              // Top Arena Bar
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () {
                      _showQuitDialog();
                    },
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Question ${_currentIndex + 1} of ${_questions.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Timer Indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: timerRatio < 0.3
                          ? Colors.red.withValues(alpha: 0.2)
                          : Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: timerRatio < 0.3 ? Colors.red : Colors.amber,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer_rounded,
                          size: 16,
                          color: timerRatio < 0.3 ? Colors.red : Colors.amber,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_secondsRemaining}s',
                          style: TextStyle(
                            color: timerRatio < 0.3 ? Colors.red : Colors.amber,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Animated Timer Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: timerRatio,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(
                    timerRatio < 0.3
                        ? const Color(0xFFEF4444)
                        : (timerRatio < 0.6 ? const Color(0xFFF59E0B) : const Color(0xFF10B981)),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Question Statement Card
              Expanded(
                flex: 4,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: SingleChildScrollView(
                    child: Text(
                      qText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 4 Colored Answer Buttons
              Expanded(
                flex: 5,
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.4,
                  children: List.generate(options.length, (idx) {
                    final color = optionColors[idx % optionColors.length];
                    final icon = optionIcons[idx % optionIcons.length];
                    final isSelected = _selectedOptionIndex == idx;
                    final isDimmed = _isAnswerLocked && !isSelected;

                    return AnimatedScale(
                      scale: isSelected ? 1.03 : 1.0,
                      duration: const Duration(milliseconds: 150),
                      child: InkWell(
                        onTap: _isAnswerLocked ? null : () => _selectOption(idx),
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDimmed ? color.withValues(alpha: 0.3) : color,
                            borderRadius: BorderRadius.circular(16),
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.6),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(icon, color: Colors.white, size: 24),
                              Text(
                                options[idx]?.toString() ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
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

              // Bottom Action Bar when answer is locked
              if (_isAnswerLocked) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _nextQuestion,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0F172A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: Icon(
                      _currentIndex < _questions.length - 1
                          ? Icons.arrow_forward_rounded
                          : Icons.check_circle_rounded,
                    ),
                    label: Text(
                      _currentIndex < _questions.length - 1 ? 'Next Question' : 'Finish Quiz',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultScreen() {
    if (_isSubmitting) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.amber),
              SizedBox(height: 16),
              Text(
                'Submitting & Calculating Rank...',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    final score = _resultData?['score'] ?? 0;
    final maxScore = _resultData?['max_possible_score'] ?? 1000;
    final correctCount = _resultData?['correct_count'] ?? 0;
    final totalQ = _resultData?['total_questions'] ?? _questions.length;
    final totalTime = _resultData?['total_time_seconds'] ?? 0;
    final rank = _resultData?['rank'];

    final accuracy = totalQ > 0 ? ((correctCount / totalQ) * 100).toStringAsFixed(0) : '0';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 550),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Trophy Icon
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade500.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.amber, width: 2),
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      size: 64,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Quiz Complete!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Awesome job pushing your algorithmic problem-solving speed!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 28),

                  // Score & Stats Card
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$score',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: Colors.amber,
                          ),
                        ),
                        Text(
                          'POINTS EARNED (Max: $maxScore)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(color: Colors.white12),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildResultMetric('Accuracy', '$accuracy%', Icons.percent_rounded),
                            _buildResultMetric('Correct', '$correctCount / $totalQ', Icons.check_circle_outline_rounded),
                            _buildResultMetric('Time', '${totalTime}s', Icons.timer_outlined),
                            if (rank != null)
                              _buildResultMetric('Rank', '#$rank', Icons.leaderboard_rounded),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Action Buttons
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: () {
                        context.push('/quizzes/${widget.quizId}/leaderboard');
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.amber.shade600,
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.leaderboard_rounded, size: 20),
                      label: const Text('View Full Leaderboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.go(AppRoutes.quizzes);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white30),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.sports_esports_rounded, size: 20),
                      label: const Text('Back to Quiz Arena'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultMetric(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade400),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade400,
          ),
        ),
      ],
    );
  }

  void _showQuitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Quiz?'),
        content: const Text('Are you sure you want to exit? Your progress in this attempt will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Resume'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}
