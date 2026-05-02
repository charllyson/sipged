// lib/_blocs/system/notification/helpers/notification_additive.dart

import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_blocs/system/notification/helpers/notification_contract_base.dart';
import 'package:sipged/_blocs/system/notification/notification_channel.dart';
import 'package:sipged/_blocs/system/notification/notification_delivery.dart';
import 'package:sipged/_blocs/system/notification/notification_source.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';

class NotificationAdditive {
  const NotificationAdditive._();

  static Future<void> show({
    required BuildContext context,
    required ProcessData contract,
    required String title,
    String? subtitle,
    String? details,
    String? leadingLabel,
    String? module,

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

    String? additiveId,
    String? additiveNumber,
    String? additiveOrder,
    String? additiveType,
    DateTime? additiveDate,

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
      source: 'additive_notification',
      sourceKey: NotificationSubSource.additivesGeneral.key,
      defaultModule: 'operation_additives',
      defaultLeadingLabel: 'Aditivo',
      extra: <String, dynamic>{
        ...extra,
        'additiveId': additiveId,
        'additiveNumber': additiveNumber,
        'additiveOrder': additiveOrder,
        'additiveType': additiveType,
        'additiveDate': additiveDate?.toIso8601String(),
      },
    );
  }
}