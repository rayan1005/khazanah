import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_model.dart';
import 'user_provider.dart';

final categoriesStreamProvider = StreamProvider<List<CategoryModel>>((ref) {
  final service = ref.read(firestoreServiceProvider);
  return service.categoriesStream();
});
