import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'router.dart';

class AlgoVerseApp extends StatelessWidget {
  const AlgoVerseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'AlgoVerse',
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
