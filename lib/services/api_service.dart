import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/todo.dart';
import '../models/user.dart';

class ApiService {
  static const String baseUrl = 'https://jsonplaceholder.typicode.com';

  Future<List<Todo>> fetchTodos({int? userId}) async {
    final uri = userId == null
        ? Uri.parse('$baseUrl/todos')
        : Uri.parse('$baseUrl/todos?userId=$userId');

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((item) => Todo.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    throw Exception('Failed to load todos');
  }

  Future<List<User>> fetchUsers() async {
    final response = await http.get(Uri.parse('$baseUrl/users'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((item) => User.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    throw Exception('Failed to load users');
  }

  Future<Todo> createTodo(Todo todo) async {
    final response = await http.post(
      Uri.parse('$baseUrl/todos'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'title': todo.title,
        'userId': todo.userId,
        'completed': todo.completed,
      }),
    );

    if (response.statusCode == 201) {
      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      return Todo.fromJson(data);
    }

    throw Exception('Failed to create todo');
  }

  Future<Todo> updateTodo(Todo todo) async {
    final response = await http.put(
      Uri.parse('$baseUrl/todos/${todo.id}'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(todo.toJson()),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      return Todo.fromJson(data);
    }

    throw Exception('Failed to update todo');
  }

  Future<Todo> toggleTodo(int id, bool completed) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/todos/$id'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'completed': completed}),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      return Todo.fromJson(data);
    }

    throw Exception('Failed to toggle todo status');
  }

  Future<void> deleteTodo(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/todos/$id'));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete todo');
    }
  }
}