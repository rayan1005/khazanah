class SaudiCities {
  SaudiCities._();

  static const List<String> cities = [
    'الرياض',
    'جدة',
    'مكة المكرمة',
    'المدينة المنورة',
    'الدمام',
    'الخبر',
    'الظهران',
    'الطائف',
    'تبوك',
    'بريدة',
    'عنيزة',
    'حائل',
    'خميس مشيط',
    'أبها',
    'نجران',
    'جيزان',
    'ينبع',
    'الأحساء',
    'الجبيل',
    'القطيف',
    'الباحة',
    'سكاكا',
    'عرعر',
    'القصيم',
    'حفر الباطن',
    'الخرج',
    'المجمعة',
    'رابغ',
    'أخرى',
  ];

  /// Try to map a geocoded city name to one of our known cities
  static String? matchCity(String geocodedName) {
    final lower = geocodedName.trim();
    for (final city in cities) {
      if (lower.contains(city) || city.contains(lower)) {
        return city;
      }
    }
    // English name mappings
    final englishMap = {
      'riyadh': 'الرياض',
      'jeddah': 'جدة',
      'jidda': 'جدة',
      'mecca': 'مكة المكرمة',
      'makkah': 'مكة المكرمة',
      'medina': 'المدينة المنورة',
      'madinah': 'المدينة المنورة',
      'dammam': 'الدمام',
      'khobar': 'الخبر',
      'dhahran': 'الظهران',
      'taif': 'الطائف',
      'tabuk': 'تبوك',
      'buraidah': 'بريدة',
      'hail': 'حائل',
      'abha': 'أبها',
      'najran': 'نجران',
      'jizan': 'جيزان',
      'yanbu': 'ينبع',
      'jubail': 'الجبيل',
    };
    final lowerEn = lower.toLowerCase();
    for (final entry in englishMap.entries) {
      if (lowerEn.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }
}
