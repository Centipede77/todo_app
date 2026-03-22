import 'package:flutter/material.dart';
import '../models/todo.dart';
import '../services/api_service.dart';
import 'create_edit_screen.dart';

class DetailScreen extends StatefulWidget {
  final Todo todo;

  DetailScreen({required this.todo});

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final ApiService api = ApiService();
  late Todo todo;

  @override
  void initState() {
    super.initState();
    todo = widget.todo;
  }

  void toggleCompleted(bool? value) async {
    if (value == null) return;
    setState(() {
      todo.completed = value;
    });
    try {
      await api.toggleTodo(todo.id, value);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void deleteTodo() async {
    try {
      await api.deleteTodo(todo.id);
      Navigator.pop(context); // повернутися на список
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Todo deleted')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void editTodo() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateEditScreen(todo: todo)),
    );
    setState(() {
      // оновлюємо після редагування
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Todo Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: editTodo,
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: deleteTodo,
          )
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Title:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(todo.title),
            SizedBox(height: 16),
            Text(
              'User ID:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(todo.userId.toString()),
            SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Completed:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Checkbox(
                  value: todo.completed,
                  onChanged: toggleCompleted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}