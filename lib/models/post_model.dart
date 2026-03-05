import 'package:cloud_firestore/cloud_firestore.dart';

enum PostStatus { active, sold, expired }

class PostModel {
  final String postId;
  final String userId;
  final String title;
  final String description;
  final List<String> photos;
  final String category;
  final String brand;
  final String size;
  final String color;
  final String condition;
  final double price;
  final double? purchasePrice;
  final bool negotiable;
  final String city;
  final String gender;
  final PostStatus status;
  final int views;
  final DateTime createdAt;
  // Contact methods (at least one of chat/whatsapp must be true)
  final bool allowChat;
  final bool allowWhatsapp;
  // Comments enabled by default, user can disable
  final bool commentsEnabled;

  const PostModel({
    required this.postId,
    required this.userId,
    required this.title,
    this.description = '',
    required this.photos,
    required this.category,
    required this.brand,
    required this.size,
    required this.color,
    required this.condition,
    required this.price,
    this.purchasePrice,
    this.negotiable = false,
    required this.city,
    required this.gender,
    this.status = PostStatus.active,
    this.views = 0,
    required this.createdAt,
    this.allowChat = true,
    this.allowWhatsapp = false,
    this.commentsEnabled = true,
  });

  bool get isSold => status == PostStatus.sold;
  bool get isActive => status == PostStatus.active;
  bool get isExpired => status == PostStatus.expired;

  String get statusText {
    switch (status) {
      case PostStatus.active:
        return 'نشط';
      case PostStatus.sold:
        return 'تم البيع';
      case PostStatus.expired:
        return 'منتهي';
    }
  }

  PostModel copyWith({
    String? postId,
    String? userId,
    String? title,
    String? description,
    List<String>? photos,
    String? category,
    String? brand,
    String? size,
    String? color,
    String? condition,
    double? price,
    double? purchasePrice,
    bool? negotiable,
    String? city,
    String? gender,
    PostStatus? status,
    int? views,
    DateTime? createdAt,
    bool? allowChat,
    bool? allowWhatsapp,
    bool? commentsEnabled,
  }) {
    return PostModel(
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      photos: photos ?? this.photos,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      size: size ?? this.size,
      color: color ?? this.color,
      condition: condition ?? this.condition,
      price: price ?? this.price,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      negotiable: negotiable ?? this.negotiable,
      city: city ?? this.city,
      gender: gender ?? this.gender,
      status: status ?? this.status,
      views: views ?? this.views,
      createdAt: createdAt ?? this.createdAt,
      allowChat: allowChat ?? this.allowChat,
      allowWhatsapp: allowWhatsapp ?? this.allowWhatsapp,
      commentsEnabled: commentsEnabled ?? this.commentsEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'userId': userId,
      'title': title,
      'description': description,
      'photos': photos,
      'category': category,
      'brand': brand,
      'size': size,
      'color': color,
      'condition': condition,
      'price': price,
      'purchasePrice': purchasePrice,
      'negotiable': negotiable,
      'city': city,
      'gender': gender,
      'status': status.name,
      'views': views,
      'createdAt': Timestamp.fromDate(createdAt),
      'allowChat': allowChat,
      'allowWhatsapp': allowWhatsapp,
      'commentsEnabled': commentsEnabled,
    };
  }

  factory PostModel.fromMap(Map<String, dynamic> map) {
    // Backward compatibility: convert old contactMethod to new allowChat/allowWhatsapp
    bool allowChat = map['allowChat'] ?? true;
    bool allowWhatsapp = map['allowWhatsapp'] ?? false;
    if (map.containsKey('contactMethod') && !map.containsKey('allowChat')) {
      final method = map['contactMethod'] as String?;
      allowChat = method == 'chat' || method == null;
      allowWhatsapp = method == 'whatsapp';
    }

    return PostModel(
      postId: map['postId'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      photos: List<String>.from(map['photos'] ?? []),
      category: map['category'] ?? '',
      brand: map['brand'] ?? '',
      size: map['size'] ?? '',
      color: map['color'] ?? '',
      condition: map['condition'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      purchasePrice: map['purchasePrice'] != null ? (map['purchasePrice']).toDouble() : null,
      negotiable: map['negotiable'] ?? false,
      city: map['city'] ?? '',
      gender: map['gender'] ?? '',
      status: PostStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => PostStatus.active,
      ),
      views: map['views'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      allowChat: allowChat,
      allowWhatsapp: allowWhatsapp,
      commentsEnabled: map['commentsEnabled'] ?? true,
    );
  }

  factory PostModel.fromDoc(DocumentSnapshot doc) {
    return PostModel.fromMap(doc.data() as Map<String, dynamic>);
  }
}
