import '../../models/login.dart';
import 'storage_service.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final StorageService _storage = StorageService.instance;

  /// Save authenticated user locally
  Future<void> saveUser(LoginModel user) async {
    await _storage.saveLoginSession(
      userId: user.id,
      role: user.role,
      mustResetPassword: user.mustResetPassword,
    );
  }

  /// Returns true if user already logged in
  Future<bool> isLoggedIn() async {
    return await _storage.isLoggedIn();
  }

  /// Returns logged-in user
  Future<LoginModel?> getLoggedInUser() async {
    final loggedIn = await _storage.isLoggedIn();

    if (!loggedIn) {
      return null;
    }

    final id = await _storage.getUserId();
    final role = await _storage.getRole();
    final mustReset =
    await _storage.mustResetPassword();

    if (id == null || role == null) {
      return null;
    }

    return LoginModel(
      success: true,
      id: id,
      name: "", // Placeholder until profile is fetched
      role: role,
      mustResetPassword: mustReset,
    );
  }

  /// Logout
  Future<void> logout() async {
    await _storage.clearSession();
  }
}