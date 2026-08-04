import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/login.dart';
import '../repositories/auth_repository.dart';
import '../services/push_notification_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository = AuthRepository();

  static const FlutterSecureStorage _secureStorage =
  FlutterSecureStorage();

  static const String _sessionKey = 'student_login_session';

  LoginModel? _user;

  LoginModel? get user => _user;

  bool get isLoggedIn => _user != null;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  String? _error;

  String? get error => _error;

  AuthProvider() {
    restoreSession();
  }

  // ==========================================================
  // RESTORE SAVED SESSION
  // ==========================================================

  Future<void> restoreSession() async {
    try {
      final savedSession = await _secureStorage.read(
        key: _sessionKey,
      );

      if (savedSession == null || savedSession.isEmpty) {
        _user = null;
        return;
      }

      final decodedSession =
      jsonDecode(savedSession) as Map<String, dynamic>;

      final restoredUser = LoginModel.fromJson(decodedSession);

      if (!restoredUser.success ||
          restoredUser.id.isEmpty ||
          !restoredUser.isStudent) {
        await _secureStorage.delete(key: _sessionKey);
        _user = null;
        return;
      }

      _user = restoredUser;

      try {
        await PushNotificationService.instance.registerForStudent(
          restoredUser.id,
        );
      } catch (error) {
        debugPrint(
          'Could not re-register the notification token: $error',
        );
      }
    } catch (error) {
      debugPrint('Could not restore login session: $error');

      await _secureStorage.delete(key: _sessionKey);

      _user = null;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  // ==========================================================
  // LOGIN
  // ==========================================================

  Future<bool> login({
    required String id,
    required String password,
  }) async {
    _setLoading(true);

    try {
      _error = null;

      final loginResult = await _repository.login(
        id: id,
        password: password,
      );

      if (!loginResult.success) {
        _error = loginResult.message ?? 'Login failed.';
        _setLoading(false);
        return false;
      }

      if (!loginResult.isStudent) {
        _error = 'Only student accounts can use this application.';
        _setLoading(false);
        return false;
      }

      _user = loginResult;

      await _saveSession(loginResult);

      try {
        await PushNotificationService.instance.registerForStudent(
          loginResult.id,
        );
      } catch (error) {
        debugPrint(
          'Could not register the notification token: $error',
        );
      }

      _setLoading(false);

      return true;
    } catch (error) {
      _user = null;
      _error = _cleanErrorMessage(error);

      await _secureStorage.delete(key: _sessionKey);

      _setLoading(false);

      return false;
    }
  }

  // ==========================================================
  // CHANGE PASSWORD
  // ==========================================================

  Future<bool> changePassword({
    required String newPassword,
  }) async {
    if (_user == null) {
      _error = 'User not logged in.';
      notifyListeners();
      return false;
    }

    _setLoading(true);

    try {
      _error = null;

      final result = await _repository.changePassword(
        id: _user!.id,
        newPassword: newPassword,
      );

      if (result) {
        _user = LoginModel(
          success: _user!.success,
          message: _user!.message,
          id: _user!.id,
          name: _user!.name,
          role: _user!.role,
          mustResetPassword: false,
        );

        await _saveSession(_user!);
      }

      _setLoading(false);

      return result;
    } catch (error) {
      _error = _cleanErrorMessage(error);

      _setLoading(false);

      return false;
    }
  }

  // ==========================================================
  // LOGOUT
  // ==========================================================

  Future<void> logout() async {
    try {
      await PushNotificationService.instance
          .unregisterCurrentStudent();
    } catch (error) {
      debugPrint(
        'Could not unregister the notification token: $error',
      );
    }

    await _secureStorage.delete(key: _sessionKey);

    _user = null;
    _error = null;

    notifyListeners();
  }

  // ==========================================================
  // PRIVATE HELPERS
  // ==========================================================

  Future<void> _saveSession(LoginModel user) async {
    await _secureStorage.write(
      key: _sessionKey,
      value: jsonEncode(user.toJson()),
    );
  }

  String _cleanErrorMessage(Object error) {
    return error
        .toString()
        .replaceFirst('Exception: ', '')
        .trim();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}