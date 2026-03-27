import 'package:flutter/material.dart';

import '../models/todo.dart';
import '../models/user.dart';

class CreateEditScreen extends StatefulWidget {
  final Todo? todo;
  final List<User> users;

  const CreateEditScreen({
    super.key,
    this.todo,
    required this.users,
  });

  @override
  State<CreateEditScreen> createState() => _CreateEditScreenState();
}

class _CreateEditScreenState extends State<CreateEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;

  int? _selectedUserId;
  bool _completed = false;

  bool get _isEdit => widget.todo != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo?.title ?? '');
    _selectedUserId = widget.todo?.userId;
    _completed = widget.todo?.completed ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUserId == null) return;

    final result = Todo(
      id: widget.todo?.id ?? 0,
      userId: _selectedUserId!,
      title: _titleController.text.trim(),
      completed: _completed,
    );

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit task' : 'Create task'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<int>(
                value: _selectedUserId,
                decoration: const InputDecoration(
                  labelText: 'User',
                  border: OutlineInputBorder(),
                ),
                items: widget.users
                    .map(
                      (user) => DropdownMenuItem<int>(
                        value: user.id,
                        child: Text(user.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedUserId = value;
                  });
                },
                validator: (value) {
                  if (value == null) return 'Select a user';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter task title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Completed'),
                value: _completed,
                onChanged: (value) {
                  setState(() {
                    _completed = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  child: Text(_isEdit ? 'Save changes' : 'Create task'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}