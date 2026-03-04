class FirestorePaths {
  FirestorePaths._();

  // Collections
  static const String users = 'users';
  static const String posts = 'posts';
  static const String chats = 'chats';
  static const String categories = 'categories';
  static const String brands = 'brands';
  static const String favorites = 'favorites';
  static const String reports = 'reports';
  static const String comments = 'comments';
  static const String notifications = 'notifications';
  static const String postMutes = 'postMutes';
  static const String banners = 'banners';
  static const String homeSections = 'homeSections';
  static const String quickFilters = 'quickFilters';
  static const String boutiqueRequests = 'boutiqueRequests';

  // Sub-collections
  static String chatMessages(String chatId) => 'chats/$chatId/messages';

  // Storage paths
  static String postImages(String postId) => 'posts/$postId';
  static String userAvatar(String uid) => 'users/$uid/avatar';
  static String brandImage(String brandId) => 'brands/$brandId';
  static String bannerImage(String bannerId) => 'banners/$bannerId';
  static String sectionItemImage(String sectionId, int index) => 'sections/$sectionId/item_$index';
  static String boutiqueLogo(String uid) => 'boutiques/$uid/logo';
  static String boutiqueCover(String uid) => 'boutiques/$uid/cover';
  static String maaroofCertificate(String uid) => 'boutiques/$uid/maaroof';
}
