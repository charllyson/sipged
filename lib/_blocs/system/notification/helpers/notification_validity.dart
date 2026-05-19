// lib/_blocs/system/notification/helpers/notification_validity.dart

import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/system/notification/helpers/notification_contract_base.dart';
import 'package:sipged/_blocs/system/notification/helpers/notification_source.dart';
import 'package:sipged/_blocs/system/notification/notification_channel.dart';
import 'package:sipged/_blocs/system/notification/notification_delivery.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';

class NotificationValidity {
  const NotificationValidity._();

  static const String defaultSource = 'validity_notification';
  static const String defaultModule = 'contracts_validity';
  static const String defaultLabel = 'Vigência';

  static Future<void> show({
    required BuildContext context,
    required ContractData contract,
    required String title,
    String? subtitle,
    String? details,
    String? leadingLabel,
    String? module,
    NotificationStatus status = NotificationStatus.info,
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
    String? source,
    String? sourceKey,
    String? notificationSource,

    // Contexto multi-tenant / contrato.
    String? tenantId,
    String? companyId,
    String? contractId,
    String? contractNumber,
    String? contractTitle,
    String? contractSummary,
    String? processNumber,
    String? processoAdministrativo,
    String? descricaoObjeto,
    String? nomeDemanda,
    String? action,

    // Dados específicos da vigência.
    String? validityId,
    String? validityOrder,
    String? validityType,
    DateTime? validityStartDate,
    DateTime? validityEndDate,
    int? contractValidityDays,
    int? executionValidityDays,

    // Dados de anexos.
    String? attachmentLabel,
    String? attachmentUrl,
    String? oldAttachmentLabel,
    String? newAttachmentLabel,

    Map<String, dynamic> extra = const <String, dynamic>{},
  }) async {
    final resolvedStatus = type ?? status;

    final resolvedSource = _firstNotEmpty(
      <String?>[
        source,
        defaultSource,
      ],
    );

    final resolvedSourceKey = _resolveSourceKey(
      sourceKey: sourceKey,
      notificationSource: notificationSource,
    );

    final resolvedModule = _firstNotEmpty(
      <String?>[
        module,
        defaultModule,
      ],
    );

    final resolvedLeadingLabel = _firstNotEmpty(
      <String?>[
        leadingLabel,
        defaultLabel,
      ],
    );

    final resolvedContractId = _firstNotEmpty(
      <String?>[
        contractId,
        contract.id,
      ],
    );

    final resolvedContractNumber = _firstNotEmpty(
      <String?>[
        contractNumber,
        processNumber,
        processoAdministrativo,
        contract.displayNumber,
        resolvedContractId,
      ],
    );

    final resolvedContractSummary = _firstNotEmpty(
      <String?>[
        contractSummary,
        contractTitle,
        descricaoObjeto,
        nomeDemanda,
        contract.displaySummary,
        resolvedContractId.isNotEmpty ? 'Contrato $resolvedContractId' : null,
      ],
    );

    final resolvedProcessNumber = _firstNotEmpty(
      <String?>[
        processNumber,
        processoAdministrativo,
        resolvedContractNumber,
      ],
    );

    final resolvedTenantId = _clean(tenantId);
    final resolvedCompanyId = _firstNotEmpty(
      <String?>[
        companyId,
        tenantId,
      ],
    );

    await NotificationContractBase.show(
      context: context,
      contract: contract,
      title: title,
      subtitle: subtitle,
      details: details ?? resolvedContractSummary,
      leadingLabel: resolvedLeadingLabel,
      module: resolvedModule,
      status: resolvedStatus,
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

        // Contexto de rota/origem.
        'route': resolvedModule,
        'module': resolvedModule,
        'source': resolvedSource,
        'sourceKey': resolvedSourceKey,
        'subSource': resolvedSourceKey,
        'notificationSource': resolvedSourceKey,

        // Contexto multi-tenant.
        if (resolvedTenantId.isNotEmpty) 'tenantId': resolvedTenantId,
        if (resolvedCompanyId.isNotEmpty) 'companyId': resolvedCompanyId,

        // Contexto do contrato.
        if (resolvedContractId.isNotEmpty) 'contractId': resolvedContractId,
        if (resolvedContractNumber.isNotEmpty)
          'contractNumber': resolvedContractNumber,
        if (resolvedProcessNumber.isNotEmpty)
          'processNumber': resolvedProcessNumber,
        if (_clean(processoAdministrativo).isNotEmpty)
          'processoAdministrativo': _clean(processoAdministrativo),
        if (resolvedContractSummary.isNotEmpty)
          'contractTitle': resolvedContractSummary,
        if (resolvedContractSummary.isNotEmpty)
          'contractSummary': resolvedContractSummary,
        if (_clean(descricaoObjeto).isNotEmpty)
          'descricaoObjeto': _clean(descricaoObjeto),
        if (_clean(nomeDemanda).isNotEmpty) 'nomeDemanda': _clean(nomeDemanda),

        // Ação.
        if (_clean(action).isNotEmpty) 'action': _clean(action),

        // Dados da vigência.
        if (_clean(validityId).isNotEmpty) 'validityId': _clean(validityId),
        if (_clean(validityOrder).isNotEmpty)
          'validityOrder': _clean(validityOrder),
        if (_clean(validityType).isNotEmpty)
          'validityType': _clean(validityType),
        if (validityStartDate != null)
          'validityStartDate': validityStartDate.toIso8601String(),
        if (validityEndDate != null)
          'validityEndDate': validityEndDate.toIso8601String(),
        'contractValidityDays': ?contractValidityDays,
        'executionValidityDays': ?executionValidityDays,

        // Dados de anexo.
        if (_clean(attachmentLabel).isNotEmpty)
          'attachmentLabel': _clean(attachmentLabel),
        if (_clean(attachmentUrl).isNotEmpty)
          'attachmentUrl': _clean(attachmentUrl),
        if (_clean(oldAttachmentLabel).isNotEmpty)
          'oldAttachmentLabel': _clean(oldAttachmentLabel),
        if (_clean(newAttachmentLabel).isNotEmpty)
          'newAttachmentLabel': _clean(newAttachmentLabel),
      }..removeWhere((key, value) => value == null),
    );
  }

  static String _resolveSourceKey({
    String? sourceKey,
    String? notificationSource,
  }) {
    final raw = _firstNotEmpty(
      <String?>[
        notificationSource,
        sourceKey,
      ],
    );

    final clean = raw.trim();

    if (clean.isEmpty) {
      return NotificationSubSource.validityGeneral.key;
    }

    switch (clean) {
      case 'validity':
      case 'validities':
      case 'validade':
      case 'vigencia':
      case 'vigência':
      case 'contracts_validity':
      case 'validity_notification':
        return NotificationSubSource.validityGeneral.key;

      default:
        return clean;
    }
  }

  static String _firstNotEmpty(Iterable<String?> values) {
    for (final value in values) {
      final clean = _clean(value);

      if (clean.isNotEmpty) {
        return clean;
      }
    }

    return '';
  }

  static String _clean(String? value) {
    return (value ?? '').trim();
  }
}