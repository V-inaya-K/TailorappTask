// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:tailorapptask/services/todo.dart';
// import 'package:tailorapptask/services/supabase_stuff.dart';
//
// class HomePage extends StatefulWidget {
//   const HomePage({super.key});
//   @override
//   State<HomePage> createState() => _HomePageState();
// }
//
// class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
//   final _client = Supabase.instance.client;
//   late AnimationController _menuCtrl;
//   late AnimationController _searchCtrl;
//   List<Todo> _todos = [];
//   Map<String, dynamic>? _profile;
//   RealtimeChannel? _channel;
//
//   @override
//   void initState() {
//     super.initState();
//     _menuCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
//     _searchCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
//     _loadAll();
//
//     // subscribe to realtime changes (simple approach)
//     _channel = _client.channel('public:todos')
//       ..on(
//         RealtimeListenTypes.postgresChanges,
//         ChannelFilter(event: '*', schema: 'public', table: 'todos'),
//             (payload, [ref]) => _loadAll(),
//       ).subscribe();
//   }
//
//   @override
//   void dispose() {
//     _menuCtrl.dispose();
//     _searchCtrl.dispose();
//     _channel?.unsubscribe();
//     super.dispose();
//   }
//
//   Future<void> _loadAll() async {
//     await _loadProfile();
//     await _loadTodos();
//   }
//
//   Future<void> _loadProfile() async {
//     try {
//       final res = await _client
//           .from('profiles')
//           .select()
//           .single(); // returns Map<String, dynamic>
//
//       setState(() {
//         _profile = Map<String, dynamic>.from(res);
//       });
//     } catch (e) {
//       debugPrint("Error loading profile: $e");
//     }
//   }
//
//
//   Future<void> _loadTodos() async {
//     final rows = await SB.fetchTodos();
//     setState(() => _todos = rows.map((m) => Todo.fromMap(m)).toList());
//   }
//
//   Future<void> _addOrEdit({Todo? t}) async {
//     final titleCtrl = TextEditingController(text: t?.title ?? '');
//     DateTime deadline = t?.deadline ?? DateTime.now().add(const Duration(hours: 2));
//
//     await showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
//       builder: (ctx) => Padding(
//         padding: EdgeInsets.only(
//           bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
//           left: 16, right: 16, top: 16,
//         ),
//         child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
//           Text(t == null ? 'New Todo' : 'Edit Todo', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//           const SizedBox(height: 12),
//           TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
//           const SizedBox(height: 12),
//           Row(children: [
//             Expanded(child: Text(DateFormat('EEE, d MMM • HH:mm').format(deadline))),
//             TextButton(
//               onPressed: () async {
//                 final d = await showDatePicker(
//                   context: ctx, firstDate: DateTime.now(), lastDate: DateTime(2100), initialDate: deadline,
//                 );
//                 if (d == null) return;
//                 final tm = await showTimePicker(context: ctx, initialTime: TimeOfDay.fromDateTime(deadline));
//                 if (tm == null) return;
//                 setState(() => deadline = DateTime(d.year, d.month, d.day, tm.hour, tm.minute));
//               },
//               child: const Text('Pick time'),
//             )
//           ]),
//           const SizedBox(height: 8),
//           FilledButton(
//             onPressed: () async {
//               final userId = _client.auth.currentUser!.id;
//               if (t == null) {
//                 await SB.insertTodo(userId: userId, title: titleCtrl.text.trim(), deadline: deadline);
//               } else {
//                 await SB.updateTodo(id: t.id, title: titleCtrl.text.trim(), deadline: deadline);
//               }
//               if (context.mounted) Navigator.pop(ctx);
//             },
//             child: const Text('Save'),
//           ),
//           const SizedBox(height: 8),
//         ]),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final user = _client.auth.currentUser!;
//     return Scaffold(
//       backgroundColor: Colors.grey.shade100,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         toolbarHeight: 76,
//         title: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             IconButton(
//               icon: AnimatedIcon(icon: AnimatedIcons.menu_close, progress: _menuCtrl),
//               onPressed: () => _menuCtrl.isCompleted ? _menuCtrl.reverse() : _menuCtrl.forward(),
//             ),
//             IconButton(
//               icon: AnimatedIcon(icon: AnimatedIcons.search_ellipsis, progress: _searchCtrl),
//               onPressed: () => _searchCtrl.isCompleted ? _searchCtrl.reverse() : _searchCtrl.forward(),
//             ),
//             Row(children: [
//               const Icon(Icons.calendar_today, size: 18),
//               const SizedBox(width: 6),
//               const Text('January', style: TextStyle(fontWeight: FontWeight.w700)),
//               const Icon(Icons.arrow_drop_down),
//               const SizedBox(width: 12),
//               // profile avatar
//               if (_profile != null)
//                 CircleAvatar(
//                   radius: 16,
//                   backgroundImage: _profile!['avatar_url'] != null ? NetworkImage(_profile!['avatar_url']) : null,
//                   child: _profile!['avatar_url'] == null ? const Icon(Icons.person) : null,
//                 ),
//             ])
//           ],
//         ),
//       ),
//       body: Column(
//         children: [
//           // date selector row (simple)
//           SizedBox(
//             height: 80,
//             child: ListView.builder(
//               scrollDirection: Axis.horizontal,
//               padding: const EdgeInsets.symmetric(horizontal: 12),
//               itemCount: 7,
//               itemBuilder: (context, i) {
//                 final dayNames = ["S", "M", "T", "W", "T", "F", "S"];
//                 final day = DateTime.now().add(Duration(days: i));
//                 final isActive = i == 3;
//                 return Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
//                   child: Column(children: [
//                     Text(dayNames[day.weekday % 7], style: const TextStyle(color: Colors.grey)),
//                     const SizedBox(height: 6),
//                     CircleAvatar(
//                       backgroundColor: isActive ? Colors.orange : Colors.grey.shade200,
//                       child: Text('${day.day}', style: TextStyle(color: isActive ? Colors.white : Colors.black)),
//                     )
//                   ]),
//                 );
//               },
//             ),
//           ),
//
//           Expanded(
//             child: ListView.separated(
//               padding: const EdgeInsets.all(16),
//               itemCount: _todos.length,
//               separatorBuilder: (_, __) => const SizedBox(height: 14),
//               itemBuilder: (context, idx) {
//                 final t = _todos[idx];
//                 final isEven = idx.isEven;
//                 return Dismissible(
//                   key: ValueKey(t.id),
//                   background: Container(
//                     decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)),
//                     alignment: Alignment.centerLeft,
//                     padding: const EdgeInsets.only(left: 20),
//                     child: const Icon(Icons.delete, color: Colors.white),
//                   ),
//                   onDismissed: (_) => SB.deleteTodo(t.id),
//                   child: InkWell(
//                     onTap: () => _addOrEdit(t: t),
//                     child: Container(
//                       decoration: BoxDecoration(
//                         color: isEven ? Colors.green.shade100 : Colors.black87,
//                         borderRadius: BorderRadius.circular(22),
//                       ),
//                       padding: const EdgeInsets.all(16),
//                       child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//                         Text(t.title, style: TextStyle(color: isEven ? Colors.black : Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
//                         const SizedBox(height: 6),
//                         Row(children: [
//                           const Icon(Icons.access_time, size: 16, color: Colors.grey),
//                           const SizedBox(width: 6),
//                           Text(DateFormat('EEE, d MMM • HH:mm').format(t.deadline.toLocal()), style: const TextStyle(color: Colors.grey)),
//                         ])
//                       ]),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           )
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         backgroundColor: Colors.orange,
//         onPressed: () => _addOrEdit(),
//         child: const Icon(Icons.add),
//       ),
//     );
//   }
// }
// ------------------------------
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  late AnimationController _menuCtrl;
  late AnimationController _searchCtrl;
  List<Todo> _todos = [];
  Map<String, dynamic>? _profile;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _menuCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _searchCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _loadAll();

    // ✅ subscribe to realtime changes (Supabase v2 API)
    _channel = _client
        .channel('public:todos')
        .onPostgresChanges(
      event: PostgresChangeEvent.all, // listen to INSERT, UPDATE, DELETE
      schema: 'public',
      table: 'todos',
      callback: (payload) {
        // You can print the payload to debug:
        // print("Realtime change: $payload");
        _loadAll(); // simple approach: refresh list on any change
      },
    )
        .subscribe();
  }

  @override
  void dispose() {
    _menuCtrl.dispose();
    _searchCtrl.dispose();

    // ✅ clean up channel
    if (_channel != null) {
      _client.removeChannel(_channel!);
    }

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
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          left: 16, right: 16, top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t == null ? 'New Todo' : 'Edit Todo',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: Text(DateFormat('EEE, d MMM • HH:mm').format(deadline))),
              TextButton(
                onPressed: () async {
                  final d = await showDatePicker(
                    context: ctx, firstDate: DateTime.now(), lastDate: DateTime(2100), initialDate: deadline,
                  );
                  if (d == null) return;
                  final tm = await showTimePicker(context: ctx, initialTime: TimeOfDay.fromDateTime(deadline));
                  if (tm == null) return;
                  setState(() => deadline = DateTime(d.year, d.month, d.day, tm.hour, tm.minute));
                },
                child: const Text('Pick time'),
              )
            ]),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () async {
                final userId = _client.auth.currentUser!.id;
                if (t == null) {
                  await SB.insertTodo(userId: userId, title: titleCtrl.text.trim(), deadline: deadline);
                } else {
                  await SB.updateTodo(id: t.id, title: titleCtrl.text.trim(), deadline: deadline);
                }
                if (context.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _client.auth.currentUser!;
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 76,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: AnimatedIcon(icon: AnimatedIcons.menu_close, progress: _menuCtrl),
              onPressed: () => _menuCtrl.isCompleted ? _menuCtrl.reverse() : _menuCtrl.forward(),
            ),
            IconButton(
              icon: AnimatedIcon(icon: AnimatedIcons.search_ellipsis, progress: _searchCtrl),
              onPressed: () => _searchCtrl.isCompleted ? _searchCtrl.reverse() : _searchCtrl.forward(),
            ),
            Row(children: [
              const Icon(Icons.calendar_today, size: 18),
              const SizedBox(width: 6),
              const Text('January', style: TextStyle(fontWeight: FontWeight.w700)),
              const Icon(Icons.arrow_drop_down),
              const SizedBox(width: 12),
              if (_profile != null)
                CircleAvatar(
                  radius: 16,
                  backgroundImage: _profile!['avatar_url'] != null
                      ? NetworkImage(_profile!['avatar_url'])
                      : null,
                  child: _profile!['avatar_url'] == null ? const Icon(Icons.person) : null,
                ),
            ])
          ],
        ),
      ),
      body: Column(
        children: [
          // date selector row
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: 7,
              itemBuilder: (context, i) {
                final dayNames = ["S", "M", "T", "W", "T", "F", "S"];
                final day = DateTime.now().add(Duration(days: i));
                final isActive = i == 3;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Column(children: [
                    Text(dayNames[day.weekday % 7], style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 6),
                    CircleAvatar(
                      backgroundColor: isActive ? Colors.orange : Colors.grey.shade200,
                      child: Text('${day.day}', style: TextStyle(color: isActive ? Colors.white : Colors.black)),
                    )
                  ]),
                );
              },
            ),
          ),

          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _todos.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, idx) {
                final t = _todos[idx];
                final isEven = idx.isEven;
                return Dismissible(
                  key: ValueKey(t.id),
                  background: Container(
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => SB.deleteTodo(t.id),
                  child: InkWell(
                    onTap: () => _addOrEdit(t: t),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isEven ? Colors.green.shade100 : Colors.black87,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          t.title,
                          style: TextStyle(
                            color: isEven ? Colors.black : Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(children: [
                          const Icon(Icons.access_time, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('EEE, d MMM • HH:mm').format(t.deadline.toLocal()),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ])
                      ]),
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: () => _addOrEdit(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
