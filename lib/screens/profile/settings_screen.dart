import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeColorProvider);
    final currentUser = ref.watch(currentUserStreamProvider).valueOrNull;
    final isAdmin = currentUser?.isAdmin ?? false;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        children: [
          // Theme color selector
          ListTile(
            leading: Icon(Icons.palette_outlined, color: currentTheme.primary),
            title: const Text('لون التطبيق'),
            subtitle: Text(currentTheme.arabicName, style: const TextStyle(fontSize: 12)),
            trailing: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: currentTheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.divider, width: 2),
              ),
            ),
            onTap: () => _showColorPicker(context, ref, currentTheme),
          ),
          
          // Admin Panel - only visible for admins
          if (isAdmin)
            ListTile(
              leading: Icon(Icons.admin_panel_settings, color: currentTheme.primary),
              title: const Text('لوحة التحكم'),
              subtitle: const Text('إدارة التطبيق', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_left,
                  size: 20, color: AppColors.textHint),
              onTap: () => context.push('/admin'),
            ),
          
          const Divider(height: 1),

          // About
          ListTile(
            leading:
                const Icon(Icons.info_outline, color: AppColors.textSecondary),
            title: const Text('عن التطبيق'),
            trailing: const Icon(Icons.chevron_left,
                size: 20, color: AppColors.textHint),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'خزانة',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2025 خزانة',
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text(
                      'تطبيق إعلانات مبوبة للملابس والأزياء المستعملة في السعودية',
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              );
            },
          ),

          // Privacy
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined,
                color: AppColors.textSecondary),
            title: const Text('سياسة الخصوصية'),
            trailing: const Icon(Icons.chevron_left,
                size: 20, color: AppColors.textHint),
            onTap: () => context.push('/privacy'),
          ),

          // Terms
          ListTile(
            leading: const Icon(Icons.article_outlined,
                color: AppColors.textSecondary),
            title: const Text('الشروط والأحكام'),
            trailing: const Icon(Icons.chevron_left,
                size: 20, color: AppColors.textHint),
            onTap: () => context.push('/terms'),
          ),

          const Divider(height: 1),

          // App version
          const ListTile(
            leading: Icon(Icons.build_outlined, color: AppColors.textSecondary),
            title: Text('الإصدار'),
            trailing: Text('1.0.0',
                style: TextStyle(color: AppColors.textHint)),
          ),
        ],
      ),
    );
  }

  void _showColorPicker(BuildContext context, WidgetRef ref, AppThemeColor currentTheme) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اختر لون التطبيق',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: AppThemeColor.values.map((theme) {
                final isSelected = theme == currentTheme;
                return GestureDetector(
                  onTap: () {
                    ref.read(themeColorProvider.notifier).setTheme(theme);
                    Navigator.pop(ctx);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: theme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? AppColors.textPrimary : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 28)
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        theme.arabicName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                          color: isSelected ? theme.primary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
