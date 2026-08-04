import 'package:flutter/foundation.dart';

import '../../models/useful_link.dart';
import '../../services/student/useful_links_service.dart';

class UsefulLinksProvider extends ChangeNotifier {
  List<UsefulLink> _links = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<UsefulLink> get links => _links;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  bool get hasError => _errorMessage != null;

  bool get hasLinks => _links.isNotEmpty;

  Future<void> loadUsefulLinks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _links = await UsefulLinksService.getUsefulLinks();
    } catch (error) {
      _links = [];
      _errorMessage = 'Failed to load useful links';

      debugPrint('Error loading useful links: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshUsefulLinks() async {
    await loadUsefulLinks();
  }

  void clear() {
    _links = [];
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
