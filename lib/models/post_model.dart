import 'package:cloud_firestore/cloud_firestore.dart';

enum PostStatus { active, sold, expired }

/// Contact method for private messages (comments are always enabled)
enum ContactMethod { chat, whatsapp }

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
  final bool negotiable;
  final String city;
  final String gender;
  final PostStatus status;
  final int views;
  final DateTime createdAt;
  // Contact method for private messages (chat or whatsapp)
  final ContactMethod contactMethod;

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
    this.negotiable = false,
    required this.city,
    required this.gender,
    this.status = PostStatus.active,
    this.views = 0,
    required this.createdAt,
    this.contactMethod = ContactMethod.chat,
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
    bool? negotiable,
    String? city,
    String? gender,
    PostStatus? status,
    int? views,
    DateTime? createdAt,
    ContactMethod? contactMethod,
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
      negotiable: negotiable ?? this.negotiable,
      city: city ?? this.city,
      gender: gender ?? this.gender,
      status: status ?? this.status,
      views: views ?? this.views,
      createdAt: createdAt ?? this.createdAt,
      contactMethod: contactMethod ?? this.contactMethod,
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
      'negotiable': negotiable,
      'city': city,
      'gender': gender,
      'status': status.name,
      'views': views,
      'createdAt': Timestamp.fromDate(createdAt),
      'contactMethod': contactMethod.name,
    };
  }

  factory PostModel.fromMap(Map<String, dynamic> map) {
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
      negotiable: map['negotiable'] ?? false,
      city: map['city'] ?? '',
      gender: map['gender'] ?? '',
      status: PostStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => PostStatus.active,
      ),
      views: map['views'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      contactMethod: ContactMethod.values.firstWhere(
        (e) => e.name == map['contactMethod'],
        orElse: () => ContactMethod.chat,
      ),
    );
  }

  factory PostModel.fromDoc(DocumentSnapshot doc) {
    return PostModel.fromMap(doc.data() as Map<String, dynamic>);
  }
}
