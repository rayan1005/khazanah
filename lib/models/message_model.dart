import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String messageId;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool read;

  const MessageModel({
    required this.messageId,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.read = false,
  });

  MessageModel copyWith({
    String? messageId,
    String? senderId,
    String? text,
    DateTime? timestamp,
    bool? read,
  }) {
    return MessageModel(
      messageId: messageId ?? this.messageId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      read: read ?? this.read,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'read': read,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      messageId: map['messageId'] ?? '',
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: map['read'] ?? false,
    );
  }

  factory MessageModel.fromDoc(DocumentSnapshot doc) {
    return MessageModel.fromMap(doc.data() as Map<String, dynamic>);
  }
}
