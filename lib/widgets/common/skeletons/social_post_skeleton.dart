import 'package:flutter/material.dart';
import 'package:to_do_app/widgets/common/shimmer_box.dart';
import 'package:to_do_app/widgets/common/skeletons/skeleton_tokens.dart';

class SocialPostSkeleton extends StatelessWidget {
  const SocialPostSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: skeletonBase.withValues(alpha: .5),
          borderRadius: radiusMd,
          border: Border.all(color: Colors.white.withValues(alpha: .04)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header
            Row(
              children: [
                const ShimmerBox(
                  width: 40,
                  height: 40,
                  borderRadius: radiusCircle,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerBox(width: 120, height: 14),
                      SizedBox(height: 6),
                      ShimmerBox(width: 80, height: 11),
                    ],
                  ),
                ),
                const ShimmerBox(
                  width: 24,
                  height: 24,
                  borderRadius: radiusSm,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Text Content (1-2 lines)
            const ShimmerBox(width: double.infinity, height: 12),
            const SizedBox(height: 8),
            const ShimmerBox(width: 200, height: 12),
            const SizedBox(height: 16),
            
            // Media block (e.g., Image/Video container)
            ShimmerBox(
              width: double.infinity,
              height: 220,
              borderRadius: radiusMd,
            ),
            const SizedBox(height: 16),
            
            // Interaction Row (Like/Comment/Share)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildActionPlaceholder(),
                _buildActionPlaceholder(),
                _buildActionPlaceholder(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionPlaceholder() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        ShimmerBox(
          width: 20,
          height: 20,
          borderRadius: radiusCircle,
        ),
        SizedBox(width: 6),
        ShimmerBox(width: 42, height: 12),
      ],
    );
  }
}
