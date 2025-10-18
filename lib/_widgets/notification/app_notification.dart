import 'package:flutter/material.dart';

enum AppNotificationType { info, success, warning, error }

class AppNotification {
  AppNotification({
    required this.title,
    this.subtitle,
    this.details,
    this.leadingIcon,   // ← opcional: se null, cai no padrão pelo tipo
    this.leadingLabel,
    this.type = AppNotificationType.info,
    this.accentColor,
    this.backgroundColor = Colors.white,
    this.duration = const Duration(seconds: 5),
    this.id,
  });

  final Widget title;
  final Widget? subtitle;
  final Widget? details;

  /// Ícone opcional. Se não vier, usamos o padrão baseado em [type].
  final Widget? leadingIcon;
  final Widget? leadingLabel;

  final AppNotificationType type;
  final Color? accentColor;
  final Color backgroundColor;
  final Duration duration;

  /// Para rastrear/cancelar específico (opcional)
  final String? id;

  /// Cor de acento (padrão por tipo se não vier `accentColor`)
  Color get resolvedAccent {
    if (accentColor != null) return accentColor!;
    switch (type) {
      case AppNotificationType.success: return const Color(0xFF2E7D32);
      case AppNotificationType.warning: return const Color(0xFFFFB300);
      case AppNotificationType.error:   return const Color(0xFFD32F2F);
      case AppNotificationType.info:
      default:                          return const Color(0xFF9E9E9E);
    }
  }

  /// Ícone resolvido: usa o fornecido ou um padrão pelo tipo.
  Widget get resolvedLeadingIcon => leadingIcon ?? _defaultIconForType(type);

  static Widget _defaultIconForType(AppNotificationType t) {
    switch (t) {
      case AppNotificationType.success:
        return const Icon(Icons.check_circle, color: Color(0xFF2E7D32));
      case AppNotificationType.warning:
        return const Icon(Icons.warning_amber_rounded, color: Color(0xFFFFB300));
      case AppNotificationType.error:
        return const Icon(Icons.error_outline, color: Color(0xFFD32F2F));
      case AppNotificationType.info:
      default:
        return const Icon(Icons.info_outline, color: Color(0xFF9E9E9E));
    }
  }
}
