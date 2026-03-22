import 'package:flutter/material.dart';
import '../models/todo.dart';
import '../services/api_service.dart';
import '../widgets/error_widget.dart';
import 'create_edit_screen.dart';

class ListScreen extends StatefulWidget {
  @override
  _ListScreenState createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final ApiService api = ApiService();
  late Future<List<Todo>> todos;
  String filter = 'All';

  @override
  void initState() {
    super.initState();
    todos = api.fetchTodos();
  }

  List<Todo> filterTodos(List<Todo> todos) {
    if (filter == 'Completed') {
      return todos.where((t) => t.completed).toList();
    } else if (filter == 'Pending') {
      return todos.where((t) => !t.completed).toList();
    }
    return todos;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TODO List'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                filter = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'All', child: Text('All')),
              PopupMenuItem(value: 'Completed', child: Text('Completed')),
              PopupMenuItem(value: 'Pending', child: Text('Pending')),
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<Todo>>(
        future: todos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return CustomErrorWidget(
              message: snapshot.error.toString(),
              onRetry: () {
                setState(() {
                  todos = api.fetchTodos();
                });
              },
            );
          } else {
            final data = filterTodos(snapshot.data!);
            return ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                final todo = data[index];
                return Dismissible(
                  key: Key(todo.id.toString()),
                  onDismissed: (_) async {
                    await api.deleteTodo(todo.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Deleted'),
                        action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () {},
                        ),
                      ),
                    );
                    setState(() {
                      todos = api.fetchTodos();
                    });
                  },
                  child: CheckboxListTile(
                    title: Text(todo.title),
                    value: todo.completed,
                    onChanged: (value) {
                      setState(() {
                        todo.completed = value!;
                      });
                      api.toggleTodo(todo.id, value!);
                    },
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CreateEditScreen()),
          );
          setState(() {
            todos = api.fetchTodos();
          });
        },
      ),
    );
  }
}