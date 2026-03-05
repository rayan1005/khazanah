import 'package:flutter/material.dart';
import '../../providers/theme_provider.dart';

class AppColors {
  AppColors._();
  
  // Dynamic primary colors - default to blue (can be overridden by theme)
  static Color primary = const Color(0xFF2563EB);
  static Color primaryLight = const Color(0xFF3B82F6);
  static Color primaryDark = const Color(0xFF1D4ED8);
  
  /// Update colors based on theme
  static void updateFromTheme(AppThemeColor theme) {
    primary = theme.primary;
    primaryLight = theme.primaryLight;
    primaryDark = theme.primaryDark;
  }

  // Background
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);

  // Status
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Badges
  static const Color soldBadge = Color(0xFFEF4444);
  static const Color newBadge = Color(0xFF10B981);
  static const Color negotiableBadge = Color(0xFFF59E0B);

  // Dark text
  static const Color darkText = Color(0xFF333333);

  // Other
  static const Color divider = Color(0xFFE5E7EB);
  static const Color shimmerBase = Color(0xFFE5E7EB);
  static const Color shimmerHighlight = Color(0xFFF3F4F6);
  static const Color favorite = Color(0xFFEF4444);
  static const Color whatsapp = Color(0xFF25D366);
}
