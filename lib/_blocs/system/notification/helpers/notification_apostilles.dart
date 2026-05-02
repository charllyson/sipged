// lib/_blocs/system/notification/helpers/notification_apostilles.dart

import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_blocs/system/notification/helpers/notification_contract_base.dart';
import 'package:sipged/_blocs/system/notification/notification_channel.dart';
import 'package:sipged/_blocs/system/notification/notification_delivery.dart';
import 'package:sipged/_blocs/system/notification/notification_source.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';

class NotificationApostilles {
  const NotificationApostilles._();

  static const String defaultSource = 'apostille_notification';
  static const String defaultModule = 'contracts_apostilles';
  static const String defaultLabel = 'Apostilamento';

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

    /// Origem principal.
    ///
    /// Exemplo:
    /// apostille_notification
    String? source,

    /// Suborigem para preferências/canais.
    String? sourceKey,

    /// Alias mais explícito usado pelas páginas novas.
    ///
    /// Quando informado, tem prioridade sobre sourceKey.
    String? notificationSource,

    String? apostilleId,
    String? apostilleNumber,
    String? apostilleOrder,
    String? apostilleType,
    DateTime? apostilleDate,
    num? apostilleValue,

    Map<String, dynamic> extra = const <String, dynamic>{},
  }) async {
    final resolvedSource = source?.trim().isNotEmpty == true
        ? source!.trim()
        : defaultSource;

    final resolvedSourceKey = notificationSource?.trim().isNotEmpty == true
        ? notificationSource!.trim()
        : sourceKey?.trim().isNotEmpty == true
        ? sourceKey!.trim()
        : NotificationSubSource.apostillesGeneral.key;

    final resolvedModule = module?.trim().isNotEmpty == true
        ? module!.trim()
        : defaultModule;

    final resolvedLeadingLabel = leadingLabel?.trim().isNotEmpty == true
        ? leadingLabel!.trim()
        : defaultLabel;

    await NotificationContractBase.show(
      context: context,
      contract: contract,
      title: title,
      subtitle: subtitle,
      details: details,
      leadingLabel: resolvedLeadingLabel,
      module: resolvedModule,
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
      source: resolvedSource,
      sourceKey: resolvedSourceKey,
      defaultModule: defaultModule,
      defaultLeadingLabel: defaultLabel,
      extra: <String, dynamic>{
        ...extra,

        /// Identificação da origem.
        'source': resolvedSource,
        'sourceKey': resolvedSourceKey,
        'subSource': resolvedSourceKey,
        'notificationSource': resolvedSourceKey,
        'module': resolvedModule,

        /// Dados do apostilamento.
        'apostilleId': apostilleId,
        'apostilleNumber': apostilleNumber,
        'apostilleOrder': apostilleOrder,
        'apostilleType': apostilleType,
        'apostilleDate': apostilleDate?.toIso8601String(),
        'apostilleValue': apostilleValue,
      },
    );
  }
}