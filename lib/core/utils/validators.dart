class Validators {
  Validators._();

  /// Validate Saudi phone number (9 digits after removing +966)
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'أدخل رقم الجوال';
    }
    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length != 9 || !cleaned.startsWith('5')) {
      return 'أدخل رقم جوال صحيح يبدأ بـ 5';
    }
    return null;
  }

  /// Format phone to international format
  static String formatPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.startsWith('966')) return '+$cleaned';
    if (cleaned.startsWith('0')) return '+966${cleaned.substring(1)}';
    return '+966$cleaned';
  }

  /// Validate OTP (4 digits)
  static String? validateOtp(String? value) {
    if (value == null || value.isEmpty) {
      return 'أدخل رمز التحقق';
    }
    if (value.length != 4 || !RegExp(r'^\d{4}$').hasMatch(value)) {
      return 'أدخل رمز التحقق المكون من 4 أرقام';
    }
    return null;
  }

  /// Validate display name
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'أدخل الاسم';
    }
    if (value.trim().length < 2) {
      return 'الاسم قصير جداً';
    }
    if (value.trim().length > 50) {
      return 'الاسم طويل جداً';
    }
    return null;
  }

  /// Validate post title
  static String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'أدخل عنوان الإعلان';
    }
    if (value.trim().length < 3) {
      return 'العنوان قصير جداً';
    }
    if (value.trim().length > 100) {
      return 'العنوان طويل جداً';
    }
    return null;
  }

  /// Validate post price
  static String? validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'أدخل السعر';
    }
    final price = double.tryParse(value);
    if (price == null || price <= 0) {
      return 'أدخل سعراً صحيحاً';
    }
    if (price > 99999) {
      return 'السعر مرتفع جداً';
    }
    return null;
  }

  /// Validate description (optional but has length limit)
  static String? validateDescription(String? value) {
    if (value != null && value.length > 1000) {
      return 'الوصف طويل جداً';
    }
    return null;
  }
}
