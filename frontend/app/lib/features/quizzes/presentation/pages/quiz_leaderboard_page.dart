import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';

class QuizLeaderboardPage extends StatefulWidget {
  final String quizId;

  const QuizLeaderboardPage({super.key, required this.quizId});

  @override
  State<QuizLeaderboardPage> createState() => _QuizLeaderboardPageState();
}

class _QuizLeaderboardPageState extends State<QuizLeaderboardPage> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _leaderboard = [];

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) throw Exception('Authentication required');
      final res = await ApiClient.getQuizLeaderboard(
        accessToken: token,
        quizId: widget.quizId,
      );
      if (mounted) {
        setState(() {
          _leaderboard = res;
          _isLoading = false;
        });
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.leaderboard_rounded, color: Colors.amber.shade800, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Quiz Leaderboard',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: _buildBody(theme),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: FilledButton.icon(
          onPressed: () {
            context.push('/quizzes/${widget.quizId}/play');
          },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.play_arrow_rounded, size: 20),
          label: const Text('Play Quiz Again', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Colors.red.shade700)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loadLeaderboard, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_leaderboard.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.emoji_events_outlined, size: 56, color: Colors.amber.shade700),
              ),
              const SizedBox(height: 20),
              const Text(
                'No Scores Recorded Yet',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Be the first player to submit answers and claim the #1 spot on the leaderboard!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLeaderboard,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _leaderboard.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = _leaderboard[index];
          final rank = item['rank'] ?? (index + 1);
          final name = item['student_name']?.toString() ?? 'Student';
          final score = item['score'] ?? 0;
          final time = item['total_time_seconds'] ?? 0;

          Color rankBg;
          Color rankColor;
          Widget rankWidget;

          if (rank == 1) {
            rankBg = Colors.amber.shade100;
            rankColor = Colors.amber.shade900;
            rankWidget = Icon(Icons.emoji_events_rounded, color: Colors.amber.shade800, size: 24);
          } else if (rank == 2) {
            rankBg = Colors.grey.shade200;
            rankColor = Colors.grey.shade800;
            rankWidget = Icon(Icons.emoji_events_rounded, color: Colors.grey.shade600, size: 22);
          } else if (rank == 3) {
            rankBg = Colors.brown.shade100;
            rankColor = Colors.brown.shade800;
            rankWidget = Icon(Icons.emoji_events_rounded, color: Colors.brown.shade600, size: 20);
          } else {
            rankBg = const Color(0xFFF1F5F9);
            rankColor = const Color(0xFF475569);
            rankWidget = Text(
              '#$rank',
              style: TextStyle(fontWeight: FontWeight.bold, color: rankColor, fontSize: 13),
            );
          }

          return Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: rank <= 3 ? Colors.amber.shade200 : const Color(0xFFE2E8F0),
                width: rank == 1 ? 1.5 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: rankBg,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: rankWidget,
                  ),
                  const SizedBox(width: 14),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.purple.shade50,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'S',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple.shade900),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${time}s elapsed',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purple.shade200),
                    ),
                    child: Text(
                      '$score pts',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
