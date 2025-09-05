class Todo {
  final String id;
  final String title;
  final DateTime deadline;

  Todo({required this.id, required this.title, required this.deadline});

  factory Todo.fromMap(Map<String, dynamic> m) => Todo(
    id: m['id'] as String,
    title: m['title'] as String,
    deadline: DateTime.parse(m['deadline'] as String),
  );
}
