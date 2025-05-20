import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/firestore_service.dart';

/// Provider for FirestoreService
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});
