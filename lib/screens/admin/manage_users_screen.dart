import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../services/firestore_service.dart';

class ManageUsersScreen extends ConsumerWidget {
  const ManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.manageUsers),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text('لا يوجد مستخدمين'));
          }
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return _UserTile(user: user);
            },
          );
        },
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserModel user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        backgroundImage: user.photoUrl != null
            ? CachedNetworkImageProvider(user.photoUrl!)
            : null,
        child: user.photoUrl == null
            ? Text(
                user.name.isNotEmpty ? user.name[0] : '?',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w700),
              )
            : null,
      ),
      title: Row(
        children: [
          Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (user.role == 'admin')
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('مشرف',
                  style: TextStyle(fontSize: 10, color: Colors.white)),
            ),
          if (user.isBanned)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('محظور',
                  style: TextStyle(fontSize: 10, color: Colors.white)),
            ),
        ],
      ),
      subtitle: Text(
        '${user.phone} • ${user.city ?? ''}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) async {
          if (value == 'ban') {
            await FirestoreService()
                .updateUser(user.uid, {'isBanned': true});
          } else if (value == 'unban') {
            await FirestoreService()
                .updateUser(user.uid, {'isBanned': false});
          } else if (value == 'make_admin') {
            await FirestoreService()
                .updateUser(user.uid, {'role': 'admin'});
          } else if (value == 'remove_admin') {
            await FirestoreService()
                .updateUser(user.uid, {'role': 'user'});
          }
        },
        itemBuilder: (ctx) => [
          if (!user.isBanned)
            const PopupMenuItem(
              value: 'ban',
              child: Row(
                children: [
                  Icon(Icons.block, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('حظر المستخدم'),
                ],
              ),
            ),
          if (user.isBanned)
            const PopupMenuItem(
              value: 'unban',
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 18, color: Colors.green),
                  SizedBox(width: 8),
                  Text('إلغاء الحظر'),
                ],
              ),
            ),
          if (user.role != 'admin')
            const PopupMenuItem(
              value: 'make_admin',
              child: Row(
                children: [
                  Icon(Icons.admin_panel_settings, size: 18),
                  SizedBox(width: 8),
                  Text('ترقية لمشرف'),
                ],
              ),
            ),
          if (user.role == 'admin')
            const PopupMenuItem(
              value: 'remove_admin',
              child: Row(
                children: [
                  Icon(Icons.person, size: 18),
                  SizedBox(width: 8),
                  Text('إلغاء صلاحية المشرف'),
                ],
              ),
            ),
        ],
      ),
      onTap: () => context.push('/user/${user.uid}'),
    );
  }
}
