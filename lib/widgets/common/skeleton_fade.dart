import 'package:flutter/material.dart';

class SkeletonFade extends StatelessWidget {
  final bool isLoading;
  final Widget skeleton;
  final Widget child;

  const SkeletonFade({
    super.key,
    required this.isLoading,
    required this.skeleton,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: isLoading
          ? KeyedSubtree(key: const ValueKey('skeleton'), child: skeleton)
          : KeyedSubtree(key: const ValueKey('content'), child: child),
    );
  }
}
