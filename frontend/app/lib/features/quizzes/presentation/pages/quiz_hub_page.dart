import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';

class QuizHubPage extends StatefulWidget {
  const QuizHubPage({super.key});

  @override
  State<QuizHubPage> createState() => _QuizHubPageState();
}

class _QuizHubPageState extends State<QuizHubPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoadingClass = true;
  bool _isLoadingPublic = true;
  List<dynamic> _classQuizzes = [];
  List<dynamic> _publicQuizzes = [];
  String? _classError;
  String? _publicError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadQuizzes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadQuizzes() async {
    _loadClassQuizzes();
    _loadPublicQuizzes();
  }

  Future<void> _loadClassQuizzes() async {
    setState(() {
      _isLoadingClass = true;
      _classError = null;
    });
    try {
      final token = await TokenStorage.getAccessToken();
      final res = await ApiClient.getClassQuizzes(accessToken: token);
      if (mounted) {
        setState(() {
          _classQuizzes = res;
          _isLoadingClass = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading class quizzes: $e');
      if (mounted) {
        setState(() {
          _classQuizzes = [];
          _classError = null;
          _isLoadingClass = false;
        });
      }
    }
  }

  Future<void> _loadPublicQuizzes() async {
    setState(() {
      _isLoadingPublic = true;
      _publicError = null;
    });
    try {
      final token = await TokenStorage.getAccessToken();
      final res = await ApiClient.getPublicQuizzes(accessToken: token);
      if (mounted) {
        setState(() {
          _publicQuizzes = res;
          _isLoadingPublic = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading public quizzes: $e');
      if (mounted) {
        setState(() {
          _publicQuizzes = [];
          _publicError = null;
          _isLoadingPublic = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.dashboard);
            }
          },
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.sports_esports_rounded, color: Colors.amber.shade800, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Live Quiz Arena',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.purple.shade700,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: Colors.purple.shade700,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          tabs: const [
            Tab(icon: Icon(Icons.school_rounded), text: 'My Class Quizzes'),
            Tab(icon: Icon(Icons.public_rounded), text: 'Public Quizzes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQuizList(_classQuizzes, _isLoadingClass, _classError, _loadClassQuizzes, isClass: true),
          _buildQuizList(_publicQuizzes, _isLoadingPublic, _publicError, _loadPublicQuizzes, isClass: false),
        ],
      ),
    );
  }

  Widget _buildQuizList(
    List<dynamic> quizzes,
    bool isLoading,
    String? error,
    Future<void> Function() onRefresh, {
    required bool isClass,
  }) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 12),
            Text(error, style: TextStyle(color: Colors.red.shade700)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRefresh, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (quizzes.isEmpty) {
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
                child: Icon(Icons.sports_esports_rounded, size: 56, color: Colors.amber.shade700),
              ),
              const SizedBox(height: 20),
              Text(
                isClass ? 'No Class Quizzes Right Now' : 'No Public Quizzes Found',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                isClass
                    ? 'Your linked professor hasn\'t published a class quiz yet. Check back soon or try Public Quizzes!'
                    : 'Be the first educator to author an interactive public live quiz!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: quizzes.length,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final q = quizzes[index];
          final id = q['id']?.toString() ?? '';
          final title = q['title']?.toString() ?? 'Live Quiz';
          final desc = q['description']?.toString() ?? '';
          final teacherName = q['teacher_name']?.toString() ?? 'Educator';
          final qCount = q['question_count'] ?? (q['questions'] as List?)?.length ?? 0;
          final timePerQ = q['time_per_question_seconds'] ?? 30;

          return Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.bolt_rounded,
                          color: Colors.amber.shade900,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'By $teacherName',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.purple.shade700,
                              ),
                            ),
                            if (desc.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                desc,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.help_outline_rounded,
                                  size: 14,
                                  color: Color(0xFF475569),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$qCount Questions',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.timer_outlined,
                                  size: 14,
                                  color: Color(0xFF475569),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${timePerQ}s / Q',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.leaderboard_rounded,
                              color: Colors.amber,
                            ),
                            tooltip: 'View Leaderboard',
                            onPressed: () {
                              context.push('/quizzes/$id/leaderboard');
                            },
                          ),
                          const SizedBox(width: 4),
                          FilledButton.icon(
                            onPressed: () {
                              context.push('/quizzes/$id/play');
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            icon:
                                const Icon(Icons.play_arrow_rounded, size: 18),
                            label: const Text(
                              'Play Now',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
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
