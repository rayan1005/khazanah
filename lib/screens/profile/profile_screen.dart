import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('يرجى تسجيل الدخول')),
      );
    }

    final userAsync = ref.watch(userStreamByIdProvider(uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.profile),
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('لم يتم العثور على الحساب'));
          }

          return ListView(
            children: [
              const SizedBox(height: 24),
              // Avatar
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.1),
                      backgroundImage: user.photoUrl != null
                          ? CachedNetworkImageProvider(user.photoUrl!)
                          : null,
                      child: user.photoUrl == null
                          ? Text(
                              user.name.isNotEmpty ? user.name[0] : '?',
                              style: TextStyle(
                                fontSize: 32,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: GestureDetector(
                        onTap: () => context.push('/edit-profile'),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primary,
                          child: Icon(Icons.edit, size: 16,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (user.city != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on,
                            size: 14, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Text(
                          user.city!,
                          style: const TextStyle(
                            color: AppColors.textHint,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              const Divider(height: 1),

              // Admin panel (only for admin role)
              if (user.role == 'admin')
                _ProfileTile(
                  icon: Icons.admin_panel_settings,
                  title: AppStrings.adminPanel,
                  onTap: () => context.push('/admin'),
                ),

              // My Posts (moved from bottom nav)
              _ProfileTile(
                icon: Icons.article_rounded,
                title: AppStrings.myPosts,
                onTap: () => context.push('/my-posts'),
              ),

              // Boutique upgrade or my store
              if (user.isBoutique)
                _ProfileTile(
                  icon: Icons.storefront,
                  title: 'متجري',
                  onTap: () => context.push('/boutique/${user.uid}'),
                )
              else
                _ProfileTile(
                  icon: Icons.storefront_outlined,
                  title: AppStrings.upgradeToBoutique,
                  onTap: () => context.push('/upgrade-to-boutique'),
                ),

              // Favorites
              _ProfileTile(
                icon: Icons.favorite_outline,
                title: AppStrings.favorites,
                onTap: () => context.push('/favorites'),
              ),

              // Settings
              _ProfileTile(
                icon: Icons.settings_outlined,
                title: AppStrings.settings,
                onTap: () => context.push('/settings'),
              ),

              const Divider(height: 1),

              // Logout
              _ProfileTile(
                icon: Icons.logout,
                title: AppStrings.logout,
                color: Colors.red,
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('تسجيل الخروج'),
                      content:
                          const Text('هل أنت متأكد من تسجيل الخروج؟'),
                      actions: [
                        TextButton(
                          onPressed: () => ctx.pop(false),
                          child: const Text(AppStrings.cancel),
                        ),
                        TextButton(
                          onPressed: () => ctx.pop(true),
                          child: const Text(AppStrings.logout,
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await ref.read(authServiceProvider).signOut();
                    if (context.mounted) context.go('/login');
                  }
                },
              ),

              // Delete account
              _ProfileTile(
                icon: Icons.delete_forever,
                title: AppStrings.deleteAccount,
                color: Colors.red,
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text(AppStrings.deleteAccount),
                      content: const Text(AppStrings.deleteAccountConfirm),
                      actions: [
                        TextButton(
                          onPressed: () => ctx.pop(false),
                          child: const Text(AppStrings.cancel),
                        ),
                        TextButton(
                          onPressed: () => ctx.pop(true),
                          child: const Text(AppStrings.delete,
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await ref.read(authServiceProvider).deleteAccount();
                    if (context.mounted) context.go('/login');
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.textSecondary),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_left,
          size: 20, color: AppColors.textHint),
      onTap: onTap,
    );
  }
}
