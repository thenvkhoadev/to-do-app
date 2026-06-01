class ToDo {
  String? id;
  String? todoText;
  bool isDone;

  ToDo({required this.id, required this.todoText, this.isDone = false});

  static List<ToDo> todoList() {
    return [
      ToDo(id: '01', todoText: 'Learning Flutter', isDone: true),
      ToDo(id: '02', todoText: 'Create project Flutter', isDone: false),
    ];
  }
}
