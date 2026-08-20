import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/teacher_dashboard/presentation/pages/teacher_dashboard_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ProviderScope(child: TeacherDashboardTestApp()));
}

class TeacherDashboardTestApp extends StatelessWidget {
  const TeacherDashboardTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AlgoVerse Teacher Dashboard',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const TeacherDashboardPage(),
    );
  }
}
