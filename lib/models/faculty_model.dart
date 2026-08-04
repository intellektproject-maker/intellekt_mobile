class FacultyModel {
  final String facultyId;
  final String name;
  final String email;
  final String phone;

  const FacultyModel({
    required this.facultyId,
    required this.name,
    required this.email,
    required this.phone,
  });

  factory FacultyModel.fromJson(Map<String, dynamic> json) {
    return FacultyModel(
      facultyId: json['faculty_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'faculty_id': facultyId,
      'name': name,
      'email': email,
      'phone': phone,
    };
  }

  // ==========================================================
  // DUMMY FACULTY DATA FOR UI DEVELOPMENT
  // ==========================================================

  static const FacultyModel dummyAdmin = FacultyModel(
    facultyId: 'IG001',
    name: 'Admin User',
    email: 'admin@intellekt.com',
    phone: '9876543210',
  );

  static const List<FacultyModel> dummyFacultyList = [
    FacultyModel(
      facultyId: 'IG001',
      name: 'Admin User',
      email: 'admin@intellekt.com',
      phone: '9876543210',
    ),
    FacultyModel(
      facultyId: 'IG003',
      name: 'Anitha',
      email: 'anitha@intellekt.com',
      phone: '9876543211',
    ),
    FacultyModel(
      facultyId: 'IG004',
      name: 'Rahul',
      email: 'rahul@intellekt.com',
      phone: '9876543212',
    ),
    FacultyModel(
      facultyId: 'IG005',
      name: 'Meera',
      email: 'meera@intellekt.com',
      phone: '9876543213',
    ),
  ];
}