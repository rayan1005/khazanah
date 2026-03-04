class AppStrings {
  AppStrings._();

  // App
  static const String appName = 'خزانة';

  // Bottom Nav
  static const String home = 'الرئيسية';
  static const String addPost = 'أضف إعلان';
  static const String myPosts = 'إعلاناتي';
  static const String chats = 'المحادثات';
  static const String profile = 'حسابي';
  static const String boutiques = 'بوتيكات';

  // Auth
  static const String login = 'تسجيل الدخول';
  static const String enterPhone = 'أدخل رقم الجوال';
  static const String phoneHint = '5XXXXXXXX';
  static const String sendOtp = 'إرسال رمز التحقق';
  static const String enterOtp = 'أدخل رمز التحقق';
  static const String otpSentTo = 'تم إرسال رمز التحقق إلى';
  static const String verify = 'تحقق';
  static const String resendOtp = 'إعادة إرسال الرمز';
  static const String loginSubtitle = 'سجّل دخولك لتصفح الإعلانات والتواصل مع البائعين';

  // Profile Setup
  static const String setupProfile = 'إعداد الحساب';
  static const String displayName = 'الاسم';
  static const String displayNameHint = 'أدخل اسمك';
  static const String whatsappNumber = 'رقم الواتساب';
  static const String whatsappHint = '5XXXXXXXX';
  static const String selectCity = 'اختر المدينة';
  static const String save = 'حفظ';
  static const String skip = 'تخطي';

  // Home
  static const String search = 'ابحث عن ملابس، حقائب...';
  static const String allCities = 'كل المدن';
  static const String filter = 'تصفية';
  static const String noPostsFound = 'لا توجد إعلانات';
  static const String pullToRefresh = 'اسحب للتحديث';

  // Filters
  static const String category = 'الفئة';
  static const String brand = 'الماركة';
  static const String size = 'المقاس';
  static const String color = 'اللون';
  static const String condition = 'الحالة';
  static const String priceRange = 'نطاق السعر';
  static const String gender = 'القسم';
  static const String applyFilters = 'تطبيق';
  static const String resetFilters = 'إعادة ضبط';

  // Post
  static const String title = 'العنوان';
  static const String titleHint = 'مثال: فستان زارا مقاس M';
  static const String description = 'الوصف';
  static const String descriptionHint = 'اكتب تفاصيل المنتج...';
  static const String price = 'السعر';
  static const String priceHint = 'أدخل السعر بالريال';
  static const String negotiable = 'قابل للتفاوض';
  static const String addPhotos = 'أضف صور';
  static const String maxPhotos = 'حتى 5 صور';
  static const String publishPost = 'نشر الإعلان';
  static const String saveDraft = 'حفظ كمسودة';
  static const String editPost = 'تعديل الإعلان';
  static const String deletePost = 'حذف الإعلان';
  static const String markAsSold = 'تم البيع';
  static const String sold = 'تم البيع';
  static const String active = 'نشط';
  static const String expired = 'منتهي';
  static const String views = 'مشاهدة';

  // Conditions
  static const String conditionNewWithTag = 'جديد بالتاق';
  static const String conditionNew = 'جديد';
  static const String conditionLikeNew = 'شبه جديد';
  static const String conditionUsedClean = 'مستعمل نظيف';
  static const String conditionUsed = 'مستعمل';

  // Gender
  static const String women = 'نسائي';
  static const String men = 'رجالي';
  static const String unisex = 'للجنسين';
  static const String kids = 'أطفال';

  // Colors
  static const String colorBlack = 'أسود';
  static const String colorWhite = 'أبيض';
  static const String colorRed = 'أحمر';
  static const String colorBlue = 'أزرق';
  static const String colorBeige = 'بيج';
  static const String colorBrown = 'بني';
  static const String colorGray = 'رمادي';
  static const String colorPink = 'وردي';
  static const String colorGreen = 'أخضر';
  static const String colorOrange = 'برتقالي';
  static const String colorYellow = 'أصفر';
  static const String colorPurple = 'بنفسجي';
  static const String colorMulti = 'ملون';

  // Sizes
  static const List<String> clothingSizes = [
    'XS', 'S', 'M', 'L', 'XL', 'XXL', 'مقاس حر',
  ];

  // Chat
  static const String typeMessage = 'اكتب رسالة...';
  static const String openWhatsApp = 'التواصل عبر واتساب';
  static const String blockUser = 'حظر المستخدم';
  static const String unblockUser = 'إلغاء الحظر';
  static const String chatWithSeller = 'محادثة البائع';
  static const String noChats = 'لا توجد محادثات';

  // Profile
  static const String myFavorites = 'المفضلة';
  static const String settings = 'الإعدادات';
  static const String editProfile = 'تعديل الملك الشخصي';
  static const String changeCity = 'تغيير المدينة';
  static const String notificationPreferences = 'إعدادات الإشعارات';
  static const String logout = 'تسجيل الخروج';
  static const String deleteAccount = 'حذف الحساب';
  static const String viewProfile = 'عرض الملف الشخصي';

  // Post Detail
  static const String similarPosts = 'إعلانات مشابهة';
  static const String share = 'مشاركة';
  static const String report = 'إبلاغ';
  static const String reportReason = 'سبب الإبلاغ';
  static const String reportSubmitted = 'تم إرسال البلاغ';
  static const String sellerInfo = 'معلومات البائع';

  // Admin
  static const String adminPanel = 'لوحة التحكم';
  static const String manageCategories = 'إدارة الفئات';
  static const String manageBrands = 'إدارة الماركات';
  static const String manageReports = 'إدارة البلاغات';
  static const String manageUsers = 'إدارة المستخدمين';
  static const String dashboard = 'الإحصائيات';
  static const String totalPosts = 'إجمالي الإعلانات';
  static const String totalUsers = 'إجمالي المستخدمين';
  static const String activeCities = 'المدن النشطة';
  static const String addCategory = 'إضافة فئة';
  static const String addBrand = 'إضافة ماركة';
  static const String banUser = 'حظر المستخدم';
  static const String warnUser = 'تحذير المستخدم';

  // Errors & Messages
  static const String error = 'خطأ';
  static const String success = 'تم بنجاح';
  static const String loading = 'جاري التحميل...';
  static const String noInternet = 'لا يوجد اتصال بالإنترنت';
  static const String somethingWentWrong = 'حدث خطأ، حاول مرة أخرى';
  static const String confirmDelete = 'هل أنت متأكد من الحذف؟';
  static const String confirmLogout = 'هل تريد تسجيل الخروج؟';
  static const String yes = 'نعم';
  static const String no = 'لا';
  static const String cancel = 'إلغاء';
  static const String ok = 'حسناً';
  static const String draftSaved = 'تم حفظ المسودة';
  static const String postPublished = 'تم نشر الإعلان';
  static const String postUpdated = 'تم تحديث الإعلان';
  static const String postDeleted = 'تم حذف الإعلان';

  // Permission dialogs
  static const String cameraPermissionTitle = 'إذن الكاميرا';
  static const String cameraPermissionMessage = 'نحتاج إذن الكاميرا لالتقاط صور المنتجات التي تريد بيعها';
  static const String galleryPermissionTitle = 'إذن الصور';
  static const String galleryPermissionMessage = 'نحتاج إذن الوصول للصور لاختيار صور المنتجات من معرض الصور';
  static const String locationPermissionTitle = 'إذن الموقع';
  static const String locationPermissionMessage = 'نحتاج إذن الموقع لتحديد مدينتك تلقائياً وعرض الإعلانات القريبة منك';
  static const String notificationPermissionTitle = 'إذن الإشعارات';
  static const String notificationPermissionMessage = 'فعّل الإشعارات لتصلك تنبيهات الرسائل الجديدة وتحديثات إعلاناتك';
  static const String permissionDenied = 'تم رفض الإذن. يمكنك تفعيله من الإعدادات';
  static const String openSettings = 'فتح الإعدادات';

  // Missing / additional strings
  static const String deleteAccountConfirm = 'سيتم حذف حسابك نهائياً ولن تتمكن من استعادته. هل تريد المتابعة؟';
  static const String noFavorites = 'لا توجد مفضلات';
  static const String send = 'إرسال';
  static const String delete = 'حذف';
  static const String favorites = 'المفضلة';
  static const String fullName = 'الاسم';
  static const String cityLabel = 'المدينة';
  static const String whatsappOptional = 'واتساب (اختياري)';

  // Boutique
  static const String upgradeToBoutique = 'ترقية لبوتيك';
  static const String boutiqueRequest = 'طلب ترقية لبوتيك';
  static const String boutiqueName = 'اسم البوتيك';
  static const String boutiqueDescription = 'وصف البوتيك';
  static const String instagramAccount = 'حساب انستقرام';
  static const String tiktokAccount = 'حساب تيكتوك (اختياري)';
  static const String maaroofCertificate = 'شهادة معروف';
  static const String maaroofUrl = 'رابط متجر معروف';
  static const String uploadMaaroofCertificate = 'تحميل شهادة معروف';
  static const String submitRequest = 'إرسال الطلب';
  static const String requestPending = 'طلبك قيد المراجعة';
  static const String requestApproved = 'تم قبول طلبك';
  static const String requestRejected = 'تم رفض طلبك';
  static const String manageBoutiqueRequests = 'طلبات البوتيك';
  static const String noBoutiques = 'لا توجد بوتيكات حالياً';
  static const String visitStore = 'زيارة المتجر';
  static const String boutiqueVerified = 'بوتيك معتمد';
}
