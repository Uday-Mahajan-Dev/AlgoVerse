import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';

class ProblemRatingWidget extends StatefulWidget {
  final String problemId;
  final String problemKind; // 'course' or 'custom'
  final String? problemTitle;
  final VoidCallback? onRated;

  const ProblemRatingWidget({
    super.key,
    required this.problemId,
    this.problemKind = 'course',
    this.problemTitle,
    this.onRated,
  });

  static Future<void> showSheet(
    BuildContext context, {
    required String problemId,
    String problemKind = 'course',
    String? problemTitle,
    VoidCallback? onRated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: 24 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: ProblemRatingWidget(
            problemId: problemId,
            problemKind: problemKind,
            problemTitle: problemTitle,
            onRated: onRated,
          ),
        ),
      ),
    );
  }

  @override
  State<ProblemRatingWidget> createState() => _ProblemRatingWidgetState();
}

class _ProblemRatingWidgetState extends State<ProblemRatingWidget> {
  int _selectedRating = 5;
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _hasSubmitted = false;
  double _avgRating = 0.0;
  int _ratingCount = 0;

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
      final summary = await ApiClient.getProblemFeedbackSummary(
        problemId: widget.problemId,
        problemKind: widget.problemKind,
      );
      if (mounted) {
        setState(() {
          _avgRating = (summary['avg_rating'] as num?)?.toDouble() ?? 0.0;
          _ratingCount = (summary['rating_count'] as num?)?.toInt() ?? 0;
          if (summary['my_rating'] != null) {
            _selectedRating = (summary['my_rating'] as num).toInt();
            _hasSubmitted = true;
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
      await ApiClient.submitProblemFeedback(
        problemId: widget.problemId,
        problemKind: widget.problemKind,
        rating: _selectedRating,
        comment: _commentController.text.trim(),
      );

      if (!mounted) return;
      setState(() {
        _hasSubmitted = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rated $_selectedRating stars for clarity & challenge! ⭐'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );

      _fetchSummary();
      widget.onRated?.call();
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
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.rate_review_rounded,
                  color: Color(0xFFD97706),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.problemTitle != null
                          ? 'Rate Problem: ${widget.problemTitle}'
                          : 'Rate Problem Clarity & Difficulty',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _ratingCount > 0
                          ? '★ ${_avgRating.toStringAsFixed(1)} ($_ratingCount ${_ratingCount == 1 ? 'rating' : 'ratings'})'
                          : 'Be the first to rate this problem!',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (_hasSubmitted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, size: 14, color: Colors.green.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Rated $_selectedRating★',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Interactive 5 Stars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starIndex = index + 1;
              final isFilled = starIndex <= _selectedRating;
              return IconButton(
                iconSize: 32,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                icon: Icon(
                  isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: isFilled ? const Color(0xFFF59E0B) : Colors.grey.shade300,
                ),
                onPressed: () {
                  setState(() {
                    _selectedRating = starIndex;
                  });
                },
              );
            }),
          ),
          const SizedBox(height: 8),

          // Quick Comment Field
          TextField(
            controller: _commentController,
            maxLines: 2,
            maxLength: 300,
            decoration: InputDecoration(
              hintText: 'Share feedback on test cases, wording, or difficulty (optional)...',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Submit Rating Button
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _isSubmitting ? null : _submitRating,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.star_rounded, size: 16),
              label: Text(
                _hasSubmitted ? 'Update Rating' : 'Submit Rating',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
