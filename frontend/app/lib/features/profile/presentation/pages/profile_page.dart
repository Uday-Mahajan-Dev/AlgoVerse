import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _isLoading = true;
  bool _isLoggingOut = false;
  String? _errorMessage;
  bool _isAuthError = false;
  Map<String, dynamic>? _userData;
  List<dynamic> _badges = [];

  @override
  void initState() {
    super.initState();
    _loadProfileAndBadges();
  }

  Future<void> _loadProfileAndBadges() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isAuthError = false;
    });

    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        if (mounted) {
          setState(() {
            _errorMessage = 'You are not logged in. Please sign in to view your profile.';
            _isAuthError = true;
            _isLoading = false;
          });
        }
        return;
      }

      final data = await ApiClient.me(token);
      List<dynamic> badges = [];
      try {
        badges = await ApiClient.getMyBadges(token);
      } catch (_) {
        badges = [];
      }

      if (mounted) {
        setState(() {
          _userData = data;
          _badges = badges;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final errText = e.toString().replaceFirst('Exception: ', '');
        final isAuth = errText.toLowerCase().contains('401') ||
            errText.toLowerCase().contains('unauthorized') ||
            errText.toLowerCase().contains('not authenticated') ||
            errText.toLowerCase().contains('session expired');

        setState(() {
          _errorMessage = isAuth
              ? 'Your session has expired. Please log in again.'
              : errText;
          _isAuthError = isAuth;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openUrl(String url) async {
    String formattedUrl = url.trim();
    if (!formattedUrl.startsWith('http://') && !formattedUrl.startsWith('https://')) {
      formattedUrl = 'https://$formattedUrl';
    }
    final uri = Uri.tryParse(formattedUrl);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        if (!mounted) return;
        Clipboard.setData(ClipboardData(text: formattedUrl));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Link copied to clipboard: $formattedUrl')),
        );
      }
    }
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await ref.read(authNotifierProvider.notifier).logout(context: context);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged out successfully')),
      );
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

  IconData _getBadgeIcon(String iconKey) {
    switch (iconKey.toLowerCase()) {
      case 'rocket':
        return Icons.rocket_launch_rounded;
      case 'book_open':
        return Icons.menu_book_rounded;
      case 'eye':
        return Icons.visibility_rounded;
      case 'check_circle':
        return Icons.check_circle_rounded;
      case 'flame':
        return Icons.local_fire_department_rounded;
      case 'trophy':
        return Icons.emoji_events_rounded;
      case 'layers':
        return Icons.layers_rounded;
      case 'award':
        return Icons.military_tech_rounded;
      case 'terminal':
        return Icons.terminal_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'users':
        return Icons.groups_rounded;
      case 'clipboard_check':
        return Icons.assignment_turned_in_rounded;
      default:
        return Icons.stars_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Profile',
            onPressed: _loadProfileAndBadges,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isAuthError
                                  ? Icons.lock_person_rounded
                                  : Icons.error_outline_rounded,
                              size: 56,
                              color: _isAuthError ? Colors.amber.shade800 : Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _isAuthError
                                  ? 'Authentication Required'
                                  : 'Unable to Load Profile',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (_isAuthError)
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: FilledButton.icon(
                                  onPressed: () => context.go(AppRoutes.login),
                                  icon: const Icon(Icons.login_rounded),
                                  label: const Text('Go to Login'),
                                ),
                              )
                            else
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: FilledButton.icon(
                                  onPressed: _loadProfileAndBadges,
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text('Retry'),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 680),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,

                          children: [
                            // Pending TA status banner (if applicant)
                            if (_userData?['ta_application_status'] == 'PENDING') ...[
                              _buildPendingTABanner(),
                              const SizedBox(height: 18),
                            ],

                            // Profile Header & Socials
                            _buildProfileHeader(theme),
                            const SizedBox(height: 24),

                            // Achievements & Badges Section
                            _buildBadgesSection(theme),
                            const SizedBox(height: 24),

                            // Educator / Class Code Section
                            _buildEducatorSection(theme),
                            const SizedBox(height: 24),

                            // Logout Button
                            _buildLogoutButton(),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildPendingTABanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.hourglass_top_rounded, color: Colors.amber.shade900, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TA Application Pending Approval',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: const Color(0xFF78350F),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your Teaching Assistant application is currently under review by your supervising professor.',
                  style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                ),
              ],
            ),
          ),
        ],
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
    final bio = _userData?['bio']?.toString();
    final instagramUrl = _userData?['instagram_url']?.toString();
    final linkedinUrl = _userData?['linkedin_url']?.toString();
    final country = _userData?['country']?.toString();

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 40),
                CircleAvatar(
                  radius: 46,
                  backgroundColor: roleColor.withValues(alpha: 0.15),
                  child: Text(
                    fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: roleColor,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () async {
                    final res = await context.push(AppRoutes.editProfile, extra: _userData);
                    if (res == true) {
                      _loadProfileAndBadges();
                    }
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: 'Edit Profile',
                ),
              ],
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
            if (country != null && country.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    country,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
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
                    'ROLE: ${roleName.toUpperCase()}',
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
            if (bio != null && bio.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  bio,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.4),
                ),
              ),
            ],
            if ((instagramUrl != null && instagramUrl.isNotEmpty) ||
                (linkedinUrl != null && linkedinUrl.isNotEmpty)) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  if (instagramUrl != null && instagramUrl.isNotEmpty)
                    ActionChip(
                      avatar: const Icon(Icons.camera_alt_outlined, size: 16, color: Colors.pink),
                      label: const Text('Instagram', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      backgroundColor: Colors.pink.shade50,
                      side: BorderSide(color: Colors.pink.shade200),
                      onPressed: () => _openUrl(instagramUrl),
                    ),
                  if (linkedinUrl != null && linkedinUrl.isNotEmpty)
                    ActionChip(
                      avatar: const Icon(Icons.business_center_outlined, size: 16, color: Colors.blue),
                      label: const Text('LinkedIn', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      backgroundColor: Colors.blue.shade50,
                      side: BorderSide(color: Colors.blue.shade200),
                      onPressed: () => _openUrl(linkedinUrl),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBadgesSection(ThemeData theme) {
    final earnedCount = _badges.where((b) => b['is_earned'] == true).length;
    final totalCount = _badges.isNotEmpty ? _badges.length : 12;

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
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.military_tech_rounded, color: Colors.amber.shade800),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Achievement Badges',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Earn badges as you conquer problems, streaks, and courses',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$earnedCount / $totalCount',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (_badges.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Loading achievement badges...', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 140,
                ),
                itemCount: _badges.length,
                itemBuilder: (context, i) {
                  final badge = _badges[i];
                  final isEarned = badge['is_earned'] == true;
                  final title = badge['title']?.toString() ?? 'Badge';
                  final desc = badge['description']?.toString() ?? '';
                  final iconKey = badge['icon_key']?.toString() ?? 'star';
                  final icon = _getBadgeIcon(iconKey);

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isEarned ? Colors.amber.shade50.withValues(alpha: 0.6) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isEarned ? Colors.amber.shade300 : Colors.grey.shade300,
                        width: isEarned ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: isEarned ? Colors.amber.shade100 : Colors.grey.shade300,
                              child: Icon(
                                icon,
                                size: 18,
                                color: isEarned ? Colors.amber.shade900 : Colors.grey.shade600,
                              ),
                            ),
                            if (isEarned)
                              const Icon(Icons.check_circle_rounded, size: 16, color: Colors.green)
                            else
                              Icon(Icons.lock_outline_rounded, size: 16, color: Colors.grey.shade500),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isEarned ? const Color(0xFF1E293B) : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          desc,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: isEarned ? Colors.grey.shade700 : Colors.grey.shade500,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  );
                },
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
    final designation = _userData?['designation']?.toString() ?? 'Educator';
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verified $designation',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const Text(
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
                onPressed: () async {
                  await context.push(AppRoutes.becomeEducator);
                  _loadProfileAndBadges();
                },
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
