import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/logger.dart';
import '../models/user_model.dart';

/// Service class to handle local storage of user data
class UserStorageService {
  static const String _userKey = 'user_data';
  final SharedPreferences _prefs;

  UserStorageService(this._prefs);

  /// Save user data to local storage
  Future<void> saveUser(UserModel user) async {
    try {
      final userData = user.toJson();
      await _prefs.setString(_userKey, jsonEncode(userData));
      logger.logInfo('User data saved to local storage');
    } catch (e) {
      logger.logError('Error saving user data to local storage', e);
      throw Exception('Failed to save user data locally');
    }
  }

  /// Get user data from local storage
  UserModel? getUser() {
    try {
      final userData = _prefs.getString(_userKey);
      if (userData == null) {
        return null;
      }
      return UserModel.fromJson(jsonDecode(userData));
    } catch (e) {
      logger.logError('Error getting user data from local storage', e);
      return null;
    }
  }

  /// Clear user data from local storage
  Future<void> clearUser() async {
    try {
      await _prefs.remove(_userKey);
      logger.logInfo('User data cleared from local storage');
    } catch (e) {
      logger.logError('Error clearing user data from local storage', e);
      throw Exception('Failed to clear user data locally');
    }
  }

  /// Check if user exists in local storage
  bool hasUser() {
    return _prefs.containsKey(_userKey);
  }
}
