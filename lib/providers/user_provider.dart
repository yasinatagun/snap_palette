import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/logger.dart';
import '../models/user_model.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';
import '../services/user_storage_service.dart';
import 'auth_provider.dart';
import 'firestore_provider.dart';
import 'storage_provider.dart';

/// Provider for the current user state
final userProvider = NotifierProvider<UserNotifier, UserModel?>(() {
  return UserNotifier();
});

/// Notifier class to handle user state
class UserNotifier extends Notifier<UserModel?> {
  late FirebaseAuthService _authService;
  late FirestoreService _firestoreService;
  UserStorageService? _storageService;
  late AsyncValue<UserStorageService> _storageServiceAsync;

  @override
  UserModel? build() {
    // Initialize services
    _authService = ref.watch(authServiceProvider);
    _firestoreService = ref.watch(firestoreServiceProvider);
    _storageServiceAsync = ref.watch(userStorageServiceProvider);

    // Setup initialization
    _init();

    return null;
  }

  /// Initialize the user state
  Future<void> _init() async {
    // Initialize storage service when it's ready
    _storageServiceAsync.whenData((service) {
      _storageService = service;
      _loadStoredUser();
      _setupAuthListener();
    });
  }

  /// Load user from local storage
  void _loadStoredUser() {
    if (_storageService == null) return;

    final savedUser = _storageService!.getUser();
    if (savedUser != null) {
      state = savedUser;
      logger.logInfo('User loaded from local storage');

      // Sync user profile with Firestore
      _firestoreService
          .syncUserProfile()
          .then((_) {
            _updateUserFromFirestore();
          })
          .catchError((e) {
            logger.logError('Error syncing user with Firestore', e);
          });
    }
  }

  /// Setup listener for auth state changes
  void _setupAuthListener() {
    _authService.authStateChanges.listen((user) async {
      if (user == null) {
        await _storageService?.clearUser();
        state = null;
        logger.logInfo('User signed out');
      } else {
        // Create or update user in Firestore
        await _firestoreService.syncUserProfile();
        // Update user data from Firestore
        await _updateUserFromFirestore();
      }
    });
  }

  /// Update user data from Firestore
  Future<void> _updateUserFromFirestore() async {
    if (_storageService == null) return;

    final userData = await _firestoreService.getCurrentUser();
    if (userData != null) {
      await _storageService!.saveUser(userData);
      state = userData;
      logger.logInfo('User data updated from Firestore');
    }
  }

  /// Sign in with email and password
  Future<void> signIn(String email, String password) async {
    try {
      // Authenticate with Firebase
      final user = await _authService.signInWithEmail(email, password);

      // Save basic user to storage and state
      await _storageService?.saveUser(user);
      state = user;

      // Sync user profile with Firestore
      await _firestoreService.syncUserProfile();
      await _updateUserFromFirestore();

      logger.logInfo('User signed in successfully');
    } catch (e) {
      logger.logError('Sign in failed', e);
      rethrow;
    }
  }

  /// Register with email and password
  Future<void> register(String email, String password) async {
    try {
      // Register with Firebase
      final user = await _authService.registerWithEmail(email, password);

      // Save basic user to storage and state
      await _storageService?.saveUser(user);
      state = user;

      // Create user in Firestore and update with full data
      await _firestoreService.syncUserProfile();
      await _updateUserFromFirestore();

      logger.logInfo('User registered successfully');
    } catch (e) {
      logger.logError('Registration failed', e);
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      await _storageService?.clearUser();
      state = null;
      logger.logInfo('User signed out successfully');
    } catch (e) {
      logger.logError('Sign out failed', e);
      rethrow;
    }
  }

  /// Update user data
  Future<void> updateUser(UserModel user) async {
    try {
      // Update in Firestore
      final updatedUser = await _firestoreService.updateUser(user);

      // Update in storage and state
      await _storageService?.saveUser(updatedUser);
      state = updatedUser;

      logger.logInfo('User data updated successfully');
    } catch (e) {
      logger.logError('Update user failed', e);
      rethrow;
    }
  }
}
