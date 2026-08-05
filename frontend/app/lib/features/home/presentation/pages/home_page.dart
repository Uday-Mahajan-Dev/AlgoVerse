import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/section_title.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AlgoVerse")),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(title: "Welcome to AlgoVerse"),

            const SizedBox(height: AppSpacing.lg),

            const AppCard(
              child: Text("Your adaptive DSA learning journey starts here."),
            ),

            const SizedBox(height: AppSpacing.lg),

            PrimaryButton(text: "Start Learning", onPressed: () {}),
          ],
        ),
      ),
    );
  }
}
