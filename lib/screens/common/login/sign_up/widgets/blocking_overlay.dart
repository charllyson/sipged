import 'package:flutter/material.dart';

import 'package:sipged/_widgets/loading/loading_tree_dots.dart';

class BlockingOverlay extends StatelessWidget {
  const BlockingOverlay({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: ModalBarrier(
            dismissible: false,
            color: Color(0x66000000),
          ),
        ),
        Positioned.fill(
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF374151),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.20),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LoadingTreeDots(
                    size: 22,
                    strokeWidth: 2.6,
                    color: Colors.white,
                    centered: false,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}