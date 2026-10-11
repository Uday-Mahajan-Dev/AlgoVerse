import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';

class LessonRatingSheet extends StatefulWidget {
  final String lessonId;
  final String lessonTitle;
  final VoidCallback? onSubmitted;

  const LessonRatingSheet({
    super.key,
    required this.lessonId,
    required this.lessonTitle,
    this.onSubmitted,
  });

  static Future<void> show(
    BuildContext context, {
    required String lessonId,
    required String lessonTitle,
    VoidCallback? onSubmitted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LessonRatingSheet(
        lessonId: lessonId,
        lessonTitle: lessonTitle,
        onSubmitted: onSubmitted,
      ),
    );
  }

  @override
  State<LessonRatingSheet> createState() => _LessonRatingSheetState();
}

class _LessonRatingSheetState extends State<LessonRatingSheet> {
  int _selectedRating = 5;
  final TextEditingController _commentController = TextEditingController();
  bool _isLoadingSummary = true;
  bool _isSubmitting = false;
  double _avgRating = 0.0;
  int _ratingCount = 0;

  final List<String> _ratingLabels = [
    'Needs Improvement',
    'Fair',
    'Good',
    'Very Good',
    'Excellent & Clear! 🚀',
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
      final summary = await ApiClient.getLessonFeedbackSummary(
        lessonId: widget.lessonId,
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
          _isLoadingSummary = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingSummary = false;
        });
      }
    }
  }

  Future<void> _submitFeedback() async {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
    });

    try {
      await ApiClient.submitLessonFeedback(
        lessonId: widget.lessonId,
        rating: _selectedRating,
        comment: _commentController.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Feedback submitted! Rated $_selectedRating stars ⭐'),
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
                const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Rate This Lesson',
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
              widget.lessonTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),

            if (!_isLoadingSummary && _ratingCount > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Class Average: ★ ${_avgRating.toStringAsFixed(1)} ($_ratingCount ${_ratingCount == 1 ? 'review' : 'reviews'})',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // 5 Stars Row
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

            // Rating description label
            Text(
              _ratingLabels[_selectedRating - 1],
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4F46E5),
              ),
            ),
            const SizedBox(height: 20),

            // Optional Comment TextField
            TextField(
              controller: _commentController,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'What did you like about this lesson? (Optional thoughts or questions)',
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
                onPressed: _isSubmitting ? null : _submitFeedback,
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
                  _isSubmitting ? 'Submitting...' : 'Submit Review',
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
