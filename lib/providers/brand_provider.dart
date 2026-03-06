import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/brand_model.dart';
import 'post_provider.dart';
import 'user_provider.dart';

final brandsStreamProvider = StreamProvider<List<BrandModel>>((ref) {
  final service = ref.read(firestoreServiceProvider);
  return service.brandsStream();
});

// Brands that have posts in the selected city
final brandsInCityProvider = FutureProvider.family<List<String>, String?>((ref, city) async {
  if (city == null || city.isEmpty) return [];
  final service = ref.read(firestoreServiceProvider);
  return service.brandsInCity(city);
});

/// Set of brand names that have active posts (respects city filter).
/// Used to filter the brand bar in home screen.
final activeBrandNamesProvider = FutureProvider<Set<String>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  final service = ref.read(firestoreServiceProvider);
  return service.activeBrandNames(city: city);
});

/// Brands filtered to only those with active posts. Cached via Riverpod.
final visibleBrandsProvider = Provider<AsyncValue<List<BrandModel>>>((ref) {
  final allBrands = ref.watch(brandsStreamProvider);
  final activeNames = ref.watch(activeBrandNamesProvider);

  return allBrands.when(
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
    data: (brands) => activeNames.when(
      loading: () => AsyncValue.data(brands), // show all while loading
      error: (_, __) => AsyncValue.data(brands),
      data: (names) {
        final filtered = brands.where((b) => names.contains(b.name)).toList();
        return AsyncValue.data(filtered);
      },
    ),
  );
});
