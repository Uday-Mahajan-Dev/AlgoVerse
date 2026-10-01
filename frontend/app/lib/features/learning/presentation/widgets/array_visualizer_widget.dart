import 'package:flutter/material.dart';

class ArrayVisualizerWidget extends StatelessWidget {
  final List<int?> arrayState;
  final List<int> highlights;
  final Map<String, int> pointers;
  final String operation;

  const ArrayVisualizerWidget({
    super.key,
    required this.arrayState,
    this.highlights = const [],
    this.pointers = const {},
    required this.operation,
  });

  Color _getBoxColor(int index, bool isHighlighted) {
    if (isHighlighted) {
      if (operation == 'SWAP' || operation == 'UPDATE') {
        return const Color(0xFF10B981); // Emerald
      }
      if (operation == 'FOUND') {
        return const Color(0xFF059669); // Dark green
      }
      return const Color(0xFFF59E0B); // Amber compare
    }
    if (arrayState[index] == null) {
      return Colors.grey.shade200;
    }
    return Colors.indigo.shade50;
  }

  Color _getBorderColor(int index, bool isHighlighted) {
    if (isHighlighted) {
      if (operation == 'SWAP' || operation == 'UPDATE' || operation == 'FOUND') {
        return const Color(0xFF047857);
      }
      return const Color(0xFFD97706);
    }
    return Colors.indigo.shade200;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
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
              const Icon(Icons.view_array_outlined, size: 20, color: Colors.indigo),
              const SizedBox(width: 8),
              const Text(
                'ARRAY STATE IN MEMORY',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: Colors.indigo,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Size: ${arrayState.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Scrollable Array Canvas
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(arrayState.length, (index) {
                final val = arrayState[index];
                final isHighlighted = highlights.contains(index);
                final boxColor = _getBoxColor(index, isHighlighted);
                final borderColor = _getBorderColor(index, isHighlighted);

                // Collect pointers that point to this index
                final activePointers = pointers.entries
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
                          fontSize: 11,
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
                        width: 52,
                        height: 54,
                        decoration: BoxDecoration(
                          color: boxColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: borderColor,
                            width: isHighlighted ? 2.5 : 1.5,
                          ),
                          boxShadow: isHighlighted
                              ? [
                                  BoxShadow(
                                    color: boxColor.withValues(alpha: 0.5),
                                    blurRadius: 8,
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
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isHighlighted
                                          ? (operation == 'SWAP' ||
                                                  operation == 'UPDATE' ||
                                                  operation == 'FOUND'
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
                        height: 48,
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
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
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
        ],
      ),
    );
  }
}
