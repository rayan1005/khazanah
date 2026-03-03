import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Available theme colors
enum AppThemeColor {
  blue('أزرق', Color(0xFF2563EB), Color(0xFF3B82F6), Color(0xFF1D4ED8)),
  teal('أخضر مائي', Color(0xFF0D7377), Color(0xFF14A3A8), Color(0xFF095456)),
  purple('بنفسجي', Color(0xFF7C3AED), Color(0xFF8B5CF6), Color(0xFF6D28D9)),
  pink('وردي', Color(0xFFDB2777), Color(0xFFEC4899), Color(0xFFBE185D)),
  orange('برتقالي', Color(0xFFEA580C), Color(0xFFF97316), Color(0xFFC2410C)),
  green('أخضر', Color(0xFF059669), Color(0xFF10B981), Color(0xFF047857));

  final String arabicName;
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;

  const AppThemeColor(this.arabicName, this.primary, this.primaryLight, this.primaryDark);
}

/// Theme state notifier
class ThemeNotifier extends StateNotifier<AppThemeColor> {
  static const _key = 'app_theme_color';
  
  ThemeNotifier() : super(AppThemeColor.blue) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString(_key);
    if (themeName != null) {
      try {
        state = AppThemeColor.values.firstWhere((t) => t.name == themeName);
      } catch (_) {
        state = AppThemeColor.blue;
      }
    }
  }

  Future<void> setTheme(AppThemeColor theme) async {
    state = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, theme.name);
  }
}

/// Provider for the theme color
final themeColorProvider = StateNotifierProvider<ThemeNotifier, AppThemeColor>((ref) {
  return ThemeNotifier();
});
