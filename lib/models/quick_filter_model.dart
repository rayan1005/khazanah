import 'package:cloud_firestore/cloud_firestore.dart';

class QuickFilterModel {
  final String id;
  final String label;
  final String filterQuery; // مثل ?gender=women أو ?category=shoes
  final String? iconName; // اسم الأيقونة (اختياري)
  final int order;
  final bool isActive;

  const QuickFilterModel({
    required this.id,
    required this.label,
    required this.filterQuery,
    this.iconName,
    required this.order,
    this.isActive = true,
  });

  factory QuickFilterModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QuickFilterModel(
      id: doc.id,
      label: data['label'] ?? '',
      filterQuery: data['filterQuery'] ?? '',
      iconName: data['iconName'],
      order: data['order'] ?? 0,
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'filterQuery': filterQuery,
      'iconName': iconName,
      'order': order,
      'isActive': isActive,
    };
  }

  QuickFilterModel copyWith({
    String? id,
    String? label,
    String? filterQuery,
    String? iconName,
    int? order,
    bool? isActive,
  }) {
    return QuickFilterModel(
      id: id ?? this.id,
      label: label ?? this.label,
      filterQuery: filterQuery ?? this.filterQuery,
      iconName: iconName ?? this.iconName,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
    );
  }
}
