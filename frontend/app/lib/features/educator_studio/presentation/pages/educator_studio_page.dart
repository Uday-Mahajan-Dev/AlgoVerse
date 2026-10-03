import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';

class EducatorStudioPage extends ConsumerStatefulWidget {
  const EducatorStudioPage({super.key});

  @override
  ConsumerState<EducatorStudioPage> createState() => _EducatorStudioPageState();
}

class _EducatorStudioPageState extends ConsumerState<EducatorStudioPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoadingProblems = true;
  bool _isLoadingQuizzes = true;
  List<dynamic> _customProblems = [];
  List<dynamic> _quizzes = [];
  String? _problemError;
  String? _quizError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    _loadProblems();
    _loadQuizzes();
  }

  Future<void> _loadProblems() async {
    setState(() {
      _isLoadingProblems = true;
      _problemError = null;
    });
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) throw Exception('Authentication required');
      final res = await ApiClient.getTeacherCustomProblems(accessToken: token);
      if (mounted) {
        setState(() {
          _customProblems = res;
          _isLoadingProblems = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _problemError = e.toString().replaceAll('Exception: ', '');
          _isLoadingProblems = false;
        });
      }
    }
  }

  Future<void> _loadQuizzes() async {
    setState(() {
      _isLoadingQuizzes = true;
      _quizError = null;
    });
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) throw Exception('Authentication required');
      final res = await ApiClient.getTeacherQuizzes(accessToken: token);
      if (mounted) {
        setState(() {
          _quizzes = res;
          _isLoadingQuizzes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _quizError = e.toString().replaceAll('Exception: ', '');
          _isLoadingQuizzes = false;
        });
      }
    }
  }

  void _openCreateProblemDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _CreateProblemDialog(onCreated: _loadProblems),
    );
  }

  void _openCreateQuizDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _CreateQuizDialog(onCreated: _loadQuizzes),
    );
  }

  void _showProblemStats(String problemId, String title) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => _ProblemStatsSheet(problemId: problemId, title: title),
    );
  }

  void _showQuizStats(String quizId, String title) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => _QuizStatsSheet(quizId: quizId, title: title),
    );
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
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.edit_note_rounded, color: Colors.purple.shade700, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Educator Studio',
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
            Tab(
              icon: Icon(Icons.code_rounded),
              text: 'Custom Problems',
            ),
            Tab(
              icon: Icon(Icons.quiz_rounded),
              text: 'Live Quizzes',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProblemsTab(theme),
          _buildQuizzesTab(theme),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            _openCreateProblemDialog();
          } else {
            _openCreateQuizDialog();
          }
        },
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(_tabController.index == 0 ? 'Create Problem' : 'Create Quiz'),
      ),
    );
  }

  Widget _buildProblemsTab(ThemeData theme) {
    if (_isLoadingProblems) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_problemError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 12),
            Text(_problemError!, style: TextStyle(color: Colors.red.shade700)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loadProblems, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_customProblems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.code_rounded, size: 56, color: Colors.purple.shade700),
              ),
              const SizedBox(height: 20),
              const Text(
                'No Custom Problems Yet',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Create custom algorithmic coding challenges with customized test cases to assign as homework or share publicly.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _openCreateProblemDialog,
                style: FilledButton.styleFrom(backgroundColor: Colors.purple.shade700),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create First Problem'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProblems,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
        itemCount: _customProblems.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final p = _customProblems[index];
          final title = p['title']?.toString() ?? 'Untitled Problem';
          final desc = p['description']?.toString() ?? '';
          final visibility = p['visibility']?.toString() ?? 'CLASS_ONLY';
          final isPublic = visibility == 'PUBLIC';
          final testCases = (p['test_cases'] as List<dynamic>?) ?? [];
          final id = p['id']?.toString() ?? '';

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
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isPublic ? Colors.green.shade50 : Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.terminal_rounded,
                          color: isPublic ? Colors.green.shade700 : Colors.indigo.shade700,
                          size: 22,
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
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              desc,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPublic ? Colors.green.shade50 : Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isPublic ? Colors.green.shade200 : Colors.purple.shade200,
                          ),
                        ),
                        child: Text(
                          isPublic ? 'Public' : 'Class Only',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isPublic ? Colors.green.shade800 : Colors.purple.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.checklist_rounded, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Text(
                            '${testCases.length} Test Cases',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _showProblemStats(id, title),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.purple.shade700,
                          side: BorderSide(color: Colors.purple.shade300),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Icons.analytics_outlined, size: 16),
                        label: const Text('View Stats', style: TextStyle(fontSize: 12)),
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

  Widget _buildQuizzesTab(ThemeData theme) {
    if (_isLoadingQuizzes) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_quizError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 12),
            Text(_quizError!, style: TextStyle(color: Colors.red.shade700)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loadQuizzes, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_quizzes.isEmpty) {
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
                child: Icon(Icons.quiz_rounded, size: 56, color: Colors.amber.shade700),
              ),
              const SizedBox(height: 20),
              const Text(
                'No Quizzes Created Yet',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Build interactive Kahoot-style timed multiple-choice quizzes with live leaderboards for your classroom or the whole AlgoVerse community.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _openCreateQuizDialog,
                style: FilledButton.styleFrom(backgroundColor: Colors.purple.shade700),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create First Quiz'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadQuizzes,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
        itemCount: _quizzes.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final q = _quizzes[index];
          final title = q['title']?.toString() ?? 'Untitled Quiz';
          final desc = q['description']?.toString() ?? '';
          final visibility = q['visibility']?.toString() ?? 'CLASS_ONLY';
          final isPublic = visibility == 'PUBLIC';
          final qCount = q['question_count'] ?? (q['questions'] as List?)?.length ?? 0;
          final timePerQ = q['time_per_question_seconds'] ?? 30;
          final id = q['id']?.toString() ?? '';

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
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.sports_esports_rounded,
                          color: Colors.amber.shade800,
                          size: 22,
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
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            if (desc.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                desc,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPublic ? Colors.green.shade50 : Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isPublic ? Colors.green.shade200 : Colors.purple.shade200,
                          ),
                        ),
                        child: Text(
                          isPublic ? 'Public' : 'Class Only',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isPublic ? Colors.green.shade800 : Colors.purple.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.help_outline_rounded, size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                '$qCount Questions',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.timer_outlined, size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                '${timePerQ}s / Q',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ],
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _showQuizStats(id, title),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.purple.shade700,
                          side: BorderSide(color: Colors.purple.shade300),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Icons.leaderboard_rounded, size: 16),
                        label: const Text('View Stats', style: TextStyle(fontSize: 12)),
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

