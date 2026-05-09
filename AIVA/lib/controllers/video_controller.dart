import 'package:get/get.dart';
import '../data/models/doubt_model.dart';
import '../data/mock/mock_data.dart';

class VideoController extends GetxController {
  final RxBool isPlaying = false.obs;
  final RxDouble progress = 0.42.obs;
  final RxString currentTime = '42:31'.obs;
  final RxString totalTime = '1:02:15'.obs;
  final RxDouble playbackSpeed = 1.0.obs;
  final RxInt selectedTab = 1.obs;
  final RxBool isHindi = false.obs;
  final RxList<DoubtModel> chatMessages = <DoubtModel>[].obs;
  final RxBool isTyping = false.obs;
  final RxString quickSummary = ''.obs;

  @override
  void onInit() {
    super.onInit();
    chatMessages.addAll([MockData.doubts[0], MockData.doubts[1]]);
  }

  void togglePlay() => isPlaying.toggle();
  void toggleLanguage() => isHindi.toggle();
  void selectTab(int index) => selectedTab.value = index;

  void seekTo(double value) {
    progress.value = value;
    const totalSeconds = 3735;
    final currentSeconds = (totalSeconds * value).toInt();
    final minutes = currentSeconds ~/ 60;
    final seconds = currentSeconds % 60;
    currentTime.value =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void changeSpeed(double speed) => playbackSpeed.value = speed;

  Future<void> askDoubt(String question) async {
    final userDoubt = DoubtModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      question: question,
      answer: '',
      lectureId: 'l1',
      lectureName: 'React Hooks Deep Dive',
      timestamp: currentTime.value,
      askedAt: DateTime.now(),
      language: isHindi.value ? 'HI' : 'EN',
      isAi: false,
    );
    chatMessages.add(userDoubt);
    isTyping.value = true;

    await Future.delayed(const Duration(milliseconds: 1200));
    isTyping.value = false;

    final aiReply = DoubtModel(
      id: '${DateTime.now().millisecondsSinceEpoch}_ai',
      question: '',
      answer: isHindi.value
          ? 'AIVA aapke sawaal ka jawab de raha hai...\n\nIs concept ko samajhne ke liye, pehle hum basic theory dekhte hain.\n\n📍 From ${currentTime.value} — Yahi timestamp pe instructor ne iske baare mein explain kiya tha.'
          : 'Great question! Based on your lecture at ${currentTime.value}:\n\nThis concept is fundamental to understanding the topic. The instructor explained it clearly with examples.\n\n📍 From ${currentTime.value} — This exact timestamp covers your question.\n🔗 Also in Lecture 2 · 15:42 — Related concept covered there too.',
      lectureId: 'l1',
      lectureName: 'React Hooks Deep Dive',
      timestamp: currentTime.value,
      askedAt: DateTime.now(),
      language: isHindi.value ? 'HI' : 'EN',
      isAi: true,
    );
    chatMessages.add(aiReply);
  }

  void sendQuickAction(String action) {
    final Map<String, String> questions = {
      '📝 Summary': 'Give me a summary of this lecture so far',
      '🔗 Related': 'What other lectures are related to this topic?',
      '💡 Explain Simply': 'Explain the current concept in simpler terms',
    };
    askDoubt(questions[action] ?? action);
  }
}
