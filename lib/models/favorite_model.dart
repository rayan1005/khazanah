import 'package:cloud_firestore/cloud_firestore.dart';

class FavoriteModel {
  final String id;
  final String userId;
  final String postId;
  final DateTime createdAt;

  const FavoriteModel({
    required this.id,
    required this.userId,
    required this.postId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'postId': postId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory FavoriteModel.fromMap(String id, Map<String, dynamic> map) {
    return FavoriteModel(
      id: id,
      userId: map['userId'] ?? '',
      postId: map['postId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory FavoriteModel.fromDoc(DocumentSnapshot doc) {
    return FavoriteModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }
}
