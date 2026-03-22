import 'package:flutter/material.dart';
import '../models/todo.dart';

class ItemCard extends StatelessWidget {
  final Todo todo;
  final ValueChanged<bool?> onChanged;

  ItemCard({required this.todo, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: CheckboxListTile(
        title: Text(todo.title),
        value: todo.completed,
        onChanged: onChanged,
      ),
    );
  }
}