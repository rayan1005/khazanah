import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String commentId;
  final String postId;
  final String userId;
  final String text;
  final DateTime createdAt;
  final String? replyToCommentId;
  final bool isPrivate; // Only visible to post owner, admin, and comment author

  const CommentModel({
    required this.commentId,
    required this.postId,
    required this.userId,
    required this.text,
    required this.createdAt,
    this.replyToCommentId,
    this.isPrivate = false,
  });

  CommentModel copyWith({
    String? commentId,
    String? postId,
    String? userId,
    String? text,
    DateTime? createdAt,
    String? replyToCommentId,
    bool? isPrivate,
  }) {
    return CommentModel(
      commentId: commentId ?? this.commentId,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      replyToCommentId: replyToCommentId ?? this.replyToCommentId,
      isPrivate: isPrivate ?? this.isPrivate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'userId': userId,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      'replyToCommentId': replyToCommentId,
      'isPrivate': isPrivate,
    };
  }

  factory CommentModel.fromMap(String id, Map<String, dynamic> map) {
    return CommentModel(
      commentId: id,
      postId: map['postId'] ?? '',
      userId: map['userId'] ?? '',
      text: map['text'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      replyToCommentId: map['replyToCommentId'],
      isPrivate: map['isPrivate'] ?? false,
    );
  }

  factory CommentModel.fromDoc(DocumentSnapshot doc) {
    return CommentModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }
}
