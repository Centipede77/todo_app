import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/todo.dart';
import '../models/user.dart';

class CreateEditScreen extends StatefulWidget {
  final Todo? todo;
  CreateEditScreen({this.todo});

  @override
  _CreateEditScreenState createState() => _CreateEditScreenState();
}

class _CreateEditScreenState extends State<CreateEditScreen> {
  final ApiService api = ApiService();
  final _formKey = GlobalKey<FormState>();
  String title = '';
  int? selectedUserId;
  bool completed = false;
  List<User> users = [];

  @override
  void initState() {
    super.initState();
    api.fetchUsers().then((data) => setState(() {
          users = data;
          if (widget.todo != null) {
            title = widget.todo!.title;
            selectedUserId = widget.todo!.userId;
            completed = widget.todo!.completed;
          }
        }));
  }

  void saveTodo() async {
    if (!_formKey.currentState!.validate() || selectedUserId == null) return;

    final todo = Todo(
      id: widget.todo?.id ?? 0,
      userId: selectedUserId!,
      title: title,
      completed: completed,
    );

    try {
      if (widget.todo == null) {
        await api.createTodo(todo);
      } else {
        await api.updateTodo(todo);
      }
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.todo == null ? 'Create Todo' : 'Edit Todo')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<int>(
                value: selectedUserId,
                items: users
                    .map((user) => DropdownMenuItem(
                          value: user.id,
                          child: Text(user.name),
                        ))
                    .toList(),
                hint: Text('Select user'),
                onChanged: (val) => setState(() => selectedUserId = val),
                validator: (val) => val == null ? 'Choose user' : null,
              ),
              TextFormField(
                initialValue: title,
                decoration: InputDecoration(labelText: 'Title'),
                onChanged: (val) => title = val,
                validator: (val) => val == null || val.isEmpty ? 'Enter title' : null,
              ),
              CheckboxListTile(
                value: completed,
                onChanged: (val) => setState(() => completed = val!),
                title: Text('Completed'),
              ),
              ElevatedButton(
                onPressed: saveTodo,
                child: Text('Save'),
              )
            ],
          ),
        ),
      ),
    );
  }
}