import 'package:flutter/material.dart';
import 'package:to_do_app/widgets/common/skeletons/task_item_skeleton.dart';

class StaggeredTaskListSkeleton extends StatefulWidget {
  final int count;
  const StaggeredTaskListSkeleton({super.key, this.count = 6});

  @override
  State<StaggeredTaskListSkeleton> createState() =>
      _StaggeredTaskListSkeletonState();
}

class _StaggeredTaskListSkeletonState extends State<StaggeredTaskListSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.count * 80 + 300),
    )..forward();

    _animations = List.generate(widget.count, (i) {
      final start = i * 0.08;
      final end = (start + 0.4).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(widget.count, (i) {
        return AnimatedBuilder(
          animation: _animations[i],
          builder: (context, child) => Opacity(
            opacity: _animations[i].value,
            child: Transform.translate(
              offset: Offset(0, 12 * (1 - _animations[i].value)),
              child: child,
            ),
          ),
          child: const TaskItemSkeleton(),
        );
      }),
    );
  }
}
