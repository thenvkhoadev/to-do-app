import 'package:flutter/material.dart';

const Color skeletonBase = Color(0xFF1E1E2E); // nền skeleton
const Color skeletonHighlight = Color(0xFF2E2E42); // vùng sáng shimmer
const Color skeletonBg = Color(0xFF0B0B12); // nền app (NEXUS dark)

const Duration shimmerDuration = Duration(milliseconds: 1400);
const double shimmerAngle = -0.3; // radian, như FB
const BorderRadius radiusSm = BorderRadius.all(Radius.circular(6));
const BorderRadius radiusMd = BorderRadius.all(Radius.circular(10));
const BorderRadius radiusCircle = BorderRadius.all(Radius.circular(999));

Duration getShimmerPeriod(BuildContext context) {
  final reduceMotion = MediaQuery.of(context).disableAnimations;
  return reduceMotion ? Duration.zero : shimmerDuration;
}
