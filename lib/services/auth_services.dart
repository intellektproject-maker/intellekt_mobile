class AuthService {
  AuthService._();

  static Future<Map<String, dynamic>?> login({
    required String id,
    required String password,
  }) async {
    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    final userId = id.toUpperCase();

    if (password != '123456') {
      return null;
    }

    // Student
    if (userId == 'IA001') {
      return {
        'id': 'IA001',
        'role': 'student',
        'must_reset_password': false,
      };
    }

    // Admin
    if (userId == 'IG001' || userId == 'IG002') {
      return {
        'id': userId,
        'role': 'admin',
        'must_reset_password': false,
      };
    }

    // Faculty
    if (userId.startsWith('IG')) {
      final number =
          int.tryParse(userId.substring(2)) ?? 0;

      if (number >= 3) {
        return {
          'id': userId,
          'role': 'faculty',
          'must_reset_password': false,
        };
      }
    }

    return null;
  }
}