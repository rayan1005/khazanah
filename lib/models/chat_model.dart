import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String chatId;
  final List<String> participants;
  final String postId;
  final String lastMessage;
  final DateTime lastMessageTime;
  final Map<String, bool> blockedBy; // userId -> true if they blocked

  const ChatModel({
    required this.chatId,
    required this.participants,
    required this.postId,
    this.lastMessage = '',
    required this.lastMessageTime,
    this.blockedBy = const {},
  });

  String otherParticipant(String myUid) {
    return participants.firstWhere((p) => p != myUid, orElse: () => '');
  }

  bool isBlockedBy(String uid) => blockedBy[uid] == true;
  bool get hasBlock => blockedBy.values.any((v) => v);

  ChatModel copyWith({
    String? chatId,
    List<String>? participants,
    String? postId,
    String? lastMessage,
    DateTime? lastMessageTime,
    Map<String, bool>? blockedBy,
  }) {
    return ChatModel(
      chatId: chatId ?? this.chatId,
      participants: participants ?? this.participants,
      postId: postId ?? this.postId,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      blockedBy: blockedBy ?? this.blockedBy,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'participants': participants,
      'postId': postId,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'blockedBy': blockedBy,
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      chatId: map['chatId'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      postId: map['postId'] ?? '',
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime:
          (map['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      blockedBy: Map<String, bool>.from(map['blockedBy'] ?? {}),
    );
  }

  factory ChatModel.fromDoc(DocumentSnapshot doc) {
    return ChatModel.fromMap(doc.data() as Map<String, dynamic>);
  }
}
