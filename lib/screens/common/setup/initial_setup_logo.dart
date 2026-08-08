// lib/screens/common/setup/initial_setup_logo.dart

import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class InitialSetupLogo extends StatelessWidget {
  final Uint8List? logoBytes;
  final String? existingLogoUrl;
  final bool saving;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const InitialSetupLogo({
    super.key,
    required this.logoBytes,
    required this.existingLogoUrl,
    required this.saving,
    required this.onTap,
    this.onRemove,
  });

  bool get _hasLogo {
    return logoBytes != null || (existingLogoUrl ?? '').trim().isNotEmpty;
  }

  Widget _buildImageContent() {
    if (logoBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.memory(
          logoBytes!,
          fit: BoxFit.contain,
        ),
      );
    }

    final url = existingLogoUrl?.trim();

    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.contain,
          errorWidget: (_, _, _) {
            return const Icon(
              Icons.image_not_supported_outlined,
              size: 34,
              color: Color(0xFF98A2B3),
            );
          },
        ),
      );
    }

    return const Icon(
      Icons.image_outlined,
      size: 38,
      color: Color(0xFF98A2B3),
    );
  }

  @override
  Widget build(BuildContext context) {
    final child = _buildImageContent();

    return SizedBox(
      width: 118,
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: saving ? null : onTap,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                  ),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF101828).withValues(alpha: 0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: child,
                      ),
                    ),
                    Positioned(
                      right: 7,
                      bottom: 7,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF101828).withValues(alpha: 0.78),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _hasLogo ? Icons.edit_rounded : Icons.add_rounded,
                          size: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_hasLogo && onRemove != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: saving ? null : onRemove,
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 15,
              ),
              label: const Text('Remover'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                disabledForegroundColor: Colors.grey,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}