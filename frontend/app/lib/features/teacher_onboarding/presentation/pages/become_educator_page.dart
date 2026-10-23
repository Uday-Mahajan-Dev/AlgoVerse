import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/dob_constants.dart';
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
  final _supervisorEmailController = TextEditingController();

  DateTime? _selectedDob;
  String _selectedDesignation = 'Professor';

  bool _isSubmitting = false;
  bool _isLoadingUser = true;
  bool _hasProfileDob = false;
  bool _isDobLocked = false;
  Map<String, dynamic>? _userData;

  final List<String> _allDesignations = [
    'Professor',
    'Assistant Professor',
    'Industry Educator',
    'Teaching Assistant',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoadingUser = true);
    try {
      final token = await TokenStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        final user = await ApiClient.me(token);
        _userData = user;
        final dobStr = user['date_of_birth']?.toString();
        if (dobStr != null && dobStr.isNotEmpty) {
          _selectedDob = DateTime.tryParse(dobStr);
          _hasProfileDob = true;
        }
        _isDobLocked = user['is_dob_locked'] == true;
        if (_isUnder25) {
          _selectedDesignation = 'Teaching Assistant';
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoadingUser = false);
    }
  }

  @override
  void dispose() {
    _institutionController.dispose();
    _subjectController.dispose();
    _bioController.dispose();
    _supervisorEmailController.dispose();
    super.dispose();
  }

  int? get _computedAge {
    return DobConstants.computeAge(_selectedDob);
  }

  bool get _isUnder25 {
    final age = _computedAge;
    return age != null && age <= 25;
  }

  bool get _requiresSupervisor {
    return _isUnder25 || _selectedDesignation == 'Teaching Assistant';
  }

  Future<void> _pickDateOfBirth() async {
    final initialDate = DobConstants.initialPickerDate(_selectedDob);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DobConstants.minBirthDate,
      lastDate: DobConstants.maxBirthDate,
      helpText: 'Select Date of Birth',
    );

    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        if (_isUnder25) {
          _selectedDesignation = 'Teaching Assistant';
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedDob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your Date of Birth before submitting.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!DobConstants.isWithinRange(_selectedDob!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Age must be between 17 and 80 years old.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        throw Exception('Not authenticated. Please log in first.');
      }

      final y = _selectedDob!.year.toString().padLeft(4, '0');
      final m = _selectedDob!.month.toString().padLeft(2, '0');
      final d = _selectedDob!.day.toString().padLeft(2, '0');
      final dobStr = '$y-$m-$d';

      if (!_hasProfileDob) {
        await ApiClient.updateProfile(
          accessToken: token,
          dateOfBirth: dobStr,
          dobSource: 'MANUAL',
        );
      }

      final requestedRole = _selectedDesignation == 'Teaching Assistant'
          ? 'ASSISTANT'
          : 'PROFESSOR';

      await ApiClient.applyEducatorApplication(
        accessToken: token,
        requestedRole: requestedRole,
        dateOfBirth: dobStr,
        institutionName: _institutionController.text.trim(),
        designation: _selectedDesignation,
        subjectExpertise: _subjectController.text.trim(),
        bio: _bioController.text.trim(),
        supervisorEmail: _requiresSupervisor
            ? _supervisorEmailController.text.trim()
            : null,
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.hourglass_top_rounded, color: Colors.purple, size: 28),
              SizedBox(width: 10),
              Text('Application Submitted'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your educator application is under admin review.',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, height: 1.4),
              ),
              SizedBox(height: 10),
              Text(
                'Once approved by an administrator, your educator role and class code will become active.',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
            ],
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.purple),
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop(true);
              },
              child: const Text('Understood'),
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
    if (_isLoadingUser) {
      return Scaffold(
        appBar: AppBar(title: const Text('Become an Educator')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final age = _computedAge;

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
                    const SizedBox(height: 24),

                    // Institution Name Field
                    _buildLabel('Institution / University *'),
                    TextFormField(
                      controller: _institutionController,
                      decoration: _inputDecoration(
                        hint: 'e.g. Stanford University, MIT, VIT',
                        prefixIcon: Icons.account_balance_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your university or institution name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // Date of Birth Field
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildLabel('Date of Birth *'),
                        if (_hasProfileDob)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.purple.shade200),
                            ),
                            child: const Text(
                              'From your profile',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (_hasProfileDob) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.purple.shade200),
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.purple.shade50.withValues(alpha: 0.3),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.cake_outlined, color: Colors.purple, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedDob != null
                                    ? '${_selectedDob!.year}-${_selectedDob!.month.toString().padLeft(2, '0')}-${_selectedDob!.day.toString().padLeft(2, '0')} (Age: $age)'
                                    : 'Profile DOB',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () async {
                                if (_isDobLocked) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Contact admin to change date of birth.'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }
                                await context.push(AppRoutes.editProfile, extra: _userData);
                                _loadUserProfile();
                              },
                              icon: Icon(
                                _isDobLocked ? Icons.lock_rounded : Icons.edit_outlined,
                                size: 14,
                                color: _isDobLocked ? Colors.amber.shade800 : Colors.purple,
                              ),
                              label: Text(
                                _isDobLocked ? 'Locked' : 'Edit in profile',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _isDobLocked ? Colors.amber.shade800 : Colors.purple,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      InkWell(
                        onTap: _pickDateOfBirth,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _selectedDob == null ? Colors.grey.shade400 : Colors.purple.shade400,
                              width: _selectedDob == null ? 1 : 1.5,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            color: Colors.grey.shade50,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.cake_outlined, color: Colors.purple, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                _selectedDob != null
                                    ? '${_selectedDob!.year}-${_selectedDob!.month.toString().padLeft(2, '0')}-${_selectedDob!.day.toString().padLeft(2, '0')} (Age: $age)'
                                    : 'Select Date of Birth (Required)',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _selectedDob != null ? const Color(0xFF1E293B) : Colors.grey.shade600,
                                  fontWeight: _selectedDob != null ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.calendar_month_rounded, size: 18, color: Colors.purple),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),

                    // Age Gate Notice Banner (if under 25)
                    if (_isUnder25) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.shield_outlined, color: Colors.amber.shade900, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Teaching Assistant (TA) Pathway Required',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF78350F),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Educators under 25 years old ($age yrs) must register through the Teaching Assistant pathway with supervisor professor approval.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.amber.shade900,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Designation Dropdown
                    _buildLabel('Designation / Academic Role *'),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedDesignation,
                      decoration: _inputDecoration(
                        hint: 'Select designation',
                        prefixIcon: Icons.badge_outlined,
                      ),
                      items: _allDesignations.map((d) {
                        final isDisabled = _isUnder25 && d != 'Teaching Assistant';
                        return DropdownMenuItem<String>(
                          value: d,
                          enabled: !isDisabled,
                          child: Text(
                            d + (isDisabled ? ' (Requires age ≥ 25)' : ''),
                            style: TextStyle(
                              color: isDisabled ? Colors.grey : const Color(0xFF1E293B),
                              fontSize: 14,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: _isUnder25
                          ? null
                          : (val) {
                              if (val != null) {
                                setState(() => _selectedDesignation = val);
                              }
                            },
                    ),
                    const SizedBox(height: 18),

                    // Supervisor Email Field (Shown if under 25 or TA)
                    if (_requiresSupervisor) ...[
                      _buildLabel('Supervising Professor Email *'),
                      TextFormField(
                        controller: _supervisorEmailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _inputDecoration(
                          hint: 'e.g. professor@university.edu',
                          prefixIcon: Icons.email_outlined,
                        ),
                        validator: (value) {
                          if (!_requiresSupervisor) return null;
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your supervising professor\'s email address';
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Your supervisor must have an active Educator account on AlgoVerse to approve your request.',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Subject Expertise Field
                    _buildLabel('Subject / Domain Expertise *'),
                    TextFormField(
                      controller: _subjectController,
                      decoration: _inputDecoration(
                        hint: 'e.g. Data Structures & Algorithms, Graph Theory',
                        prefixIcon: Icons.code_rounded,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your teaching domain or expertise';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // Professional Bio Field
                    _buildLabel('Professional Bio (Optional)'),
                    TextFormField(
                      controller: _bioController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Brief summary of your teaching background, lab, or research focus...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
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
                              ? 'Processing Application...'
                              : (_requiresSupervisor
                                  ? 'Submit TA Application for Review'
                                  : 'Create Educator Profile & Get Class Code'),
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      prefixIcon: Icon(prefixIcon, size: 20),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }
}
