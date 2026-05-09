import 'package:get/get.dart';
import '../data/models/doubt_model.dart';
import '../data/mock/mock_data.dart';

class DoubtController extends GetxController {
  final RxList<DoubtModel> allDoubts =
      MockData.doubts.where((d) => !d.isAi).toList().obs;
  final RxString selectedFilter = 'All'.obs;
  final RxString searchQuery = ''.obs;

  List<DoubtModel> get filteredDoubts {
    List<DoubtModel> result = allDoubts;
    if (searchQuery.value.isNotEmpty) {
      result = result
          .where((d) => d.question
              .toLowerCase()
              .contains(searchQuery.value.toLowerCase()))
          .toList();
    }
    return result;
  }

  Map<String, List<DoubtModel>> get groupedDoubts {
    final filtered = filteredDoubts;
    final Map<String, List<DoubtModel>> grouped = {};
    for (final d in filtered) {
      grouped.putIfAbsent(d.lectureName, () => []).add(d);
    }
    return grouped;
  }

  void setFilter(String filter) => selectedFilter.value = filter;
  void setSearch(String q) => searchQuery.value = q;
}
