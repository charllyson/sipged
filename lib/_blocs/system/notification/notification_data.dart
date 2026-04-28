import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';

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
  /// Importante:
  /// Não reconstruir IconData dinamicamente a partir do Firestore,
  /// pois isso quebra o build Web release com tree-shake-icons ativo.
  final IconData? icon;

  final Duration duration;

  final DateTime? createdAt;
  final String? createdBy;
  final bool seen;

  /// Quando true, o Cubit salva a notificação no Firestore.
  final bool persistInFirebase;

  /// Campo livre para salvar origem, módulo, contractId, processId etc.
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
      extra: extra ?? this.extra,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'details': details,
      'leadingLabel': leadingLabel,
      'type': type.name,
      'accentColor': accentColor?.toARGB32(),
      'backgroundColor': backgroundColor.toARGB32(),

      /// Não salvar iconCodePoint/iconFontFamily/iconFontPackage.
      /// O ícone deve ser resolvido pelo NotificationType.
      'durationMilliseconds': duration.inMilliseconds,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'createdBy': createdBy,
      'seen': seen,
      'extra': extra,
    };
  }

  factory NotificationData.fromMap(
      Map<String, dynamic> map, {
        String? id,
      }) {
    final createdAtRaw = map['createdAt'];

    DateTime? resolvedCreatedAt;

    if (createdAtRaw is Timestamp) {
      resolvedCreatedAt = createdAtRaw.toDate();
    } else if (createdAtRaw is DateTime) {
      resolvedCreatedAt = createdAtRaw;
    } else if (createdAtRaw is String) {
      resolvedCreatedAt = DateTime.tryParse(createdAtRaw);
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
      backgroundColor: backgroundValue is int
          ? Color(backgroundValue)
          : Colors.white,

      /// Sempre usa o ícone padrão do tipo.
      /// Evita IconData(...) dinâmico no Web release.
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
}