import 'package:flutter/material.dart';

import 'theme.dart';

class AlgoVerseApp extends StatelessWidget {
  const AlgoVerseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'AlgoVerse',

      theme: AppTheme.lightTheme,

      home: const Scaffold(
        body: Center(
          child: Text(
            'AlgoVerse',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
