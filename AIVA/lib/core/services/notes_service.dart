import 'api_service.dart';

class NotesService {
  static Future<Map<String, dynamic>> getLectureNotes(String lectureId) async {
    return await ApiService.get('/api/notes/$lectureId');
  }
}
