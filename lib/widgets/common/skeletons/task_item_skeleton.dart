import 'package:flutter/material.dart';
import 'package:to_do_app/widgets/common/shimmer_box.dart';
import 'package:to_do_app/widgets/common/skeletons/skeleton_tokens.dart';

class TaskItemSkeleton extends StatelessWidget {
  const TaskItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox circle
            const ShimmerBox(
              width: 22,
              height: 22,
              borderRadius: radiusCircle,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: ShimmerBox(height: 14),
                      ),
                      const SizedBox(width: 8),
                      ShimmerBox(
                        width: 52,
                        height: 22,
                        borderRadius: radiusCircle,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const ShimmerBox(width: 140, height: 12),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ShimmerBox(
                        width: 72,
                        height: 20,
                        borderRadius: radiusCircle,
                      ),
                      const SizedBox(width: 8),
                      ShimmerBox(
                        width: 72,
                        height: 20,
                        borderRadius: radiusCircle,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
