import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tailorapptask/services/todo.dart';
import 'package:tailorapptask/services/supabase_stuff.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final _client = Supabase.instance.client;
  List<Todo> _todos = [];
  Map<String, dynamic>? _profile;
  RealtimeChannel? _channel;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  int _viewIndex = 0; // 0 = agenda, 1 = timeline

  bool _isSearching = false;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAll();

    // Subscribe to realtime updates for todos
    _channel = _client
        .channel('public:todos')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'todos',
      callback: (payload) => _loadTodos(),
    )
        .subscribe();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    if (_channel != null) _client.removeChannel(_channel!);
    super.dispose();
  }

  Future<void> _loadAll() async {
    await _loadProfile();
    await _loadTodos();
  }

  Future<void> _loadProfile() async {
    try {
      final res = await _client.from('profiles').select().single();
      setState(() {
        _profile = Map<String, dynamic>.from(res);
      });
    } catch (e) {
      debugPrint("Error loading profile: $e");
    }
  }

  Future<void> _loadTodos() async {
    final rows = await SB.fetchTodos();
    setState(() => _todos = rows.map((m) => Todo.fromMap(m)).toList());
  }

  Future<void> _addOrEdit({Todo? t}) async {
    final titleCtrl = TextEditingController(text: t?.title ?? '');
    DateTime deadline = t?.deadline ?? DateTime.now().add(const Duration(hours: 2));

    await showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: StatefulBuilder(builder: (context, setModalState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t == null ? 'New Task' : 'Edit Task',
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Task Title'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(DateFormat('EEE, d MMM • HH:mm').format(deadline)),
                  ),
                  TextButton(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                        initialDate: deadline,
                      );
                      if (d == null) return;
                      final tm = await showTimePicker(
                        context: ctx,
                        initialTime: TimeOfDay.fromDateTime(deadline),
                      );
                      if (tm == null) return;
                      setModalState(() {
                        deadline = DateTime(d.year, d.month, d.day, tm.hour, tm.minute);
                      });
                    },
                    child: Text(
                      'Pick time',
                      style: TextStyle(color: Colors.grey[900], fontSize: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.blue.shade100),
                onPressed: () async {
                  final userId = _client.auth.currentUser?.id ?? "guest";

                  if (t == null) {
                    await SB.insertTodo(
                      userId: userId,
                      title: titleCtrl.text.trim(),
                      deadline: deadline,
                    );
                  } else {
                    await SB.updateTodo(
                      id: t.id,
                      title: titleCtrl.text.trim(),
                      deadline: deadline,
                    );
                  }

                  // Reload todos to update the list immediately
                  await _loadTodos();

                  if (context.mounted) Navigator.pop(ctx);
                },
                child: Text(
                  'Save',
                  style: TextStyle(color: Colors.grey[900], fontSize: 20),
                ),
              ),
              const SizedBox(height: 8),
            ],
          );
        }),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<Todo> get _selectedTodos {
    final day = _selectedDay ?? _focusedDay;
    final list =
    _todos.where((t) => _isSameDay(t.deadline.toLocal(), day)).toList();

    // Apply search filter if active
    if (_isSearching && _searchCtrl.text.isNotEmpty) {
      return list
          .where((t) =>
          t.title.toLowerCase().contains(_searchCtrl.text.toLowerCase()))
          .toList();
    }

    list.sort((a, b) => a.deadline.compareTo(b.deadline));
    return list;
  }

  Widget _buildAgenda() {
    if (_selectedTodos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              "https://t4.ftcdn.net/jpg/12/95/47/51/240_F_1295475161_D5nQktb0H4lRUFjqJPYMKpiS4gNIQci6.jpg",
              height: 180,
            ),
            const Text(
              "No tasks for this day.",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _selectedTodos.length,
      itemBuilder: (context, idx) {
        final t = _selectedTodos[idx];
        return Card(
          color: Colors.blue.shade100,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(DateFormat('hh:mm a').format(t.deadline)),
            onTap: () => _addOrEdit(t: t),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.black),
              onPressed: () async {
                await SB.deleteTodo(t.id);
                await _loadTodos(); // Reload after deletion
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeline() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 24,
      itemBuilder: (context, hour) {
        final timeLabel = DateFormat('HH:00').format(DateTime(0, 0, 0, hour));
        final hourTasks = _selectedTodos.where((t) => t.deadline.hour == hour).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(timeLabel, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            ...hourTasks.map((t) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(t.title, style: const TextStyle(fontWeight: FontWeight.w600)),
            )),
            const Divider(),
          ],
        );
      },
    );
  }

  Widget _buildViewSwitcher() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ChoiceChip(
          label: const Text("Agenda"),
          selectedColor: Colors.blue.shade100,
          backgroundColor: Colors.grey.shade100,
          side: const BorderSide(color: Colors.grey),
          selected: _viewIndex == 0,
          onSelected: (_) => setState(() => _viewIndex = 0),
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text("Timeline"),
          selectedColor: Colors.blue.shade100,
          backgroundColor: Colors.grey.shade100,
          side: const BorderSide(color: Colors.grey),
          selected: _viewIndex == 1,
          onSelected: (_) => setState(() => _viewIndex = 1),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: Container(
          color: Colors.grey.shade100,
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: NetworkImage(
                        'https://images.unsplash.com/photo-1552845108-5f775a2ccb9b?q=80&w=871&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D'),
                  ),
                ),
                accountName: Text(_profile?['username'] ?? 'Guest'),
                accountEmail: Text(_profile?['email'] ?? 'Not signed in'),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: _profile?['avatar_url'] != null
                      ? NetworkImage(_profile!['avatar_url'])
                      : null,
                  child: _profile?['avatar_url'] == null
                      ? const Icon(Icons.person, size: 32)
                      : null,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.settings, color: Colors.black),
                title: const Text("Settings", style: TextStyle(color: Colors.black)),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.black),
                title: const Text("Logout", style: TextStyle(color: Colors.black)),
                onTap: () async {
                  await _client.auth.signOut();
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade100,
        elevation: 0,
        toolbarHeight: 76,
        title: _isSearching
            ? Container(
          height: 42,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: TextField(
            controller: _searchCtrl,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: "Search tasks...",
              border: InputBorder.none,
              icon: Icon(Icons.search),
            ),
            onChanged: (_) => setState(() {}),
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => setState(() => _isSearching = true),
            ),
            Row(children: [
              const Icon(Icons.calendar_today, size: 18),
              const SizedBox(width: 6),
              Text(DateFormat('MMMM').format(_focusedDay),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(width: 12),
              if (_profile != null)
                CircleAvatar(
                  radius: 16,
                  backgroundImage: _profile?['avatar_url'] != null
                      ? NetworkImage(_profile!['avatar_url'])
                      : null,
                  child: _profile?['avatar_url'] == null
                      ? const Icon(Icons.person)
                      : null,
                ),
            ])
          ],
        ),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchCtrl.clear();
                });
              },
            )
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) =>
            _selectedDay != null ? _isSameDay(_selectedDay!, day) : false,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarFormat: _calendarFormat,
            onFormatChanged: (format) => setState(() => _calendarFormat = format),
            calendarStyle: CalendarStyle(
              todayDecoration:
              BoxDecoration(color: Colors.orange[900], shape: BoxShape.circle),
              selectedDecoration:
              const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
              markersAlignment: Alignment.bottomCenter,
            ),
          ),
          _buildViewSwitcher(),
          Expanded(child: _viewIndex == 0 ? _buildAgenda() : _buildTimeline()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade100,
        onPressed: () => _addOrEdit(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
