import 'package:flutter/material.dart';
import 'package:to_do_app/widgets/common/skeletons/task_item_skeleton.dart';

class TaskListSkeleton extends StatelessWidget {
  final int count;
  const TaskListSkeleton({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: count,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        color: Color(0xFF1E1E2E),
      ),
      itemBuilder: (_, i) => const TaskItemSkeleton(),
    );
  }
}
