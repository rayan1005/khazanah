import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/brand_model.dart';
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
