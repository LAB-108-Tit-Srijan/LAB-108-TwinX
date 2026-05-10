import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String kBaseUrl = 'https://backend-aiva.mrsumi.com';
  static String? _studentToken;

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_studentToken != null) 'Authorization': 'Bearer $_studentToken',
  };

  static void setToken(String token) => _studentToken = token;
  static void clearToken() => _studentToken = null;
  static bool get hasToken => _studentToken != null;

  static Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$kBaseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 30));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> get(String path) async {
    final res = await http.get(
      Uri.parse('$kBaseUrl$path'),
      headers: _headers,
    ).timeout(const Duration(seconds: 30));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async {
    final res = await http.put(
      Uri.parse('$kBaseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 30));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> delete(String path) async {
    final res = await http.delete(
      Uri.parse('$kBaseUrl$path'),
      headers: _headers,
    ).timeout(const Duration(seconds: 30));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) async {
    final res = await http.patch(
      Uri.parse('$kBaseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 30));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // Returns an SSE stream request
  static http.Request buildStreamRequest(String path, Map<String, dynamic> body) {
    final req = http.Request('POST', Uri.parse('$kBaseUrl$path'));
    req.headers['Content-Type'] = 'application/json';
    if (_studentToken != null) {
      req.headers['Authorization'] = 'Bearer $_studentToken';
    }
    req.body = jsonEncode(body);
    return req;
  }
}
