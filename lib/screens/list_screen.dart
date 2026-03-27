import 'package:flutter/material.dart';

import '../models/todo.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import 'create_edit_screen.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<User> _users = [];
  List<Todo> _baseTodos = [];

  final Map<int, Todo> _editedTodos = {};
  final Map<int, Todo> _createdTodos = {};
  final Set<int> _deletedTodoIds = {};

  bool _isLoading = true;
  String? _error;

  String _statusFilter = 'All';
  int? _selectedUserId;
  bool _groupByUser = false;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.trim().toLowerCase();
      });
    });
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _api.fetchUsers(),
        _api.fetchTodos(),
      ]);

      setState(() {
        _users = results[0] as List<User>;
        _baseTodos = results[1] as List<Todo>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTodosForSelectedUser() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final todos = await _api.fetchTodos(userId: _selectedUserId);

      setState(() {
        _baseTodos = todos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _userNameById(int userId) {
    return _users
        .firstWhere(
          (user) => user.id == userId,
          orElse: () => User(id: userId, name: 'User $userId'),
        )
        .name;
  }

  List<Todo> get _mergedTodos {
    final Map<int, Todo> map = {};

    for (final todo in _baseTodos) {
      if (_deletedTodoIds.contains(todo.id)) continue;
      map[todo.id] = _editedTodos[todo.id] ?? todo;
    }

    for (final entry in _createdTodos.entries) {
      if (_deletedTodoIds.contains(entry.key)) continue;
      map[entry.key] = entry.value;
    }

    var list = map.values.toList();

    if (_selectedUserId != null) {
      list = list.where((todo) => todo.userId == _selectedUserId).toList();
    }

    if (_statusFilter == 'Completed') {
      list = list.where((todo) => todo.completed).toList();
    } else if (_statusFilter == 'Pending') {
      list = list.where((todo) => !todo.completed).toList();
    }

    if (_searchText.isNotEmpty) {
      list = list
          .where((todo) => todo.title.toLowerCase().contains(_searchText))
          .toList();
    }

    list.sort((a, b) {
      final userCompare = a.userId.compareTo(b.userId);
      if (_groupByUser && userCompare != 0) return userCompare;
      return a.id.compareTo(b.id);
    });

    return list;
  }

  List<Todo> get _statsTodos {
    final Map<int, Todo> map = {};

    for (final todo in _baseTodos) {
      if (_deletedTodoIds.contains(todo.id)) continue;
      map[todo.id] = _editedTodos[todo.id] ?? todo;
    }

    for (final entry in _createdTodos.entries) {
      if (_deletedTodoIds.contains(entry.key)) continue;
      map[entry.key] = entry.value;
    }

    var list = map.values.toList();

    if (_selectedUserId != null) {
      list = list.where((todo) => todo.userId == _selectedUserId).toList();
    }

    return list;
  }

  Future<void> _onUserChanged(int? value) async {
    setState(() {
      _selectedUserId = value;
    });
    await _loadTodosForSelectedUser();
  }

  Future<void> _openCreateScreen() async {
    final Todo? draft = await Navigator.push<Todo>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateEditScreen(users: _users),
      ),
    );

    if (draft == null) return;

    final int localId = -DateTime.now().millisecondsSinceEpoch;
    final Todo localTodo = draft.copyWith(id: localId);

    setState(() {
      _createdTodos[localId] = localTodo;
    });

    try {
      await _api.createTodo(draft);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task created')),
      );
    } catch (e) {
      setState(() {
        _createdTodos.remove(localId);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Create failed: $e')),
      );
    }
  }

  Future<void> _openEditScreen(Todo todo) async {
    final Todo? updatedDraft = await Navigator.push<Todo>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateEditScreen(
          users: _users,
          todo: todo,
        ),
      ),
    );

    if (updatedDraft == null) return;

    final Todo updatedTodo = todo.copyWith(
      userId: updatedDraft.userId,
      title: updatedDraft.title,
      completed: updatedDraft.completed,
    );

    setState(() {
      if (_createdTodos.containsKey(todo.id)) {
        _createdTodos[todo.id] = updatedTodo;
      } else {
        _editedTodos[todo.id] = updatedTodo;
      }
    });

    if (todo.id < 0) {
      return;
    }

    try {
      await _api.updateTodo(updatedTodo);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task updated')),
      );
    } catch (e) {
      setState(() {
        _editedTodos.remove(todo.id);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    }
  }

  Future<void> _toggleTodo(Todo todo, bool value) async {
    final Todo updatedTodo = todo.copyWith(completed: value);

    setState(() {
      if (_createdTodos.containsKey(todo.id)) {
        _createdTodos[todo.id] = updatedTodo;
      } else {
        _editedTodos[todo.id] = updatedTodo;
      }
    });

    if (todo.id < 0) return;

    try {
      await _api.toggleTodo(todo.id, value);
    } catch (e) {
      setState(() {
        if (_createdTodos.containsKey(todo.id)) {
          _createdTodos[todo.id] = todo;
        } else {
          _editedTodos[todo.id] = todo;
        }
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status update failed: $e')),
      );
    }
  }

  Future<void> _deleteTodo(Todo todo) async {
    setState(() {
      _deletedTodoIds.add(todo.id);
    });

    bool undone = false;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    final controller = messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        content: Text('Deleted: ${todo.title}'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            undone = true;
            setState(() {
              _deletedTodoIds.remove(todo.id);
            });
          },
        ),
      ),
    );

    await controller.closed;

    if (undone) return;

    if (todo.id < 0) {
      setState(() {
        _createdTodos.remove(todo.id);
      });
      return;
    }

    try {
      await _api.deleteTodo(todo.id);
    } catch (e) {
      setState(() {
        _deletedTodoIds.remove(todo.id);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  Widget _buildStatsCard() {
    final stats = _statsTodos;
    final total = stats.length;
    final completed = stats.where((todo) => todo.completed).length;
    final pending = total - completed;
    final progress = total == 0 ? 0.0 : completed / total;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatItem(label: 'Total', value: total.toString()),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Completed',
                    value: completed.toString(),
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Pending',
                    value: pending.toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text('${(progress * 100).toStringAsFixed(0)}% done'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Column(
      children: [
        DropdownButtonFormField<int?>(
          value: _selectedUserId,
          decoration: const InputDecoration(
            labelText: 'User',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('All users'),
            ),
            ..._users.map(
              (user) => DropdownMenuItem<int?>(
                value: user.id,
                child: Text(user.name),
              ),
            ),
          ],
          onChanged: _onUserChanged,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search by title',
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
            suffixIcon: _searchText.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                    },
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('All'),
              selected: _statusFilter == 'All',
              onSelected: (_) {
                setState(() {
                  _statusFilter = 'All';
                });
              },
            ),
            ChoiceChip(
              label: const Text('Completed'),
              selected: _statusFilter == 'Completed',
              onSelected: (_) {
                setState(() {
                  _statusFilter = 'Completed';
                });
              },
            ),
            ChoiceChip(
              label: const Text('Pending'),
              selected: _statusFilter == 'Pending',
              onSelected: (_) {
                setState(() {
                  _statusFilter = 'Pending';
                });
              },
            ),
            FilterChip(
              label: const Text('Group by user'),
              selected: _groupByUser,
              onSelected: (value) {
                setState(() {
                  _groupByUser = value;
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTodoTile(Todo todo) {
    return Dismissible(
      key: ValueKey(todo.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        _deleteTodo(todo);
      },
      child: Card(
        child: ListTile(
          onTap: () => _openEditScreen(todo),
          leading: Checkbox(
            value: todo.completed,
            onChanged: (value) {
              if (value == null) return;
              _toggleTodo(todo, value);
            },
          ),
          title: Text(
            todo.title,
            style: TextStyle(
              decoration: todo.completed
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
            ),
          ),
          subtitle: Text('User: ${_userNameById(todo.userId)}'),
          trailing: IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _openEditScreen(todo),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupedList(List<Todo> todos) {
    final Map<int, List<Todo>> grouped = {};

    for (final todo in todos) {
      grouped.putIfAbsent(todo.userId, () => []).add(todo);
    }

    final userIds = grouped.keys.toList()..sort();

    return ListView.builder(
      itemCount: userIds.length,
      itemBuilder: (context, index) {
        final userId = userIds[index];
        final items = grouped[userId]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
              child: Text(
                _userNameById(userId),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ...items.map(_buildTodoTile),
          ],
        );
      },
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loadInitialData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final todos = _mergedTodos;

    return RefreshIndicator(
      onRefresh: _loadTodosForSelectedUser,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildStatsCard(),
          const SizedBox(height: 12),
          _buildFilters(),
          const SizedBox(height: 12),
          if (todos.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(
                child: Text('No tasks found'),
              ),
            )
          else if (_groupByUser && _selectedUserId == null)
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: _buildGroupedList(todos),
            )
          else
            ...todos.map(_buildTodoTile),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TODO Manager'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadTodosForSelectedUser,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateScreen,
        icon: const Icon(Icons.add),
        label: const Text('Add task'),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(label),
      ],
    );
  }
}