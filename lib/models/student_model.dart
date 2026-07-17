class StudentModel {
  final String rollNo;
  final String name;
  final String className;
  final String board;
  final String subject;

  const StudentModel({
    required this.rollNo,
    required this.name,
    required this.className,
    required this.board,
    required this.subject,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      rollNo: json['roll_no'] ?? '',
      name: json['name'] ?? '',
      className: json['class_name'] ?? '',
      board: json['board'] ?? '',
      subject: json['subject'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roll_no': rollNo,
      'name': name,
      'class_name': className,
      'board': board,
      'subject': subject,
    };
  }
}