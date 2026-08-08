// lib/_blocs/system/notification/helpers/notification_contract_base.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/10Publicacao/publicacao_extrato_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';

import 'package:sipged/_blocs/system/notification/notification_channel.dart';
import 'package:sipged/_blocs/system/notification/notification_data.dart';
import 'package:sipged/_blocs/system/notification/notification_delivery.dart';
import 'package:sipged/_blocs/system/notification/notification_dispatcher.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';

class NotificationContractBase {
  const NotificationContractBase._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> show({
    required BuildContext context,
    required ContractData contract,
    required String title,
    required String source,
    required String sourceKey,
    required String defaultModule,
    required String defaultLeadingLabel,
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
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) async {
    if (!context.mounted) return;

    final currentUser = FirebaseAuth.instance.currentUser;

    final resolvedStatus = type ?? status;

    final resolvedActorId = clean(actorId) ?? clean(currentUser?.uid);

    final resolvedActorName = clean(actorName) ??
        resolveActorNameFromContract(
          contract: contract,
          uid: resolvedActorId,
        ) ??
        clean(currentUser?.displayName) ??
        clean(currentUser?.email) ??
        'Usuário';

    final recipients = resolveRecipients(
      contract: contract,
      targetUserIds: targetUserIds,
      currentUserId: resolvedActorId,
      includeCurrentUser: includeCurrentUser,
    );

    final callerDefinedDelivery = channels != null || delivery != null;

    final requestedChannels = resolveRequestedChannels(
      saveInBell: saveInBell,
      sendPush: sendPush,
      delivery: delivery,
      channels: channels,
      callerDefinedDelivery: callerDefinedDelivery,
      hasRemoteRecipients: global || recipients.isNotEmpty,
    );

    final contractId = clean(contract.id);

    final tenantId = clean(extra['tenantId']?.toString()) ??
        clean(extra['companyId']?.toString());

    final resolvedDisplay = await resolveContractDisplay(
      contract: contract,
      tenantId: tenantId,
    );

    if (!context.mounted) return;

    final contractSummary =
        clean(resolvedDisplay.summary) ?? fallbackContractSummary(contract);

    final contractNumber = clean(resolvedDisplay.number) ?? contractId;

    final cleanModule = clean(module) ?? defaultModule;

    final resolvedExtra = NotificationData.sanitizeExtra(
      <String, dynamic>{
        ...extra,
        'tenantId': ?tenantId,
        'companyId': ?tenantId,
        'contractId': contractId,
        'contractNumber': contractNumber,
        'contractSummary': contractSummary,
        'contractTitle': contractSummary,
        'module': cleanModule,
        'route': extra['route'] ?? cleanModule,
        'actorId': resolvedActorId,
        'actorName': resolvedActorName,
        'source': source,
        'sourceKey': sourceKey,
        'subSource': sourceKey,
        'notificationSource': sourceKey,
        'requestedChannels': requestedChannels.map((item) => item.key).toList(),
        'sendPush': requestedChannels.contains(NotificationChannel.push),
        'recipientCount': recipients.length,
        if (recipients.isNotEmpty) 'targetUserIds': recipients,
      },
    );

    final data = NotificationData(
      title: title,
      subtitle: subtitle,
      details: details ?? contractSummary,
      leadingLabel: leadingLabel ?? defaultLeadingLabel,
      status: resolvedStatus,
      channels: requestedChannels,
      duration: duration,
      createdBy: resolvedActorId,
      persistInFirebase: requestedChannels.contains(NotificationChannel.bell),
      sendPush: requestedChannels.contains(NotificationChannel.push),
      sendEmail: requestedChannels.contains(NotificationChannel.email),
      sendSms: requestedChannels.contains(NotificationChannel.sms),
      extra: resolvedExtra,
    );

    await NotificationDispatcher.dispatch(
      context: context,
      data: data,
      delivery: NotificationDelivery(channels: requestedChannels),
      targetUserIds: global ? const <String>[] : recipients,
      fallbackUserId: resolvedActorId,
      sendPush: requestedChannels.contains(NotificationChannel.push),
      global: global,
    );
  }

  static Set<NotificationChannel> resolveRequestedChannels({
    required bool saveInBell,
    required bool sendPush,
    required bool callerDefinedDelivery,
    required bool hasRemoteRecipients,
    NotificationDelivery? delivery,
    Set<NotificationChannel>? channels,
  }) {
    final resolvedChannels = <NotificationChannel>{
      ...?channels,
      if (delivery != null) ...delivery.channels,
      if (channels == null && delivery == null) NotificationChannel.local,
      if (saveInBell) NotificationChannel.bell,
      if (sendPush) NotificationChannel.push,
    };

    if (!callerDefinedDelivery && hasRemoteRecipients) {
      resolvedChannels.add(NotificationChannel.local);
      resolvedChannels.add(NotificationChannel.bell);
      resolvedChannels.add(NotificationChannel.push);
    }

    if (resolvedChannels.isEmpty) {
      resolvedChannels.add(NotificationChannel.local);
    }

    return resolvedChannels;
  }

  static Future<({String? number, String? summary})> resolveContractDisplay({
    required ContractData contract,
    String? tenantId,
  }) async {
    final contractId = clean(contract.id);
    final cleanTenantId = clean(tenantId);

    if (contractId == null || cleanTenantId == null) {
      return (
      number: clean(contract.displayNumber),
      summary: clean(contract.displaySummary),
      );
    }

    final publicacao = await _loadPublicacaoExtrato(
      tenantId: cleanTenantId,
      contractId: contractId,
    );

    final dfd = await _loadDfd(
      tenantId: cleanTenantId,
      contractId: contractId,
    );

    final number = clean(publicacao?.numeroContrato) ??
        clean(publicacao?.processo) ??
        clean(contract.displayNumber);

    final summary = clean(dfd?.descricaoObjeto) ??
        clean(publicacao?.objetoResumo) ??
        clean(contract.displaySummary);

    return (
    number: number,
    summary: summary,
    );
  }

  static Future<PublicacaoExtratoData?> _loadPublicacaoExtrato({
    required String tenantId,
    required String contractId,
  }) async {
    final data = await _tryReadDocument(
      'tenants/$tenantId/contracts/$contractId/hiring/main/publicacaoExtrato',
    );

    if (data == null) return null;

    return _parsePublicacaoExtrato(data);
  }

  static PublicacaoExtratoData? _parsePublicacaoExtrato(
      Map<String, dynamic> data,
      ) {
    final sectionsData = data['sectionsData'];

    if (sectionsData is Map) {
      return PublicacaoExtratoData.fromSectionsMap(
        _toSectionsMap(sectionsData),
      );
    }

    return PublicacaoExtratoData.fromFlatMap(data);
  }

  static Future<DfdData?> _loadDfd({
    required String tenantId,
    required String contractId,
  }) async {
    final data = await _tryReadDocument(
      'tenants/$tenantId/contracts/$contractId/hiring/main/dfd',
    );

    if (data == null) return null;

    return _parseDfd(
      data,
      contractId: contractId,
    );
  }

  static DfdData? _parseDfd(
      Map<String, dynamic> data, {
        required String contractId,
      }) {
    final sectionsData = data['sectionsData'];

    if (sectionsData is Map) {
      return DfdData.fromSectionsMap(
        _toDynamicMap(sectionsData),
        contractId: contractId,
      );
    }

    return DfdData.fromMap(
      data,
      contractId: contractId,
    );
  }

  static Future<Map<String, dynamic>?> _tryReadDocument(String path) async {
    try {
      final snapshot = await _firestore.doc(path).get();

      if (!snapshot.exists) return null;

      final data = snapshot.data();

      if (data == null || data.isEmpty) return null;

      return Map<String, dynamic>.from(data);
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _toDynamicMap(Map raw) {
    return raw.map(
          (key, value) => MapEntry(
        key.toString(),
        value is Map ? _toDynamicMap(value) : value,
      ),
    );
  }

  static Map<String, Map<String, dynamic>> _toSectionsMap(Map raw) {
    final result = <String, Map<String, dynamic>>{};

    for (final entry in raw.entries) {
      final key = entry.key.toString();
      final value = entry.value;

      if (value is Map<String, dynamic>) {
        result[key] = value;
      } else if (value is Map) {
        result[key] = Map<String, dynamic>.from(
          value.map(
                (k, v) => MapEntry(
              k.toString(),
              v,
            ),
          ),
        );
      }
    }

    return result;
  }

  static List<String> resolveRecipients({
    required ContractData contract,
    required Iterable<String> targetUserIds,
    required String? currentUserId,
    required bool includeCurrentUser,
  }) {
    final current = clean(currentUserId);
    final explicitRecipients = _cleanUserIds(targetUserIds);

    if (explicitRecipients.isNotEmpty) {
      if (includeCurrentUser && current != null) {
        explicitRecipients.add(current);
      }

      if (!includeCurrentUser && current != null) {
        explicitRecipients.remove(current);
      }

      return _sortedUserIds(explicitRecipients);
    }

    final recipients = _recipientsFromParticipantsInfo(
      contract.participantsInfo,
    );

    if (includeCurrentUser && current != null) {
      recipients.add(current);
    }

    if (!includeCurrentUser && current != null) {
      recipients.remove(current);
    }

    return _sortedUserIds(recipients);
  }

  static Set<String> _recipientsFromParticipantsInfo(
      Map<String, Map<String, dynamic>> participantsInfo,
      ) {
    final recipients = <String>{};

    for (final entry in participantsInfo.entries) {
      final userId = clean(entry.key);

      if (userId == null) continue;

      final meta = entry.value;

      if (_participantCanReceiveNotification(meta)) {
        recipients.add(userId);
      }
    }

    return recipients;
  }

  static bool _participantCanReceiveNotification(
      Map<String, dynamic> meta,
      ) {
    final active = meta['active'];

    if (active is bool) {
      return active;
    }

    return true;
  }

  static Set<String> _cleanUserIds(Iterable<String> values) {
    return values
        .map(clean)
        .whereType<String>()
        .where((item) => item.isNotEmpty)
        .toSet();
  }

  static List<String> _sortedUserIds(Set<String> values) {
    final list = values.toList()..sort();

    return list;
  }

  static String? resolveActorNameFromContract({
    required ContractData contract,
    required String? uid,
  }) {
    final cleanUid = clean(uid);

    if (cleanUid == null) return null;

    final meta = contract.participantsInfo[cleanUid];

    if (meta == null) return null;

    final fullName = clean(
      meta['fullName']?.toString(),
    );

    if (fullName != null) return fullName;

    final name = clean(
      meta['name']?.toString(),
    );

    final surname = clean(
      meta['surname']?.toString(),
    );

    final composed = <String>[
      ?name,
      ?surname,
    ].join(' ').trim();

    if (composed.isNotEmpty) return composed;

    final email = clean(
      meta['email']?.toString(),
    );

    if (email != null) return email;

    return null;
  }

  static String fallbackContractSummary(ContractData contract) {
    final id = clean(contract.id);

    if (id != null) {
      return 'Contrato $id';
    }

    return 'Contrato sem identificação';
  }

  static String? clean(String? value) {
    final cleanValue = value?.trim();

    if (cleanValue == null || cleanValue.isEmpty) return null;

    return cleanValue;
  }
}