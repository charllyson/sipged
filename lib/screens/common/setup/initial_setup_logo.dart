import 'dart:typed_data';
import 'package:flutter/material.dart';

class InitialSetupLogo extends StatelessWidget {
  final Uint8List? logoBytes;
  final String? existingLogoUrl;
  final bool saving;
  final VoidCallback onTap;

  const InitialSetupLogo({
    super.key,
    required this.logoBytes,
    required this.existingLogoUrl,
    required this.saving,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (logoBytes != null) {
      child = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          logoBytes!,
          fit: BoxFit.contain,
        ),
      );
    } else if ((existingLogoUrl ?? '').isNotEmpty) {
      child = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          existingLogoUrl!,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) =>
          const Icon(Icons.image_not_supported_outlined, size: 34),
        ),
      );
    } else {
      child = const Icon(Icons.image_outlined, size: 38);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: saving ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black12),
            color: Colors.white,
          ),
          child: Stack(
            children: [
              Positioned.fill(child: child),
              Positioned(
                right: 6,
                bottom: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    (logoBytes != null || (existingLogoUrl ?? '').isNotEmpty)
                        ? Icons.edit
                        : Icons.add,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}