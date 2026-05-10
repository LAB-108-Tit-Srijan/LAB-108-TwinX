import 'api_service.dart';

class QuizService {
  static Future<Map<String, dynamic>> getQuiz(String lectureId) async {
    return await ApiService.get('/api/quiz/$lectureId');
  }

  static Future<Map<String, dynamic>> submitAttempt(
    String lectureId,
    List<int> answers,
  ) async {
    return await ApiService.post(
      '/api/quiz/$lectureId/attempt',
      {'answers': answers},
    );
  }
}
