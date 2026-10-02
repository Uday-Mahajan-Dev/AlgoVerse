import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic>? initialUserData;

  const EditProfilePage({super.key, this.initialUserData});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;
  late final TextEditingController _instagramController;
  late final TextEditingController _linkedinController;
  late final TextEditingController _countryController;

  DateTime? _selectedDob;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final data = widget.initialUserData ?? {};
    _firstNameController = TextEditingController(text: data['first_name']?.toString() ?? '');
    _lastNameController = TextEditingController(text: data['last_name']?.toString() ?? '');
    _usernameController = TextEditingController(text: data['username']?.toString() ?? '');
    _bioController = TextEditingController(text: data['bio']?.toString() ?? '');
    _instagramController = TextEditingController(text: data['instagram_url']?.toString() ?? '');
    _linkedinController = TextEditingController(text: data['linkedin_url']?.toString() ?? '');
    _countryController = TextEditingController(text: data['country']?.toString() ?? '');

    final dobStr = data['date_of_birth']?.toString();
    if (dobStr != null && dobStr.isNotEmpty) {
      _selectedDob = DateTime.tryParse(dobStr);
    }

    if (widget.initialUserData == null) {
      _fetchCurrentUserData();
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _instagramController.dispose();
    _linkedinController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentUserData() async {
    setState(() => _isLoading = true);
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null || token.isEmpty) return;

      final user = await ApiClient.me(token);
      if (!mounted) return;

      setState(() {
        _firstNameController.text = user['first_name']?.toString() ?? '';
        _lastNameController.text = user['last_name']?.toString() ?? '';
        _usernameController.text = user['username']?.toString() ?? '';
        _bioController.text = user['bio']?.toString() ?? '';
        _instagramController.text = user['instagram_url']?.toString() ?? '';
        _linkedinController.text = user['linkedin_url']?.toString() ?? '';
        _countryController.text = user['country']?.toString() ?? '';

        final dobStr = user['date_of_birth']?.toString();
        if (dobStr != null && dobStr.isNotEmpty) {
          _selectedDob = DateTime.tryParse(dobStr);
        }
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDob() async {
    final now = DateTime.now();
    final initial = _selectedDob ?? DateTime(now.year - 20, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1930),
      lastDate: now,
      helpText: 'Select Date of Birth',
    );

    if (picked != null) {
      setState(() => _selectedDob = picked);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        throw Exception('Not authenticated.');
      }

      String? dobFormatted;
      if (_selectedDob != null) {
        final y = _selectedDob!.year.toString().padLeft(4, '0');
        final m = _selectedDob!.month.toString().padLeft(2, '0');
        final d = _selectedDob!.day.toString().padLeft(2, '0');
        dobFormatted = '$y-$m-$d';
      }

      await ApiClient.updateProfile(
        accessToken: token,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        username: _usernameController.text.trim(),
        bio: _bioController.text.trim(),
        country: _countryController.text.trim(),
        dateOfBirth: dobFormatted,
        instagramUrl: _instagramController.text.trim(),
        linkedinUrl: _linkedinController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '').trim();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline_rounded,
                                      color: Colors.red.shade700, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(
                                          color: Colors.red.shade800,
                                          fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Names Row
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFieldLabel('First Name'),
                                    TextFormField(
                                      controller: _firstNameController,
                                      decoration: _inputDecoration(
                                        hint: 'e.g. Alex',
                                        prefixIcon: Icons.person_outline_rounded,
                                      ),
                                      validator: (v) => (v == null || v.trim().isEmpty)
                                          ? 'First name required'
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFieldLabel('Last Name'),
                                    TextFormField(
                                      controller: _lastNameController,
                                      decoration: _inputDecoration(
                                        hint: 'e.g. Mercer',
                                        prefixIcon: Icons.person_outline_rounded,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Username
                          _buildFieldLabel('Username'),
                          TextFormField(
                            controller: _usernameController,
                            decoration: _inputDecoration(
                              hint: 'username',
                              prefixIcon: Icons.alternate_email_rounded,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Username is required';
                              }
                              if (v.trim().length < 3) {
                                return 'Username must be at least 3 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),

                          // Date of Birth Field
                          _buildFieldLabel('Date of Birth'),
                          InkWell(
                            onTap: _selectDob,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(14),
                                color: Colors.grey.shade50,
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.cake_outlined,
                                      color: Colors.indigo, size: 20),
                                  const SizedBox(width: 12),
                                  Text(
                                    _selectedDob != null
                                        ? '${_selectedDob!.year}-${_selectedDob!.month.toString().padLeft(2, '0')}-${_selectedDob!.day.toString().padLeft(2, '0')}'
                                        : 'Select Date of Birth',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _selectedDob != null
                                          ? const Color(0xFF1E293B)
                                          : Colors.grey.shade500,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(Icons.calendar_month_rounded,
                                      size: 18, color: Colors.grey.shade600),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Bio
                          _buildFieldLabel('Bio'),
                          TextFormField(
                            controller: _bioController,
                            maxLines: 3,
                            decoration: _inputDecoration(
                              hint: 'Share a little about yourself, coding interests, or university...',
                              prefixIcon: null,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Social Links Header
                          Row(
                            children: [
                              const Icon(Icons.link_rounded,
                                  color: Colors.indigo, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'SOCIAL & PROFESSIONAL LINKS',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Instagram URL
                          _buildFieldLabel('Instagram Profile URL'),
                          TextFormField(
                            controller: _instagramController,
                            decoration: _inputDecoration(
                              hint: 'https://instagram.com/yourhandle',
                              prefixIcon: Icons.camera_alt_outlined,
                            ),
                          ),
                          const SizedBox(height: 18),

                          // LinkedIn URL
                          _buildFieldLabel('LinkedIn Profile URL'),
                          TextFormField(
                            controller: _linkedinController,
                            decoration: _inputDecoration(
                              hint: 'https://linkedin.com/in/yourprofile',
                              prefixIcon: Icons.business_center_outlined,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Save Button
                          SizedBox(
                            height: 52,
                            child: FilledButton.icon(
                              onPressed: _isSaving ? null : _saveProfile,
                              style: FilledButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.check_rounded),
                              label: Text(
                                _isSaving ? 'Saving Changes...' : 'Save Profile',
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

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
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
