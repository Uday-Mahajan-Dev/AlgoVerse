import 'package:flutter/material.dart';

class CodeViewerWidget extends StatelessWidget {
  final String codeSnippet;
  final int activeSourceLine;
  final String explanation;
  final String operation;

  const CodeViewerWidget({
    super.key,
    required this.codeSnippet,
    required this.activeSourceLine,
    required this.explanation,
    required this.operation,
  });

  Color _getOperationColor(String op) {
    switch (op.toUpperCase()) {
      case 'FOUND':
      case 'DONE':
        return const Color(0xFF10B981);
      case 'SWAP':
      case 'SHIFT':
      case 'UPDATE':
      case 'POP':
        return const Color(0xFF06B6D4);
      case 'COMPARE':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF818CF8);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lines = codeSnippet.split('\n');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E), // Catppuccin Mocha Base
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF313244)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF181825),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF38BA8),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF9E2AF),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFFA6E3A1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                const Text(
                  'ALGORITHM EXECUTION TRACE',
                  style: TextStyle(
                    color: Color(0xFFCDD6F4),
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getOperationColor(operation).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    operation,
                    style: TextStyle(
                      color: _getOperationColor(operation),
                      fontSize: 10,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Code Lines
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: lines.asMap().entries.map((entry) {
                final lineIndex = entry.key + 1; // 1-based line number
                final lineText = entry.value;
                final isActive = lineIndex == activeSourceLine;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  color: isActive
                      ? const Color(0xFF45475A).withValues(alpha: 0.6)
                      : Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 3,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Active Arrow Indicator
                      SizedBox(
                        width: 14,
                        child: isActive
                            ? const Text(
                                '▶',
                                style: TextStyle(
                                  color: Color(0xFFF9E2AF),
                                  fontSize: 10,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      // Line Number
                      SizedBox(
                        width: 24,
                        child: Text(
                          '$lineIndex',
                          style: TextStyle(
                            color: isActive
                                ? const Color(0xFFF9E2AF)
                                : const Color(0xFF6C7086),
                            fontFamily: 'monospace',
                            fontSize: 13,
                            fontWeight: isActive
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Code Line Content
                      Expanded(
                        child: Text(
                          lineText,
                          style: TextStyle(
                            color: isActive
                                ? const Color(0xFFF5E0DC)
                                : const Color(0xFFCDD6F4),
                            fontFamily: 'monospace',
                            fontSize: 13,
                            fontWeight: isActive
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // Live Step Explanation Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFF11111B),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: Color(0xFF89B4FA),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    explanation,
                    style: const TextStyle(
                      color: Color(0xFFBAC2DE),
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
