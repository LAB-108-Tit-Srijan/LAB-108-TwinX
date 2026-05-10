import 'api_service.dart';

class ChatHistoryService {
  /// Save a completed Q&A exchange to the server.
  static Future<void> save({
    required String lectureId,
    required String question,
    required String answer,
    String language = 'en',
  }) async {
    try {
      await ApiService.post('/api/chat-history', {
        'lecture_id': lectureId,
        'question': question,
        'answer': answer,
        'language': language,
      });
    } catch (_) {
      // Fire-and-forget — don't block the UI if saving fails
    }
  }

  /// Retrieve all saved Q&A pairs for this student + lecture.
  /// Returns a list of maps with keys: question, answer, created_at
  static Future<List<Map<String, dynamic>>> getHistory(String lectureId) async {
    try {
      final data = await ApiService.get('/api/chat-history/$lectureId');
      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['history'] as List? ?? []);
      }
    } catch (_) {}
    return [];
  }
}
