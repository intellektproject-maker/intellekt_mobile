class StudentDetailsModel {
  final String id;
  final String rollNo;
  final String name;
  final String gender;
  final String dob;

  final String className;
  final String board;
  final String modeOfEducation;

  final String email;
  final String phone;

  final String fatherName;
  final String motherName;

  final String schoolName;
  final String address;

  final List<String> subjects;

  final String password;

  final double totalFee;
  final double paidFee;

  final bool active;

  const StudentDetailsModel({
    required this.id,
    required this.rollNo,
    required this.name,
    required this.gender,
    required this.dob,
    required this.className,
    required this.board,
    required this.modeOfEducation,
    required this.email,
    required this.phone,
    required this.fatherName,
    required this.motherName,
    required this.schoolName,
    required this.address,
    required this.subjects,
    required this.password,
    required this.totalFee,
    required this.paidFee,
    required this.active,
  });

  factory StudentDetailsModel.fromJson(Map<String, dynamic> json) {
    return StudentDetailsModel(
      id: json['id'] ?? '',
      rollNo: json['roll_no'] ?? '',
      name: json['name'] ?? '',
      gender: json['gender'] ?? '',
      dob: json['dob'] ?? '',
      className: json['class_name'] ?? '',
      board: json['board'] ?? '',
      modeOfEducation: json['mode_of_education'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      fatherName: json['father_name'] ?? '',
      motherName: json['mother_name'] ?? '',
      schoolName: json['school_name'] ?? '',
      address: json['address'] ?? '',
      subjects: List<String>.from(json['subjects'] ?? []),
      password: json['password'] ?? '',
      totalFee: (json['total_fee'] ?? 0).toDouble(),
      paidFee: (json['paid_fee'] ?? 0).toDouble(),
      active: json['active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roll_no': rollNo,
      'name': name,
      'gender': gender,
      'dob': dob,
      'class_name': className,
      'board': board,
      'mode_of_education': modeOfEducation,
      'email': email,
      'phone': phone,
      'father_name': fatherName,
      'mother_name': motherName,
      'school_name': schoolName,
      'address': address,
      'subjects': subjects,
      'password': password,
      'total_fee': totalFee,
      'paid_fee': paidFee,
      'active': active,
    };
  }

  StudentDetailsModel copyWith({
    String? id,
    String? rollNo,
    String? name,
    String? gender,
    String? dob,
    String? className,
    String? board,
    String? modeOfEducation,
    String? email,
    String? phone,
    String? fatherName,
    String? motherName,
    String? schoolName,
    String? address,
    List<String>? subjects,
    String? password,
    double? totalFee,
    double? paidFee,
    bool? active,
  }) {
    return StudentDetailsModel(
      id: id ?? this.id,
      rollNo: rollNo ?? this.rollNo,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      className: className ?? this.className,
      board: board ?? this.board,
      modeOfEducation: modeOfEducation ?? this.modeOfEducation,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      fatherName: fatherName ?? this.fatherName,
      motherName: motherName ?? this.motherName,
      schoolName: schoolName ?? this.schoolName,
      address: address ?? this.address,
      subjects: subjects ?? this.subjects,
      password: password ?? this.password,
      totalFee: totalFee ?? this.totalFee,
      paidFee: paidFee ?? this.paidFee,
      active: active ?? this.active,
    );
  }
}