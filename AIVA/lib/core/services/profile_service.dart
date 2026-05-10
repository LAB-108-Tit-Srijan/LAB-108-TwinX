import 'api_service.dart';

class ProfileService {
  static Future<Map<String, dynamic>> getProfile() async {
    return await ApiService.get('/api/profile');
  }

  static Future<Map<String, dynamic>> getCredits() async {
    return await ApiService.get('/api/credits');
  }

  static Future<Map<String, dynamic>> updateName(String name) async {
    return await ApiService.patch('/api/profile', {'name': name});
  }
}
