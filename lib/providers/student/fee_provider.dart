import 'package:flutter/foundation.dart';

import '../../models/fee.dart';
import '../../services/student/fee_service.dart';

class FeeProvider extends ChangeNotifier {
  List<Fee> _fees = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Fee> get fees => _fees;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  bool get hasError => _errorMessage != null;

  bool get hasFees => _fees.isNotEmpty;

  Future<void> loadFees(String rollNo) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _fees = await FeeService.getFees(rollNo);
    } catch (error) {
      _fees = [];
      _errorMessage = 'Failed to load fee details';

      debugPrint('Error loading fee details: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshFees(String rollNo) async {
    await loadFees(rollNo);
  }

  void clear() {
    _fees = [];
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
