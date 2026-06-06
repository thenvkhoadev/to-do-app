import 'package:flutter/material.dart';
import 'package:to_do_app/features/tasks/domain/entities/task_board_item.dart';
import 'package:to_do_app/screens/task_details/task_detail_page.dart';

class TaskDetailsDesktopContent extends StatelessWidget {
  const TaskDetailsDesktopContent({
    required this.item,
    required this.onBack,
    super.key,
  });

  final TaskBoardItem item;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return TaskDetailPage(item: item, onBack: onBack);
  }
}
