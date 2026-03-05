import 'package:cloud_firestore/cloud_firestore.dart';

enum BoutiqueRequestStatus { pending, approved, rejected }

class BoutiqueRequestModel {
  final String id;
  final String userId;
  final String boutiqueName;
  final String description;
  final String instagramUrl;
  final String? tiktokUrl;
  final String? snapchatUrl;
  final String maaroofCertificateUrl; // صورة شهادة معروف
  final String maaroofUrl; // رابط متجر معروف
  final BoutiqueRequestStatus status;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  const BoutiqueRequestModel({
    required this.id,
    required this.userId,
    required this.boutiqueName,
    required this.description,
    required this.instagramUrl,
    this.tiktokUrl,
    this.snapchatUrl,
    required this.maaroofCertificateUrl,
    required this.maaroofUrl,
    this.status = BoutiqueRequestStatus.pending,
    this.rejectionReason,
    required this.createdAt,
    this.reviewedAt,
  });

  bool get isPending => status == BoutiqueRequestStatus.pending;
  bool get isApproved => status == BoutiqueRequestStatus.approved;
  bool get isRejected => status == BoutiqueRequestStatus.rejected;

  String get statusText {
    switch (status) {
      case BoutiqueRequestStatus.pending:
        return 'قيد المراجعة';
      case BoutiqueRequestStatus.approved:
        return 'مقبول';
      case BoutiqueRequestStatus.rejected:
        return 'مرفوض';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'boutiqueName': boutiqueName,
      'description': description,
      'instagramUrl': instagramUrl,
      'tiktokUrl': tiktokUrl,
      'snapchatUrl': snapchatUrl,
      'maaroofCertificateUrl': maaroofCertificateUrl,
      'maaroofUrl': maaroofUrl,
      'status': status.name,
      'rejectionReason': rejectionReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'reviewedAt':
          reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
    };
  }

  factory BoutiqueRequestModel.fromMap(String id, Map<String, dynamic> map) {
    return BoutiqueRequestModel(
      id: id,
      userId: map['userId'] ?? '',
      boutiqueName: map['boutiqueName'] ?? '',
      description: map['description'] ?? '',
      instagramUrl: map['instagramUrl'] ?? '',
      tiktokUrl: map['tiktokUrl'],
      snapchatUrl: map['snapchatUrl'],
      maaroofCertificateUrl: map['maaroofCertificateUrl'] ?? '',
      maaroofUrl: map['maaroofUrl'] ?? '',
      status: BoutiqueRequestStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => BoutiqueRequestStatus.pending,
      ),
      rejectionReason: map['rejectionReason'],
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedAt: map['reviewedAt'] != null
          ? (map['reviewedAt'] as Timestamp).toDate()
          : null,
    );
  }

  factory BoutiqueRequestModel.fromDoc(DocumentSnapshot doc) {
    return BoutiqueRequestModel.fromMap(
        doc.id, doc.data() as Map<String, dynamic>);
  }
}
