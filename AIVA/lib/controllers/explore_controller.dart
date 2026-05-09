import 'package:get/get.dart';
import '../data/models/lecture_model.dart';
import '../data/mock/mock_data.dart';

class ExploreController extends GetxController {
  final RxList<LectureModel> allLectures = MockData.lectures.obs;
  final RxList<LectureModel> filteredLectures = MockData.lectures.obs;
  final RxString selectedFilter = 'All'.obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;

  void filterBy(String topic) {
    selectedFilter.value = topic;
    isLoading.value = true;
    Future.delayed(const Duration(milliseconds: 400), () {
      if (topic == 'All') {
        filteredLectures.value = allLectures;
      } else {
        filteredLectures.value = allLectures
            .where((l) =>
                l.courseName.toLowerCase().contains(topic.toLowerCase()) ||
                l.topics.any(
                    (t) => t.toLowerCase().contains(topic.toLowerCase())))
            .toList();
      }
      isLoading.value = false;
    });
  }

  void search(String query) {
    searchQuery.value = query;
    if (query.isEmpty) {
      filteredLectures.value = allLectures;
    } else {
      filteredLectures.value = allLectures
          .where((l) =>
              l.title.toLowerCase().contains(query.toLowerCase()) ||
              l.courseName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }
}
