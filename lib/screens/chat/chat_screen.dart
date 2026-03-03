import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/message_model.dart';
import '../../providers/chat_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/post_provider.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String chatId;
  const ChatDetailScreen({super.key, required this.chatId});

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    // Mark messages as read
    ref.read(chatServiceProvider).markAsRead(widget.chatId, _uid);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    await ref
        .read(chatServiceProvider)
        .sendMessage(widget.chatId, _uid, text);

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _openWhatsApp(String? phone) async {
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد رقم واتساب')),
      );
      return;
    }
    final url = 'https://wa.me/${phone.replaceAll('+', '')}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatAsync = ref.watch(chatStreamProvider(widget.chatId));
    final messagesAsync = ref.watch(messagesStreamProvider(widget.chatId));

    return chatAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('$e')),
      ),
      data: (chat) {
        if (chat == null) {
          return const Scaffold(
            body: Center(child: Text('المحادثة غير موجودة')),
          );
        }

        final otherUid = chat.otherParticipant(_uid);
        final otherUserAsync = ref.watch(userStreamByIdProvider(otherUid));
        final postAsync = ref.watch(postDetailProvider(chat.postId));
        final isBlocked = chat.hasBlock;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () => context.pop(),
            ),
            title: otherUserAsync.when(
              loading: () => const Text('...'),
              error: (_, __) => const Text(''),
              data: (user) {
                if (user == null) return const Text('');
                return GestureDetector(
                  onTap: () => context.push('/user/$otherUid'),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.1),
                        backgroundImage: user.photoUrl != null
                            ? CachedNetworkImageProvider(user.photoUrl!)
                            : null,
                        child: user.photoUrl == null
                            ? Text(user.name.isNotEmpty ? user.name[0] : '?',
                                style: const TextStyle(fontSize: 12))
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(user.name, style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                );
              },
            ),
            actions: [
              // WhatsApp button
              otherUserAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (user) {
                  if (user?.whatsapp == null) return const SizedBox.shrink();
                  return IconButton(
                    icon: const Icon(Icons.chat, color: AppColors.whatsapp),
                    tooltip: AppStrings.openWhatsApp,
                    onPressed: () => _openWhatsApp(user!.whatsapp),
                  );
                },
              ),
              // More options
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'block') {
                    await ref
                        .read(chatServiceProvider)
                        .blockUser(widget.chatId, _uid);
                  } else if (value == 'unblock') {
                    await ref
                        .read(chatServiceProvider)
                        .unblockUser(widget.chatId, _uid);
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: chat.isBlockedBy(_uid) ? 'unblock' : 'block',
                    child: Row(
                      children: [
                        const Icon(Icons.block, size: 18),
                        const SizedBox(width: 8),
                        Text(chat.isBlockedBy(_uid)
                            ? AppStrings.unblockUser
                            : AppStrings.blockUser),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Post info header
          body: Column(
            children: [
              // Post thumbnail bar
              postAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (post) {
                  if (post == null) return const SizedBox.shrink();
                  return GestureDetector(
                    onTap: () => context.push('/post/${post.postId}'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        border: Border(
                          bottom: BorderSide(color: AppColors.divider),
                        ),
                      ),
                      child: Row(
                        children: [
                          if (post.photos.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: CachedNetworkImage(
                                imageUrl: post.photos.first,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                              ),
                            ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  '${post.price.toStringAsFixed(0)} ر.س',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_left,
                              color: AppColors.textHint),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Messages
              Expanded(
                child: messagesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('$e')),
                  data: (messages) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_scrollController.hasClients) {
                        _scrollController.jumpTo(
                          _scrollController.position.maxScrollExtent,
                        );
                      }
                    });

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMine = msg.senderId == _uid;
                        return _MessageBubble(message: msg, isMine: isMine);
                      },
                    );
                  },
                ),
              ),

              // Input bar
              if (isBlocked)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppColors.background,
                  child: const Text(
                    'تم حظر هذه المحادثة',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textHint),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                      top: BorderSide(color: AppColors.divider),
                    ),
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: AppStrings.typeMessage,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: AppColors.background,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                            ),
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: IconButton(
                            icon: const Icon(Icons.send,
                                color: Colors.white, size: 20),
                            onPressed: _sendMessage,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMine;

  const _MessageBubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMine ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft:
                isMine ? const Radius.circular(4) : const Radius.circular(16),
            bottomRight:
                isMine ? const Radius.circular(16) : const Radius.circular(4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isMine ? Colors.white : AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 10,
                    color: isMine
                        ? Colors.white.withValues(alpha: 0.7)
                        : AppColors.textHint,
                  ),
                ),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.read ? Icons.done_all : Icons.done,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
