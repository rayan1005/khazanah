import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/firestore_service.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('الإشعارات')),
        body: const Center(child: Text('يرجى تسجيل الدخول')),
      );
    }

    final notificationsAsync = ref.watch(notificationsStreamProvider(uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await FirestoreService().markAllNotificationsRead(uid);
            },
            child: const Text('قراءة الكل'),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: AppColors.textHint),
                  SizedBox(height: 16),
                  Text(
                    'لا توجد إشعارات',
                    style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return _NotificationTile(notification: notif, uid: uid);
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final NotificationModel notification;
  final String uid;

  const _NotificationTile({required this.notification, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final triggeredByAsync = notification.triggeredByUserId != null
        ? ref.watch(userStreamByIdProvider(notification.triggeredByUserId!))
        : null;

    return Dismissible(
      key: Key(notification.notificationId),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.error,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        FirestoreService().deleteNotification(notification.notificationId);
      },
      child: ListTile(
        onTap: () async {
          // Mark as read
          if (!notification.isRead) {
            await FirestoreService().markNotificationRead(notification.notificationId);
          }
          // Navigate to post
          if (context.mounted) {
            context.push('/post/${notification.postId}');
          }
        },
        leading: triggeredByAsync?.when(
          data: (user) => CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: user?.photoUrl != null
                ? CachedNetworkImageProvider(user!.photoUrl!)
                : null,
            child: user?.photoUrl == null
                ? Text(
                    user?.name.isNotEmpty == true ? user!.name[0] : '?',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          loading: () => const CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.shimmerBase,
          ),
          error: (_, __) => const CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.shimmerBase,
            child: Icon(Icons.person),
          ),
        ) ?? CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: _getNotificationIcon(notification.type),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          notification.message,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: notification.isRead ? AppColors.textHint : AppColors.textSecondary,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatTime(notification.createdAt),
              style: const TextStyle(fontSize: 10, color: AppColors.textHint),
            ),
            if (!notification.isRead)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        tileColor: notification.isRead ? null : AppColors.primary.withValues(alpha: 0.05),
      ),
    );
  }

  Widget _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.newComment:
        return Icon(Icons.comment, color: AppColors.primary, size: 20);
      case NotificationType.replyToComment:
        return Icon(Icons.reply, color: AppColors.primary, size: 20);
      case NotificationType.postSold:
        return Icon(Icons.sell, color: AppColors.primary, size: 20);
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} ي';
    return '${dt.day}/${dt.month}';
  }
}
