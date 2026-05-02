// lib/_blocs/system/notification/preferences/notification_preference_data.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'package:sipged/_blocs/system/notification/notification_channel.dart';
import 'package:sipged/_blocs/system/notification/notification_source.dart';

class NotificationPreferenceData extends Equatable {
  const NotificationPreferenceData({
    required this.sourceKey,
    this.source,
    this.subSource,
    this.enabled = true,
    this.channels = const <NotificationChannel, bool>{},
    this.createdAt,
    this.updatedAt,
  });

  /// Chave principal usada nas preferências.
  ///
  /// Agora deve ser preferencialmente uma NotificationSubSource.key:
  /// - contracts_hiring_dfd
  /// - measurements_bulletin
  /// - schedule_general
  /// - additives_general
  final String sourceKey;

  /// Fonte macro, apenas para agrupamento visual.
  final NotificationSource? source;

  /// Subfonte granular usada de fato para salvar/consultar preferência.
  final NotificationSubSource? subSource;

  final bool enabled;
  final Map<NotificationChannel, bool> channels;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory NotificationPreferenceData.defaultForSubSource(
      NotificationSubSource subSource,
      ) {
    return NotificationPreferenceData(
      sourceKey: subSource.key,
      source: subSource.source,
      subSource: subSource,
      enabled: true,
      channels: <NotificationChannel, bool>{
        for (final channel in NotificationChannel.values)
          channel: channel.enabledByDefault,
      },
    );
  }

  /// Compatibilidade temporária.
  ///
  /// Usa a primeira subfonte da fonte macro.
  factory NotificationPreferenceData.defaultForSource(
      NotificationSource source,
      ) {
    final subSources = source.subSources;

    if (subSources.isEmpty) {
      return NotificationPreferenceData(
        sourceKey: source.key,
        source: source,
        enabled: true,
        channels: <NotificationChannel, bool>{
          for (final channel in NotificationChannel.values)
            channel: channel.enabledByDefault,
        },
      );
    }

    return NotificationPreferenceData.defaultForSubSource(subSources.first);
  }

  bool isChannelEnabled(NotificationChannel channel) {
    if (!enabled) return false;

    return channels[channel] ?? channel.enabledByDefault;
  }

  Set<NotificationChannel> filterChannels(
      Iterable<NotificationChannel> requestedChannels,
      ) {
    if (!enabled) return <NotificationChannel>{};

    return requestedChannels.where(isChannelEnabled).toSet();
  }

  NotificationPreferenceData copyWith({
    String? sourceKey,
    NotificationSource? source,
    NotificationSubSource? subSource,
    bool? enabled,
    Map<NotificationChannel, bool>? channels,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearSource = false,
    bool clearSubSource = false,
    bool clearCreatedAt = false,
    bool clearUpdatedAt = false,
  }) {
    return NotificationPreferenceData(
      sourceKey: sourceKey ?? this.sourceKey,
      source: clearSource ? null : source ?? this.source,
      subSource: clearSubSource ? null : subSource ?? this.subSource,
      enabled: enabled ?? this.enabled,
      channels: channels ?? this.channels,
      createdAt: clearCreatedAt ? null : createdAt ?? this.createdAt,
      updatedAt: clearUpdatedAt ? null : updatedAt ?? this.updatedAt,
    );
  }

  NotificationPreferenceData toggleChannel({
    required NotificationChannel channel,
    required bool value,
  }) {
    return copyWith(
      channels: <NotificationChannel, bool>{
        ...channels,
        channel: value,
      },
    );
  }

  Map<String, dynamic> toMap() {
    final cleanSourceKey = sourceKey.trim();

    final resolvedSubSource =
        subSource ?? NotificationSourceRegistry.tryResolveSubSource(cleanSourceKey);

    final resolvedSource = source ?? resolvedSubSource?.source;

    return <String, dynamic>{
      'sourceKey': cleanSourceKey,
      'source': resolvedSource?.key,
      'subSource': resolvedSubSource?.key ?? cleanSourceKey,
      'enabled': enabled,
      'channels': channels.map(
            (channel, value) {
          return MapEntry(channel.key, value);
        },
      ),
      'updatedAt': FieldValue.serverTimestamp(),
      if (createdAt == null) 'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory NotificationPreferenceData.fromMap(
      Map<String, dynamic> map, {
        required String sourceKey,
      }) {
    final cleanSourceKey = _clean(
      map['subSource']?.toString(),
    ) ??
        _clean(
          map['sourceKey']?.toString(),
        ) ??
        sourceKey.trim();

    final resolvedSubSource =
    NotificationSourceRegistry.tryResolveSubSource(cleanSourceKey);

    final resolvedSource = resolvedSubSource?.source ??
        NotificationSourceRegistry.resolveSource(
          map['source']?.toString(),
        );

    final fallback = resolvedSubSource != null
        ? NotificationPreferenceData.defaultForSubSource(resolvedSubSource)
        : NotificationPreferenceData.defaultForSource(resolvedSource);

    final rawChannels = map['channels'];
    final parsedChannels = <NotificationChannel, bool>{};

    if (rawChannels is Map) {
      rawChannels.forEach((key, value) {
        final channel = NotificationChannelExtension.tryFromString(
          key.toString(),
        );

        if (channel != null) {
          parsedChannels[channel] = value == true;
        }
      });
    }

    return NotificationPreferenceData(
      sourceKey: cleanSourceKey,
      source: resolvedSource,
      subSource: resolvedSubSource,
      enabled: map['enabled'] != false,
      channels: <NotificationChannel, bool>{
        ...fallback.channels,
        ...parsedChannels,
      },
      createdAt: _dateFromValue(map['createdAt']),
      updatedAt: _dateFromValue(map['updatedAt']),
    );
  }

  static DateTime? _dateFromValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);

    return null;
  }

  static String? _clean(String? value) {
    final cleanValue = value?.trim();

    if (cleanValue == null || cleanValue.isEmpty) {
      return null;
    }

    return cleanValue;
  }

  @override
  List<Object?> get props => [
    sourceKey,
    source,
    subSource,
    enabled,
    channels,
    createdAt,
    updatedAt,
  ];
}