import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../auth/data/social_auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;
  bool _isLoggingOut = false;
  String? _errorMessage;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        throw Exception('Not authenticated. Please log in.');
      }

      final data = await ApiClient.me(token);
      if (mounted) {
        setState(() {
          _userData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      final refreshToken = await TokenStorage.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          await ApiClient.logout(refreshToken);
        } catch (_) {}
      }

      try {
        await SocialAuthService.signOut();
      } catch (_) {}

      await TokenStorage.clear();

      if (!mounted) return;

      context.go(AppRoutes.login);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoggingOut = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to logout. Please try again.')),
      );
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toUpperCase()) {
      case 'TEACHER':
        return Colors.purple;
      case 'ADMIN':
        return Colors.amber.shade800;
      case 'STUDENT':
      default:
        return Colors.indigo;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              size: 48, color: Colors.red),
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _loadUserProfile,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildProfileHeader(theme),
                            const SizedBox(height: 24),
                            _buildEducatorSection(theme),
                            const SizedBox(height: 24),
                            _buildLogoutButton(),
                          ],
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme) {
    final username = _userData?['username']?.toString() ?? 'User';
    final firstName = _userData?['first_name']?.toString() ?? '';
    final lastName = _userData?['last_name']?.toString() ?? '';
    final fullName = ('$firstName $lastName').trim().isNotEmpty
        ? ('$firstName $lastName').trim()
        : username;
    final email = _userData?['email']?.toString() ?? '';
    final roleName = _userData?['role_name']?.toString() ?? 'STUDENT';
    final roleColor = _getRoleColor(roleName);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 44,
              backgroundColor: roleColor.withValues(alpha: 0.15),
              child: Text(
                fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: roleColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              fullName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '@$username',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: roleColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    roleName.toUpperCase() == 'TEACHER'
                        ? Icons.school_rounded
                        : Icons.person_rounded,
                    size: 16,
                    color: roleColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'CURRENT ROLE: ${roleName.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: roleColor,
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

  Widget _buildEducatorSection(ThemeData theme) {
    final roleName =
        (_userData?['role_name']?.toString() ?? 'STUDENT').toUpperCase();
    final isTeacher = roleName == 'TEACHER';
    final classCode = _userData?['class_code']?.toString();
    final institutionName =
        _userData?['institution_name']?.toString() ?? 'AlgoVerse Faculty';
    final subjectExpertise = _userData?['subject_expertise']?.toString() ??
        'Data Structures & Algorithms';

    if (isTeacher) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.purple.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                    child: const Icon(Icons.verified_rounded,
                        color: Colors.purple),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verified Educator Account',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Manage your classroom, track bottlenecks, and assign homework',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (classCode != null && classCode.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'YOUR CLASS JOINING CODE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                              color: Colors.purple.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            classCode,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                      IconButton.filledTonal(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: classCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Class Code copied to clipboard!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        tooltip: 'Copy Code',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Institution: $institutionName • Focus: $subjectExpertise',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
              ],
            ],
          ),
        ),
      );
    }

    // Student -> Show "Become an Educator" Card
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.indigo),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Become an Educator',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Self-serve onboarding for professors, instructors, and TAs',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Register as an educator to generate your unique Class Joining Code, assign interactive coding homework, and monitor real-time student learning bottlenecks.',
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade700, height: 1.4),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.push(AppRoutes.becomeEducator),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.assignment_ind_outlined),
                label: const Text(
                  'Register as Educator (Get Class Code)',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return OutlinedButton.icon(
      onPressed: _isLoggingOut ? null : _logout,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red.shade700,
        side: BorderSide(color: Colors.red.shade300),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      icon: _isLoggingOut
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
            )
          : const Icon(Icons.logout_rounded),
      label: const Text(
        'Logout from AlgoVerse',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
