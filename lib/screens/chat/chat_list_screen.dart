import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/chat_model.dart';
import '../../providers/chat_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/post_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeletons/skeleton_loading.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    // Set Arabic locale for timeago
    timeago.setLocaleMessages('ar', timeago.ArMessages());
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.login,
          title: 'سجّل دخولك لعرض المحادثات',
        ),
      );
    }

    final chatsAsync = ref.watch(chatsStreamProvider(uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.chats),
      ),
      body: chatsAsync.when(
        loading: () => ListView.builder(
          itemCount: 5,
          itemBuilder: (_, __) => const ChatListSkeleton(),
        ),
        error: (e, _) => Center(child: Text('$e')),
        data: (chats) {
          if (chats.isEmpty) {
            return const EmptyState(
              icon: Icons.chat_bubble_outline,
              title: AppStrings.noChats,
              subtitle: 'ابدأ محادثة مع بائع من صفحة الإعلان',
            );
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              return _ChatTile(chat: chats[index], currentUid: uid);
            },
          );
        },
      ),
    );
  }
}

class _ChatTile extends ConsumerWidget {
  final ChatModel chat;
  final String currentUid;

  const _ChatTile({required this.chat, required this.currentUid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otherUid = chat.otherParticipant(currentUid);
    final otherUserAsync = ref.watch(userStreamByIdProvider(otherUid));
    final postAsync = ref.watch(postDetailProvider(chat.postId));

    return otherUserAsync.when(
      loading: () => const ChatListSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
      data: (otherUser) {
        if (otherUser == null) return const SizedBox.shrink();

        return ListTile(
          onTap: () => context.push('/chat/${chat.chatId}'),
          leading: CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: otherUser.photoUrl != null
                ? CachedNetworkImageProvider(otherUser.photoUrl!)
                : null,
            child: otherUser.photoUrl == null
                ? Text(
                    otherUser.name.isNotEmpty ? otherUser.name[0] : '?',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          title: Text(
            otherUser.name,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Row(
            children: [
              // Post thumbnail
              postAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (post) {
                  if (post == null) return const SizedBox.shrink();
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (post.photos.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: CachedNetworkImage(
                            imageUrl: post.photos.first,
                            width: 20,
                            height: 20,
                            fit: BoxFit.cover,
                          ),
                        ),
                      const SizedBox(width: 4),
                    ],
                  );
                },
              ),
              Expanded(
                child: Text(
                  chat.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          trailing: Text(
            timeago.format(chat.lastMessageTime, locale: 'ar'),
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textHint,
            ),
          ),
        );
      },
    );
  }
}
