import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../providers/teacher_provider.dart';

class ProfessorRatingSheet extends ConsumerStatefulWidget {
  final String teacherId;
  final String teacherName;
  final VoidCallback? onSubmitted;

  const ProfessorRatingSheet({
    super.key,
    required this.teacherId,
    required this.teacherName,
    this.onSubmitted,
  });

  static Future<void> show(
    BuildContext context, {
    required String teacherId,
    required String teacherName,
    VoidCallback? onSubmitted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ProfessorRatingSheet(
        teacherId: teacherId,
        teacherName: teacherName,
        onSubmitted: onSubmitted,
      ),
    );
  }

  @override
  ConsumerState<ProfessorRatingSheet> createState() =>
      _ProfessorRatingSheetState();
}

class _ProfessorRatingSheetState extends ConsumerState<ProfessorRatingSheet> {
  int _selectedRating = 5;
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = true;
  bool _isSubmitting = false;
  double _avgRating = 0.0;
  int _ratingCount = 0;

  final List<String> _ratingLabels = [
    'Needs Better Guidance',
    'Fair Mentorship',
    'Good & Helpful Educator',
    'Great Mentorship Experience',
    'Outstanding & Inspiring Professor! 🌟',
  ];

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _fetchSummary() async {
    try {
      final summary = await ApiClient.getProfessorRatingsSummary(
        teacherId: widget.teacherId,
      );
      if (mounted) {
        setState(() {
          _avgRating = (summary['avg_rating'] as num?)?.toDouble() ?? 0.0;
          _ratingCount = (summary['rating_count'] as num?)?.toInt() ?? 0;
          if (summary['my_rating'] != null) {
            _selectedRating = (summary['my_rating'] as num).toInt();
          }
          if (summary['my_comment'] != null) {
            _commentController.text = summary['my_comment'].toString();
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitRating() async {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
    });

    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) throw Exception('Please log in to submit a review');

      await ApiClient.submitProfessorRating(
        teacherId: widget.teacherId,
        rating: _selectedRating,
        comment: _commentController.text.trim(),
        accessToken: token,
      );

      if (!mounted) return;
      Navigator.of(context).pop();

      // Invalidate relevant teacher providers for live updates
      ref.invalidate(teachersListProvider);
      ref.invalidate(teacherProfileProvider(widget.teacherId));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Review submitted for ${widget.teacherName}! Rated $_selectedRating★',
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );

      widget.onSubmitted?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: 24 + bottomInset,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.school_rounded, color: Color(0xFF4F46E5), size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Rate Professor',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              widget.teacherName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4F46E5),
              ),
            ),

            if (!_isLoading && _ratingCount > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Current Rating: ★ ${_avgRating.toStringAsFixed(1)} ($_ratingCount ${_ratingCount == 1 ? 'review' : 'reviews'})',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // 5 Interactive Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                final isSelected = starIndex <= _selectedRating;
                return IconButton(
                  iconSize: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  icon: Icon(
                    isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: isSelected ? const Color(0xFFF59E0B) : Colors.grey.shade300,
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedRating = starIndex;
                    });
                  },
                );
              }),
            ),

            // Rating label
            Text(
              _ratingLabels[_selectedRating - 1],
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4F46E5),
              ),
            ),
            const SizedBox(height: 20),

            // Review text
            TextField(
              controller: _commentController,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Share your mentorship experience, guidance quality, or feedback...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : _submitRating,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  _isSubmitting ? 'Submitting...' : 'Submit Rating & Review',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
