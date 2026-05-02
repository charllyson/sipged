import 'dart:typed_data';

import 'package:flutter/material.dart';

class AvatarEditable extends StatelessWidget {
  const AvatarEditable({
    super.key,
    required this.photoUrl,
    required this.previewBytes,
    this.onTap,
    this.radius = 46,
    this.borderColor,
    this.showEditButton = true,
  });

  final String? photoUrl;
  final Uint8List? previewBytes;
  final VoidCallback? onTap;
  final double radius;
  final Color? borderColor;
  final bool showEditButton;

  @override
  Widget build(BuildContext context) {
    final image = _buildAvatarImage();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: borderColor ?? Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .16),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: image,
        ),
        if (showEditButton && onTap != null)
          Positioned(
            bottom: 2,
            right: 2,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(999),
                child: Ink(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .22),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAvatarImage() {
    if (previewBytes != null) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: MemoryImage(previewBytes!),
      );
    }

    if ((photoUrl ?? '').trim().isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.blueGrey.shade100,
        backgroundImage: NetworkImage(photoUrl!),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.blueGrey.shade200,
      child: Icon(
        Icons.person_rounded,
        size: radius,
        color: Colors.white.withValues(alpha: .86),
      ),
    );
  }
}