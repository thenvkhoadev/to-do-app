import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/tasks/domain/entities/task_board_item.dart';

final editingTaskProvider = StateProvider<TaskBoardItem?>((ref) => null);
