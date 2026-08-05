import 'package:flutter/material.dart';

import '../theme/app_typography.dart';

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTypography.heading2);
  }
}
