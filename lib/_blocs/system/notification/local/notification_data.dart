import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'notification_type.dart';

class NotificationData {
  const NotificationData({
    this.id,
    required this.title,
    this.subtitle,
    this.details,
    this.leadingLabel,
    this.type = NotificationType.info,
    this.accentColor,
    this.backgroundColor = Colors.white,
    this.icon,
    this.duration = const Duration(seconds: 5),
    this.createdAt,
    this.createdBy,
    this.seen = false,
    this.persistInFirebase = false,
    this.sendPush = false,
    this.pushSent = false,
    this.pushSentAt,
    this.pushError,
    this.extra = const <String, dynamic>{},
  });

  final String? id;

  final String title;
  final String? subtitle;
  final String? details;
  final String? leadingLabel;

  final NotificationType type;

  final Color? accentColor;
  final Color backgroundColor;

  /// Ícone opcional apenas em memória.
  ///
  /// Não salve IconData no Firestore.
  /// No Web release isso pode quebrar com tree-shake-icons.
  final IconData? icon;

  final Duration duration;

  final DateTime? createdAt;
  final String? createdBy;
  final bool seen;

  /// Quando true, o Cubit salva a notificação no Firestore.
  final bool persistInFirebase;

  /// Quando true, a Firebase Function envia remote ao criar o doc.
  final bool sendPush;

  /// Controle preenchido pelo backend após tentativa de envio.
  final bool pushSent;
  final DateTime? pushSentAt;
  final String? pushError;

  /// Campo livre para origem, módulo, contractId, route, action etc.
  final Map<String, dynamic> extra;

  Color get resolvedAccentColor => accentColor ?? type.defaultAccentColor;

  IconData get resolvedIcon => icon ?? type.defaultIcon;

