import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  newComment,
  replyToComment,
  postSold,
}

class NotificationModel {
  final String notificationId;
  final String userId; // Who receives the notification
  final String postId;
  final String? commentId;
  final NotificationType type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final String? triggeredByUserId; // Who triggered the notification

  const NotificationModel({
    required this.notificationId,
    required this.userId,
    required this.postId,
    this.commentId,
    required this.type,
    required this.title,
    required this.message,
    this.isRead = false,
    required this.createdAt,
    this.triggeredByUserId,
  });

  NotificationModel copyWith({
    String? notificationId,
    String? userId,
    String? postId,
    String? commentId,
    NotificationType? type,
    String? title,
    String? message,
    bool? isRead,
    DateTime? createdAt,
    String? triggeredByUserId,
  }) {
    return NotificationModel(
      notificationId: notificationId ?? this.notificationId,
      userId: userId ?? this.userId,
      postId: postId ?? this.postId,
      commentId: commentId ?? this.commentId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      triggeredByUserId: triggeredByUserId ?? this.triggeredByUserId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'postId': postId,
      'commentId': commentId,
      'type': type.name,
      'title': title,
      'message': message,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'triggeredByUserId': triggeredByUserId,
    };
  }

  factory NotificationModel.fromMap(String id, Map<String, dynamic> map) {
    return NotificationModel(
      notificationId: id,
      userId: map['userId'] ?? '',
      postId: map['postId'] ?? '',
      commentId: map['commentId'],
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.newComment,
      ),
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      isRead: map['isRead'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      triggeredByUserId: map['triggeredByUserId'],
    );
  }

  factory NotificationModel.fromDoc(DocumentSnapshot doc) {
    return NotificationModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }
}

/// Tracks if a user has muted notifications for a specific post
class PostMuteModel {
  final String id;
  final String userId;
  final String postId;
  final DateTime mutedAt;

  const PostMuteModel({
    required this.id,
    required this.userId,
    required this.postId,
    required this.mutedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'postId': postId,
      'mutedAt': Timestamp.fromDate(mutedAt),
    };
  }

  factory PostMuteModel.fromMap(String id, Map<String, dynamic> map) {
    return PostMuteModel(
      id: id,
      userId: map['userId'] ?? '',
      postId: map['postId'] ?? '',
      mutedAt: (map['mutedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory PostMuteModel.fromDoc(DocumentSnapshot doc) {
    return PostMuteModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }
}
