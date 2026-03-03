import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../core/constants/firestore_paths.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  /// Get or create a chat between two users about a specific post
  Future<String> getOrCreateChat(
      String myUid, String otherUid, String postId) async {
    // Check if chat already exists
    final existing = await _db
        .collection(FirestorePaths.chats)
        .where('participants', arrayContains: myUid)
        .where('postId', isEqualTo: postId)
        .get();

    for (final doc in existing.docs) {
      final participants = List<String>.from(doc.data()['participants'] ?? []);
      if (participants.contains(otherUid)) {
        return doc.id;
      }
    }

    // Create new chat
    final docRef = _db.collection(FirestorePaths.chats).doc();
    final chat = ChatModel(
      chatId: docRef.id,
      participants: [myUid, otherUid],
      postId: postId,
      lastMessage: '',
      lastMessageTime: DateTime.now(),
    );
    await docRef.set(chat.toMap());
    return docRef.id;
  }

  /// Get user's chats stream
  Stream<List<ChatModel>> chatsStream(String userId) {
    return _db
        .collection(FirestorePaths.chats)
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ChatModel.fromDoc(d)).toList());
  }

  /// Get single chat
  Future<ChatModel?> getChat(String chatId) async {
    final doc = await _db.collection(FirestorePaths.chats).doc(chatId).get();
    if (!doc.exists) return null;
    return ChatModel.fromDoc(doc);
  }

  /// Chat stream
  Stream<ChatModel?> chatStream(String chatId) {
    return _db
        .collection(FirestorePaths.chats)
        .doc(chatId)
        .snapshots()
        .map((doc) => doc.exists ? ChatModel.fromDoc(doc) : null);
  }

  /// Get messages stream for a chat
  Stream<List<MessageModel>> messagesStream(String chatId) {
    return _db
        .collection(FirestorePaths.chatMessages(chatId))
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => MessageModel.fromDoc(d)).toList());
  }

  /// Send a message
  Future<void> sendMessage(String chatId, String senderId, String text) async {
    final messageId = _uuid.v4();
    final message = MessageModel(
      messageId: messageId,
      senderId: senderId,
      text: text,
      timestamp: DateTime.now(),
    );

    final batch = _db.batch();

    // Add message
    batch.set(
      _db.collection(FirestorePaths.chatMessages(chatId)).doc(messageId),
      message.toMap(),
    );

    // Update chat's last message
    batch.update(
      _db.collection(FirestorePaths.chats).doc(chatId),
      {
        'lastMessage': text,
        'lastMessageTime': Timestamp.fromDate(DateTime.now()),
      },
    );

    await batch.commit();
  }

  /// Mark messages as read
  Future<void> markAsRead(String chatId, String currentUserId) async {
    final unread = await _db
        .collection(FirestorePaths.chatMessages(chatId))
        .where('read', isEqualTo: false)
        .where('senderId', isNotEqualTo: currentUserId)
        .get();

    final batch = _db.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  /// Get unread count for a chat
  Stream<int> unreadCountStream(String chatId, String currentUserId) {
    return _db
        .collection(FirestorePaths.chatMessages(chatId))
        .where('read', isEqualTo: false)
        .where('senderId', isNotEqualTo: currentUserId)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Block user in chat
  Future<void> blockUser(String chatId, String blockerUid) async {
    await _db.collection(FirestorePaths.chats).doc(chatId).update({
      'blockedBy.$blockerUid': true,
    });
  }

  /// Unblock user in chat
  Future<void> unblockUser(String chatId, String blockerUid) async {
    await _db.collection(FirestorePaths.chats).doc(chatId).update({
      'blockedBy.$blockerUid': FieldValue.delete(),
    });
  }
}
