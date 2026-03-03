import 'package:cloud_firestore/cloud_firestore.dart';

enum SectionType {
  styles,      // تسوق حسب الستايل (2 عناصر بجانب بعض)
  brands,      // الماركات (سكرول أفقي مع صور)
  categories,  // الفئات (بطاقات عمودية)
  featured,    // إعلانات مميزة
}

enum SectionLayout {
  grid2,       // شبكة 2 عناصر
  grid3,       // شبكة 3 عناصر
  horizontal,  // سكرول أفقي
  vertical,    // قائمة عمودية
}

class SectionItem {
  final String name;
  final String imageUrl;
  final String filterQuery; // مثل ?category=shoes أو ?brand=nike

  const SectionItem({
    required this.name,
    required this.imageUrl,
    required this.filterQuery,
  });

  factory SectionItem.fromMap(Map<String, dynamic> map) {
    return SectionItem(
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      filterQuery: map['filterQuery'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'filterQuery': filterQuery,
    };
  }

  SectionItem copyWith({
    String? name,
    String? imageUrl,
    String? filterQuery,
  }) {
    return SectionItem(
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      filterQuery: filterQuery ?? this.filterQuery,
    );
  }
}

class HomeSectionModel {
  final String id;
  final SectionType type;
  final SectionLayout layout;
  final String title;
  final String? subtitle;
  final List<SectionItem> items;
  final int order;
  final bool isActive;
  final bool showViewAll; // إظهار زر "عرض الكل"
  final String? viewAllQuery;
  final DateTime createdAt;

  const HomeSectionModel({
    required this.id,
    required this.type,
    required this.layout,
    required this.title,
    this.subtitle,
    required this.items,
    required this.order,
    this.isActive = true,
    this.showViewAll = false,
    this.viewAllQuery,
    required this.createdAt,
  });

  factory HomeSectionModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HomeSectionModel(
      id: doc.id,
      type: SectionType.values.firstWhere(
        (e) => e.name == (data['type'] ?? 'styles'),
        orElse: () => SectionType.styles,
      ),
      layout: SectionLayout.values.firstWhere(
        (e) => e.name == (data['layout'] ?? 'grid2'),
        orElse: () => SectionLayout.grid2,
      ),
      title: data['title'] ?? '',
      subtitle: data['subtitle'],
      items: (data['items'] as List<dynamic>?)
              ?.map((e) => SectionItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      order: data['order'] ?? 0,
      isActive: data['isActive'] ?? true,
      showViewAll: data['showViewAll'] ?? false,
      viewAllQuery: data['viewAllQuery'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'layout': layout.name,
      'title': title,
      'subtitle': subtitle,
      'items': items.map((e) => e.toMap()).toList(),
      'order': order,
      'isActive': isActive,
      'showViewAll': showViewAll,
      'viewAllQuery': viewAllQuery,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  HomeSectionModel copyWith({
    String? id,
    SectionType? type,
    SectionLayout? layout,
    String? title,
    String? subtitle,
    List<SectionItem>? items,
    int? order,
    bool? isActive,
    bool? showViewAll,
    String? viewAllQuery,
    DateTime? createdAt,
  }) {
    return HomeSectionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      layout: layout ?? this.layout,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      items: items ?? this.items,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      showViewAll: showViewAll ?? this.showViewAll,
      viewAllQuery: viewAllQuery ?? this.viewAllQuery,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get typeLabel {
    switch (type) {
      case SectionType.styles:
        return 'ستايلات';
      case SectionType.brands:
        return 'ماركات';
      case SectionType.categories:
        return 'فئات';
      case SectionType.featured:
        return 'مميزة';
    }
  }

  String get layoutLabel {
    switch (layout) {
      case SectionLayout.grid2:
        return 'شبكة (2)';
      case SectionLayout.grid3:
        return 'شبكة (3)';
      case SectionLayout.horizontal:
        return 'أفقي';
      case SectionLayout.vertical:
        return 'عمودي';
    }
  }
}
