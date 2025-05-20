import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/logger.dart';
import '../models/palette_model.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';

/// Service class to handle Firestore operations
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StorageService _storageService = StorageService();

  // Collection references
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Gets a reference to the current user's palettes subcollection
  CollectionReference<Map<String, dynamic>>? _getUserPalettesCollection() {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.email == null) {
      return null;
    }

    // Use email as the user document ID
    return _usersCollection.doc(currentUser.email).collection('palettes');
  }

  /// Creates or updates the current user's document in Firestore using email as ID
  Future<void> syncUserProfile() async {
    try {
      // Get current user from Firebase Auth
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      // Ensure email is available
      final email = currentUser.email;
      if (email == null || email.isEmpty) {
        throw Exception('User has no email address');
      }

      // Use email as document ID instead of UID
      final docId = email;

      // Check if user document already exists
      final userDoc = await _usersCollection.doc(docId).get();

      if (!userDoc.exists) {
        logger.logInfo(
          'Creating new user document in Firestore with email as ID',
        );
        // Create new user model with demo data
        final user = UserModel(
          id: currentUser.uid, // Keep UID in the user model
          email: email,
          displayName: currentUser.displayName ?? 'User ${email.split('@')[0]}',
          photoUrl:
              currentUser.photoURL ??
              'https://ui-avatars.com/api/?name=${email.split('@')[0]}',
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          isEmailVerified: currentUser.emailVerified,
        );

        // Save user data to Firestore using email as document ID
        await _usersCollection.doc(docId).set(user.toJson());
        logger.logInfo('User document created successfully with email: $email');
      } else {
        // Update last login time
        await _usersCollection.doc(docId).update({
          'lastLoginAt': DateTime.now().toIso8601String(),
        });
        logger.logInfo('Updated user last login time for email: $email');
      }
    } catch (e) {
      logger.logError('Error in ensureUserInFirestore', e);
      throw Exception('Failed to create/update user: $e');
    }
  }

  /// Get current user data from Firestore
  Future<UserModel?> getCurrentUser() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      final email = currentUser.email;
      if (email == null || email.isEmpty) return null;

      // Use email as document ID
      final doc = await _usersCollection.doc(email).get();
      if (!doc.exists) return null;

      return UserModel.fromJson({...doc.data()!, 'id': currentUser.uid});
    } catch (e) {
      logger.logError('Error getting current user data', e);
      return null;
    }
  }

  /// Update user data in Firestore
  Future<UserModel> updateUser(UserModel user) async {
    try {
      // Get email for document ID
      final currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.email == null) {
        throw Exception('No authenticated user with email found');
      }

      // Use email as the document ID
      await _usersCollection.doc(currentUser.email!).update(user.toJson());
      logger.logInfo(
        'User data updated in Firestore for email: ${currentUser.email}',
      );
      return user;
    } catch (e) {
      logger.logError('Error updating user data', e);
      throw Exception('Failed to update user data: $e');
    }
  }

  /// Save a palette to Firestore under the user's collection
  Future<PaletteModel> savePalette(PaletteModel palette) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      // Get user's palettes collection
      final palettesCollection = _getUserPalettesCollection();
      if (palettesCollection == null) {
        throw Exception('Could not get user palettes collection');
      }

      // Use palette name as document ID if provided, otherwise generate a random ID
      final String docId =
          (palette.name != null && palette.name!.isNotEmpty)
              ? palette.name!
              : palettesCollection.doc().id;

      // Create palette with the new ID
      final updatedPalette = palette.copyWith(
        id: docId,
        userId: currentUser.uid,
      );

      // Save to Firestore under user's palettes subcollection
      await palettesCollection.doc(docId).set(updatedPalette.toJson());
      logger.logInfo('Palette saved successfully with ID: $docId');

      return updatedPalette;
    } catch (e) {
      logger.logError('Error saving palette', e);
      throw Exception('Failed to save palette: $e');
    }
  }

  /// Get user palettes from Firestore
  Future<List<PaletteModel>> getUserPalettes() async {
    try {
      // Get user's palettes collection
      final palettesCollection = _getUserPalettesCollection();
      if (palettesCollection == null) {
        return [];
      }

      // Query palettes ordered by created date
      final querySnapshot =
          await palettesCollection.orderBy('createdAt', descending: true).get();

      return querySnapshot.docs
          .map((doc) => PaletteModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      logger.logError('Error fetching user palettes', e);
      return [];
    }
  }

  /// Delete a palette
  Future<void> deletePalette(String paletteId) async {
    try {
      // Get user's palettes collection
      final palettesCollection = _getUserPalettesCollection();
      if (palettesCollection == null) {
        throw Exception('Could not get user palettes collection');
      }

      // First get the palette to check if it has an image
      final paletteDoc = await palettesCollection.doc(paletteId).get();

      if (paletteDoc.exists) {
        final paletteData = paletteDoc.data();
        final String? imageUrl = paletteData?['imageUrl'] as String?;

        // Delete the palette document from Firestore
        await palettesCollection.doc(paletteId).delete();
        logger.logInfo('Palette document deleted successfully: $paletteId');

        // If palette has image URL, delete the image from storage
        if (imageUrl != null && imageUrl.isNotEmpty) {
          try {
            final bool deleted = await _storageService.deleteImage(imageUrl);
            if (deleted) {
              logger.logInfo('Palette image deleted successfully: $imageUrl');
            } else {
              logger.logWarning('Failed to delete palette image: $imageUrl');
            }
          } catch (storageError) {
            // If storage deletion fails, log but don't throw error
            // The Firestore document is already deleted at this point
            logger.logError('Error deleting palette image', storageError);
          }
        }
      } else {
        logger.logWarning('Palette document not found: $paletteId');
      }
    } catch (e) {
      logger.logError('Error deleting palette', e);
      throw Exception('Failed to delete palette: $e');
    }
  }
}
