import '../../models/student_details_model.dart';
import '../../repositories/mock_student_repository.dart';

class StudentService {
  final MockStudentRepository _repository = MockStudentRepository();

  Future<List<StudentDetailsModel>> getStudents() async {
    return _repository.getStudents();
  }

  Future<StudentDetailsModel?> getStudentById(String id) async {
    return _repository.getStudentById(id);
  }

  Future<void> addStudent(StudentDetailsModel student) async {
    await _repository.addStudent(student);
  }

  Future<void> updateStudent(StudentDetailsModel student) async {
    await _repository.updateStudent(student);
  }

  Future<void> deleteStudent(String id) async {
    await _repository.deleteStudent(id);
  }

  Future<List<StudentDetailsModel>> searchStudents(String query) async {
    final students = await _repository.getStudents();

    if (query.trim().isEmpty) {
      return students;
    }

    final q = query.toLowerCase();

    return students.where((student) {
      return student.name.toLowerCase().contains(q) ||
          student.rollNo.toLowerCase().contains(q) ||
          student.className.toLowerCase().contains(q);
    }).toList();
  }

  Future<List<StudentDetailsModel>> filterStudents({
    String? className,
    String? board,
  }) async {
    var students = await _repository.getStudents();

    if (className != null && className.isNotEmpty) {
      students = students
          .where((student) => student.className == className)
          .toList();
    }

    if (board != null && board.isNotEmpty) {
      students =
          students.where((student) => student.board == board).toList();
    }

    return students;
  }
  /// Existing API used by StudentProvider
  static Future<Map<String, dynamic>?> getStudent(String rollNo) async {
    // Temporary mock implementation.
    // Later this will call the repository/API.

    return {
      "rollNo": rollNo,
      "name": "Student",
      "className": "III B.Sc",
      "department": "Computer Science",
    };
  }
}