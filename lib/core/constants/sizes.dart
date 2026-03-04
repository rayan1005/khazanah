import '../../models/category_model.dart';

/// Get sizes based on category size type
class Sizes {
  Sizes._();

  /// Clothing sizes (S, M, L, XL, etc.)
  static const List<String> clothes = [
    'XS',
    'S',
    'M',
    'L',
    'XL',
    'XXL',
    'XXXL',
  ];

  /// Shoe sizes (EU 30-50)
  static const List<String> shoes = [
    '30', '31', '32', '33', '34', '35', '36', '37', '38', '39',
    '40', '41', '42', '43', '44', '45', '46', '47', '48', '49', '50',
  ];

  /// Abaya sizes (52-62)
  static const List<String> abayas = [
    '52', '54', '56', '58', '60', '62',
  ];

  /// Bag sizes
  static const List<String> bags = [
    'صغير',
    'وسط',
    'كبير',
  ];

  /// Kids sizes (age-based)
  static const List<String> kids = [
    '0-3 شهور',
    '3-6 شهور',
    '6-12 شهر',
    '1-2 سنة',
    '2-3 سنوات',
    '3-4 سنوات',
    '4-5 سنوات',
    '5-6 سنوات',
    '6-7 سنوات',
    '7-8 سنوات',
    '8-9 سنوات',
    '9-10 سنوات',
    '10-11 سنة',
    '11-12 سنة',
    '12-13 سنة',
    '13-14 سنة',
  ];

  /// Get sizes for a given size type
  static List<String> forSizeType(SizeType sizeType) {
    switch (sizeType) {
      case SizeType.clothes:
        return clothes;
      case SizeType.shoes:
        return shoes;
      case SizeType.abayas:
        return abayas;
      case SizeType.kids:
        return kids;
      case SizeType.bags:
        return bags;
      case SizeType.none:
        return [];
    }
  }

  /// Get sizes for a category ID (fallback when category model not available)
  static List<String> forCategoryId(String? categoryId) {
    switch (categoryId) {
      case 'shoes':
        return shoes;
      case 'abayas':
        return abayas;
      case 'kids':
        return kids;
      case 'bags':
        return bags;
      case 'accessories':
        return [];
      default:
        return clothes;
    }
  }
}
