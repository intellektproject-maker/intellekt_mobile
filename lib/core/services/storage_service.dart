import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ===========================================================
/// INTELLEKT STORAGE SERVICE
/// ===========================================================
///
/// Secure Storage
/// --------------
/// Access Token
/// Refresh Token
/// User ID
/// User Role
///
/// Shared Preferences
/// ------------------
/// Theme
/// Remember Me
/// Login State
///
/// ===========================================================

class StorageService {
  StorageService._();

  static const FlutterSecureStorage _secureStorage =
  FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(),
  );

  // ==========================================================
  // Secure Storage Keys
  // ==========================================================

  static const String _accessToken = "access_token";

  static const String _refreshToken = "refresh_token";

  static const String _userId = "user_id";

  static const String _userRole = "user_role";

  // ==========================================================
  // Shared Preference Keys
  // ==========================================================

  static const String _rememberMe = "remember_me";

  static const String _isLoggedIn = "is_logged_in";

  static const String _themeMode = "theme_mode";

  // ==========================================================
  // ACCESS TOKEN
  // ==========================================================

  static Future<void> saveAccessToken(String token) async {
    await _secureStorage.write(
      key: _accessToken,
      value: token,
    );
  }

  static Future<String?> getAccessToken() async {
    return await _secureStorage.read(
      key: _accessToken,
    );
  }

  static Future<void> deleteAccessToken() async {
    await _secureStorage.delete(
      key: _accessToken,
    );
  }

  // ==========================================================
  // REFRESH TOKEN
  // ==========================================================

  static Future<void> saveRefreshToken(String token) async {
    await _secureStorage.write(
      key: _refreshToken,
      value: token,
    );
  }

  static Future<String?> getRefreshToken() async {
    return await _secureStorage.read(
      key: _refreshToken,
    );
  }

  static Future<void> deleteRefreshToken() async {
    await _secureStorage.delete(
      key: _refreshToken,
    );
  }

  // ==========================================================
  // USER ID
  // ==========================================================

  static Future<void> saveUserId(String userId) async {
    await _secureStorage.write(
      key: _userId,
      value: userId,
    );
  }

  static Future<String?> getUserId() async {
    return await _secureStorage.read(
      key: _userId,
    );
  }

  static Future<void> deleteUserId() async {
    await _secureStorage.delete(
      key: _userId,
    );
  }

  // ==========================================================
  // USER ROLE
  // ==========================================================

  static Future<void> saveUserRole(String role) async {
    await _secureStorage.write(
      key: _userRole,
      value: role,
    );
  }

  static Future<String?> getUserRole() async {
    return await _secureStorage.read(
      key: _userRole,
    );
  }

  static Future<void> deleteUserRole() async {
    await _secureStorage.delete(
      key: _userRole,
    );
  }

  // ==========================================================
  // REMEMBER ME
  // ==========================================================

  static Future<void> setRememberMe(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_rememberMe, value);
  }

  static Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(_rememberMe) ?? false;
  }

  // ==========================================================
  // LOGIN STATE
  // ==========================================================

  static Future<void> setLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_isLoggedIn, value);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(_isLoggedIn) ?? false;
  }

  // ==========================================================
  // THEME
  // ==========================================================

  static Future<void> saveThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_themeMode, mode);
  }

  static Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_themeMode) ?? "light";
  }

  // ==========================================================
  // LOGOUT
  // ==========================================================

  static Future<void> clearSession() async {
    await deleteAccessToken();
    await deleteRefreshToken();
    await deleteUserId();
    await deleteUserRole();

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_isLoggedIn);
  }

  // ==========================================================
  // CLEAR EVERYTHING
  // ==========================================================

  static Future<void> clearAll() async {
    await _secureStorage.deleteAll();

    final prefs = await SharedPreferences.getInstance();

    await prefs.clear();
  }
}