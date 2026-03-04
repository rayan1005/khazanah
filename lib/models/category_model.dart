import 'package:cloud_firestore/cloud_firestore.dart';

/// Size types for different categories
enum SizeType {
  clothes,  // XS, S, M, L, XL, XXL
  shoes,    // EU 30-50
  abayas,   // 52-62
  kids,     // Age-based: 0-3m, 3-6m, 6-12m, 1-2y, 2-3y, etc.
  bags,     // صغير, وسط, كبير
  none,     // No size (accessories)
}

class CategoryModel {
  final String id;
  final String name;
  final String icon;
  final String? imageUrl;
  final SizeType sizeType;
  final int order;

  const CategoryModel({
    required this.id,
    required this.name,
    this.icon = '',
    this.imageUrl,
    this.sizeType = SizeType.clothes,
    this.order = 0,
  });

  CategoryModel copyWith({
    String? id,
    String? name,
    String? icon,
    String? imageUrl,
    SizeType? sizeType,
    int? order,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      imageUrl: imageUrl ?? this.imageUrl,
      sizeType: sizeType ?? this.sizeType,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'icon': icon,
      'imageUrl': imageUrl,
      'sizeType': sizeType.name,
      'order': order,
    };
  }

  factory CategoryModel.fromMap(String id, Map<String, dynamic> map) {
    return CategoryModel(
      id: id,
      name: map['name'] ?? '',
      icon: map['icon'] ?? '',
      imageUrl: map['imageUrl'],
      sizeType: _parseSizeType(map['sizeType']),
      order: map['order'] ?? 0,
    );
  }

  static SizeType _parseSizeType(String? value) {
    switch (value) {
      case 'shoes':
        return SizeType.shoes;
      case 'abayas':
        return SizeType.abayas;
      case 'kids':
        return SizeType.kids;
      case 'bags':
        return SizeType.bags;
      case 'none':
        return SizeType.none;
      default:
        return SizeType.clothes;
    }
  }

  factory CategoryModel.fromDoc(DocumentSnapshot doc) {
    return CategoryModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }
}
