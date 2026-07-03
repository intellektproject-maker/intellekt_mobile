import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Keys
  static const String _userIdKey = "user_id";
  static const String _roleKey = "user_role";
  static const String _loggedInKey = "logged_in";
  static const String _mustResetPasswordKey = "must_reset_password";

  // Save Login Session
  Future<void> saveLoginSession({
    required String userId,
    required String role,
    required bool mustResetPassword,
  }) async {
    await _storage.write(key: _userIdKey, value: userId);
    await _storage.write(key: _roleKey, value: role);
    await _storage.write(
      key: _mustResetPasswordKey,
      value: mustResetPassword.toString(),
    );
    await _storage.write(key: _loggedInKey, value: "true");
  }

  // User ID
  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  // Role
  Future<String?> getRole() async {
    return await _storage.read(key: _roleKey);
  }

  // Password Reset Flag
  Future<bool> mustResetPassword() async {
    final value =
    await _storage.read(key: _mustResetPasswordKey);

    return value == "true";
  }

  // Login Status
  Future<bool> isLoggedIn() async {
    final value =
    await _storage.read(key: _loggedInKey);

    return value == "true";
  }

  // Logout
  Future<void> clearSession() async {
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _roleKey);
    await _storage.delete(key: _loggedInKey);
    await _storage.delete(key: _mustResetPasswordKey);
  }
}