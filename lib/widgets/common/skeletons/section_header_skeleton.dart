import 'package:flutter/material.dart';
import 'package:to_do_app/widgets/common/shimmer_box.dart';
import 'package:to_do_app/widgets/common/skeletons/skeleton_tokens.dart';

class SectionHeaderSkeleton extends StatelessWidget {
  const SectionHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Row(
          children: [
            const ShimmerBox(width: 120, height: 16),
            const Spacer(),
            ShimmerBox(
              width: 80,
              height: 28,
              borderRadius: radiusSm,
            ),
          ],
        ),
      ),
    );
  }
}
