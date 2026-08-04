import '../../core/api/api_client.dart';
import '../../core/api/api_routes.dart';
import '../../models/fee.dart';

class FeeService {
  FeeService._();

  static Future<List<Fee>> getFees(String rollNo) async {
    final response = await ApiClient().dio.get(
      ApiRoutes.studentFees(rollNo),
    );

    return (response.data as List)
        .map((json) => Fee.fromJson(json))
        .toList();
  }
}