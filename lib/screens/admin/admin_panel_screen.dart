import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../services/firestore_service.dart';

class AdminPanelScreen extends ConsumerWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.adminPanel),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stats section
          FutureBuilder<Map<String, int>>(
            future: FirestoreService().getAdminStats(),
            builder: (context, snap) {
              if (snap.hasError) {
                return const SizedBox.shrink();
              }
              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final stats = snap.data!;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _StatCard(
                    title: 'الإعلانات',
                    count: stats['posts'] ?? 0,
                    icon: Icons.grid_view,
                    color: AppColors.primary,
                  ),
                  _StatCard(
                    title: 'المستخدمين',
                    count: stats['users'] ?? 0,
                    icon: Icons.people,
                    color: Colors.blue,
                  ),
                  _StatCard(
                    title: 'البلاغات',
                    count: stats['reports'] ?? 0,
                    icon: Icons.flag,
                    color: Colors.orange,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Management sections
          const Text(
            'الإدارة',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),

          _AdminTile(
            icon: Icons.image,
            title: 'إدارة البانرات',
            subtitle: 'البانرات والحملات الإعلانية',
            onTap: () => context.push('/admin/banners'),
          ),
          _AdminTile(
            icon: Icons.view_module,
            title: 'إدارة الأقسام',
            subtitle: 'أقسام الشاشة الرئيسية',
            onTap: () => context.push('/admin/home-sections'),
          ),
          _AdminTile(
            icon: Icons.category,
            title: AppStrings.manageCategories,
            subtitle: 'إضافة وتعديل وحذف التصنيفات',
            onTap: () => context.push('/admin/categories'),
          ),
          _AdminTile(
            icon: Icons.shopping_bag,
            title: AppStrings.manageBrands,
            subtitle: 'إضافة وتعديل وحذف الماركات',
            onTap: () => context.push('/admin/brands'),
          ),
          _AdminTile(
            icon: Icons.flag,
            title: AppStrings.manageReports,
            subtitle: 'مراجعة البلاغات واتخاذ إجراء',
            onTap: () => context.push('/admin/reports'),
          ),
          _AdminTile(
            icon: Icons.people,
            title: AppStrings.manageUsers,
            subtitle: 'إدارة المستخدمين وحظرهم',
            onTap: () => context.push('/admin/users'),
          ),
          _AdminTile(
            icon: Icons.storefront,
            title: AppStrings.manageBoutiqueRequests,
            subtitle: 'مراجعة طلبات الترقية لبوتيك',
            onTap: () => context.push('/admin/boutique-requests'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width - 44) / 3;
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AdminTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
        trailing:
            const Icon(Icons.chevron_left, color: AppColors.textHint),
        onTap: onTap,
      ),
    );
  }
}
