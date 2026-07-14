import '../../data/mock/mock_fee_data.dart';
import '../../models/fee.dart';

class FeeService {
  FeeService._();

  static Future<List<Fee>> getFees(String rollNo) async {
    await Future.delayed(const Duration(milliseconds: 500));

    return mockFeeData.map(Fee.fromJson).toList();
  }
}
