import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String postId;
  final String reporterId;
  final String reason;
  final DateTime createdAt;

  const ReportModel({
    required this.id,
    required this.postId,
    required this.reporterId,
    required this.reason,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'reporterId': reporterId,
      'reason': reason,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ReportModel.fromMap(String id, Map<String, dynamic> map) {
    return ReportModel(
      id: id,
      postId: map['postId'] ?? '',
      reporterId: map['reporterId'] ?? '',
      reason: map['reason'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory ReportModel.fromDoc(DocumentSnapshot doc) {
    return ReportModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }
}
