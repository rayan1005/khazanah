import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/app_settings_provider.dart';

class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الدعم والتواصل'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (settings) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header
              Center(
                child: Column(
                  children: [
                    Icon(Icons.support_agent,
                        size: 64, color: AppColors.primary),
                    const SizedBox(height: 12),
                    const Text(
                      'كيف يمكننا مساعدتك؟',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'تواصل معنا وسنرد عليك في أقرب وقت',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Email
              if (settings.supportEmail.isNotEmpty)
                _SupportTile(
                  icon: Icons.email_outlined,
                  title: 'البريد الإلكتروني',
                  subtitle: settings.supportEmail,
                  onTap: () async {
                    final uri = Uri(
                      scheme: 'mailto',
                      path: settings.supportEmail,
                      queryParameters: {
                        'subject': 'دعم تطبيق خزانة',
                      },
                    );
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                ),

              // Terms
              _SupportTile(
                icon: Icons.article_outlined,
                title: 'الشروط والأحكام',
                subtitle: 'اطلع على شروط وأحكام الاستخدام',
                onTap: () => context.push('/terms'),
              ),

              // Privacy
              _SupportTile(
                icon: Icons.privacy_tip_outlined,
                title: 'سياسة الخصوصية',
                subtitle: 'اطلع على سياسة الخصوصية',
                onTap: () => context.push('/privacy'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SupportTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SupportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textHint)),
        trailing:
            const Icon(Icons.chevron_left, color: AppColors.textHint),
        onTap: onTap,
      ),
    );
  }
}
