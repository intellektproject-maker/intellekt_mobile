/// ===========================================================
/// INTELLEKT LOGIN MODEL
/// ===========================================================
///
/// User ID Rules
/// -------------------------------------
/// IA001+   -> Student
/// IG001+   -> Faculty / Admin accounts
///
/// The role returned by the backend is authoritative. The ID
/// prefix is retained only as a backward-compatible fallback for
/// older stored sessions.
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
          json["mustResetPassword"] ??
          json["must_reset_password"] ??
          false,
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
      role.trim().toLowerCase() == 'student' ||
      (role.trim().isEmpty && id.trim().toUpperCase().startsWith('IA'));

  bool get isFaculty =>
      role.trim().toLowerCase() == 'faculty' ||
      (role.trim().isEmpty && id.trim().toUpperCase().startsWith('IG'));

  bool get isAdmin => role.trim().toLowerCase() == 'admin';
}
