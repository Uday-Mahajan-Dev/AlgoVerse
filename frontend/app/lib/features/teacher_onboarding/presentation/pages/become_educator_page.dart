import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';

class BecomeEducatorPage extends StatefulWidget {
  const BecomeEducatorPage({super.key});

  @override
  State<BecomeEducatorPage> createState() => _BecomeEducatorPageState();
}

class _BecomeEducatorPageState extends State<BecomeEducatorPage> {
  final _formKey = GlobalKey<FormState>();
  final _institutionController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bioController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _institutionController.dispose();
    _subjectController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        throw Exception('Not authenticated. Please log in first.');
      }

      final res = await ApiClient.registerEducator(
        accessToken: token,
        institutionName: _institutionController.text.trim(),
        subjectExpertise: _subjectController.text.trim(),
        bio: _bioController.text.trim(),
      );

      if (!mounted) return;

      final classCode = res['class_code']?.toString() ?? '';

      // Show congratulations dialog with Class Code
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.verified_rounded, color: Colors.purple, size: 28),
              SizedBox(width: 10),
              Text('Welcome, Educator!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your educator profile is now active. Share your unique Class Code with your students so they can join your class:',
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      classCode,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: Colors.purple,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, color: Colors.purple),
                      tooltip: 'Copy Class Code',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: classCode));
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Class Code copied to clipboard!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your teacher dashboard will automatically populate as students join your class.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.purple),
              onPressed: () {
                Navigator.of(ctx).pop();
                context.go('/teacher-dashboard');
              },
              child: const Text('Go to Teacher Dashboard'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '').trim()),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Become an Educator'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Banner Header
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.shade900,
                            Colors.purple.shade700,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.school_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Text(
                                  'Join AlgoVerse Faculty',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Empower your students with live algorithm visualizations, track student bottlenecks, and assign custom homework sets.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Institution Name Field
                    Text(
                      'Institution / Organization',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _institutionController,
                      decoration: InputDecoration(
                        hintText: 'e.g. VIT University, MIT, Indian Institute of Tech',
                        prefixIcon: const Icon(Icons.account_balance_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your university or institution name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Subject Expertise Field
                    Text(
                      'Subject / Domain Expertise',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _subjectController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Advanced Data Structures, Graph Algorithms',
                        prefixIcon: const Icon(Icons.code_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your teaching domain or expertise';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Professional Bio Field
                    Text(
                      'Professional Bio (Optional)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _bioController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Brief summary of your teaching background or research focus...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _isSubmitting ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.purple.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_circle_outline_rounded),
                        label: Text(
                          _isSubmitting
                              ? 'Creating Educator Profile...'
                              : 'Create Educator Profile & Get Class Code',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
