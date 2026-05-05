import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'notification_channel.dart';
import 'notification_delivery.dart';
import 'notification_type.dart';

class NotificationData {
  const NotificationData({
    this.id,
    required this.title,
    this.subtitle,
    this.details,
    this.leadingLabel,
    this.status = NotificationStatus.info,
    NotificationStatus? type,
    this.channels = const <NotificationChannel>{},
    this.accentColor,
    this.backgroundColor = Colors.white,
    this.icon,
    this.duration = const Duration(seconds: 5),
    this.createdAt,
    this.createdBy,
    this.seen = false,
    this.persistInFirebase = false,
    this.sendPush = false,
    this.sendEmail = false,
    this.sendSms = false,
    this.pushSent = false,
    this.pushSentAt,
    this.pushError,
    this.recipientUserId,
    this.extra = const <String, dynamic>{},
  }) : type = type ?? status;

  final String? id;

  final String title;
  final String? subtitle;
  final String? details;
  final String? leadingLabel;

  final NotificationStatus status;

  /// Compatibilidade temporária com versões antigas.
  final NotificationStatus type;

  final Set<NotificationChannel> channels;

  final Color? accentColor;
  final Color backgroundColor;

  /// Ícone somente em memória.
  /// Não deve ser persistido no Firestore.
  final IconData? icon;

  final Duration duration;

  final DateTime? createdAt;
  final String? createdBy;
  final bool seen;

  /// Compatibilidade antiga.
  /// Na arquitetura nova, prefira channels contendo NotificationChannel.bell.
  final bool persistInFirebase;

  /// Compatibilidade antiga.
  /// Na arquitetura nova, prefira channels contendo NotificationChannel.push.
  final bool sendPush;

  final bool sendEmail;
  final bool sendSms;

  final bool pushSent;
  final DateTime? pushSentAt;
  final String? pushError;

  final String? recipientUserId;

  final Map<String, dynamic> extra;

  Color get resolvedAccentColor {
    return accentColor ?? status.defaultAccentColor;
  }

  IconData get resolvedIcon {
    return icon ?? status.defaultIcon;
  }

  bool get shouldShowLocal {
    return channels.contains(NotificationChannel.local);
  }

  bool get shouldSaveInBell {
    return channels.contains(NotificationChannel.bell) || persistInFirebase;
  }

  bool get shouldSendPush {
    return channels.contains(NotificationChannel.push) || sendPush;
  }

  bool get shouldSendEmail {
    return channels.contains(NotificationChannel.email) || sendEmail;
  }

  bool get shouldSendSms {
    return channels.contains(NotificationChannel.sms) || sendSms;
  }

  NotificationDelivery get delivery {
    final resolvedChannels = <NotificationChannel>{
      ...channels,
      if (persistInFirebase) NotificationChannel.bell,
      if (sendPush) NotificationChannel.push,
      if (sendEmail) NotificationChannel.email,
      if (sendSms) NotificationChannel.sms,
    };

    return NotificationDelivery(channels: resolvedChannels);
  }

