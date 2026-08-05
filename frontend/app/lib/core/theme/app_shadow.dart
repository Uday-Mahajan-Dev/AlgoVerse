import 'package:flutter/material.dart';

class AppShadow {
  AppShadow._();

  static const soft = [
    BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 8)),
  ];

  static const medium = [
    BoxShadow(color: Color(0x22000000), blurRadius: 30, offset: Offset(0, 12)),
  ];
}
