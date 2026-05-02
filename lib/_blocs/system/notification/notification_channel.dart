// lib/_blocs/system/notification/notification_channel.dart

import 'package:flutter/material.dart';

enum NotificationChannel {
  local,
  bell,
  push,
  email,
  sms,
}

extension NotificationChannelExtension on NotificationChannel {
  String get key {
    switch (this) {
      case NotificationChannel.local:
        return 'local';
      case NotificationChannel.bell:
        return 'bell';
      case NotificationChannel.push:
        return 'push';
      case NotificationChannel.email:
        return 'email';
      case NotificationChannel.sms:
        return 'sms';
    }
  }

  /// Alias para compatibilidade com códigos que usam `.value`.
  String get value => key;

  String get title {
    switch (this) {
      case NotificationChannel.local:
        return 'Tela';
      case NotificationChannel.bell:
        return 'Sino';
      case NotificationChannel.push:
        return 'Push';
      case NotificationChannel.email:
        return 'E-mail';
      case NotificationChannel.sms:
        return 'SMS';
    }
  }

  String get subtitle {
    switch (this) {
      case NotificationChannel.local:
        return 'Exibe avisos temporários dentro do sistema.';
      case NotificationChannel.bell:
        return 'Salva a notificação no sino do usuário.';
      case NotificationChannel.push:
        return 'Envia alerta push para dispositivos cadastrados.';
      case NotificationChannel.email:
        return 'Envia a notificação por e-mail.';
      case NotificationChannel.sms:
        return 'Envia a notificação por SMS.';
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationChannel.local:
        return Icons.web_asset_rounded;
      case NotificationChannel.bell:
        return Icons.notifications_rounded;
      case NotificationChannel.push:
        return Icons.phone_iphone_rounded;
      case NotificationChannel.email:
        return Icons.mail_rounded;
      case NotificationChannel.sms:
        return Icons.sms_rounded;
    }
  }

  bool get enabledByDefault {
    switch (this) {
      case NotificationChannel.local:
        return true;
      case NotificationChannel.bell:
        return true;
      case NotificationChannel.push:
        return false;
      case NotificationChannel.email:
        return false;
      case NotificationChannel.sms:
        return false;
    }
  }

  static NotificationChannel fromString(String? value) {
    return tryFromString(value) ?? NotificationChannel.local;
  }

  static NotificationChannel? tryFromString(String? value) {
    final clean = (value ?? '').trim().toLowerCase();

    if (clean.isEmpty) return null;

    for (final channel in NotificationChannel.values) {
      if (channel.key == clean || channel.name == clean) {
        return channel;
      }
    }

    return null;
  }

  static Map<String, bool> defaultMap({
    bool? local,
    bool? bell,
    bool? push,
    bool? email,
    bool? sms,
  }) {
    return <String, bool>{
      NotificationChannel.local.key:
      local ?? NotificationChannel.local.enabledByDefault,
      NotificationChannel.bell.key:
      bell ?? NotificationChannel.bell.enabledByDefault,
      NotificationChannel.push.key:
      push ?? NotificationChannel.push.enabledByDefault,
      NotificationChannel.email.key:
      email ?? NotificationChannel.email.enabledByDefault,
      NotificationChannel.sms.key:
      sms ?? NotificationChannel.sms.enabledByDefault,
    };
  }

  static Map<String, bool> normalizeMap(
      Map<String, dynamic>? raw, {
        Map<String, bool>? fallback,
      }) {
    final base = fallback ?? defaultMap();

    if (raw == null) {
      return Map<String, bool>.from(base);
    }

    final result = <String, bool>{};

    for (final channel in NotificationChannel.values) {
      final key = channel.key;
      final value = raw[key];

      result[key] = value is bool ? value : base[key] ?? channel.enabledByDefault;
    }

    return result;
  }

  static Set<NotificationChannel> enabledSetFromMap(
      Map<String, dynamic>? raw, {
        Map<String, bool>? fallback,
      }) {
    final normalized = normalizeMap(
      raw,
      fallback: fallback,
    );

    return NotificationChannel.values.where((channel) {
      return normalized[channel.key] == true;
    }).toSet();
  }

  static Map<String, bool> toMapFromSet(
      Iterable<NotificationChannel> channels,
      ) {
    final enabled = channels.toSet();

    return <String, bool>{
      for (final channel in NotificationChannel.values)
        channel.key: enabled.contains(channel),
    };
  }
}