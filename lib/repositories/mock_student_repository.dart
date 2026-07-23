import '../models/student_details_model.dart';

class MockStudentRepository {
  final List<StudentDetailsModel> _students = [
    const StudentDetailsModel(
      id: "1",
      rollNo: "IA001",
      name: "Murugesh",
      gender: "Male",
      dob: "2006-01-10",
      className: "II B.Sc CS",
      board: "Autonomous",
      modeOfEducation: "Regular",
      email: "murugesh@gmail.com",
      phone: "9876543210",
      fatherName: "Subramanian",
      motherName: "Lakshmi",
      schoolName: "NGP School",
      address: "Coimbatore",
      subjects: ["Java", "Python", "Cyber Security"],
      password: "IA001",
      totalFee: 50000,
      paidFee: 35000,
      active: true,
    ),
    const StudentDetailsModel(
      id: "2",
      rollNo: "IA002",
      name: "Kavin",
      gender: "Male",
      dob: "2005-12-15",
      className: "II B.Sc CS",
      board: "Autonomous",
      modeOfEducation: "Regular",
      email: "kavin@gmail.com",
      phone: "9876501234",
      fatherName: "Ramesh",
      motherName: "Priya",
      schoolName: "ABC School",
      address: "Erode",
      subjects: ["Java", "Python"],
      password: "IA002",
      totalFee: 50000,
      paidFee: 50000,
      active: true,
    ),
    const StudentDetailsModel(
      id: "3",
      rollNo: "IA003",
      name: "Harish",
      gender: "Male",
      dob: "2006-03-08",
      className: "I B.Sc CS",
      board: "Autonomous",
      modeOfEducation: "Regular",
      email: "harish@gmail.com",
      phone: "9123456789",
      fatherName: "Suresh",
      motherName: "Meena",
      schoolName: "XYZ School",
      address: "Salem",
      subjects: ["C", "Python"],
      password: "IA003",
      totalFee: 45000,
      paidFee: 20000,
      active: true,
    ),
  ];

  Future<List<StudentDetailsModel>> getStudents() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_students);
  }

  Future<void> addStudent(StudentDetailsModel student) async {
    _students.add(student);
  }

  Future<void> updateStudent(StudentDetailsModel student) async {
    final index = _students.indexWhere((s) => s.id == student.id);

    if (index != -1) {
      _students[index] = student;
    }
  }

  Future<void> deleteStudent(String id) async {
    _students.removeWhere((student) => student.id == id);
  }

  Future<StudentDetailsModel?> getStudentById(String id) async {
    try {
      return _students.firstWhere((student) => student.id == id);
    } catch (_) {
      return null;
    }
  }
}