// lib/screens/_pages/physical_financial/widgets/banner_tip.dart
import 'package:flutter/material.dart';

class PhysFinBannerTip extends StatelessWidget {
  final String text;
  const PhysFinBannerTip({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, left: 28, right: 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 18, color: Colors.blueGrey.shade700),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.blueGrey.shade800,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
