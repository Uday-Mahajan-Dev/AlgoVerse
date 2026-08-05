import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showSubtitle;

  const AppLogo({super.key, this.size = 80, this.showSubtitle = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(size * 0.25),
          ),
          child: Icon(
            Icons.auto_graph_rounded,
            color: Colors.white,
            size: size * 0.55,
          ),
        ),

        const SizedBox(height: 20),

        Text("AlgoVerse", style: AppTypography.heading1),

        if (showSubtitle) ...[
          const SizedBox(height: 6),

          Text("Learn • Visualize • Conquer", style: AppTypography.caption),
        ],
      ],
    );
  }
}
