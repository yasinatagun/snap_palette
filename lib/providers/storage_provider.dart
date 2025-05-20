import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/storage_service.dart';
import '../services/user_storage_service.dart';

/// Provider for SharedPreferences
final sharedPreferencesProvider = Provider<Future<SharedPreferences>>((ref) {
  return SharedPreferences.getInstance();
});

/// Provider for UserStorageService
final userStorageServiceProvider = FutureProvider<UserStorageService>((
  ref,
) async {
  final prefs = await ref.watch(sharedPreferencesProvider);
  return UserStorageService(prefs);
});

/// Provider for Firebase StorageService
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});
