class MarkEntry {
  final String rollNo;
  final String studentName;
  int marks;

  MarkEntry({
    required this.rollNo,
    required this.studentName,
    this.marks = 0,
  });

  factory MarkEntry.fromJson(Map<String, dynamic> json) {
    return MarkEntry(
      rollNo: json['rollNo'],
      studentName: json['studentName'],
      marks: json['marks'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rollNo': rollNo,
      'studentName': studentName,
      'marks': marks,
    };
  }
}