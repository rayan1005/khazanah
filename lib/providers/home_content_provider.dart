import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import '../models/banner_model.dart';
import '../models/home_section_model.dart';
import '../models/quick_filter_model.dart';
import 'user_provider.dart';

// ==================== BANNERS ====================

/// All banners stream (for admin)
final bannersStreamProvider = StreamProvider<List<BannerModel>>((ref) {
  final service = ref.read(firestoreServiceProvider);
  return service.bannersStream();
});

/// Active banners only (for home screen)
final activeBannersStreamProvider = StreamProvider<List<BannerModel>>((ref) {
  final service = ref.read(firestoreServiceProvider);
  return service.activeBannersStream();
});

// ==================== HOME SECTIONS ====================

/// All home sections stream (for admin)
final homeSectionsStreamProvider = StreamProvider<List<HomeSectionModel>>((ref) {
  final service = ref.read(firestoreServiceProvider);
  return service.homeSectionsStream();
});

/// Active home sections only (for home screen)
final activeHomeSectionsStreamProvider = StreamProvider<List<HomeSectionModel>>((ref) {
  final service = ref.read(firestoreServiceProvider);
  return service.activeHomeSectionsStream();
});

// ==================== QUICK FILTERS ====================

/// All quick filters stream (for admin)
final quickFiltersStreamProvider = StreamProvider<List<QuickFilterModel>>((ref) {
  final service = ref.read(firestoreServiceProvider);
  return service.quickFiltersStream();
});

/// Active quick filters only (for home screen)
final activeQuickFiltersStreamProvider = StreamProvider<List<QuickFilterModel>>((ref) {
  final service = ref.read(firestoreServiceProvider);
  return service.activeQuickFiltersStream();
});
