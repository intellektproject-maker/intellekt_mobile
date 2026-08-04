import '../../data/mock/mock_useful_links_data.dart';
import '../../models/useful_link.dart';

class UsefulLinksService {
  UsefulLinksService._();

  static Future<List<UsefulLink>> getUsefulLinks() async {
    await Future.delayed(const Duration(milliseconds: 500));

    return mockUsefulLinksData.map(UsefulLink.fromJson).toList();
  }
}
