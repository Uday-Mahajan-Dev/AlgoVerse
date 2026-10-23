import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ArrayVisualizerWidget extends StatefulWidget {
  final List<int?> arrayState;
  final List<int> highlights;
  final Map<String, int> pointers;
  final String operation;
  final bool isLarge;
  final int stepIntervalMs;
  final bool isPlaying;
  final Widget? trailingHeaderAction;

  const ArrayVisualizerWidget({
    super.key,
    required this.arrayState,
    this.highlights = const [],
    this.pointers = const {},
    required this.operation,
    this.isLarge = false,
    this.stepIntervalMs = 750,
    this.isPlaying = false,
    this.trailingHeaderAction,
  });

  @override
  State<ArrayVisualizerWidget> createState() => _ArrayVisualizerWidgetState();
}

class _ArrayVisualizerWidgetState extends State<ArrayVisualizerWidget> {
  late final ScrollController _scrollController;
  bool _isAutoFollowPaused = false;
  Set<int> _recentlyChangedIndices = {};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToActiveIndex(animated: false);
    });
  }

  @override
  void didUpdateWidget(covariant ArrayVisualizerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Auto-follow resumes when playback is restarted / running
    if (widget.isPlaying && _isAutoFollowPaused) {
      _isAutoFollowPaused = false;
    }

    // Value change detection for brief color pulse
    final changed = <int>{};
    for (int i = 0; i < widget.arrayState.length; i++) {
      if (oldWidget.arrayState.length > i &&
          widget.arrayState[i] != oldWidget.arrayState[i]) {
        changed.add(i);
      }
    }
    if (changed.isNotEmpty) {
      _recentlyChangedIndices = changed;
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          setState(() {
            _recentlyChangedIndices = {};
          });
        }
      });
    }

    if (!_isAutoFollowPaused) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToActiveIndex();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  double? _computeActiveIndex() {
    if (widget.pointers.isNotEmpty) {
      final vals = widget.pointers.values.toList();
      final minVal = vals.reduce((a, b) => a < b ? a : b);
      final maxVal = vals.reduce((a, b) => a > b ? a : b);
      return (minVal + maxVal) / 2.0;
    }
    if (widget.highlights.isNotEmpty) {
      final minVal = widget.highlights.reduce((a, b) => a < b ? a : b);
      final maxVal = widget.highlights.reduce((a, b) => a > b ? a : b);
      return (minVal + maxVal) / 2.0;
    }
    return null;
  }

  void _scrollToActiveIndex({bool animated = true}) {
    if (!mounted || !_scrollController.hasClients) return;
    final activeIdx = _computeActiveIndex();
    if (activeIdx == null) return;

    final cellWidth = widget.isLarge ? 64.0 : 52.0;
    const cellMargin = 10.0; // 5.0 horizontal on each side
    final itemTotalWidth = cellWidth + cellMargin;

    final viewportWidth = _scrollController.position.viewportDimension;
    final targetOffset =
        ((activeIdx * itemTotalWidth) + (itemTotalWidth / 2.0)) -
            (viewportWidth / 2.0);
    final clamped =
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent);

    final durationMs = math.min(300, (widget.stepIntervalMs * 0.8).round());

    if (animated && durationMs > 0) {
      _scrollController.animateTo(
        clamped,
        duration: Duration(milliseconds: durationMs),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(clamped);
    }
  }

  Color _getBoxColor(int index, bool isHighlighted, bool isChanged) {
    if (isChanged) {
      return const Color(0xFF06B6D4); // Cyan pulse for value changes
    }
    if (isHighlighted) {
      if (widget.operation == 'SWAP' || widget.operation == 'UPDATE') {
        return const Color(0xFF10B981); // Emerald
      }
      if (widget.operation == 'FOUND') {
        return const Color(0xFF059669); // Dark green
      }
      return const Color(0xFFF59E0B); // Amber compare
    }
    if (widget.arrayState[index] == null) {
      return Colors.grey.shade200;
    }
    return Colors.indigo.shade50;
  }

  Color _getBorderColor(int index, bool isHighlighted, bool isChanged) {
    if (isChanged) {
      return const Color(0xFF0891B2);
    }
    if (isHighlighted) {
      if (widget.operation == 'SWAP' ||
          widget.operation == 'UPDATE' ||
          widget.operation == 'FOUND') {
        return const Color(0xFF047857);
      }
      return const Color(0xFFD97706);
    }
    return Colors.indigo.shade200;
  }

  @override
  Widget build(BuildContext context) {
    final cellWidth = widget.isLarge ? 64.0 : 52.0;
    final cellHeight = widget.isLarge ? 66.0 : 54.0;
    final fontSize = widget.isLarge ? 22.0 : 18.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: widget.isLarge ? 24 : 20,
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.view_array_outlined, size: 18, color: Colors.indigo),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'ARRAY STATE IN MEMORY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: Colors.indigo,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              if (_isAutoFollowPaused) ...[
                ActionChip(
                  avatar: const Icon(
                    Icons.my_location_rounded,
                    size: 13,
                    color: Colors.indigo,
                  ),
                  label: const Text(
                    'Follow',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: Colors.indigo.shade50,
                  side: BorderSide(color: Colors.indigo.shade200),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    setState(() => _isAutoFollowPaused = false);
                    _scrollToActiveIndex();
                  },
                ),
                const SizedBox(width: 6),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Size: ${widget.arrayState.length}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              if (widget.trailingHeaderAction != null) ...[
                const SizedBox(width: 6),
                widget.trailingHeaderAction!,
              ],
            ],
          ),
          SizedBox(height: widget.isLarge ? 28 : 24),

          // Scrollable Array Canvas with pointer auto-follow & drag detection
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is UserScrollNotification &&
                  notification.direction != ScrollDirection.idle) {
                if (!_isAutoFollowPaused) {
                  setState(() => _isAutoFollowPaused = true);
                }
              }
              return false;
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(widget.arrayState.length, (index) {
                  final val = widget.arrayState[index];
                  final isHighlighted = widget.highlights.contains(index);
                  final isChanged = _recentlyChangedIndices.contains(index);
                  final boxColor = _getBoxColor(index, isHighlighted, isChanged);
                  final borderColor =
                      _getBorderColor(index, isHighlighted, isChanged);

                  // Collect pointers that point to this index
                  final activePointers = widget.pointers.entries
                      .where((entry) => entry.value == index)
                      .map((entry) => entry.key)
                      .toList();

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Column(
                      children: [
                        // Index Label Top
                        Text(
                          '[$index]',
                          style: TextStyle(
                            fontSize: widget.isLarge ? 12 : 11,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            color: isHighlighted
                                ? Colors.indigo.shade900
                                : Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Array Cell Box
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          width: cellWidth,
                          height: cellHeight,
                          decoration: BoxDecoration(
                            color: boxColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: borderColor,
                              width: isHighlighted || isChanged ? 2.5 : 1.5,
                            ),
                            boxShadow: isHighlighted || isChanged
                                ? [
                                    BoxShadow(
                                      color: boxColor.withValues(alpha: 0.5),
                                      blurRadius: isChanged ? 12 : 8,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: val == null
                                  ? Icon(
                                      Icons.more_horiz,
                                      key: const ValueKey('null_val'),
                                      color: Colors.grey.shade400,
                                    )
                                  : Text(
                                      '$val',
                                      key: ValueKey('val_${index}_$val'),
                                      style: TextStyle(
                                        fontSize: fontSize,
                                        fontWeight: FontWeight.bold,
                                        color: isHighlighted || isChanged
                                            ? (widget.operation == 'SWAP' ||
                                                    widget.operation ==
                                                        'UPDATE' ||
                                                    widget.operation == 'FOUND' ||
                                                    isChanged
                                                ? Colors.white
                                                : Colors.black87)
                                            : Colors.indigo.shade900,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Pointers Badge Bottom
                        SizedBox(
                          height: widget.isLarge ? 52 : 48,
                          child: activePointers.isEmpty
                              ? const SizedBox.shrink()
                              : Column(
                                  children: [
                                    const Icon(
                                      Icons.arrow_drop_up_rounded,
                                      size: 16,
                                      color: Colors.indigo,
                                    ),
                                    Wrap(
                                      direction: Axis.vertical,
                                      spacing: 2,
                                      children: activePointers.map((pName) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.indigo.shade700,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            pName,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize:
                                                  widget.isLarge ? 11 : 10,
                                              fontFamily: 'monospace',
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
