import 'package:flutter/material.dart';

enum NotificationType {
  info,
  success,
  warning,
  error,
}

extension NotificationTypeExtension on NotificationType {
  String get name {
    switch (this) {
      case NotificationType.info:
        return 'info';
      case NotificationType.success:
        return 'success';
      case NotificationType.warning:
        return 'warning';
      case NotificationType.error:
        return 'error';
    }
  }

  static NotificationType fromString(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'success':
        return NotificationType.success;
      case 'warning':
        return NotificationType.warning;
      case 'error':
        return NotificationType.error;
      case 'info':
      default:
        return NotificationType.info;
    }
  }

  Color get defaultAccentColor {
    switch (this) {
      case NotificationType.success:
        return const Color(0xFF2E7D32);
      case NotificationType.warning:
        return const Color(0xFFFFB300);
      case NotificationType.error:
        return const Color(0xFFD32F2F);
      case NotificationType.info:
        return const Color(0xFF9E9E9E);
    }
  }

  IconData get defaultIcon {
    switch (this) {
      case NotificationType.success:
        return Icons.check_circle;
      case NotificationType.warning:
        return Icons.warning_amber_rounded;
      case NotificationType.error:
        return Icons.error_outline;
      case NotificationType.info:
        return Icons.info_outline;
    }
  }
}