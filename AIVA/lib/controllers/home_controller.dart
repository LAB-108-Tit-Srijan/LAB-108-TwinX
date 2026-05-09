import 'package:get/get.dart';
import '../data/models/lecture_model.dart';
import '../data/models/doubt_model.dart';
import '../data/mock/mock_data.dart';

class HomeController extends GetxController {
  final RxInt currentNavIndex = 0.obs;
  final RxList<LectureModel> lectures = MockData.lectures.obs;
  final RxList<DoubtModel> recentDoubts =
      MockData.doubts.where((d) => !d.isAi).toList().obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxInt lecturesWatchedToday = 3.obs;
  final RxInt doubtsSolvedToday = 7.obs;
  final RxInt streakDays = 14.obs;
  final RxString greeting = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _setGreeting();
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      greeting.value = 'Good morning';
    } else if (hour < 17) {
      greeting.value = 'Good afternoon';
    } else {
      greeting.value = 'Good evening';
    }
  }

  void changeNavIndex(int index) => currentNavIndex.value = index;
}
