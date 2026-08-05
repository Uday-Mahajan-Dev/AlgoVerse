import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Primary Brand Color
  static const Color primaryColor = Color(0xFF2563EB);

  // Scaffold Background
  static const Color backgroundColor = Color(0xFFF8FAFC);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),

      scaffoldBackgroundColor: backgroundColor,

      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),

      cardTheme: const CardThemeData(elevation: 2, margin: EdgeInsets.all(8)),

      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}