  NotificationData copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? details,
    String? leadingLabel,
    NotificationStatus? status,
    NotificationStatus? type,
    Set<NotificationChannel>? channels,
    Color? accentColor,
    Color? backgroundColor,
    IconData? icon,
    Duration? duration,
    DateTime? createdAt,
    String? createdBy,
    bool? seen,
    bool? persistInFirebase,
    bool? sendPush,
    bool? sendEmail,
    bool? sendSms,
    bool? pushSent,
    DateTime? pushSentAt,
    String? pushError,
    String? recipientUserId,
    Map<String, dynamic>? extra,
    bool clearSubtitle = false,
    bool clearDetails = false,
    bool clearLeadingLabel = false,
    bool clearAccentColor = false,
    bool clearIcon = false,
    bool clearPushError = false,
    bool clearRecipientUserId = false,
  }) {
    final resolvedStatus = status ?? type ?? this.status;

    return NotificationData(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: clearSubtitle ? null : subtitle ?? this.subtitle,
      details: clearDetails ? null : details ?? this.details,
      leadingLabel: clearLeadingLabel ? null : leadingLabel ?? this.leadingLabel,
      status: resolvedStatus,
      type: resolvedStatus,
      channels: channels ?? this.channels,
      accentColor: clearAccentColor ? null : accentColor ?? this.accentColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      icon: clearIcon ? null : icon ?? this.icon,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      seen: seen ?? this.seen,
      persistInFirebase: persistInFirebase ?? this.persistInFirebase,
      sendPush: sendPush ?? this.sendPush,
      sendEmail: sendEmail ?? this.sendEmail,
      sendSms: sendSms ?? this.sendSms,
      pushSent: pushSent ?? this.pushSent,
      pushSentAt: pushSentAt ?? this.pushSentAt,
      pushError: clearPushError ? null : pushError ?? this.pushError,
      recipientUserId:
      clearRecipientUserId ? null : recipientUserId ?? this.recipientUserId,
      extra: extra ?? this.extra,
    );
  }

  Map<String, dynamic> toMap() {
    final cleanExtra = sanitizeExtra(extra);

    final resolvedChannels = <NotificationChannel>{
      ...channels,
      if (persistInFirebase) NotificationChannel.bell,
      if (sendPush) NotificationChannel.push,
      if (sendEmail) NotificationChannel.email,
      if (sendSms) NotificationChannel.sms,
    };

    final map = <String, dynamic>{
      'title': title.trim(),
      'status': status.name,
      'type': status.name,
      'channels': resolvedChannels.map((item) => item.value).toList(),
      'backgroundColor': backgroundColor.toARGB32(),
      'durationMilliseconds': duration.inMilliseconds,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'seen': seen,
      'sendPush': resolvedChannels.contains(NotificationChannel.push),
      'sendEmail': resolvedChannels.contains(NotificationChannel.email),
      'sendSms': resolvedChannels.contains(NotificationChannel.sms),
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
    addIfNotEmpty('recipientUserId', recipientUserId);

    if (accentColor != null) {
      map['accentColor'] = accentColor!.toARGB32();
    }

    if (pushSentAt != null) {
      map['pushSentAt'] = Timestamp.fromDate(pushSentAt!);
    }

    addIfNotEmpty('route', cleanExtra['route']?.toString());
    addIfNotEmpty('module', cleanExtra['module']?.toString());
    addIfNotEmpty('action', cleanExtra['action']?.toString());
    addIfNotEmpty('source', cleanExtra['source']?.toString());
    addIfNotEmpty('notificationSource', cleanExtra['notificationSource']?.toString());

    addIfNotEmpty('contractId', cleanExtra['contractId']?.toString());
    addIfNotEmpty('contractNumber', cleanExtra['contractNumber']?.toString());
    addIfNotEmpty('contractSummary', cleanExtra['contractSummary']?.toString());
    addIfNotEmpty('contractTitle', cleanExtra['contractTitle']?.toString());

    addIfNotEmpty('processId', cleanExtra['processId']?.toString());
    addIfNotEmpty('processNumber', cleanExtra['processNumber']?.toString());

    addIfNotEmpty('actorId', cleanExtra['actorId']?.toString());
    addIfNotEmpty('actorName', cleanExtra['actorName']?.toString());
    addIfNotEmpty('actorPhotoUrl', cleanExtra['actorPhotoUrl']?.toString());
    addIfNotEmpty('photoUrl', cleanExtra['photoUrl']?.toString());
    addIfNotEmpty('photoURL', cleanExtra['photoURL']?.toString());
    addIfNotEmpty('profilePhotoUrl', cleanExtra['profilePhotoUrl']?.toString());
    addIfNotEmpty('urlPhoto', cleanExtra['urlPhoto']?.toString());

    final targetUserIds = cleanExtra['targetUserIds'];

    if (targetUserIds is Iterable) {
      final cleanTargets = targetUserIds
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList();

      if (cleanTargets.isNotEmpty) {
        map['targetUserIds'] = cleanTargets;
      }
    }

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

    final rawChannels = map['channels'];
    final parsedChannels = <NotificationChannel>{};

    if (rawChannels is Iterable) {
      for (final item in rawChannels) {
        final channel = NotificationChannelExtension.tryFromString(
          item?.toString(),
        );

        if (channel != null) {
          parsedChannels.add(channel);
        }
      }
    }

    if (map['sendPush'] == true) {
      parsedChannels.add(NotificationChannel.push);
    }

    if (map['sendEmail'] == true) {
      parsedChannels.add(NotificationChannel.email);
    }

    if (map['sendSms'] == true) {
      parsedChannels.add(NotificationChannel.sms);
    }

    final resolvedStatus = NotificationStatusExtension.fromString(
      map['status']?.toString() ?? map['type']?.toString(),
    );

    return NotificationData(
      id: id ?? map['id']?.toString(),
      title: map['title']?.toString() ?? '',
      subtitle: map['subtitle']?.toString(),
      details: map['details']?.toString(),
      leadingLabel: map['leadingLabel']?.toString(),
      status: resolvedStatus,
      type: resolvedStatus,
      channels: parsedChannels,
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
      sendEmail: map['sendEmail'] == true,
      sendSms: map['sendSms'] == true,
      pushSent: map['pushSent'] == true,
      pushSentAt: resolvedPushSentAt,
      pushError: map['pushError']?.toString(),
      recipientUserId: map['recipientUserId']?.toString(),
      extra: _mergedExtraFromMap(map),
    );
  }

  factory NotificationData.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    return NotificationData.fromMap(
      doc.data() ?? const <String, dynamic>{},
      id: doc.id,
    );
  }

  static Map<String, dynamic> _mergedExtraFromMap(Map<String, dynamic> map) {
    final rootExtra = _extraFromRootMap(map);

    final nestedExtra = map['extra'] is Map
        ? sanitizeExtra(
      Map<String, dynamic>.from(map['extra'] as Map),
    )
        : const <String, dynamic>{};

    return sanitizeExtra(<String, dynamic>{
      ...rootExtra,
      ...nestedExtra,
    });
  }

  static Map<String, dynamic> _extraFromRootMap(Map<String, dynamic> map) {
    final extra = <String, dynamic>{};

    void addIfExists(String key) {
      final value = map[key];

      if (value == null) return;

      if (value is String && value.trim().isEmpty) return;

      extra[key] = value;
    }

    addIfExists('route');
    addIfExists('module');
    addIfExists('action');
    addIfExists('source');
    addIfExists('sourceKey');
    addIfExists('subSource');
    addIfExists('notificationSource');

    addIfExists('contractId');
    addIfExists('contractNumber');
    addIfExists('contractSummary');
    addIfExists('contractTitle');
    addIfExists('summarySubjectContract');
    addIfExists('descricaoObjeto');
    addIfExists('nomeDemanda');
    addIfExists('demandaNome');
    addIfExists('demandName');

    addIfExists('processId');
    addIfExists('processNumber');
    addIfExists('processSummary');
    addIfExists('processoAdministrativo');

    addIfExists('actorId');
    addIfExists('actorName');
    addIfExists('actorPhotoUrl');
    addIfExists('photoUrl');
    addIfExists('photoURL');
    addIfExists('profilePhotoUrl');
    addIfExists('urlPhoto');
    addIfExists('avatarUrl');
    addIfExists('imageUrl');

    addIfExists('measurementId');
    addIfExists('measurementNumber');
    addIfExists('measurementOrder');
    addIfExists('measurementDate');
    addIfExists('measurementValue');

    addIfExists('targetUserIds');

    return sanitizeExtra(extra);
  }

  static Map<String, dynamic> sanitizeExtra(Map<String, dynamic> value) {
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

      if (item is Timestamp) {
        result[cleanKey] = item.toDate().toIso8601String();
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
        final nested = sanitizeExtra(
          item.map(
                (nestedKey, nestedValue) {
              return MapEntry(nestedKey.toString(), nestedValue);
            },
          ),
        );

        if (nested.isNotEmpty) {
          result[cleanKey] = nested;
        }

        return;
      }

      final stringValue = item.toString().trim();

      if (stringValue.isNotEmpty) {
        result[cleanKey] = stringValue;
      }
    });

    return result;
  }
}