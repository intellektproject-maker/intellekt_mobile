import '../../../data/mock/mock_post_test_data.dart';
import '../../../models/posted_test.dart';

class PostTestService {
  Future<List<PostedTest>> getPostedTests() async {
    await Future.delayed(const Duration(milliseconds: 300));

    return List.from(mockPostedTests);
  }

  Future<void> createTest(PostedTest test) async {
    await Future.delayed(const Duration(milliseconds: 300));

    mockPostedTests.add(test);
  }

  Future<void> updateTest(PostedTest test) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final index = mockPostedTests.indexWhere(
          (t) => t.testCode == test.testCode,
    );

    if (index != -1) {
      mockPostedTests[index] = test;
    }
  }

  Future<void> deleteTest(String testCode) async {
    await Future.delayed(const Duration(milliseconds: 300));

    mockPostedTests.removeWhere(
          (t) => t.testCode == testCode,
    );
  }

  Future<List<PostedTest>> searchTests(
      String query,
      ) async {
    await Future.delayed(const Duration(milliseconds: 200));

    if (query.trim().isEmpty) {
      return List.from(mockPostedTests);
    }

    return mockPostedTests.where((test) {
      return test.testCode
          .toLowerCase()
          .contains(query.toLowerCase());
    }).toList();
  }
}