import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:to_do_app/widgets/common/skeletons/skeleton_tokens.dart';

class ShimmerBox extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius borderRadius;
  final Widget? child;

  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(6)),
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white, // Colors are overridden by Shimmer.fromColors but needs to be opaque
        borderRadius: borderRadius,
      ),
      child: child,
    );
  }
}

class SkeletonShimmer extends StatelessWidget {
  final Widget child;
  const SkeletonShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: skeletonBase,
      highlightColor: skeletonHighlight,
      period: getShimmerPeriod(context),
      child: child,
    );
  }
}
