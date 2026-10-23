import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class AdminEducatorsPage extends ConsumerStatefulWidget {
  const AdminEducatorsPage({super.key});

  @override
  ConsumerState<AdminEducatorsPage> createState() => _AdminEducatorsPageState();
}

class _AdminEducatorsPageState extends ConsumerState<AdminEducatorsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Educator Applications state
  bool _isLoadingApps = true;
  String? _errorApps;
  List<dynamic> _applications = [];

  // Faculty Accounts (Phase 7 gate) state
  bool _isLoadingFaculty = true;
  String? _errorFaculty;
  List<dynamic> _educators = [];
  bool _includeAllFaculty = false;

  final Set<String> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadApplications(),
      _loadEducators(),
    ]);
  }

  Future<void> _loadApplications() async {
    setState(() {
      _isLoadingApps = true;
      _errorApps = null;
    });

    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null || token.isEmpty) return;
      final data = await ApiClient.getAdminEducatorApplications(
        accessToken: token,
        status: 'PENDING',
      );
      if (mounted) {
        setState(() {
          _applications = data;
          _isLoadingApps = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorApps = e.toString().replaceAll('Exception: ', '').trim();
          _isLoadingApps = false;
        });
      }
    }
  }

  Future<void> _loadEducators() async {
    setState(() {
      _isLoadingFaculty = true;
      _errorFaculty = null;
    });

    try {
      final token = await TokenStorage.getAccessToken();
      final data = await ApiClient.getPendingEducators(
        accessToken: token,
        includeAll: _includeAllFaculty,
      );
      if (mounted) {
        setState(() {
          _educators = data;
          _isLoadingFaculty = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorFaculty = e.toString().replaceAll('Exception: ', '').trim();
          _isLoadingFaculty = false;
        });
      }
    }
  }

  Future<void> _handleApproveApplication(String applicationId) async {
    setState(() => _processingIds.add(applicationId));

    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null || token.isEmpty) return;
      await ApiClient.approveEducatorApplication(
        applicationId: applicationId,
        accessToken: token,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Educator application approved! Role updated to educator.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      _loadApplications();
      _loadEducators();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Approval failed: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _processingIds.remove(applicationId));
      }
    }
  }

  Future<void> _handleRejectApplication(String applicationId) async {
    final noteController = TextEditingController();
    final shouldReject = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Educator Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Specify an optional note/reason for rejecting this applicant:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. Incomplete credentials or eligibility criteria not met.',
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (shouldReject != true) return;

    setState(() => _processingIds.add(applicationId));

    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null || token.isEmpty) return;
      final note = noteController.text.trim();
      await ApiClient.rejectEducatorApplication(
        applicationId: applicationId,
        accessToken: token,
        adminNote: note.isNotEmpty ? note : null,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Educator application rejected.'),
          backgroundColor: Colors.orange,
        ),
      );
      _loadApplications();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rejection failed: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _processingIds.remove(applicationId));
      }
    }
  }

  Future<void> _handleFacultyAction(String educatorId, bool verify) async {
    setState(() => _processingIds.add(educatorId));

    try {
      final token = await TokenStorage.getAccessToken();
      if (verify) {
        await ApiClient.verifyEducator(educatorId: educatorId, accessToken: token);
      } else {
        await ApiClient.revokeEducator(educatorId: educatorId, accessToken: token);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(verify ? 'Educator verified successfully!' : 'Educator verification revoked.'),
          backgroundColor: verify ? const Color(0xFF10B981) : Colors.orange.shade800,
        ),
      );
      _loadEducators();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Action failed: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _processingIds.remove(educatorId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        titleSpacing: 16,
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.admin_panel_settings_rounded, color: Colors.indigo),
              SizedBox(width: 8),
              Text(
                'Faculty & Educator Admin',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh All',
            onPressed: _loadAll,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: 'Logout',
            onPressed: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Admin Logout'),
                  content: const Text(
                      'Are you sure you want to log out of the admin panel?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      style:
                          FilledButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
              if (shouldLogout == true && context.mounted) {
                await ref.read(authNotifierProvider.notifier).logout(context: context);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.indigo,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: Colors.indigo,
          indicatorWeight: 3,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Pending Applications'),
                  if (_applications.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_applications.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Faculty Accounts'),
                  if (_educators.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_educators.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildApplicationsTab(),
          _buildFacultyAccountsTab(),
        ],
      ),
    );
  }

  Widget _buildApplicationsTab() {
    if (_isLoadingApps) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorApps != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade400),
              const SizedBox(height: 12),
              Text(_errorApps!, textAlign: TextAlign.center, style: TextStyle(color: Colors.red.shade700)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadApplications, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_applications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle_outline_rounded, size: 56, color: Colors.green.shade600),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Pending Applications',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 6),
              Text(
                'All educator onboarding requests have been reviewed.',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _applications.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final app = _applications[index] as Map<String, dynamic>;
        final id = app['id']?.toString() ?? '';
        final name = app['applicant_name']?.toString() ?? 'Applicant';
        final email = app['applicant_email']?.toString() ?? '';
        final requestedRole = app['requested_role']?.toString() ?? 'ASSISTANT';
        final age = app['age_at_application']?.toString() ?? 'N/A';
        final dob = app['date_of_birth_at_application']?.toString() ?? '';
        final institution = app['institution_name']?.toString() ?? 'Unknown Institution';
        final designation = app['designation']?.toString() ?? 'Educator';
        final expertise = app['subject_expertise']?.toString() ?? '';
        final bio = app['bio']?.toString() ?? '';
        final createdAt = app['created_at']?.toString() ?? '';
        final formattedDate = createdAt.length >= 10 ? createdAt.substring(0, 10) : createdAt;
        final isProcessing = _processingIds.contains(id);

        final isProfessor = requestedRole.toUpperCase() == 'PROFESSOR';

        return Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.amber.shade300, width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.amber.shade100,
                      child: Icon(
                        isProfessor ? Icons.school_rounded : Icons.assistant_rounded,
                        color: Colors.amber.shade900,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isProfessor ? Colors.purple.shade50 : Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isProfessor ? Colors.purple.shade300 : Colors.blue.shade300,
                                  ),
                                ),
                                child: Text(
                                  requestedRole.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isProfessor ? Colors.purple.shade900 : Colors.blue.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(email, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.cake_outlined, size: 13, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text('Age: $age yrs ($dob)', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              const SizedBox(width: 12),
                              Icon(Icons.calendar_today_outlined, size: 13, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text('Applied: $formattedDate', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.business_rounded, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text('$institution • $designation', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
                      ],
                    ),
                    if (expertise.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_stories_rounded, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(expertise, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                        ],
                      ),
                  ],
                ),
                if (bio.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      bio,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isProcessing)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    else ...[
                      OutlinedButton.icon(
                        onPressed: () => _handleRejectApplication(id),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(color: Colors.red.shade300),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const Text('Reject', style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        onPressed: () => _handleApproveApplication(id),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('Approve', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFacultyAccountsTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              Icon(Icons.filter_list_rounded, size: 18, color: Colors.grey.shade700),
              const SizedBox(width: 8),
              Text(
                _includeAllFaculty ? 'All Faculty' : 'Pending Only',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const Spacer(),
              Switch(
                value: _includeAllFaculty,
                activeThumbColor: Colors.indigo,
                onChanged: (val) {
                  setState(() => _includeAllFaculty = val);
                  _loadEducators();
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _loadEducators,
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
        Expanded(child: _buildFacultyBody()),
      ],
    );
  }

  Widget _buildFacultyBody() {
    if (_isLoadingFaculty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorFaculty != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade400),
              const SizedBox(height: 12),
              Text(_errorFaculty!, textAlign: TextAlign.center, style: TextStyle(color: Colors.red.shade700)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadEducators, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_educators.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.verified_user_rounded, size: 56, color: Colors.green.shade600),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Pending Faculty',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 6),
              Text(
                'All faculty accounts have been reviewed and verified.',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _educators.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final edu = _educators[index] as Map<String, dynamic>;
        final id = edu['id']?.toString() ?? edu['user_id']?.toString() ?? '';
        final name = edu['name']?.toString() ?? 'Faculty Applicant';
        final email = edu['email']?.toString() ?? '';
        final institution = edu['institution']?.toString() ?? 'Unknown Institution';
        final isVerified = edu['is_verified'] as bool? ?? false;
        final appliedAt = edu['applied_at']?.toString() ?? '';
        final isProcessing = _processingIds.contains(id);

        return Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isVerified ? const Color(0xFFE2E8F0) : Colors.amber.shade300,
              width: isVerified ? 1 : 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: isVerified ? Colors.green.shade100 : Colors.amber.shade100,
                  child: Icon(
                    isVerified ? Icons.verified_rounded : Icons.pending_rounded,
                    color: isVerified ? Colors.green.shade800 : Colors.amber.shade900,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isVerified ? Colors.green.shade50 : Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isVerified ? Colors.green.shade300 : Colors.amber.shade400,
                              ),
                            ),
                            child: Text(
                              isVerified ? 'VERIFIED' : 'PENDING',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isVerified ? Colors.green.shade800 : Colors.amber.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(email, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.school_outlined, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              institution,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (appliedAt.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Applied: ${appliedAt.split('T').first}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (isProcessing)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else
                  Column(
                    children: [
                      if (!isVerified)
                        FilledButton.icon(
                          onPressed: () => _handleFacultyAction(id, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: const Text('Verify', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        )
                      else
                        OutlinedButton.icon(
                          onPressed: () => _handleFacultyAction(id, false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                            side: BorderSide(color: Colors.red.shade300),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          icon: const Icon(Icons.block_rounded, size: 14),
                          label: const Text('Revoke', style: TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
