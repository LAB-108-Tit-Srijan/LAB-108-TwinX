import 'package:shared_preferences/shared_preferences.dart';
import '../constants/storage_keys.dart';
import '../models/student.dart';
import 'api_service.dart';

class AuthService {
  static Future<Map<String, dynamic>> loginWithPhone(String phone, String deviceId) async {
    final data = await ApiService.post('/api/student/login', {
      'phone': phone,
      'device_id': deviceId,
    });
    if (data['success'] == true && data['token'] != null) {
      await _saveSession(data['token'] as String, data['student'] as Map<String, dynamic>);
    }
    return data;
  }

  static Future<Map<String, dynamic>> sendOtp(String phone) async {
    return await ApiService.post('/api/student/send-otp', {'phone': phone});
  }

  static Future<Map<String, dynamic>> verifyOtp(
    String phone,
    String otp,
    String deviceId, {
    String? name,
  }) async {
    final body = <String, dynamic>{
      'phone': phone,
      'otp': otp,
      'device_id': deviceId,
    };
    if (name != null) body['name'] = name;
    final data = await ApiService.post('/api/student/verify-otp', body);
    if (data['success'] == true && data['token'] != null) {
      await _saveSession(data['token'] as String, data['student'] as Map<String, dynamic>);
    }
    return data;
  }

  static Future<void> _saveSession(String token, Map<String, dynamic> studentJson) async {
    final prefs = await SharedPreferences.getInstance();
    ApiService.setToken(token);
    await prefs.setString(kStudentToken, token);
    await prefs.setBool(kIsLoggedIn, true);
    await prefs.setString(kStudentId, studentJson['id'] as String? ?? '');
    await prefs.setString(kStudentPhone, studentJson['phone'] as String? ?? '');
    await prefs.setString(kStudentName, studentJson['name'] as String? ?? '');
  }

  static Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(kStudentToken);
    if (token == null) return false;
    ApiService.setToken(token);
    return true;
  }

  static Future<Student?> getCurrentStudent() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(kStudentId);
    if (id == null || id.isEmpty) return null;
    return Student(
      id: id,
      name: prefs.getString(kStudentName),
      phone: prefs.getString(kStudentPhone) ?? '',
    );
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(kIsLoggedIn) == true &&
        (prefs.getString(kStudentToken)?.isNotEmpty == true);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    ApiService.clearToken();
  }
}
