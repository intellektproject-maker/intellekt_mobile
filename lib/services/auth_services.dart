class AuthService {
  AuthService._();

  static Future<Map<String, dynamic>?> login({
    required String id,
    required String password,
  }) async {
    // Simulate API delay.
    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    if (id.toUpperCase() == 'IA001' && password == 'IA001') {
      return {
        'id': 'IA001',
        'role': 'student',
        'must_reset_password': false,
      };
    }

    return null;
  }
}