// ============================================================
// CREATE PROBLEM DIALOG
// ============================================================

class _CreateProblemDialog extends StatefulWidget {
  final VoidCallback onCreated;

  const _CreateProblemDialog({required this.onCreated});

  @override
  State<_CreateProblemDialog> createState() => _CreateProblemDialogState();
}

class _CreateProblemDialogState extends State<_CreateProblemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  // Primary Code Editor State
  String _primaryLanguage = 'python'; // 'python', 'java', 'cpp'
  final _primaryCodeController = TextEditingController(
    text: 'def solve():\n    # Write your solution here\n    pass\n\nif __name__ == "__main__":\n    solve()',
  );

  // Multi-Language Generated Templates
  bool _isGeneratingTemplates = false;
  bool _showGeneratedTemplates = false;
  int _previewLanguageIndex = 0; // 0 = Python, 1 = Java, 2 = C++
  final _pythonCodeController = TextEditingController();
  final _javaCodeController = TextEditingController();
  final _cppCodeController = TextEditingController();

  String _visibility = 'CLASS_ONLY';
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _testCases = [
    {'input': '1 2', 'expected': '3', 'is_hidden': false},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _primaryCodeController.dispose();
    _pythonCodeController.dispose();
    _javaCodeController.dispose();
    _cppCodeController.dispose();
    super.dispose();
  }

  void _onPrimaryLanguageChanged(String? newLang) {
    if (newLang == null || newLang == _primaryLanguage) return;

    final current = _primaryCodeController.text.trim();
    final isDefaultPython = current.isEmpty ||
        current == 'def solve():\n    # Write your solution here\n    pass\n\nif __name__ == "__main__":\n    solve()';
    final isDefaultJava =
        current == 'import java.util.*;\n\npublic class Main {\n    public static void main(String[] args) {\n        // Write your solution here\n    }\n}';
    final isDefaultCpp =
        current == '#include <iostream>\nusing namespace std;\n\nint main() {\n    // Write your solution here\n    return 0;\n}';

    setState(() {
      _primaryLanguage = newLang;
      if (isDefaultPython || isDefaultJava || isDefaultCpp) {
        if (newLang == 'python') {
          _primaryCodeController.text =
              'def solve():\n    # Write your solution here\n    pass\n\nif __name__ == "__main__":\n    solve()';
        } else if (newLang == 'java') {
          _primaryCodeController.text =
              'import java.util.*;\n\npublic class Main {\n    public static void main(String[] args) {\n        // Write your solution here\n    }\n}';
        } else if (newLang == 'cpp') {
          _primaryCodeController.text =
              '#include <iostream>\nusing namespace std;\n\nint main() {\n    // Write your solution here\n    return 0;\n}';
        }
      }
    });
  }

  void _insertDefaultBoilerplate() {
    setState(() {
      if (_primaryLanguage == 'python') {
        _primaryCodeController.text =
            'def solve():\n    # Write your solution here\n    pass\n\nif __name__ == "__main__":\n    solve()';
      } else if (_primaryLanguage == 'java') {
        _primaryCodeController.text =
            'import java.util.*;\n\npublic class Main {\n    public static void main(String[] args) {\n        // Write your solution here\n    }\n}';
      } else if (_primaryLanguage == 'cpp') {
        _primaryCodeController.text =
            '#include <iostream>\nusing namespace std;\n\nint main() {\n    // Write your solution here\n    return 0;\n}';
      }
    });
  }

  Future<void> _generateTemplates() async {
    final code = _primaryCodeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter starter code first')),
      );
      return;
    }

    setState(() => _isGeneratingTemplates = true);

    try {
      final res = await ApiClient.generateStarterTemplates(
        code: _primaryCodeController.text,
        language: _primaryLanguage,
      );

      if (!mounted) return;
      setState(() {
        _pythonCodeController.text = res['starter_code_python']?.toString() ?? '';
        _javaCodeController.text = res['starter_code_java']?.toString() ?? '';
        _cppCodeController.text = res['starter_code_cpp']?.toString() ?? '';
        _showGeneratedTemplates = true;
        _isGeneratingTemplates = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✨ Multi-language starter code templates generated!'),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGeneratingTemplates = false);
      final rawError = e.toString().replaceAll('Exception: ', '').trim();
      final errorMsg = rawError.contains('401')
          ? 'Session expired. Please log in again.'
          : (rawError.isEmpty ? 'Failed to generate templates.' : rawError);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _addTestCase() {
    setState(() {
      _testCases.add({'input': '', 'expected': '', 'is_hidden': false});
    });
  }

  void _removeTestCase(int index) {
    if (_testCases.length > 1) {
      setState(() {
        _testCases.removeAt(index);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate test cases
    for (int i = 0; i < _testCases.length; i++) {
      if (_testCases[i]['input'].toString().trim().isEmpty ||
          _testCases[i]['expected'].toString().trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Test case ${i + 1} is missing input or expected output.')),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      String pyCode = _pythonCodeController.text;
      String javaCode = _javaCodeController.text;
      String cppCode = _cppCodeController.text;

      // If templates were not explicitly previewed/generated, assign the primary language code
      if (!_showGeneratedTemplates) {
        if (_primaryLanguage == 'python') {
          pyCode = _primaryCodeController.text;
          javaCode = '';
          cppCode = '';
        } else if (_primaryLanguage == 'java') {
          javaCode = _primaryCodeController.text;
          pyCode = '';
          cppCode = '';
        } else if (_primaryLanguage == 'cpp') {
          cppCode = _primaryCodeController.text;
          pyCode = '';
          javaCode = '';
        }
      } else {
        if (_primaryLanguage == 'python' && pyCode.isEmpty) pyCode = _primaryCodeController.text;
        if (_primaryLanguage == 'java' && javaCode.isEmpty) javaCode = _primaryCodeController.text;
        if (_primaryLanguage == 'cpp' && cppCode.isEmpty) cppCode = _primaryCodeController.text;
      }

      await ApiClient.createCustomProblem(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        starterCode: _primaryCodeController.text,
        starterCodePython: pyCode,
        starterCodeJava: javaCode,
        starterCodeCpp: cppCode,
        testCases: _testCases,
        visibility: _visibility,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onCreated();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Custom problem published successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      final rawError = e.toString().replaceAll('Exception: ', '').trim();
      final errorMsg = rawError.contains('401')
          ? 'Session expired. Please log in again.'
          : (rawError.isEmpty ? 'Failed to create problem.' : rawError);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Widget _buildPreviewTab(int index, String label, IconData icon) {
    final isSelected = _previewLanguageIndex == index;
    return InkWell(
      onTap: () => setState(() => _previewLanguageIndex = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7C3AED) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF7C3AED) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 750, maxHeight: 820),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.code_rounded, color: Colors.purple.shade700, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Create Custom Problem',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Expanded(
                  child: ListView(
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Problem Title *',
                          hintText: 'e.g. Reverse Linked List, Two Sum Variations',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().length < 3) ? 'Title must be at least 3 characters' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Problem Description (Markdown supported) *',
                          hintText: 'Describe the problem statement, input/output format, and constraints...',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().length < 10) ? 'Description must be at least 10 characters' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _visibility,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Visibility *',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'CLASS_ONLY',
                            child: Text('Class Only (My Students)', overflow: TextOverflow.ellipsis),
                          ),
                          DropdownMenuItem(
                            value: 'PUBLIC',
                            child: Text('Public (AlgoVerse Community)', overflow: TextOverflow.ellipsis),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _visibility = v);
                        },
                      ),
                      const SizedBox(height: 20),

                      // Single Code Editor + Auto-Generate Templates Section
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Starter Code',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _primaryLanguage,
                                      isDense: true,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.purple.shade800,
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'python',
                                          child: Text('Python 3'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'java',
                                          child: Text('Java'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'cpp',
                                          child: Text('C++'),
                                        ),
                                      ],
                                      onChanged: _onPrimaryLanguageChanged,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _primaryCodeController,
                              maxLines: 6,
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                              decoration: InputDecoration(
                                labelText: 'Starter Code Skeleton',
                                hintText: 'Enter function signature or solution boilerplate...',
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.refresh_rounded, size: 18),
                                  tooltip: 'Reset to default boilerplate',
                                  onPressed: _insertDefaultBoilerplate,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Auto-Generate Button & Info Row
                            LayoutBuilder(
                              builder: (context, constraints) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    ElevatedButton(
                                      onPressed: _isGeneratingTemplates ? null : _generateTemplates,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF7C3AED),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          if (_isGeneratingTemplates) ...[
                                            const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                            ),
                                            const SizedBox(width: 8),
                                          ] else ...[
                                            const Icon(Icons.auto_awesome_rounded, size: 18),
                                            const SizedBox(width: 8),
                                          ],
                                          Flexible(
                                            child: Text(
                                              _isGeneratingTemplates
                                                  ? 'Generating Multi-Language Templates...'
                                                  : '✨ Auto-Generate Templates for All Languages',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(Icons.info_outline_rounded, size: 13, color: Colors.grey.shade600),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'AlgoVerse AI & Smart Parser will generate Java and C++ boilerplates automatically.',
                                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),

                            // Expandable Generated Templates Preview
                            if (_showGeneratedTemplates) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFDDD6FE)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.preview_rounded, size: 16, color: Color(0xFF7C3AED)),
                                        const SizedBox(width: 6),
                                        const Expanded(
                                          child: Text(
                                            'Generated Multi-Language Templates',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF4C1D95),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () => setState(() => _showGeneratedTemplates = false),
                                          style: TextButton.styleFrom(
                                            visualDensity: VisualDensity.compact,
                                            foregroundColor: Colors.grey.shade600,
                                          ),
                                          child: const Text('Hide', style: TextStyle(fontSize: 12)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        _buildPreviewTab(0, 'Python 3', Icons.terminal_rounded),
                                        _buildPreviewTab(1, 'Java', Icons.coffee_rounded),
                                        _buildPreviewTab(2, 'C++', Icons.memory_rounded),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    TextFormField(
                                      controller: _previewLanguageIndex == 0
                                          ? _pythonCodeController
                                          : (_previewLanguageIndex == 1
                                              ? _javaCodeController
                                              : _cppCodeController),
                                      maxLines: 6,
                                      style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                                      decoration: InputDecoration(
                                        labelText: _previewLanguageIndex == 0
                                            ? 'Python 3 Template (Editable)'
                                            : (_previewLanguageIndex == 1
                                                ? 'Java Template (Editable)'
                                                : 'C++ Template (Editable)'),
                                        border: const OutlineInputBorder(),
                                        filled: true,
                                        fillColor: const Color(0xFFF8FAFC),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Test Cases Section
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Test Cases',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _addTestCase,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Test Case'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ..._testCases.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final tc = entry.value;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Test Case #${idx + 1}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const Spacer(),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Hidden', style: TextStyle(fontSize: 12)),
                                      Checkbox(
                                        value: tc['is_hidden'] as bool,
                                        onChanged: (val) {
                                          setState(() => tc['is_hidden'] = val ?? false);
                                        },
                                      ),
                                    ],
                                  ),
                                  if (_testCases.length > 1)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                                      onPressed: () => _removeTestCase(idx),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isNarrow = constraints.maxWidth < 450;
                                  if (isNarrow) {
                                    return Column(
                                      children: [
                                        TextFormField(
                                          initialValue: tc['input']?.toString(),
                                          decoration: const InputDecoration(
                                            labelText: 'Input',
                                            isDense: true,
                                            border: OutlineInputBorder(),
                                          ),
                                          onChanged: (val) => tc['input'] = val,
                                        ),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          initialValue: tc['expected']?.toString(),
                                          decoration: const InputDecoration(
                                            labelText: 'Expected Output',
                                            isDense: true,
                                            border: OutlineInputBorder(),
                                          ),
                                          onChanged: (val) => tc['expected'] = val,
                                        ),
                                      ],
                                    );
                                  } else {
                                    return Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            initialValue: tc['input']?.toString(),
                                            decoration: const InputDecoration(
                                              labelText: 'Input',
                                              isDense: true,
                                              border: OutlineInputBorder(),
                                            ),
                                            onChanged: (val) => tc['input'] = val,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TextFormField(
                                            initialValue: tc['expected']?.toString(),
                                            decoration: const InputDecoration(
                                              labelText: 'Expected Output',
                                              isDense: true,
                                              border: OutlineInputBorder(),
                                            ),
                                            onChanged: (val) => tc['expected'] = val,
                                          ),
                                        ),
                                      ],
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: FilledButton.styleFrom(backgroundColor: Colors.purple.shade700),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Publish Problem'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// CREATE QUIZ DIALOG
// ============================================================

class _CreateQuizDialog extends StatefulWidget {
  final VoidCallback onCreated;

  const _CreateQuizDialog({required this.onCreated});

  @override
  State<_CreateQuizDialog> createState() => _CreateQuizDialogState();
}

class _CreateQuizDialogState extends State<_CreateQuizDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _visibility = 'CLASS_ONLY';
  int _timePerQuestion = 30;
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _questions = [
    {
      'question_text': '',
      'options': ['', '', '', ''],
      'correct_option_index': 0,
    },
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _addQuestion() {
    setState(() {
      _questions.add({
        'question_text': '',
        'options': ['', '', '', ''],
        'correct_option_index': 0,
      });
    });
  }

  void _removeQuestion(int index) {
    if (_questions.length > 1) {
      setState(() {
        _questions.removeAt(index);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if (q['question_text'].toString().trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Question #${i + 1} has empty text.')),
        );
        return;
      }
      final opts = q['options'] as List;
      for (int j = 0; j < opts.length; j++) {
        if (opts[j].toString().trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Question #${i + 1} option #${j + 1} cannot be empty.')),
          );
          return;
        }
      }
    }

    setState(() => _isSubmitting = true);

    try {
      await ApiClient.createQuiz(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        visibility: _visibility,
        timePerQuestion: _timePerQuestion,
        questions: _questions,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onCreated();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Live Quiz launched successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      final rawError = e.toString().replaceAll('Exception: ', '').trim();
      final errorMsg = rawError.contains('401')
          ? 'Session expired. Please log in again.'
          : (rawError.isEmpty ? 'Failed to create quiz.' : rawError);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 800),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.quiz_rounded, color: Colors.amber.shade800, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Create Kahoot-Style Live Quiz',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Expanded(
                  child: ListView(
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Quiz Title *',
                          hintText: 'e.g. Dynamic Programming Blitz, Graph Theory Warmup',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().length < 3) ? 'Title must be at least 3 characters' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Quiz Description (Optional)',
                          hintText: 'Test your speed and algorithmic intuition with this quick quiz.',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 550;
                          final visibilityDropdown = DropdownButtonFormField<String>(
                            initialValue: _visibility,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Visibility *',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'CLASS_ONLY',
                                child: Text('Class Only (My Students)', overflow: TextOverflow.ellipsis),
                              ),
                              DropdownMenuItem(
                                value: 'PUBLIC',
                                child: Text('Public (Global Leaderboard)', overflow: TextOverflow.ellipsis),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _visibility = v);
                            },
                          );

                          final timeSlider = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Time Per Question: $_timePerQuestion seconds',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Slider(
                                value: _timePerQuestion.toDouble(),
                                min: 10,
                                max: 60,
                                divisions: 10,
                                label: '$_timePerQuestion s',
                                activeColor: Colors.purple.shade700,
                                onChanged: (val) {
                                  setState(() => _timePerQuestion = val.toInt());
                                },
                              ),
                            ],
                          );

                          if (isNarrow) {
                            return Column(
                              children: [
                                visibilityDropdown,
                                const SizedBox(height: 16),
                                timeSlider,
                              ],
                            );
                          } else {
                            return Row(
                              children: [
                                Expanded(child: visibilityDropdown),
                                const SizedBox(width: 16),
                                Expanded(child: timeSlider),
                              ],
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Questions & 4 Color Options',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _addQuestion,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Question'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ..._questions.asMap().entries.map((entry) {
                        final qIdx = entry.key;
                        final q = entry.value;
                        final opts = q['options'] as List;
                        final correctIdx = q['correct_option_index'] as int;

                        final optionColors = [
                          const Color(0xFFEF4444), // Red
                          const Color(0xFF3B82F6), // Blue
                          const Color(0xFFF59E0B), // Yellow/Amber
                          const Color(0xFF10B981), // Green
                        ];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Question #${qIdx + 1}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const Spacer(),
                                  if (_questions.length > 1)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                                      onPressed: () => _removeQuestion(qIdx),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                initialValue: q['question_text']?.toString(),
                                decoration: const InputDecoration(
                                  labelText: 'Question Text *',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (v) => q['question_text'] = v,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Options (Select the radio button for the correct answer):',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isNarrow = constraints.maxWidth < 500;
                                  return GridView.count(
                                    crossAxisCount: isNarrow ? 1 : 2,
                                    childAspectRatio: isNarrow ? 4.8 : 3.2,
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                    children: List.generate(4, (optIdx) {
                                      final col = optionColors[optIdx];
                                      final isCorrect = correctIdx == optIdx;

                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        decoration: BoxDecoration(
                                          color: col.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isCorrect ? col : Colors.grey.shade300,
                                            width: isCorrect ? 2 : 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Radio<int>(
                                              value: optIdx,
                                              groupValue: correctIdx,
                                              activeColor: col,
                                              onChanged: (val) {
                                                if (val != null) {
                                                  setState(() => q['correct_option_index'] = val);
                                                }
                                              },
                                            ),
                                            Expanded(
                                              child: TextFormField(
                                                initialValue: opts[optIdx]?.toString(),
                                                decoration: InputDecoration(
                                                  hintText: 'Option ${optIdx + 1}',
                                                  isDense: true,
                                                  border: InputBorder.none,
                                                ),
                                                onChanged: (v) => opts[optIdx] = v,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: FilledButton.styleFrom(backgroundColor: Colors.purple.shade700),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Launch Quiz'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// PROBLEM STATS BOTTOM SHEET
// ============================================================

class _ProblemStatsSheet extends StatefulWidget {
  final String problemId;
  final String title;

  const _ProblemStatsSheet({required this.problemId, required this.title});

  @override
  State<_ProblemStatsSheet> createState() => _ProblemStatsSheetState();
}

class _ProblemStatsSheetState extends State<_ProblemStatsSheet> {
  bool _isLoading = true;
  Map<String, dynamic>? _stats;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) throw Exception('Authentication required');
      final res = await ApiClient.getCustomProblemStats(
        accessToken: token,
        problemId: widget.problemId,
      );
      if (mounted) setState(() => _stats = res);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, controller) {
        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_error != null) {
          return Center(child: Text(_error!, style: TextStyle(color: Colors.red.shade700)));
        }

        final totalAttempts = _stats?['total_attempts'] ?? 0;
        final successSubmissions = _stats?['successful_submissions'] ?? 0;
        final successRate = _stats?['success_rate'] ?? 0.0;
        final roster = (_stats?['class_roster_stats'] as List?) ?? [];

        return ListView(
          controller: controller,
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Performance & Submissions Analytics',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    title: 'Total Attempts',
                    value: '$totalAttempts',
                    icon: Icons.assignment_outlined,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    title: 'Successful',
                    value: '$successSubmissions',
                    icon: Icons.check_circle_outline_rounded,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    title: 'Success Rate',
                    value: '$successRate%',
                    icon: Icons.percent_rounded,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Class Roster Breakdown',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (roster.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No student attempts recorded yet for this custom problem.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ),
              )
            else
              ...roster.map((r) {
                final name = r['student_name']?.toString() ?? 'Student';
                final isClass = r['is_class_student'] == true;
                final status = r['status']?.toString() ?? 'pending';
                final isCompleted = status == 'completed';

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: isClass ? Colors.purple.shade50 : Colors.grey.shade100,
                    child: Text(
                      name[0].toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isClass ? Colors.purple.shade800 : Colors.grey.shade700,
                      ),
                    ),
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(
                    isClass ? 'Classroom Student' : 'Public Student',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCompleted ? Colors.green.shade50 : Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isCompleted ? 'Completed' : 'Pending',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? Colors.green.shade800 : Colors.amber.shade800,
                      ),
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}

// ============================================================
// QUIZ STATS BOTTOM SHEET
// ============================================================

class _QuizStatsSheet extends StatefulWidget {
  final String quizId;
  final String title;

  const _QuizStatsSheet({required this.quizId, required this.title});

  @override
  State<_QuizStatsSheet> createState() => _QuizStatsSheetState();
}

class _QuizStatsSheetState extends State<_QuizStatsSheet> {
  bool _isLoading = true;
  Map<String, dynamic>? _stats;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) throw Exception('Authentication required');
      final res = await ApiClient.getQuizStats(
        accessToken: token,
        quizId: widget.quizId,
      );
      if (mounted) setState(() => _stats = res);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, controller) {
        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_error != null) {
          return Center(child: Text(_error!, style: TextStyle(color: Colors.red.shade700)));
        }

        final totalAttempts = _stats?['total_attempts'] ?? 0;
        final avgScore = _stats?['average_score'] ?? 0.0;
        final highestScore = _stats?['highest_score'] ?? 0;
        final topScorers = (_stats?['top_scorers'] as List?) ?? [];

        return ListView(
          controller: controller,
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Quiz Playback & Leaderboard Analytics',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    title: 'Total Plays',
                    value: '$totalAttempts',
                    icon: Icons.sports_esports_rounded,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    title: 'Avg Score',
                    value: '$avgScore',
                    icon: Icons.analytics_outlined,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    title: 'High Score',
                    value: '$highestScore',
                    icon: Icons.emoji_events_rounded,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Top Scorers Leaderboard',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (topScorers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No student quiz submissions recorded yet.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ),
              )
            else
              ...topScorers.map((scorer) {
                final rank = scorer['rank'] ?? 1;
                final name = scorer['student_name']?.toString() ?? 'Student';
                final score = scorer['score'] ?? 0;
                final time = scorer['total_time_seconds'] ?? 0;

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: rank == 1
                        ? Colors.amber.shade100
                        : (rank == 2 ? Colors.grey.shade200 : Colors.brown.shade100),
                    child: Text(
                      '#$rank',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: rank == 1 ? Colors.amber.shade900 : Colors.black87,
                      ),
                    ),
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(
                    '${time}s total time',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$score pts',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade800,
                      ),
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final MaterialColor color;

  const _StatTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color.shade700, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color.shade900),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 11, color: color.shade800),
          ),
        ],
      ),
    );
  }
}
