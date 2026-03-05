import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_settings_model.dart';
import '../services/firestore_service.dart';

final appSettingsStreamProvider = StreamProvider<AppSettingsModel>((ref) {
  return FirestoreService().appSettingsStream();
});
