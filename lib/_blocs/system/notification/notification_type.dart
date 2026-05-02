import 'package:flutter/material.dart';

enum NotificationStatus {
  info,
  success,
  warning,
  error,
}

extension NotificationStatusExtension on NotificationStatus {
  String get value {
    switch (this) {
      case NotificationStatus.info:
        return 'info';
      case NotificationStatus.success:
        return 'success';
      case NotificationStatus.warning:
        return 'warning';
      case NotificationStatus.error:
        return 'error';
    }
  }

  String get name => value;

  static NotificationStatus fromString(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'success':
        return NotificationStatus.success;
      case 'warning':
        return NotificationStatus.warning;
      case 'error':
        return NotificationStatus.error;
      case 'info':
      default:
        return NotificationStatus.info;
    }
  }

  Color get defaultAccentColor {
    switch (this) {
      case NotificationStatus.success:
        return const Color(0xFF2E7D32);
      case NotificationStatus.warning:
        return const Color(0xFFFFB300);
      case NotificationStatus.error:
        return const Color(0xFFD32F2F);
      case NotificationStatus.info:
        return const Color(0xFF9E9E9E);
    }
  }

  IconData get defaultIcon {
    switch (this) {
      case NotificationStatus.success:
        return Icons.check_circle;
      case NotificationStatus.warning:
        return Icons.warning_amber_rounded;
      case NotificationStatus.error:
        return Icons.error_outline;
      case NotificationStatus.info:
        return Icons.info_outline;
    }
  }
}

/// Compatibilidade temporária.
/// Pode remover depois que migrarmos tudo para NotificationStatus.
@Deprecated('Use NotificationStatus no lugar de NotificationType.')
typedef NotificationType = NotificationStatus;

/// Compatibilidade temporária.
/// Pode remover depois que migrarmos tudo para NotificationStatusExtension.
@Deprecated('Use NotificationStatusExtension no lugar de NotificationTypeExtension.')
extension NotificationTypeExtension on NotificationStatus {
  static NotificationStatus fromString(String? value) {
    return NotificationStatusExtension.fromString(value);
  }
}