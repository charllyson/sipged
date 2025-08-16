import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SelectorDatesShimmer extends StatelessWidget {
  const SelectorDatesShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(

          children: [
            _buildFakeDropdown(),
            const SizedBox(height: 12),
            _buildFakeDropdown(),
          ],
        ),
        const SizedBox(width: 12),
        Column(
          children: [
            _buildFakeDropdown(),
            const SizedBox(height: 12),
            _buildFakeDropdown(),
          ],
        ),
        const SizedBox(width: 12),
        Column(
          children: [
            _buildFakeDropdown(),
            const SizedBox(height: 12),
            _buildFakeDropdown(),
          ],
        ),
        const SizedBox(width: 12),
        Column(
          children: [
            _buildFakeDropdown(),
            const SizedBox(height: 12),
            _buildFakeDropdown(),
          ],
        ),
        const SizedBox(width: 12),
        Column(
          children: [
            _buildFakeDropdown(),
            const SizedBox(height: 12),
            _buildFakeDropdown(),
          ],
        ),
        const SizedBox(width: 12),

      ],
    );
  }

  Widget _buildFakeDropdown() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Container(
          width: 70,
          height: 35,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }
}
