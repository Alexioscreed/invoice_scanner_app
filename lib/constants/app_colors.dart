import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF2196F3);
  static const Color primaryDark = Color(0xFF1976D2);
  static const Color primaryLight = Color(0xFFBBDEFB);

  // Secondary Colors
  static const Color secondary = Color(0xFF03DAC6);
  static const Color secondaryDark = Color(0xFF018786);
  static const Color secondaryLight = Color(0xFFB2DFDB);

  // Background Colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Processing Status Colors
  static const Color pending = Color(0xFFFF9800);
  static const Color processing = Color(0xFF2196F3);
  static const Color completed = Color(0xFF4CAF50);
  static const Color failed = Color(0xFFF44336);
  static const Color manualReview = Color(0xFF9C27B0);

  // Border Colors
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFE0E0E0);

  // Shadow Colors
  static const Color shadow = Color(0x1A000000);

  // Icon Colors
  static const Color iconPrimary = Color(0xFF757575);
  static const Color iconSecondary = Color(0xFFBDBDBD);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [success, Color(0xFF2E7D32)],
  );
}
