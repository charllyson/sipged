import 'package:flutter/material.dart';

import 'package:sipged/_blocs/system/user/user_data.dart';
import 'package:sipged/_widgets/images/avatar/photo_circle.dart';

class AvatarShell extends StatelessWidget {
  const AvatarShell({
    super.key,
    required this.user,
    this.size = 62,
  });

  final UserData user;
  final double size;

  bool get _isActive {
    return !user.isDeletedStatus &&
        !user.isBlockedStatus &&
        !user.isInactiveStatus &&
        !user.hasStatusRestriction;
  }

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

    if (_isActive) {
      return const [
        Color(0xFF16A34A),
        Color(0xFF22C55E),
      ];
    }

    return const [
      Color(0xFF2563EB),
      Color(0xFF7C3AED),
    ];
  }

  Color get _shadowColor {
    if (_isActive) {
      return const Color(0xFF16A34A);
    }

    return user.statusColor;
  }

  String get _tooltip {
    if (_isActive) return 'Usuário ativo';

    final label = user.statusLabel.trim();

    if (label.isNotEmpty) return label;

    return 'Usuário com restrição';
  }

  @override
  Widget build(BuildContext context) {
    final outerPadding = size <= 50 ? 1.5 : 2.0;
    final innerPadding = size <= 50 ? 0.8 : 1.0;

    return Tooltip(
      message: _tooltip,
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(outerPadding),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: _gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: _shadowColor.withValues(alpha: _isActive ? 0.24 : 0.22),
              blurRadius: size <= 50 ? 12 : 18,
              offset: Offset(0, size <= 50 ? 5 : 8),
            ),
          ],
        ),
        child: Container(
          padding: EdgeInsets.all(innerPadding),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: PhotoCircle(
              userData: user,
            ),
          ),
        ),
      ),
    );
  }
}