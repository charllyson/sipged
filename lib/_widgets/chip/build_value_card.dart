import 'package:flutter/material.dart';
import 'package:siged/_utils/formats/format_field.dart';
import 'package:siged/_widgets/overlays/shimmer_w60_h14.dart';

class BuildValueCard extends StatelessWidget {
  final String title;
  final double? value;
  final IconData icon;

  const BuildValueCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 120,
      child: Card(
        color: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: Colors.blueAccent),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              value != null ?
              Text(priceToString(value), style: const TextStyle(fontSize: 16))
              : ShimmerW60H14(),
            ],
          ),
        ),
      ),
    );
  }
}
