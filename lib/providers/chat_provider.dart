import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/chat_service.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

final chatServiceProvider = Provider<ChatService>((ref) => ChatService());

// User's chats stream
final chatsStreamProvider = StreamProvider.family<List<ChatModel>, String>((ref, userId) {
  final service = ref.read(chatServiceProvider);
  return service.chatsStream(userId);
});

// Single chat stream
final chatStreamProvider = StreamProvider.family<ChatModel?, String>((ref, chatId) {
  final service = ref.read(chatServiceProvider);
  return service.chatStream(chatId);
});

// Messages stream for a chat
final messagesStreamProvider = StreamProvider.family<List<MessageModel>, String>((ref, chatId) {
  final service = ref.read(chatServiceProvider);
  return service.messagesStream(chatId);
});

// Unread count for a specific chat
final unreadCountProvider = StreamProvider.family<int, ({String chatId, String userId})>((ref, params) {
  final service = ref.read(chatServiceProvider);
  return service.unreadCountStream(params.chatId, params.userId);
});
