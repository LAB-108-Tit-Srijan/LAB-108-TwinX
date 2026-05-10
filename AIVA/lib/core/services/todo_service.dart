import 'api_service.dart';

class TodoService {
  static Future<List<dynamic>> getTodos() async {
    final res = await ApiService.get('/api/todos');
    return res['todos'] as List<dynamic>? ?? [];
  }

  static Future<Map<String, dynamic>> createTodo(String title) async {
    return await ApiService.post('/api/todos', {'title': title});
  }

  static Future<Map<String, dynamic>> updateTodo(
    String id, {
    bool? completed,
    String? title,
  }) async {
    final body = <String, dynamic>{};
    if (completed != null) body['completed'] = completed;
    if (title != null) body['title'] = title;
    return await ApiService.put('/api/todos/$id', body);
  }

  static Future<void> deleteTodo(String id) async {
    await ApiService.delete('/api/todos/$id');
  }
}
