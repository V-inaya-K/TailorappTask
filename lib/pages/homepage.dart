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
//     // ✅ subscribe to realtime changes (Supabase v2 API)
//     _channel = _client
//         .channel('public:todos')
//         .onPostgresChanges(
//       event: PostgresChangeEvent.all, // listen to INSERT, UPDATE, DELETE
//       schema: 'public',
//       table: 'todos',
//       callback: (payload) {
//         // You can print the payload to debug:
//         // print("Realtime change: $payload");
//         _loadAll(); // simple approach: refresh list on any change
//       },
//     )
//         .subscribe();
//   }
//
//   @override
//   void dispose() {
//     _menuCtrl.dispose();
//     _searchCtrl.dispose();
//
//     // ✅ clean up channel
//     if (_channel != null) {
//       _client.removeChannel(_channel!);
//     }
//
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
//       final res = await _client.from('profiles').select().single();
//       setState(() {
//         _profile = Map<String, dynamic>.from(res);
//       });
//     } catch (e) {
//       debugPrint("Error loading profile: $e");
//     }
//   }
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
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(t == null ? 'New Todo' : 'Edit Todo',
//                 style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 12),
//             TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
//             const SizedBox(height: 12),
//             Row(children: [
//               Expanded(child: Text(DateFormat('EEE, d MMM • HH:mm').format(deadline))),
//               TextButton(
//                 onPressed: () async {
//                   final d = await showDatePicker(
//                     context: ctx, firstDate: DateTime.now(), lastDate: DateTime(2100), initialDate: deadline,
//                   );
//                   if (d == null) return;
//                   final tm = await showTimePicker(context: ctx, initialTime: TimeOfDay.fromDateTime(deadline));
//                   if (tm == null) return;
//                   setState(() => deadline = DateTime(d.year, d.month, d.day, tm.hour, tm.minute));
//                 },
//                 child: const Text('Pick time'),
//               )
//             ]),
//             const SizedBox(height: 8),
//             FilledButton(
//               onPressed: () async {
//                 final userId = _client.auth.currentUser!.id;
//                 if (t == null) {
//                   await SB.insertTodo(userId: userId, title: titleCtrl.text.trim(), deadline: deadline);
//                 } else {
//                   await SB.updateTodo(id: t.id, title: titleCtrl.text.trim(), deadline: deadline);
//                 }
//                 if (context.mounted) Navigator.pop(ctx);
//               },
//               child: const Text('Save'),
//             ),
//             const SizedBox(height: 8),
//           ],
//         ),
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
//               if (_profile != null)
//                 CircleAvatar(
//                   radius: 16,
//                   backgroundImage: _profile!['avatar_url'] != null
//                       ? NetworkImage(_profile!['avatar_url'])
//                       : null,
//                   child: _profile!['avatar_url'] == null ? const Icon(Icons.person) : null,
//                 ),
//             ])
//           ],
//         ),
//       ),
//       body: Column(
//         children: [
//           // date selector row
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
//                         Text(
//                           t.title,
//                           style: TextStyle(
//                             color: isEven ? Colors.black : Colors.white,
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 6),
//                         Row(children: [
//                           const Icon(Icons.access_time, size: 16, color: Colors.grey),
//                           const SizedBox(width: 6),
//                           Text(
//                             DateFormat('EEE, d MMM • HH:mm').format(t.deadline.toLocal()),
//                             style: const TextStyle(color: Colors.grey),
//                           ),
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
// -------------------------------------
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// // import 'package:supabase_flutter/supabase_flutter.dart';
// // import 'package:tailorapptask/services/todo.dart';
// // import 'package:tailorapptask/services/supabase_stuff.dart';
//
// class HomePage extends StatefulWidget {
//   const HomePage({super.key});
//   @override
//   State<HomePage> createState() => _HomePageState();
// }
//
// class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
//   // final _client = Supabase.instance.client; // not needed for UI preview
//   late AnimationController _menuCtrl;
//   late AnimationController _searchCtrl;
//
//   // List<Todo> _todos = []; // remove real data
//   // Map<String, dynamic>? _profile; // remove profile
//   // RealtimeChannel? _channel; // remove realtime
//
//   @override
//   void initState() {
//     super.initState();
//     _menuCtrl = AnimationController(
//         vsync: this, duration: const Duration(milliseconds: 300));
//     _searchCtrl = AnimationController(
//         vsync: this, duration: const Duration(milliseconds: 300));
//
//     // _loadAll(); // skip loading
//     // _channel = _client.channel('public:todos').onPostgresChanges(...).subscribe(); // skip realtime
//   }
//
//   @override
//   void dispose() {
//     _menuCtrl.dispose();
//     _searchCtrl.dispose();
//
//     // if (_channel != null) _client.removeChannel(_channel!); // skip channel cleanup
//     super.dispose();
//   }
//
//   // Future<void> _loadAll() async {} // skip backend
//   // Future<void> _loadProfile() async {} // skip backend
//   // Future<void> _loadTodos() async {} // skip backend
//   // Future<void> _addOrEdit({Todo? t}) async {} // skip modal bottom sheet
//
//   @override
//   Widget build(BuildContext context) {
//     // final user = _client.auth.currentUser!; // skip user auth
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
//               icon: AnimatedIcon(
//                   icon: AnimatedIcons.menu_close, progress: _menuCtrl),
//               onPressed: () =>
//                   _menuCtrl.isCompleted ? _menuCtrl.reverse() : _menuCtrl.forward(),
//             ),
//             IconButton(
//               icon: AnimatedIcon(
//                   icon: AnimatedIcons.search_ellipsis, progress: _searchCtrl),
//               onPressed: () => _searchCtrl.isCompleted
//                   ? _searchCtrl.reverse()
//                   : _searchCtrl.forward(),
//             ),
//             Row(children: [
//               const Icon(Icons.calendar_today, size: 18),
//               const SizedBox(width: 6),
//               const Text('January', style: TextStyle(fontWeight: FontWeight.w700)),
//               const Icon(Icons.arrow_drop_down),
//               const SizedBox(width: 12),
//               CircleAvatar(
//                 radius: 16,
//                 backgroundImage: null, // remove profile avatar
//                 child: const Icon(Icons.person),
//               ),
//             ])
//           ],
//         ),
//       ),
//       body: Column(
//         children: [
//           // date selector row
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
//                     Text(dayNames[day.weekday % 7],
//                         style: const TextStyle(color: Colors.grey)),
//                     const SizedBox(height: 6),
//                     CircleAvatar(
//                       backgroundColor:
//                           isActive ? Colors.orange : Colors.grey.shade200,
//                       child: Text('${day.day}',
//                           style:
//                               TextStyle(color: isActive ? Colors.white : Colors.black)),
//                     )
//                   ]),
//                 );
//               },
//             ),
//           ),
//
//           // Todos list placeholder
//           Expanded(
//             child: ListView.separated(
//               padding: const EdgeInsets.all(16),
//               itemCount: 10, // show dummy items
//               separatorBuilder: (_, __) => const SizedBox(height: 14),
//               itemBuilder: (context, idx) {
//                 final isEven = idx.isEven;
//                 return Dismissible(
//                   key: ValueKey(idx),
//                   background: Container(
//                     decoration: BoxDecoration(
//                         color: Colors.red, borderRadius: BorderRadius.circular(20)),
//                     alignment: Alignment.centerLeft,
//                     padding: const EdgeInsets.only(left: 20),
//                     child: const Icon(Icons.delete, color: Colors.white),
//                   ),
//                   onDismissed: (_) {}, // skip delete
//                   child: InkWell(
//                     onTap: () {}, // skip edit
//                     child: Container(
//                       decoration: BoxDecoration(
//                         color: isEven ? Colors.green.shade100 : Colors.black87,
//                         borderRadius: BorderRadius.circular(22),
//                       ),
//                       padding: const EdgeInsets.all(16),
//                       child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               'Todo Item $idx',
//                               style: TextStyle(
//                                 color: isEven ? Colors.black : Colors.white,
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             const SizedBox(height: 6),
//                             Row(children: [
//                               const Icon(Icons.access_time, size: 16, color: Colors.grey),
//                               const SizedBox(width: 6),
//                               Text(
//                                 DateFormat('EEE, d MMM • HH:mm')
//                                     .format(DateTime.now()),
//                                 style: const TextStyle(color: Colors.grey),
//                               ),
//                             ])
//                           ]),
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
//         onPressed: () {}, // skip add
//         child: const Icon(Icons.add),
//       ),
//     );
//   }
// }
// ------------------------------
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
//
// class Todo {
//   int id;
//   String title;
//   DateTime deadline;
//
//   Todo({required this.id, required this.title, required this.deadline});
// }
//
// class HomePage extends StatefulWidget {
//   const HomePage({super.key});
//
//   @override
//   State<HomePage> createState() => _HomePageState();
// }
//
// class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
//   late AnimationController _menuCtrl;
//   late AnimationController _searchCtrl;
//
//   List<Todo> _todos = [];
//   Map<String, dynamic>? _profile;
//
//   int _nextId = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     _menuCtrl = AnimationController(
//         vsync: this, duration: const Duration(milliseconds: 300));
//     _searchCtrl = AnimationController(
//         vsync: this, duration: const Duration(milliseconds: 300));
//
//     // Dummy profile
//     _profile = {'avatar_url': null};
//
//     // Dummy todos
//     _todos = List.generate(
//         5,
//             (i) => Todo(
//             id: _nextId++,
//             title: 'Todo Item ${i + 1}',
//             deadline: DateTime.now().add(Duration(hours: i + 1))));
//   }
//
//   @override
//   void dispose() {
//     _menuCtrl.dispose();
//     _searchCtrl.dispose();
//     super.dispose();
//   }
//
//   Future<void> _addOrEdit({Todo? t}) async {
//     final titleCtrl = TextEditingController(text: t?.title ?? '');
//     DateTime deadline = t?.deadline ?? DateTime.now().add(const Duration(hours: 2));
//
//     await showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//           borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
//       builder: (ctx) => Padding(
//         padding: EdgeInsets.only(
//           bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
//           left: 16,
//           right: 16,
//           top: 16,
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(t == null ? 'New Todo' : 'Edit Todo',
//                 style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 12),
//             TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
//             const SizedBox(height: 12),
//             Row(children: [
//               Expanded(child: Text(DateFormat('EEE, d MMM • HH:mm').format(deadline))),
//               TextButton(
//                 onPressed: () async {
//                   final d = await showDatePicker(
//                     context: ctx,
//                     firstDate: DateTime.now(),
//                     lastDate: DateTime(2100),
//                     initialDate: deadline,
//                   );
//                   if (d == null) return;
//                   final tm = await showTimePicker(
//                       context: ctx, initialTime: TimeOfDay.fromDateTime(deadline));
//                   if (tm == null) return;
//                   setState(() => deadline = DateTime(d.year, d.month, d.day, tm.hour, tm.minute));
//                 },
//                 child: const Text('Pick time'),
//               )
//             ]),
//             const SizedBox(height: 8),
//             FilledButton(
//               onPressed: () {
//                 setState(() {
//                   if (t == null) {
//                     _todos.add(Todo(id: _nextId++, title: titleCtrl.text.trim(), deadline: deadline));
//                   } else {
//                     t.title = titleCtrl.text.trim();
//                     t.deadline = deadline;
//                   }
//                 });
//                 if (context.mounted) Navigator.pop(ctx);
//               },
//               child: const Text('Save'),
//             ),
//             const SizedBox(height: 8),
//           ],
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
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
//               CircleAvatar(
//                 radius: 16,
//                 backgroundImage: _profile!['avatar_url'] != null ? NetworkImage(_profile!['avatar_url']) : null,
//                 child: _profile!['avatar_url'] == null ? const Icon(Icons.person) : null,
//               ),
//             ])
//           ],
//         ),
//       ),
//       body: Column(
//         children: [
//           // date selector row
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
//                   onDismissed: (_) {
//                     setState(() => _todos.removeAt(idx));
//                   },
//                   child: InkWell(
//                     onTap: () => _addOrEdit(t: t),
//                     child: Container(
//                       decoration: BoxDecoration(
//                         color: isEven ? Colors.green.shade100 : Colors.black87,
//                         borderRadius: BorderRadius.circular(22),
//                       ),
//                       padding: const EdgeInsets.all(16),
//                       child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//                         Text(
//                           t.title,
//                           style: TextStyle(
//                             color: isEven ? Colors.black : Colors.white,
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 6),
//                         Row(children: [
//                           const Icon(Icons.access_time, size: 16, color: Colors.grey),
//                           const SizedBox(width: 6),
//                           Text(
//                             DateFormat('EEE, d MMM • HH:mm').format(t.deadline),
//                             style: const TextStyle(color: Colors.grey),
//                           ),
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
// ------------
// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// local services
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

    _channel = _client
        .channel('public:todos')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'todos',
      callback: (payload) {
        _loadAll();
      },
    )
        .subscribe();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
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
    DateTime deadline =
        t?.deadline ?? DateTime.now().add(const Duration(hours: 2));

    await showModalBottomSheet(
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
              Text(t == null ? 'New Todo' : 'Edit Todo',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: Text(
                        DateFormat('EEE, d MMM • HH:mm').format(deadline))),
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
                        initialTime: TimeOfDay.fromDateTime(deadline));
                    if (tm == null) return;
                    setModalState(() => deadline = DateTime(
                        d.year, d.month, d.day, tm.hour, tm.minute));
                  },
                  child: const Text('Pick time'),
                )
              ]),
              const SizedBox(height: 8),
              FilledButton(
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

                  if (context.mounted) Navigator.pop(ctx);
                },
                child: const Text('Save'),
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
      return const Center(child: Text("No tasks for this day."));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _selectedTodos.length,
      itemBuilder: (context, idx) {
        final t = _selectedTodos[idx];
        return Card(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(t.title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(DateFormat('hh:mm a').format(t.deadline)),
            onTap: () => _addOrEdit(t: t),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                await SB.deleteTodo(t.id);
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
        final timeLabel = DateFormat('HH:00').format(
          DateTime(0, 0, 0, hour),
        );
        final hourTasks =
        _selectedTodos.where((t) => t.deadline.hour == hour).toList();
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
              child: Text(t.title,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
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
          selected: _viewIndex == 0,
          // backgroundColor: Colors.blue.shade100,
          onSelected: (_) => setState(() => _viewIndex = 0),
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text("Timeline"),
          selectedColor: Colors.blue.shade100,
          selected: _viewIndex == 1,
          onSelected: (_) => setState(() => _viewIndex = 1),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(   // ✅ Sidebar for account
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
                accountName: Text(_profile?['username'] ?? 'Guest'),
                accountEmail: Text(_profile?['email'] ?? 'Not signed in'),
                currentAccountPicture: CircleAvatar(
                  backgroundImage: _profile?['avatar_url'] != null
                      ? NetworkImage(_profile!['avatar_url'])
                      : null,
                  child: _profile?['avatar_url'] == null
                      ? const Icon(Icons.person, size: 32)
                      : null,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.settings,color: Colors.black,),
                title: const Text("Settings",style: TextStyle(color: Colors.black)),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.logout,color: Colors.black),
                title: const Text("Logout",style: TextStyle(color: Colors.black),),
                onTap: () async {
                  await _client.auth.signOut();
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.grey.shade100,
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
            // Builder(
            //   builder: (context) => IconButton(
            //     icon: const Icon(Icons.menu),
            //     onPressed: () => Scaffold.of(context).openDrawer(),
            //   ),
            // ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() => _isSearching = true);
              },
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
            onFormatChanged: (format) {
              setState(() => _calendarFormat = format);
            },
            calendarStyle: const CalendarStyle(
              todayDecoration:
              BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
              selectedDecoration:
              BoxDecoration(color: Colors.black, shape: BoxShape.circle),
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
