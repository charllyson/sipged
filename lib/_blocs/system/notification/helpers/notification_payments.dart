// lib/_blocs/system/notification/helpers/notification_payments.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/system/notification/helpers/notification_contract_base.dart';
import 'package:sipged/_blocs/system/notification/helpers/notification_source.dart';
import 'package:sipged/_blocs/system/notification/notification_channel.dart';
import 'package:sipged/_blocs/system/notification/notification_delivery.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';

enum NotificationPaymentKind {
  bulletin,
  adjustment,
  revision,
}

extension NotificationPaymentKindExtension on NotificationPaymentKind {
  String get sourceKey {
    switch (this) {
      case NotificationPaymentKind.bulletin:
        return NotificationSubSource.paymentsBulletin.key;
      case NotificationPaymentKind.adjustment:
        return NotificationSubSource.paymentsAdjustments.key;
      case NotificationPaymentKind.revision:
        return NotificationSubSource.paymentsRevision.key;
    }
  }

  String get label {
    switch (this) {
      case NotificationPaymentKind.bulletin:
        return 'Pagamento';
      case NotificationPaymentKind.adjustment:
        return 'Pagamento de reajuste';
      case NotificationPaymentKind.revision:
        return 'Pagamento de revisão';
    }
  }

  String get module {
    switch (this) {
      case NotificationPaymentKind.bulletin:
        return 'financial_payments_report';
      case NotificationPaymentKind.adjustment:
        return 'financial_payments_adjustments';
      case NotificationPaymentKind.revision:
        return 'financial_payments_revisions';
    }
  }

  String get defaultSource {
    switch (this) {
      case NotificationPaymentKind.bulletin:
        return 'payment_notification';
      case NotificationPaymentKind.adjustment:
        return 'adjustment_payment_notification';
      case NotificationPaymentKind.revision:
        return 'revision_payment_notification';
    }
  }

  String get value {
    switch (this) {
      case NotificationPaymentKind.bulletin:
        return 'bulletin_payment';
      case NotificationPaymentKind.adjustment:
        return 'adjustment_payment';
      case NotificationPaymentKind.revision:
        return 'revision_payment';
    }
  }
}

class NotificationPayments {
  const NotificationPayments._();