  NotificationData copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? details,
    String? leadingLabel,
    NotificationType? type,
    Color? accentColor,
    Color? backgroundColor,
    IconData? icon,
    Duration? duration,
    DateTime? createdAt,
    String? createdBy,
    bool? seen,
    bool? persistInFirebase,
    bool? sendPush,
    bool? pushSent,
    DateTime? pushSentAt,
    String? pushError,
    Map<String, dynamic>? extra,
  }) {
    return NotificationData(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      details: details ?? this.details,
      leadingLabel: leadingLabel ?? this.leadingLabel,
      type: type ?? this.type,
      accentColor: accentColor ?? this.accentColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      icon: icon ?? this.icon,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      seen: seen ?? this.seen,
      persistInFirebase: persistInFirebase ?? this.persistInFirebase,
      sendPush: sendPush ?? this.sendPush,
      pushSent: pushSent ?? this.pushSent,
      pushSentAt: pushSentAt ?? this.pushSentAt,
      pushError: pushError ?? this.pushError,
      extra: extra ?? this.extra,
    );
  }

  Map<String, dynamic> toMap() {
    final cleanExtra = _sanitizeExtra(extra);

    final map = <String, dynamic>{
      'title': title,
      'type': type.name,
      'backgroundColor': backgroundColor.toARGB32(),
      'durationMilliseconds': duration.inMilliseconds,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'seen': seen,
      'sendPush': sendPush,
      'pushSent': pushSent,
      'extra': cleanExtra,
    };

    void addIfNotEmpty(String key, String? value) {
      final cleanValue = value?.trim();

      if (cleanValue != null && cleanValue.isNotEmpty) {
        map[key] = cleanValue;
      }
    }

    addIfNotEmpty('subtitle', subtitle);
    addIfNotEmpty('details', details);
    addIfNotEmpty('leadingLabel', leadingLabel);
    addIfNotEmpty('createdBy', createdBy);
    addIfNotEmpty('pushError', pushError);

    if (accentColor != null) {
      map['accentColor'] = accentColor!.toARGB32();
    }

    if (pushSentAt != null) {
      map['pushSentAt'] = Timestamp.fromDate(pushSentAt!);
    }

    /// Campos duplicados intencionalmente na raiz para facilitar consultas,
    /// filtros e auditoria sem precisar buscar dentro de extra.
    addIfNotEmpty('route', cleanExtra['route']?.toString());
    addIfNotEmpty('module', cleanExtra['module']?.toString());
    addIfNotEmpty('action', cleanExtra['action']?.toString());
    addIfNotEmpty('source', cleanExtra['source']?.toString());
    addIfNotEmpty('contractId', cleanExtra['contractId']?.toString());
    addIfNotEmpty('contractSummary', cleanExtra['contractSummary']?.toString());
    addIfNotEmpty('processId', cleanExtra['processId']?.toString());
    addIfNotEmpty('actorId', cleanExtra['actorId']?.toString());
    addIfNotEmpty('actorName', cleanExtra['actorName']?.toString());

    return map;
  }

  factory NotificationData.fromMap(
      Map<String, dynamic> map, {
        String? id,
      }) {
    final createdAtRaw = map['createdAt'];
    final pushSentAtRaw = map['pushSentAt'];

    DateTime? resolvedCreatedAt;
    DateTime? resolvedPushSentAt;

    if (createdAtRaw is Timestamp) {
      resolvedCreatedAt = createdAtRaw.toDate();
    } else if (createdAtRaw is DateTime) {
      resolvedCreatedAt = createdAtRaw;
    } else if (createdAtRaw is String) {
      resolvedCreatedAt = DateTime.tryParse(createdAtRaw);
    }

    if (pushSentAtRaw is Timestamp) {
      resolvedPushSentAt = pushSentAtRaw.toDate();
    } else if (pushSentAtRaw is DateTime) {
      resolvedPushSentAt = pushSentAtRaw;
    } else if (pushSentAtRaw is String) {
      resolvedPushSentAt = DateTime.tryParse(pushSentAtRaw);
    }

    final accentValue = map['accentColor'];
    final backgroundValue = map['backgroundColor'];

    return NotificationData(
      id: id ?? map['id']?.toString(),
      title: map['title']?.toString() ?? '',
      subtitle: map['subtitle']?.toString(),
      details: map['details']?.toString(),
      leadingLabel: map['leadingLabel']?.toString(),
      type: NotificationTypeExtension.fromString(map['type']?.toString()),
      accentColor: accentValue is int ? Color(accentValue) : null,
      backgroundColor:
      backgroundValue is int ? Color(backgroundValue) : Colors.white,
      icon: null,
      duration: Duration(
        milliseconds: map['durationMilliseconds'] is int
            ? map['durationMilliseconds'] as int
            : 5000,
      ),
      createdAt: resolvedCreatedAt,
      createdBy: map['createdBy']?.toString(),
      seen: map['seen'] == true,
      persistInFirebase: false,
      sendPush: map['sendPush'] == true,
      pushSent: map['pushSent'] == true,
      pushSentAt: resolvedPushSentAt,
      pushError: map['pushError']?.toString(),
      extra: map['extra'] is Map
          ? Map<String, dynamic>.from(map['extra'] as Map)
          : const <String, dynamic>{},
    );
  }

  factory NotificationData.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return NotificationData.fromMap(
      doc.data() ?? const <String, dynamic>{},
      id: doc.id,
    );
  }

  static Map<String, dynamic> _sanitizeExtra(Map<String, dynamic> value) {
    final result = <String, dynamic>{};

    value.forEach((key, item) {
      final cleanKey = key.trim();

      if (cleanKey.isEmpty || item == null) return;

      if (item is String) {
        final cleanValue = item.trim();

        if (cleanValue.isNotEmpty) {
          result[cleanKey] = cleanValue;
        }

        return;
      }

      if (item is num || item is bool) {
        result[cleanKey] = item;
        return;
      }

      if (item is DateTime) {
        result[cleanKey] = item.toIso8601String();
        return;
      }

      if (item is Iterable) {
        final list = item
            .map((e) => e?.toString().trim() ?? '')
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList();

        if (list.isNotEmpty) {
          result[cleanKey] = list;
        }

        return;
      }

      if (item is Map) {
        final nested = <String, dynamic>{};

        item.forEach((nestedKey, nestedValue) {
          final cleanNestedKey = nestedKey.toString().trim();

          if (cleanNestedKey.isEmpty || nestedValue == null) return;

          if (nestedValue is String) {
            final cleanNestedValue = nestedValue.trim();

            if (cleanNestedValue.isNotEmpty) {
              nested[cleanNestedKey] = cleanNestedValue;
            }

            return;
          }

          if (nestedValue is num || nestedValue is bool) {
            nested[cleanNestedKey] = nestedValue;
          }
        });

        if (nested.isNotEmpty) {
          result[cleanKey] = nested;
        }
      }
    });

    return result;
  }
}