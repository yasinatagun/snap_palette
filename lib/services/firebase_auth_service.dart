import 'package:firebase_auth/firebase_auth.dart';

import '../core/logger.dart';
import '../models/user_model.dart';

/// Service class to handle Firebase Authentication operations
class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user from Firebase Auth
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email and password
  Future<UserModel> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('Sign in failed - no user returned');
      }

      // Create basic user model from auth data
      return _createUserModelFromAuthUser(userCredential.user!, email);
    } catch (e) {
      logger.logError('Sign in error', e);
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  /// Register with email and password
  Future<UserModel> registerWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('Registration failed - no user returned');
      }

      // Create basic user model from auth data
      return _createUserModelFromAuthUser(userCredential.user!, email);
    } catch (e) {
      logger.logError('Registration error', e);
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      logger.logError('Sign out error', e);
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  /// Create a user model from Firebase Auth user
  UserModel _createUserModelFromAuthUser(User user, String email) {
    return UserModel(
      id: user.uid,
      email: email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      isEmailVerified: user.emailVerified,
    );
  }
}
