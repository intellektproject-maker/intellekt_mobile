import 'package:flutter/material.dart';

import '../models/login.dart';
import '../repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository = AuthRepository();

  LoginModel? _user;

  LoginModel? get user => _user;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  String? _error;

  String? get error => _error;

  Future<bool> login({
    required String id,
    required String password,
  }) async {
    _setLoading(true);

    try {
      _error = null;

      _user = await _repository.login(
        id: id,
        password: password,
      );

      _setLoading(false);

      return true;
    } catch (e) {
      _error = e.toString();

      _setLoading(false);

      return false;
    }
  }

  Future<bool> changePassword({
    required String newPassword,
  }) async {
    if (_user == null) {
      _error = "User not logged in.";

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

      _setLoading(false);

      return result;
    } catch (e) {
      _error = e.toString();

      _setLoading(false);

      return false;
    }
  }

  void logout() {
    _user = null;

    _error = null;

    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;

    notifyListeners();
  }
}