import 'package:cloud_firestore/cloud_firestore.dart';

enum BannerType {
  slider, // سلايدر في الأعلى
  hero,   // صورة كبيرة مع نص
  promo,  // بانر ترويجي صغير
}

class BannerModel {
  final String id;
  final BannerType type;
  final String title;
  final String? subtitle;
  final String imageUrl;
  final String? actionUrl; // رابط عند الضغط (مثل /search?category=shoes)
  final int order;
  final bool isActive;
  final DateTime? expiresAt;
  final DateTime createdAt;

  const BannerModel({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    required this.imageUrl,
    this.actionUrl,
    required this.order,
    this.isActive = true,
    this.expiresAt,
    required this.createdAt,
  });

  factory BannerModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BannerModel(
      id: doc.id,
      type: BannerType.values.firstWhere(
        (e) => e.name == (data['type'] ?? 'slider'),
        orElse: () => BannerType.slider,
      ),
      title: data['title'] ?? '',
      subtitle: data['subtitle'],
      imageUrl: data['imageUrl'] ?? '',
      actionUrl: data['actionUrl'],
      order: data['order'] ?? 0,
      isActive: data['isActive'] ?? true,
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'title': title,
      'subtitle': subtitle,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
      'order': order,
      'isActive': isActive,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  BannerModel copyWith({
    String? id,
    BannerType? type,
    String? title,
    String? subtitle,
    String? imageUrl,
    String? actionUrl,
    int? order,
    bool? isActive,
    DateTime? expiresAt,
    DateTime? createdAt,
  }) {
    return BannerModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Check if banner is valid (active and not expired)
  bool get isValid {
    if (!isActive) return false;
    if (expiresAt != null && expiresAt!.isBefore(DateTime.now())) return false;
    return true;
  }

  String get typeLabel {
    switch (type) {
      case BannerType.slider:
        return 'سلايدر';
      case BannerType.hero:
        return 'هيرو';
      case BannerType.promo:
        return 'ترويجي';
    }
  }
}
