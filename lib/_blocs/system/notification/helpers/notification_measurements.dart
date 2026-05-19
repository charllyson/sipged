// lib/_blocs/system/notification/helpers/notification_measurements.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/system/notification/helpers/notification_contract_base.dart';
import 'package:sipged/_blocs/system/notification/helpers/notification_source.dart';
import 'package:sipged/_blocs/system/notification/notification_channel.dart';
import 'package:sipged/_blocs/system/notification/notification_delivery.dart';
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

  String get defaultSource {
    switch (this) {
      case NotificationMeasurementKind.bulletin:
        return 'measurement_notification';
      case NotificationMeasurementKind.adjustment:
        return 'adjustment_measurement_notification';
      case NotificationMeasurementKind.revision:
        return 'revision_measurement_notification';
    }
  }

  String get value {
    switch (this) {
      case NotificationMeasurementKind.bulletin:
        return 'bulletin';
      case NotificationMeasurementKind.adjustment:
        return 'adjustment';
      case NotificationMeasurementKind.revision:
        return 'revision';
    }
  }
}

class NotificationMeasurements {
  const NotificationMeasurements._();

  static Future<void> show({
    required BuildContext context,
    required ContractData contract,
    required String title,
    String? subtitle,
    String? details,
    NotificationMeasurementKind kind = NotificationMeasurementKind.bulletin,
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
    String? contractId,
    String? contractNumber,
    String? contractTitle,
    String? contractSummary,
    String? processNumber,
    String? processoAdministrativo,
    String? descricaoObjeto,
    String? nomeDemanda,
    String? action,
    String? measurementId,
    String? measurementNumber,
    String? measurementOrder,
    DateTime? measurementDate,
    num? measurementValue,
    String? adjustmentId,
    String? adjustmentNumber,
    String? adjustmentOrder,
    DateTime? adjustmentDate,
    num? adjustmentValue,
    String? revisionId,
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

    final resolvedContractId = _firstNotEmpty([
      contractId,
      contract.id,
    ]);

    final resolvedContractSummary = _firstNotEmpty([
      contractSummary,
      contractTitle,
      descricaoObjeto,
      nomeDemanda,
      resolvedContractId.isNotEmpty ? 'Contrato $resolvedContractId' : null,
      contract.displaySummary,
    ]);

    final resolvedContractNumber = _firstNotEmpty([
      contractNumber,
      processNumber,
      processoAdministrativo,
      contract.displayNumber,
      resolvedContractId,
    ]);

    final resolvedSubtitle = _firstNotEmpty([
      subtitle,
      resolvedContractSummary,
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

    final resolvedMeasurementId = _firstNotEmpty([
      measurementId,
      adjustmentId,
      revisionId,
      extra['measurementId']?.toString(),
      extra['adjustmentId']?.toString(),
      extra['revisionId']?.toString(),
    ]);

    final resolvedMeasurementNumber = _firstNotEmpty([
      measurementNumber,
      adjustmentNumber,
      revisionNumber,
      extra['measurementNumber']?.toString(),
      extra['measurementProcess']?.toString(),
      extra['adjustmentProcess']?.toString(),
      extra['revisionProcess']?.toString(),
    ]);

    final resolvedMeasurementOrder = _firstNotEmpty([
      measurementOrder,
      adjustmentOrder,
      revisionOrder,
      extra['measurementOrder']?.toString(),
      extra['adjustmentOrder']?.toString(),
      extra['revisionOrder']?.toString(),
    ]);

    final resolvedMeasurementDate = measurementDate ??
        adjustmentDate ??
        revisionDate ??
        _parseDateTime(extra['measurementDate']) ??
        _parseDateTime(extra['adjustmentDate']) ??
        _parseDateTime(extra['revisionDate']);

    final resolvedMeasurementValue = measurementValue ??
        adjustmentValue ??
        revisionValue ??
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
        ...extra,
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
        'contractId': resolvedContractId,
        'contractNumber': resolvedContractNumber,
        'processNumber': _firstNotEmpty([
          processNumber,
          processoAdministrativo,
          resolvedContractNumber,
        ]),
        'processoAdministrativo': _firstNotEmpty([
          processoAdministrativo,
          processNumber,
          resolvedContractNumber,
        ]),
        'contractTitle': resolvedContractSummary,
        'contractSummary': resolvedContractSummary,
        'descricaoObjeto': _firstNotEmpty([
          descricaoObjeto,
          resolvedContractSummary,
        ]),
        'nomeDemanda': _firstNotEmpty([
          nomeDemanda,
          resolvedContractSummary,
        ]),
        if (_clean(action).isNotEmpty) 'action': _clean(action),
        'measurementKind': kind.name,
        'measurementKindValue': kind.value,
        'measurementKindLabel': kind.label,
        'measurementId': resolvedMeasurementId,
        'measurementNumber': resolvedMeasurementNumber,
        'measurementOrder': resolvedMeasurementOrder,
        'measurementDate': resolvedMeasurementDate?.toIso8601String(),
        'measurementValue': resolvedMeasurementValue,
        if (kind == NotificationMeasurementKind.adjustment) ...{
          'adjustmentId': _firstNotEmpty([
            adjustmentId,
            resolvedMeasurementId,
          ]),
          'adjustmentNumber': _firstNotEmpty([
            adjustmentNumber,
            resolvedMeasurementNumber,
          ]),
          'adjustmentOrder': _firstNotEmpty([
            adjustmentOrder,
            resolvedMeasurementOrder,
          ]),
          'adjustmentDate':
          (adjustmentDate ?? resolvedMeasurementDate)?.toIso8601String(),
          'adjustmentValue': adjustmentValue ?? resolvedMeasurementValue,
        },
        if (kind == NotificationMeasurementKind.revision) ...{
          'revisionId': _firstNotEmpty([
            revisionId,
            resolvedMeasurementId,
          ]),
          'revisionNumber': _firstNotEmpty([
            revisionNumber,
            resolvedMeasurementNumber,
          ]),
          'revisionOrder': _firstNotEmpty([
            revisionOrder,
            resolvedMeasurementOrder,
          ]),
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
      }..removeWhere((key, value) => value == null),
    );
  }

  static String _resolveSourceKey({
    required NotificationMeasurementKind kind,
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

    if (clean == NotificationSubSource.measurementsBulletin.key ||
        clean == NotificationSubSource.measurementsAdjustments.key ||
        clean == NotificationSubSource.measurementsRevision.key) {
      return clean;
    }

    return kind.sourceKey;
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
          if (!includeCurrentUser && candidateId == cleanCurrentUserId) continue;

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