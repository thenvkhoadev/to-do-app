import 'package:flutter/material.dart';
import 'package:to_do_app/widgets/common/shimmer_box.dart';
import 'package:to_do_app/widgets/common/skeletons/skeleton_tokens.dart';

class StatsCardSkeleton extends StatelessWidget {
  const StatsCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: skeletonBase,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const ShimmerBox(
                  width: 32,
                  height: 32,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerBox(width: 100, height: 14),
                    SizedBox(height: 4),
                    ShimmerBox(width: 60, height: 12),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Progress bar
            const ShimmerBox(
              width: double.infinity,
              height: 8,
              borderRadius: radiusCircle,
            ),
          ],
        ),
      ),
    );
  }
}
