import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primaryDark = Color(0xFF192126);
  static const Color primaryLime = Color(0xFFBBF246);

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightBg = Color(0xFFF5F7FA);
  static const Color gray = Color(0xFF6B7280);
  static const Color grayLight = Color(0xFFE5E7EB);
  static const Color grayDark = Color(0xFF4B5563);
  static const Color darkerGray = Color(0xFF374151);

  // Accent Colors
  static const Color blue = Color(0xFF3B82F6);
  static const Color lightBlue = Color(0xFF60A5FA);
  static const Color green = Color(0xFF10B981);
  static const Color red = Color(0xFFEF4444);
  static const Color orange = Color(0xFFF59E0B);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color pink = Color(0xFFEC4899);
  static const Color teal = Color(0xFF14B8A6);

  // Semantic Colors
  static const Color success = green;
  static const Color error = red;
  static const Color warning = orange;
  static const Color info = blue;

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLime, Color(0xFFD4FF6B)],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryDark, Color(0xFF2D3A42)],
  );
}
