import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/firebase_auth_service.dart';

/// Provider for FirebaseAuthService
final authServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});
