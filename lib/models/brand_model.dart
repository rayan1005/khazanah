import 'package:cloud_firestore/cloud_firestore.dart';

class BrandModel {
  final String id;
  final String name;
  final String? imageUrl;
  final int order;

  const BrandModel({
    required this.id,
    required this.name,
    this.imageUrl,
    this.order = 0,
  });

  BrandModel copyWith({
    String? id,
    String? name,
    String? imageUrl,
    int? order,
  }) {
    return BrandModel(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'order': order,
    };
  }

  factory BrandModel.fromMap(String id, Map<String, dynamic> map) {
    return BrandModel(
      id: id,
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'],
      order: map['order'] ?? 0,
    );
  }

  factory BrandModel.fromDoc(DocumentSnapshot doc) {
    return BrandModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }
}
