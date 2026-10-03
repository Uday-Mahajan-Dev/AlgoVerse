import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';

class CustomProblemWorkspacePage extends StatefulWidget {
  final String problemId;

  const CustomProblemWorkspacePage({super.key, required this.problemId});

  @override
  State<CustomProblemWorkspacePage> createState() =>
      _CustomProblemWorkspacePageState();
}

class _CustomProblemWorkspacePageState
    extends State<CustomProblemWorkspacePage> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _problem;
  late TextEditingController _codeController;
  String _selectedLanguage = 'python';
  final Map<String, String> _codePerLanguage = {};
  int _activeTab = 0; // 0 = Description & Tests, 1 = Execution Output

  bool _isRunning = false;
  bool _isSubmitting = false;
  Map<String, dynamic>? _executionResult;
  String? _verdict;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController();
    _loadProblem();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  String _getStarterCodeForLanguage(String lang) {
    if (_problem == null) return '';
    if (lang == 'python') {
      final code = _problem!['starter_code_python']?.toString() ??
          _problem!['starter_code']?.toString() ??
          '';
      return code.trim().isNotEmpty
          ? code
          : 'def solve():\n    # Write your solution here\n    pass\n\nif __name__ == "__main__":\n    solve()';
    } else if (lang == 'java') {
      final code = _problem!['starter_code_java']?.toString() ?? '';
      return code.trim().isNotEmpty
          ? code
          : 'import java.util.*;\n\npublic class Main {\n    public static void main(String[] args) {\n        // Write your solution here\n    }\n}';
    } else if (lang == 'cpp') {
      final code = _problem!['starter_code_cpp']?.toString() ?? '';
      return code.trim().isNotEmpty
          ? code
          : '#include <iostream>\nusing namespace std;\n\nint main() {\n    // Write your solution here\n    return 0;\n}';
    }
    return '';
  }

  Future<void> _loadProblem() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) throw Exception('Authentication required');

      final res = await ApiClient.getCustomProblemById(
        accessToken: token,
        problemId: widget.problemId,
      );
      if (mounted) {
        setState(() {
          _problem = res;
          _codePerLanguage['python'] = _getStarterCodeForLanguage('python');
          _codePerLanguage['java'] = _getStarterCodeForLanguage('java');
          _codePerLanguage['cpp'] = _getStarterCodeForLanguage('cpp');
          _codeController.text = _codePerLanguage[_selectedLanguage] ?? '';
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

  Future<void> _runCode() async {
    setState(() {
      _isRunning = true;
      _executionResult = null;
      _verdict = null;
      _activeTab = 1;
    });

    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) throw Exception('Authentication required');

      final res = await ApiClient.runProblemTrial(
        accessToken: token,
        problemId: widget.problemId,
        code: _codeController.text,
        language: _selectedLanguage,
      );

      if (mounted) {
        setState(() {
          _executionResult = res;
          _verdict = res['verdict']?.toString();
          _isRunning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _executionResult = {'error': e.toString().replaceAll('Exception: ', '')};
          _verdict = 'ERROR';
          _isRunning = false;
        });
      }
    }
  }

  Future<void> _submitSolution() async {
    setState(() {
      _isSubmitting = true;
      _executionResult = null;
      _verdict = null;
      _activeTab = 1;
    });

    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) throw Exception('Authentication required');

      final res = await ApiClient.submitProblemSolution(
        accessToken: token,
        problemId: widget.problemId,
        code: _codeController.text,
        language: _selectedLanguage,
      );

      if (mounted) {
        final verdict = res['verdict']?.toString() ?? 'AC';
        setState(() {
          _executionResult = res;
          _verdict = verdict;
          _isSubmitting = false;
        });

        if (verdict == 'AC') {
          _showAcceptedDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _executionResult = {'error': e.toString().replaceAll('Exception: ', '')};
          _verdict = 'ERROR';
          _isSubmitting = false;
        });
      }
    }
  }

  void _showAcceptedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 28),
            ),
            const SizedBox(width: 12),
            const Text('Accepted! 🎉', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Congratulations! Your solution passed all test cases. Your homework progress has been marked as complete.',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            child: const Text('Awesome'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Problem Workspace')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade400),
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Colors.red.shade700)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadProblem, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final title = _problem?['title']?.toString() ?? 'Custom Coding Problem';
    final desc = _problem?['description']?.toString() ?? '';
    final teacherName = _problem?['teacher_name']?.toString() ?? 'Educator';
    final testCases = (_problem?['test_cases'] as List<dynamic>?) ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
            ),
            Text(
              'Authored by $teacherName',
              style: TextStyle(fontSize: 12, color: Colors.purple.shade200),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedLanguage,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                items: const [
                  DropdownMenuItem(value: 'python', child: Text('Python 3')),
                  DropdownMenuItem(value: 'java', child: Text('Java')),
                  DropdownMenuItem(value: 'cpp', child: Text('C++')),
                ],
                onChanged: (val) {
                  if (val != null && val != _selectedLanguage) {
                    setState(() {
                      _codePerLanguage[_selectedLanguage] = _codeController.text;
                      _selectedLanguage = val;
                      _codeController.text = _codePerLanguage[val] ?? _getStarterCodeForLanguage(val);
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          if (isWide) {
            return Row(
              children: [
                Expanded(
                  flex: 5,
                  child: _buildDescriptionPane(title, desc, teacherName, testCases),
                ),
                Container(width: 1, color: Colors.white12),
                Expanded(
                  flex: 6,
                  child: _buildCodeEditorPane(),
                ),
              ],
            );
          } else {
            return Column(
              children: [
                Container(
                  color: const Color(0xFF1E293B),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => setState(() => _activeTab = 0),
                          icon: const Icon(Icons.description_outlined, size: 18),
                          label: const Text('Description'),
                          style: TextButton.styleFrom(
                            foregroundColor: _activeTab == 0 ? Colors.white : Colors.white60,
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => setState(() => _activeTab = 1),
                          icon: const Icon(Icons.terminal_rounded, size: 18),
                          label: const Text('Output & Editor'),
                          style: TextButton.styleFrom(
                            foregroundColor: _activeTab == 1 ? Colors.white : Colors.white60,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _activeTab == 0
                      ? _buildDescriptionPane(title, desc, teacherName, testCases)
                      : _buildCodeEditorPane(),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildDescriptionPane(
    String title,
    String desc,
    String teacherName,
    List<dynamic> testCases,
  ) {
    return Container(
      color: const Color(0xFF0F172A),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.shade900.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.terminal_rounded, color: Colors.purple.shade300, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12),
          const SizedBox(height: 16),
          const Text(
            'Problem Statement',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFFCBD5E1),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Sample Test Cases',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          ...testCases.where((tc) => tc['is_hidden'] != true).map((tc) {
            final input = tc['input']?.toString() ?? '';
            final expected = tc['expected']?.toString() ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Input:', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(input, style: const TextStyle(fontFamily: 'monospace', color: Colors.white, fontSize: 13)),
                  const SizedBox(height: 8),
                  const Text('Expected Output:', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(expected, style: const TextStyle(fontFamily: 'monospace', color: Color(0xFF10B981), fontSize: 13)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCodeEditorPane() {
    return Column(
      children: [
        // Editor Action Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: const Color(0xFF1E293B),
          child: Row(
            children: [
              const Icon(Icons.code_rounded, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              const Text('Source Code', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _isRunning || _isSubmitting ? null : _runCode,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.amber,
                  side: const BorderSide(color: Colors.amber),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                icon: _isRunning
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber))
                    : const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('Run Code', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: _isRunning || _isSubmitting ? null : _submitSolution,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                icon: _isSubmitting
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.cloud_upload_rounded, size: 18),
                label: const Text('Submit', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),

        // Text Editor
        Expanded(
          flex: 6,
          child: Container(
            color: const Color(0xFF0F172A),
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _codeController,
              maxLines: null,
              expands: true,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                color: Color(0xFFF1F5F9),
                height: 1.4,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Type your code here...',
                hintStyle: TextStyle(color: Colors.white30),
              ),
            ),
          ),
        ),

        // Output Console Tray
        if (_executionResult != null || _isRunning || _isSubmitting) ...[
          Container(height: 1, color: Colors.white12),
          Expanded(
            flex: 4,
            child: Container(
              color: const Color(0xFF1E293B),
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  Row(
                    children: [
                      Text(
                        'VERDICT: ${_verdict ?? "RUNNING..."}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: _verdict == 'AC'
                              ? const Color(0xFF10B981)
                              : (_verdict == 'WA' ? Colors.red : Colors.amber),
                        ),
                      ),
                      const Spacer(),
                      if (_executionResult?['execution_time_ms'] != null)
                        Text(
                          'Time: ${_executionResult!['execution_time_ms']}ms',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_executionResult?['error'] != null)
                    Text(
                      _executionResult!['error'].toString(),
                      style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace', fontSize: 13),
                    ),
                  if (_executionResult?['compile_output'] != null)
                    Text(
                      _executionResult!['compile_output'].toString(),
                      style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace', fontSize: 13),
                    ),
                  if (_executionResult?['test_results'] != null) ...[
                    const SizedBox(height: 8),
                    ...(_executionResult!['test_results'] as List).map((tr) {
                      final passed = tr['passed'] == true;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: passed ? const Color(0xFF064E3B) : const Color(0xFF7F1D1D),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
                              size: 16,
                              color: passed ? const Color(0xFF34D399) : const Color(0xFFF87171),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Test #${tr['test_index']}: ${passed ? "Passed" : "Failed (${tr['error_message'] ?? 'Wrong Answer'})"}',
                              style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
