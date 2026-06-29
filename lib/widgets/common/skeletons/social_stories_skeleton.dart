import 'package:flutter/material.dart';
import 'package:to_do_app/widgets/common/shimmer_box.dart';
import 'package:to_do_app/widgets/common/skeletons/skeleton_tokens.dart';

class SocialStoriesSkeleton extends StatelessWidget {
  const SocialStoriesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Container(
        height: 96,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 6,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Column(
                children: const [
                  ShimmerBox(
                    width: 52,
                    height: 52,
                    borderRadius: radiusCircle,
                  ),
                  SizedBox(height: 6),
                  ShimmerBox(
                    width: 48,
                    height: 10,
                    borderRadius: radiusSm,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
