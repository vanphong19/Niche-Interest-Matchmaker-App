import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'Niche Interest Matchmaker';

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const Duration sendTimeout = Duration(seconds: 20);
}

class AppColors {
  AppColors._();

  static const Color seedColor = Color(0xFF0E7A73);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFEF6C00);
  static const Color error = Color(0xFFC62828);
}
