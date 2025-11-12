import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerW60H14 extends StatelessWidget {
  const ShimmerW60H14({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(width: 60, height: 14, color: Colors.grey.shade300),
    );
  }
}
