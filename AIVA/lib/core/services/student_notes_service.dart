import 'api_service.dart';

class StudentNotesService {
  /// Get or generate personalized notes for this student + lecture.
  /// Notes are built from the student's Q&A history with AIVA.
  static Future<Map<String, dynamic>?> getNotes(String lectureId) async {
    try {
      final data = await ApiService.get('/api/student-notes/$lectureId');
      if (data['success'] == true) {
        return data['notes'] as Map<String, dynamic>?;
      }
    } catch (_) {}
    return null;
  }
}
