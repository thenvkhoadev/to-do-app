import 'package:flutter/material.dart';
import 'package:to_do_app/widgets/common/shimmer_box.dart';
import 'package:to_do_app/widgets/common/skeletons/skeleton_tokens.dart';
import 'package:to_do_app/widgets/common/skeletons/stats_card_skeleton.dart';
import 'package:to_do_app/widgets/common/skeletons/section_header_skeleton.dart';
import 'package:to_do_app/widgets/common/skeletons/task_list_skeleton.dart';

class TodoHomeSkeleton extends StatelessWidget {
  const TodoHomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: skeletonBg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AppBar area
              const _SkeletonAppBar(),
              const SizedBox(height: 8),

              // Stats row
              SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: 3,
                  itemBuilder: (_, __) => const SizedBox(
                    width: 160,
                    child: StatsCardSkeleton(),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Section 1
              const SectionHeaderSkeleton(),
              const TaskListSkeleton(count: 3),

              const SizedBox(height: 12),

              // Section 2
              const SectionHeaderSkeleton(),
              const TaskListSkeleton(count: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonAppBar extends StatelessWidget {
  const _SkeletonAppBar();

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: [
            const ShimmerBox(
              width: 36,
              height: 36,
              borderRadius: radiusCircle,
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 80, height: 13),
                SizedBox(height: 4),
                ShimmerBox(width: 140, height: 18),
              ],
            ),
            const Spacer(),
            const ShimmerBox(
              width: 36,
              height: 36,
              borderRadius: radiusSm,
            ),
            const SizedBox(width: 8),
            const ShimmerBox(
              width: 36,
              height: 36,
              borderRadius: radiusSm,
            ),
          ],
        ),
      ),
    );
  }
}
