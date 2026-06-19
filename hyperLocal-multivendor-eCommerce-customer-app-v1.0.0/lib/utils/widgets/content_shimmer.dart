import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ContentShimmer extends StatelessWidget {
  final Widget child;

  const ContentShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE9EDF2),
      highlightColor: const Color(0xFFF6F8FB),
      child: child,
    );
  }
}
