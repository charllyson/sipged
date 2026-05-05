import 'package:flutter/material.dart';

import 'package:sipged/_blocs/system/user/user_data.dart';
import 'package:sipged/_widgets/images/photo_circle/photo_circle.dart';

class AvatarShell extends StatelessWidget {
  const AvatarShell({
    super.key,
    required this.user,
  });

  final UserData user;

  List<Color> get _gradientColors {
    if (user.isDeletedStatus) {
      return const [
        Color(0xFF991B1B),
        Color(0xFF7F1D1D),
      ];
    }

    if (user.isBlockedStatus) {
      return const [
        Color(0xFFDC2626),
        Color(0xFF991B1B),
      ];
    }

    if (user.isInactiveStatus) {
      return const [
        Color(0xFF667085),
        Color(0xFF475467),
      ];
    }

    return const [
      Color(0xFF2563EB),
      Color(0xFF7C3AED),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final color = user.statusColor;

    return Container(
      width: 62,
      height: 62,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: _gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: PhotoCircle(userData: user),
      ),
    );
  }
}