import '../../models/student_details_model.dart';
import '../../repositories/mock_student_repository.dart';

class StudentService {
  final MockStudentRepository _repository = MockStudentRepository();

  Future<List<StudentDetailsModel>> getStudents() async {
    return await _repository.getStudents();
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

  Future<StudentDetailsModel?> getStudentById(String id) async {
    return await _repository.getStudentById(id);
  }
}