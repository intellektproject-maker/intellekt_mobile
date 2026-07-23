import 'package:flutter/material.dart';

import '../../../models/posted_test.dart';
import '../../../services/faculty/test_management/post_test_service.dart';

class PostTestProvider extends ChangeNotifier {
  final PostTestService _service = PostTestService();

  bool isLoading = false;
  bool isSaving = false;

  List<PostedTest> tests = [];
  List<PostedTest> filteredTests = [];

  Future<void> loadTests() async {
    isLoading = true;
    notifyListeners();

    tests = await _service.getPostedTests();
    filteredTests = List.from(tests);

    isLoading = false;
    notifyListeners();
  }

  Future<void> createTest(PostedTest test) async {
    isSaving = true;
    notifyListeners();

    await _service.createTest(test);

    await loadTests();

    isSaving = false;
    notifyListeners();
  }

  Future<void> updateTest(PostedTest test) async {
    isSaving = true;
    notifyListeners();

    await _service.updateTest(test);

    await loadTests();

    isSaving = false;
    notifyListeners();
  }

  Future<void> deleteTest(String testCode) async {
    isSaving = true;
    notifyListeners();

    await _service.deleteTest(testCode);

    await loadTests();

    isSaving = false;
    notifyListeners();
  }

  Future<void> search(String query) async {
    filteredTests = await _service.searchTests(query);
    notifyListeners();
  }

  void clearSearch() {
    filteredTests = List.from(tests);
    notifyListeners();
  }
}