  static Future<void> show({
    required BuildContext context,
    required ContractData contract,
    required String title,
    String? subtitle,
    String? details,
    NotificationPaymentKind kind = NotificationPaymentKind.bulletin,
    NotificationStatus status = NotificationStatus.info,
    NotificationStatus? type,
    Duration duration = const Duration(seconds: 5),
    bool saveInBell = false,
    bool sendPush = false,
    NotificationDelivery? delivery,
    Set<NotificationChannel>? channels,
    String? actorId,
    String? actorName,
    String? actorPhotoUrl,
    Iterable<String> targetUserIds = const <String>[],
    bool includeCurrentUser = false,
    bool global = false,
    String? leadingLabel,
    String? module,
    String? source,
    String? sourceKey,
    String? notificationSource,
    String? tenantId,
    String? companyId,

    // Compatibilidade de assinatura.
    String? contractId,
    String? paymentId,
    String? paymentMeasurementId,
    String? measurementId,
    String? adjustmentId,
    String? revisionId,

    String? contractNumber,
    String? contractTitle,
    String? contractSummary,
    String? processNumber,
    String? processoAdministrativo,
    String? descricaoObjeto,
    String? nomeDemanda,
    String? action,

    String? paymentNumber,
    String? paymentOrder,
    DateTime? paymentDate,
    num? paymentValue,
    num? paymentMainValue,
    num? paymentRetentionsValue,
    num? paymentTotalValue,

    String? paymentMeasurementNumber,
    String? paymentMeasurementOrder,
    DateTime? paymentMeasurementDate,
    num? paymentMeasurementValue,

    String? measurementNumber,
    String? measurementOrder,
    DateTime? measurementDate,
    num? measurementValue,

    String? adjustmentNumber,
    String? adjustmentOrder,
    DateTime? adjustmentDate,
    num? adjustmentValue,

    String? revisionNumber,
    String? revisionOrder,
    DateTime? revisionDate,
    num? revisionValue,

    String? attachmentLabel,
    String? attachmentUrl,
    String? oldAttachmentLabel,
    String? newAttachmentLabel,
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) async {
    final resolvedStatus = type ?? status;

    final resolvedSource = _firstNotEmpty([
      source,
      kind.defaultSource,
    ]);

    final resolvedSourceKey = _resolveSourceKey(
      kind: kind,
      sourceKey: sourceKey,
      notificationSource: notificationSource,
    );

    final resolvedModule = _firstNotEmpty([
      module,
      kind.module,
    ]);

    final resolvedLeadingLabel = _firstNotEmpty([
      leadingLabel,
      kind.label,
    ]);

    final currentUser = FirebaseAuth.instance.currentUser;

    final resolvedActorId = _firstNotEmpty([
      actorId,
      currentUser?.uid,
    ]);

    final resolvedActorName = _firstNotEmpty([
      actorName,
      _resolveActorName(
        contract: contract,
        uid: resolvedActorId,
      ),
    ]);

    final resolvedActorPhotoUrl = _firstNotEmpty([
      actorPhotoUrl,
      _resolveActorPhotoUrl(
        contract: contract,
        uid: resolvedActorId,
      ),
    ]);

    final resolvedTenantId = _firstNotEmpty([
      tenantId,
      companyId,
      extra['tenantId']?.toString(),
      extra['companyId']?.toString(),
    ]);

    final safeContractSummary = _resolveSafeContractSummary(
      contract: contract,
      contractSummary: contractSummary,
      contractTitle: contractTitle,
      descricaoObjeto: descricaoObjeto,
      nomeDemanda: nomeDemanda,
      extra: extra,
    );

    final safeContractNumber = _resolveSafeContractNumber(
      contract: contract,
      contractNumber: contractNumber,
      processNumber: processNumber,
      processoAdministrativo: processoAdministrativo,
      extra: extra,
    );

    final resolvedSubtitle = _firstNotEmpty([
      subtitle,
      safeContractSummary,
    ]);

    final requestedChannels = <NotificationChannel>{
      ...?channels,
      if (saveInBell) NotificationChannel.bell,
      if (sendPush) NotificationChannel.push,
    };

    final resolvedDelivery = delivery ??
        (requestedChannels.isNotEmpty
            ? NotificationDelivery.fromChannels(
          <NotificationChannel>{
            NotificationChannel.local,
            ...requestedChannels,
          },
        )
            : NotificationDelivery.localOnly);

    final shouldIncludeCurrentUser = includeCurrentUser ||
        saveInBell ||
        sendPush ||
        resolvedDelivery.saveInBell ||
        resolvedDelivery.sendPush ||
        resolvedDelivery.sendEmail ||
        resolvedDelivery.sendSms;

    final resolvedTargetUserIds = _resolveTargetUserIds(
      contract: contract,
      explicitTargetUserIds: targetUserIds,
      currentUserId: resolvedActorId,
      includeCurrentUser: shouldIncludeCurrentUser,
    );

    final safePaymentNumber = _firstNotEmpty([
      paymentNumber,
      extra['paymentNumber']?.toString(),
      extra['paymentProcess']?.toString(),
    ]);

    final safePaymentOrder = _firstNotEmpty([
      paymentOrder,
      extra['paymentOrder']?.toString(),
    ]);

    final resolvedPaymentDate = paymentDate ??
        _parseDateTime(extra['paymentDate']) ??
        _parseDateTime(extra['date']);

    final resolvedPaymentValue = paymentValue ??
        paymentMainValue ??
        _parseNum(extra['paymentValue']) ??
        _parseNum(extra['paymentMainValue']);

    final resolvedPaymentRetentionsValue = paymentRetentionsValue ??
        _parseNum(extra['paymentRetentionsValue']) ??
        _parseNum(extra['paymentRetentionValue']) ??
        _parseNum(extra['totalRetencoes']);

    final resolvedPaymentTotalValue = paymentTotalValue ??
        _parseNum(extra['paymentTotalValue']) ??
        _parseNum(extra['totalPagamento']) ??
        ((resolvedPaymentValue ?? 0) + (resolvedPaymentRetentionsValue ?? 0));

    final safeMeasurementNumber = _firstNotEmpty([
      paymentMeasurementNumber,
      measurementNumber,
      adjustmentNumber,
      revisionNumber,
      extra['paymentMeasurementNumber']?.toString(),
      extra['measurementNumber']?.toString(),
      extra['adjustmentNumber']?.toString(),
      extra['revisionNumber']?.toString(),
      extra['measurementProcess']?.toString(),
      extra['adjustmentProcess']?.toString(),
      extra['revisionProcess']?.toString(),
    ]);

    final safeMeasurementOrder = _firstNotEmpty([
      paymentMeasurementOrder,
      measurementOrder,
      adjustmentOrder,
      revisionOrder,
      extra['paymentMeasurementOrder']?.toString(),
      extra['measurementOrder']?.toString(),
      extra['adjustmentOrder']?.toString(),
      extra['revisionOrder']?.toString(),
    ]);

    final resolvedMeasurementDate = paymentMeasurementDate ??
        measurementDate ??
        adjustmentDate ??
        revisionDate ??
        _parseDateTime(extra['paymentMeasurementDate']) ??
        _parseDateTime(extra['measurementDate']) ??
        _parseDateTime(extra['adjustmentDate']) ??
        _parseDateTime(extra['revisionDate']);

    final resolvedMeasurementValue = paymentMeasurementValue ??
        measurementValue ??
        adjustmentValue ??
        revisionValue ??
        _parseNum(extra['paymentMeasurementValue']) ??
        _parseNum(extra['measurementValue']) ??
        _parseNum(extra['adjustmentValue']) ??
        _parseNum(extra['revisionValue']);

    await NotificationContractBase.show(
      context: context,
      contract: contract,
      title: title,
      subtitle: resolvedSubtitle,
      details: details,
      leadingLabel: resolvedLeadingLabel,
      module: resolvedModule,
      status: resolvedStatus,
      duration: duration,
      saveInBell: resolvedDelivery.saveInBell,
      sendPush: resolvedDelivery.sendPush,
      delivery: resolvedDelivery,
      channels: resolvedDelivery.channels,
      actorId: resolvedActorId,
      actorName: resolvedActorName,
      targetUserIds: resolvedTargetUserIds,
      includeCurrentUser: shouldIncludeCurrentUser,
      global: global,
      source: resolvedSource,
      sourceKey: resolvedSourceKey,
      defaultModule: kind.module,
      defaultLeadingLabel: kind.label,
      extra: <String, dynamic>{
        ..._removeBlockedIds(extra),

        if (resolvedTenantId.isNotEmpty) 'tenantId': resolvedTenantId,
        if (resolvedTenantId.isNotEmpty) 'companyId': resolvedTenantId,

        'route': resolvedModule,
        'module': resolvedModule,
        'source': resolvedSource,
        'sourceKey': resolvedSourceKey,
        'subSource': resolvedSourceKey,
        'notificationSource': resolvedSourceKey,

        'actorId': resolvedActorId,
        'actorName': resolvedActorName,
        if (resolvedActorPhotoUrl.isNotEmpty)
          'actorPhotoUrl': resolvedActorPhotoUrl,
        if (resolvedActorPhotoUrl.isNotEmpty) 'photoUrl': resolvedActorPhotoUrl,

        'targetUserIds': resolvedTargetUserIds,

        if (safeContractNumber.isNotEmpty) 'contractNumber': safeContractNumber,
        if (safeContractNumber.isNotEmpty) 'processNumber': safeContractNumber,
        if (safeContractNumber.isNotEmpty)
          'processoAdministrativo': safeContractNumber,

        'summarySubjectContract': safeContractSummary,
        'contractTitle': safeContractSummary,
        'contractSummary': safeContractSummary,
        'descricaoObjeto': _firstNotEmpty([
          descricaoObjeto,
          extra['descricaoObjeto']?.toString(),
          safeContractSummary,
        ]),
        'nomeDemanda': _firstNotEmpty([
          nomeDemanda,
          extra['nomeDemanda']?.toString(),
          safeContractSummary,
        ]),

        if (_clean(action).isNotEmpty) 'action': _clean(action),

        'paymentKind': kind.name,
        'paymentKindValue': kind.value,
        'paymentKindLabel': kind.label,

        if (safePaymentNumber.isNotEmpty) 'paymentNumber': safePaymentNumber,
        if (safePaymentOrder.isNotEmpty) 'paymentOrder': safePaymentOrder,
        'paymentDate': resolvedPaymentDate?.toIso8601String(),
        'paymentValue': resolvedPaymentValue,
        'paymentMainValue': resolvedPaymentValue,
        'paymentRetentionsValue': resolvedPaymentRetentionsValue,
        'paymentTotalValue': resolvedPaymentTotalValue,

        if (safeMeasurementNumber.isNotEmpty)
          'paymentMeasurementNumber': safeMeasurementNumber,
        if (safeMeasurementOrder.isNotEmpty)
          'paymentMeasurementOrder': safeMeasurementOrder,
        'paymentMeasurementDate': resolvedMeasurementDate?.toIso8601String(),
        'paymentMeasurementValue': resolvedMeasurementValue,

        if (safeMeasurementNumber.isNotEmpty)
          'measurementNumber': safeMeasurementNumber,
        if (safeMeasurementOrder.isNotEmpty)
          'measurementOrder': safeMeasurementOrder,
        'measurementDate': resolvedMeasurementDate?.toIso8601String(),
        'measurementValue': resolvedMeasurementValue,

        if (kind == NotificationPaymentKind.adjustment) ...{
          if (safeMeasurementNumber.isNotEmpty)
            'adjustmentNumber': safeMeasurementNumber,
          if (safeMeasurementOrder.isNotEmpty)
            'adjustmentOrder': safeMeasurementOrder,
          'adjustmentDate':
          (adjustmentDate ?? resolvedMeasurementDate)?.toIso8601String(),
          'adjustmentValue': adjustmentValue ?? resolvedMeasurementValue,
        },

        if (kind == NotificationPaymentKind.revision) ...{
          if (safeMeasurementNumber.isNotEmpty)
            'revisionNumber': safeMeasurementNumber,
          if (safeMeasurementOrder.isNotEmpty)
            'revisionOrder': safeMeasurementOrder,
          'revisionDate':
          (revisionDate ?? resolvedMeasurementDate)?.toIso8601String(),
          'revisionValue': revisionValue ?? resolvedMeasurementValue,
        },

        if (_clean(attachmentLabel).isNotEmpty)
          'attachmentLabel': _clean(attachmentLabel),
        if (_clean(attachmentUrl).isNotEmpty)
          'attachmentUrl': _clean(attachmentUrl),
        if (_clean(oldAttachmentLabel).isNotEmpty)
          'oldAttachmentLabel': _clean(oldAttachmentLabel),
        if (_clean(newAttachmentLabel).isNotEmpty)
          'newAttachmentLabel': _clean(newAttachmentLabel),
      }..removeWhere((key, value) {
        if (value == null) return true;
        if (value is String && value.trim().isEmpty) return true;
        if (_isBlockedIdentifierKey(key)) return true;
        return false;
      }),
    );
  }

  static String _resolveSourceKey({
    required NotificationPaymentKind kind,
    String? sourceKey,
    String? notificationSource,
  }) {
    final clean = _firstNotEmpty([
      notificationSource,
      sourceKey,
    ]);

    if (clean.isEmpty) {
      return kind.sourceKey;
    }

    if (clean == NotificationSubSource.paymentsBulletin.key ||
        clean == NotificationSubSource.paymentsAdjustments.key ||
        clean == NotificationSubSource.paymentsRevision.key) {
      return clean;
    }

    return kind.sourceKey;
  }

  static String _resolveSafeContractSummary({
    required ContractData contract,
    String? contractSummary,
    String? contractTitle,
    String? descricaoObjeto,
    String? nomeDemanda,
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) {
    final summary = _firstNotEmpty([
      subtitleSafe(extra['summarySubjectContract']),
      descricaoObjeto,
      nomeDemanda,
      contractSummary,
      contractTitle,
      extra['descricaoObjeto']?.toString(),
      extra['nomeDemanda']?.toString(),
      extra['demandaNome']?.toString(),
      extra['demandName']?.toString(),
      extra['contractSummary']?.toString(),
      extra['contractTitle']?.toString(),
      contract.displaySummary,
    ]);

    if (summary.isNotEmpty && !_looksLikeIdOnly(summary)) {
      return summary;
    }

    return 'Obra vinculada';
  }

  static String subtitleSafe(dynamic value) {
    final text = value?.toString().trim() ?? '';

    if (text.isEmpty) return '';
    if (_looksLikeIdOnly(text)) return '';

    return text;
  }

  static String _resolveSafeContractNumber({
    required ContractData contract,
    String? contractNumber,
    String? processNumber,
    String? processoAdministrativo,
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) {
    final number = _firstNotEmpty([
      contractNumber,
      processNumber,
      processoAdministrativo,
      extra['contractNumber']?.toString(),
      extra['processNumber']?.toString(),
      extra['processoAdministrativo']?.toString(),
      contract.displayNumber,
    ]);

    if (number.isNotEmpty && !_looksLikeIdOnly(number)) {
      return number;
    }

    return '';
  }

  static bool _looksLikeIdOnly(String value) {
    final clean = value.trim();

    if (clean.isEmpty) return false;

    final withoutSeparators = clean.replaceAll(RegExp(r'[-_/.\s]'), '');

    if (withoutSeparators.length < 16) return false;

    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(withoutSeparators);
    final hasNumber = RegExp(r'[0-9]').hasMatch(withoutSeparators);

    return hasLetter && hasNumber;
  }

  static Map<String, dynamic> _removeBlockedIds(Map<String, dynamic> value) {
    final output = <String, dynamic>{};

    value.forEach((key, item) {
      final cleanKey = key.trim();

      if (cleanKey.isEmpty) return;
      if (_isBlockedIdentifierKey(cleanKey)) return;

      output[cleanKey] = item;
    });

    return output;
  }

  static bool _isBlockedIdentifierKey(String key) {
    final clean = key.trim();

    if (clean.isEmpty) return false;

    const allowedTechnicalKeys = <String>{
      'tenantId',
      'companyId',
      'actorId',
      'actorName',
      'actorPhotoUrl',
      'photoUrl',
      'recipientUserId',
      'targetUserIds',
    };

    if (allowedTechnicalKeys.contains(clean)) {
      return false;
    }

    const blockedKeys = <String>{
      'id',
      'uid',
      'userId',
      'contractId',
      'processId',
      'measurementId',
      'adjustmentId',
      'revisionId',
      'paymentId',
      'paymentMeasurementId',
      'paymentAdjustmentId',
      'paymentRevisionId',
      'validityId',
      'additiveId',
      'apostilleId',
      'fundingSourceId',
      'recordPath',
      'path',
      'documentId',
      'docId',
    };

    return blockedKeys.contains(clean);
  }

  static List<String> _resolveTargetUserIds({
    required ContractData contract,
    required Iterable<String> explicitTargetUserIds,
    required String currentUserId,
    required bool includeCurrentUser,
  }) {
    final ids = <String>{};
    final cleanCurrentUserId = currentUserId.trim();

    for (final item in explicitTargetUserIds) {
      final id = item.trim();

      if (id.isEmpty) continue;
      if (!includeCurrentUser && id == cleanCurrentUserId) continue;

      ids.add(id);
    }

    if (ids.isEmpty) {
      for (final uid in contract.participantIds) {
        final cleanUid = uid.trim();

        if (cleanUid.isEmpty) continue;
        if (!includeCurrentUser && cleanUid == cleanCurrentUserId) continue;
        if (!contract.participantIsActive(cleanUid)) continue;

        final perms = contract.permissionForUser(cleanUid);

        final canRead = perms['read'] == true ||
            perms['create'] == true ||
            perms['edit'] == true ||
            perms['delete'] == true ||
            perms['approve'] == true;

        if (!canRead) continue;

        ids.add(cleanUid);

        final meta = contract.participantInfoForUser(cleanUid);

        for (final candidate in <String?>[
          meta['uid']?.toString(),
          meta['userId']?.toString(),
          meta['id']?.toString(),
        ]) {
          final candidateId = candidate?.trim() ?? '';

          if (candidateId.isEmpty) continue;
          if (!includeCurrentUser && candidateId == cleanCurrentUserId) {
            continue;
          }

          ids.add(candidateId);
        }
      }
    }

    if (includeCurrentUser && cleanCurrentUserId.isNotEmpty) {
      ids.add(cleanCurrentUserId);
    }

    final list = ids.toList();

    list.sort(
          (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
    );

    return list;
  }

  static String _resolveActorName({
    required ContractData contract,
    required String uid,
  }) {
    final cleanUid = uid.trim();

    if (cleanUid.isNotEmpty) {
      final meta = contract.participantInfoForUser(cleanUid);

      if (meta.isNotEmpty) {
        final fullName = _clean(meta['fullName']?.toString());

        if (fullName.isNotEmpty) return fullName;

        final name = _clean(meta['name']?.toString());
        final surname = _clean(meta['surname']?.toString());

        final composed = <String>[
          name,
          surname,
        ].where((item) => item.isNotEmpty).join(' ').trim();

        if (composed.isNotEmpty) return composed;

        final email = _clean(meta['email']?.toString());

        if (email.isNotEmpty) return email;
      }
    }

    final currentUser = FirebaseAuth.instance.currentUser;

    final displayName = _clean(currentUser?.displayName);

    if (displayName.isNotEmpty) return displayName;

    final email = _clean(currentUser?.email);

    if (email.isNotEmpty) return email;

    return 'Usuário';
  }

  static String _resolveActorPhotoUrl({
    required ContractData contract,
    required String uid,
  }) {
    final cleanUid = uid.trim();

    if (cleanUid.isNotEmpty) {
      final meta = contract.participantInfoForUser(cleanUid);

      if (meta.isNotEmpty) {
        final photo = _clean(meta['urlPhoto']?.toString());

        if (photo.isNotEmpty) return photo;
      }
    }

    final firebasePhoto = _clean(FirebaseAuth.instance.currentUser?.photoURL);

    if (firebasePhoto.isNotEmpty) return firebasePhoto;

    return '';
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) return value;

    final text = value.toString().trim();

    if (text.isEmpty) return null;

    final iso = DateTime.tryParse(text);

    if (iso != null) return iso;

    final parts = text.split('/');

    if (parts.length != 3) return null;

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);

    if (day == null || month == null || year == null) return null;

    final parsed = DateTime(year, month, day);

    if (parsed.day == day && parsed.month == month && parsed.year == year) {
      return parsed;
    }

    return null;
  }

  static num? _parseNum(dynamic value) {
    if (value == null) return null;

    if (value is num) return value;

    final text = value.toString().trim();

    if (text.isEmpty) return null;

    final normalized = text
        .replaceAll('R\$', '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .trim();

    return num.tryParse(normalized);
  }

  static String _firstNotEmpty(Iterable<String?> values) {
    for (final value in values) {
      final clean = _clean(value);

      if (clean.isNotEmpty) return clean;
    }

    return '';
  }

  static String _clean(String? value) {
    return (value ?? '').trim();
  }
}