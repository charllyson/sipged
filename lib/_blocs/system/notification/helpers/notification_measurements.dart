// lib/_blocs/system/notification/helpers/notification_measurements.dart

import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_blocs/system/notification/helpers/notification_contract_base.dart';
import 'package:sipged/_blocs/system/notification/notification_channel.dart';
import 'package:sipged/_blocs/system/notification/notification_delivery.dart';
import 'package:sipged/_blocs/system/notification/notification_source.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';

enum NotificationMeasurementKind {
  bulletin,
  adjustment,
  revision,
}

extension NotificationMeasurementKindExtension on NotificationMeasurementKind {
  String get sourceKey {
    switch (this) {
      case NotificationMeasurementKind.bulletin:
        return NotificationSubSource.measurementsBulletin.key;
      case NotificationMeasurementKind.adjustment:
        return NotificationSubSource.measurementsAdjustments.key;
      case NotificationMeasurementKind.revision:
        return NotificationSubSource.measurementsRevision.key;
    }
  }

  String get label {
    switch (this) {
      case NotificationMeasurementKind.bulletin:
        return 'Medição';
      case NotificationMeasurementKind.adjustment:
        return 'Reajuste';
      case NotificationMeasurementKind.revision:
        return 'Revisão';
    }
  }

  String get module {
    switch (this) {
      case NotificationMeasurementKind.bulletin:
        return 'operation_measurements';
      case NotificationMeasurementKind.adjustment:
        return 'operation_measurements_adjustments';
      case NotificationMeasurementKind.revision:
        return 'operation_measurements_revisions';
    }
  }
}

class NotificationMeasurements {
  const NotificationMeasurements._();

  static Future<void> show({
    required BuildContext context,
    required ProcessData contract,
    required String title,
    String? subtitle,
    String? details,
    String? leadingLabel,
    String? module,

    NotificationMeasurementKind kind = NotificationMeasurementKind.bulletin,

    NotificationStatus status = NotificationStatus.info,

    /// Compatibilidade temporária.
    NotificationStatus? type,

    Duration duration = const Duration(seconds: 5),

    bool saveInBell = false,
    bool sendPush = false,

    NotificationDelivery? delivery,
    Set<NotificationChannel>? channels,

    String? actorId,
    String? actorName,
    Iterable<String> targetUserIds = const <String>[],
    bool includeCurrentUser = true,
    bool global = false,

    String? measurementId,
    String? measurementNumber,
    String? measurementOrder,
    DateTime? measurementDate,
    num? measurementValue,
    num? adjustmentValue,
    num? revisionValue,

    Map<String, dynamic> extra = const <String, dynamic>{},
  }) async {
    await NotificationContractBase.show(
      context: context,
      contract: contract,
      title: title,
      subtitle: subtitle,
      details: details,
      leadingLabel: leadingLabel,
      module: module,
      status: status,
      type: type,
      duration: duration,
      saveInBell: saveInBell,
      sendPush: sendPush,
      delivery: delivery,
      channels: channels,
      actorId: actorId,
      actorName: actorName,
      targetUserIds: targetUserIds,
      includeCurrentUser: includeCurrentUser,
      global: global,
      source: 'measurement_notification',
      sourceKey: kind.sourceKey,
      defaultModule: kind.module,
      defaultLeadingLabel: kind.label,
      extra: <String, dynamic>{
        ...extra,
        'measurementKind': kind.name,
        'measurementId': measurementId,
        'measurementNumber': measurementNumber,
        'measurementOrder': measurementOrder,
        'measurementDate': measurementDate?.toIso8601String(),
        'measurementValue': measurementValue,
        'adjustmentValue': adjustmentValue,
        'revisionValue': revisionValue,
      },
    );
  }
}