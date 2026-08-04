import 'package:flutter/foundation.dart';

import '../../models/request_pdf.dart';
import '../../services/student/request_pdf_service.dart';

class RequestPdfProvider extends ChangeNotifier {
  RequestPdfData? _data;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _successMessage;

  RequestPdfData? get data => _data;

  bool get isLoading => _isLoading;

  bool get isSubmitting => _isSubmitting;

  String? get errorMessage => _errorMessage;

  String? get successMessage => _successMessage;

  bool get hasError => _errorMessage != null;

  bool get hasSuccess => _successMessage != null;

  Future<void> loadRequestPdfData(String rollNo) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      _data = await RequestPdfService.getRequestPdfData(rollNo);
    } catch (error) {
      _data = null;
      _errorMessage = 'Unable to load data';

      debugPrint('Error loading Request PDF data: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitRequest({
    required String rollNo,
    required String testCode,
    required String phone,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final success = await RequestPdfService.submitRequest(
        rollNo: rollNo,
        testCode: testCode,
        phone: phone,
      );

      if (success) {
        _successMessage = 'Request submitted successfully';
        return true;
      }

      _errorMessage = 'Failed to submit request';
      return false;
    } catch (error) {
      _errorMessage = 'Something went wrong';

      debugPrint('Error submitting Request PDF: $error');

      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void clear() {
    _data = null;
    _isLoading = false;
    _isSubmitting = false;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
