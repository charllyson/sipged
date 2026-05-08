// lib/_blocs/system/notification/helpers/notification_additive.dart

import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/system/notification/helpers/notification_contract_base.dart';
import 'package:sipged/_blocs/system/notification/notification_channel.dart';
import 'package:sipged/_blocs/system/notification/notification_delivery.dart';
import 'package:sipged/_blocs/system/notification/notification_source.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';

class NotificationAdditive {
  const NotificationAdditive._();

  static const String defaultSource = 'additive_notification';
  static const String defaultModule = 'contracts_additives';
  static const String defaultLabel = 'Aditivo';

  static Future<void> show({
    required BuildContext context,
    required ContractData contract,
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
    /// additive_notification
    String? source,

    /// Suborigem para preferências/canais.
    String? sourceKey,

    /// Alias mais explícito usado pelas páginas novas.
    ///
    /// Quando informado, tem prioridade sobre sourceKey.
    String? notificationSource,

    String? additiveId,
    String? additiveNumber,
    String? additiveOrder,
    String? additiveType,
    DateTime? additiveDate,
    num? additiveValue,
    int? additiveValidityExecutionDays,
    int? additiveValidityContractDays,

    Map<String, dynamic> extra = const <String, dynamic>{},
  }) async {
    final resolvedSource = source?.trim().isNotEmpty == true
        ? source!.trim()
        : defaultSource;

    final resolvedSourceKey = notificationSource?.trim().isNotEmpty == true
        ? notificationSource!.trim()
        : sourceKey?.trim().isNotEmpty == true
        ? sourceKey!.trim()
        : NotificationSubSource.additivesGeneral.key;

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

        /// Dados do aditivo.
        'additiveId': additiveId,
        'additiveNumber': additiveNumber,
        'additiveOrder': additiveOrder,
        'additiveType': additiveType,
        'additiveDate': additiveDate?.toIso8601String(),
        'additiveValue': additiveValue,
        'additiveValidityExecutionDays': additiveValidityExecutionDays,
        'additiveValidityContractDays': additiveValidityContractDays,
      },
    );
  }
}