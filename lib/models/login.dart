/// ===========================================================
/// INTELLEKT LOGIN MODEL
/// ===========================================================
///
/// Login Model
///
/// User ID Rules
/// -------------------------------------
/// IA001+   -> Student
/// IG001-2  -> Admin
/// IG003+   -> Faculty
///
/// ===========================================================

class LoginModel {
  final bool success;

  final String? message;

  final String id;

  final String name;

  final String role;

  final bool mustResetPassword;

  LoginModel({
    required this.success,
    this.message,
    required this.id,
    required this.name,
    required this.role,
    required this.mustResetPassword,
  });

  factory LoginModel.fromJson(Map<String, dynamic> json) {
    return LoginModel(
      success: json["success"] ?? false,
      message: json["message"],
      id: json["id"] ?? "",
      name: json["name"] ?? "",
      role: json["role"] ?? "",
      mustResetPassword:
      json["must_reset_password"] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "success": success,
      "message": message,
      "id": id,
      "name": name,
      "role": role,
      "must_reset_password": mustResetPassword,
    };
  }

  // ==========================================================
  // ROLE HELPERS
  // ==========================================================

  bool get isStudent =>
      id.toUpperCase().startsWith("IA");

  bool get isAdmin {
    final upper = id.toUpperCase();

    if (!upper.startsWith("IG")) {
      return false;
    }

    final number =
        int.tryParse(upper.substring(2)) ?? 0;

    return number == 1 || number == 2;
  }

  bool get isFaculty {
    final upper = id.toUpperCase();

    if (!upper.startsWith("IG")) {
      return false;
    }

    final number =
        int.tryParse(upper.substring(2)) ?? 0;

    return number >= 3;
  }
}