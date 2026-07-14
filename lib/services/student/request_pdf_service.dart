import '../../data/mock/mock_request_pdf_data.dart';
import '../../models/request_pdf.dart';

class RequestPdfService {
  RequestPdfService._();

  static Future<RequestPdfData> getRequestPdfData(
      String rollNo,
      ) async {
    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    return RequestPdfData.fromJson(mockRequestPdfData);
  }

  static Future<bool> submitRequest({
    required String rollNo,
    required String testCode,
    required String phone,
  }) async {
    await Future.delayed(
      const Duration(milliseconds: 800),
    );

    return true;
  }
}