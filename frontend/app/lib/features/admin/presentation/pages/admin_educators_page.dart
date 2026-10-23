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

class _AdminEducatorsPageState extends ConsumerState<AdminEducatorsPage> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _educators = [];
  bool _includeAll = false;
  final Set<String> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _loadEducators();
  }

  Future<void> _loadEducators() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await TokenStorage.getAccessToken();
      final data = await ApiClient.getPendingEducators(
        accessToken: token,
        includeAll: _includeAll,
      );
      if (mounted) {
        setState(() {
          _educators = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '').trim();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleAction(String educatorId, bool verify) async {
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
                'Faculty Verification Gate',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
        ),
        actions: [
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
                await ref.read(authProvider.notifier).logout(context: context);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter & Control Bar below AppBar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Icon(Icons.filter_list_rounded,
                    size: 18, color: Colors.grey.shade700),
                const SizedBox(width: 8),
                Text(
                  _includeAll ? 'All Faculty' : 'Pending Only',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: _includeAll,
                  activeThumbColor: Colors.indigo,
                  onChanged: (val) {
                    setState(() => _includeAll = val);
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
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade400),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.red.shade700)),
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
                'No Pending Educators',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 6),
              Text(
                'All faculty applicants have been reviewed and verified.',
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
                          onPressed: () => _handleAction(id, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: const Text('Verify', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        )
                      else
                        OutlinedButton.icon(
                          onPressed: () => _handleAction(id, false),
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
