// lib/_blocs/system/notification/helpers/notification_contract.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_blocs/system/notification/notification_channel.dart';
import 'package:sipged/_blocs/system/notification/notification_data.dart';
import 'package:sipged/_blocs/system/notification/notification_delivery.dart';
import 'package:sipged/_blocs/system/notification/notification_dispatcher.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';

class NotificationContractBase {
  const NotificationContractBase._();

  static Future<void> show({
    required BuildContext context,
    required ProcessData contract,
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

    final requestedChannels = resolveRequestedChannels(
      saveInBell: saveInBell,
      sendPush: sendPush,
      delivery: delivery,
      channels: channels,
    );

    final recipients = resolveRecipients(
      contract: contract,
      targetUserIds: targetUserIds,
      currentUserId: resolvedActorId,
      includeCurrentUser: includeCurrentUser,
    );

    final contractId = clean(contract.id);

    final contractSummary = clean(contract.displaySummary) ??
        clean(contract.summarySubjectContract) ??
        fallbackContractSummary(contract);

    final contractNumber =
        clean(contract.contractNumber) ?? clean(contract.processNumber) ?? contractId;

    final cleanModule = clean(module) ?? defaultModule;

    final resolvedExtra = NotificationData.sanitizeExtra(
      <String, dynamic>{
        ...extra,
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
    NotificationDelivery? delivery,
    Set<NotificationChannel>? channels,
  }) {
    final resolvedChannels = channels ??
        <NotificationChannel>{
          NotificationChannel.local,
          if (saveInBell) NotificationChannel.bell,
          if (sendPush) NotificationChannel.push,
        };

    final resolvedDelivery =
        delivery ?? NotificationDelivery(channels: resolvedChannels);

    final requestedChannels = <NotificationChannel>{
      ...resolvedDelivery.channels,
      if (sendPush) NotificationChannel.push,
    };

    if (requestedChannels.isEmpty) {
      requestedChannels.add(NotificationChannel.local);
    }

    return requestedChannels;
  }

  static List<String> resolveRecipients({
    required ProcessData contract,
    required Iterable<String> targetUserIds,
    required String? currentUserId,
    required bool includeCurrentUser,
  }) {
    final current = currentUserId?.trim();

    final explicitRecipients = targetUserIds
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet();

    if (explicitRecipients.isNotEmpty) {
      if (includeCurrentUser && current != null && current.isNotEmpty) {
        explicitRecipients.add(current);
      }

      if (!includeCurrentUser && current != null && current.isNotEmpty) {
        explicitRecipients.remove(current);
      }

      return explicitRecipients.toList();
    }

    final recipients = <String>{};

    for (final entry in contract.permissionContractId.entries) {
      final userId = entry.key.trim();

      if (userId.isEmpty) continue;

      final perms = entry.value;

      final canRead = perms['read'] == true ||
          perms['view'] == true ||
          perms['create'] == true ||
          perms['edit'] == true ||
          perms['update'] == true ||
          perms['delete'] == true ||
          perms['admin'] == true ||
          perms['owner'] == true;

      if (canRead) {
        recipients.add(userId);
      }
    }

    for (final userId in contract.participantsInfo.keys) {
      final cleanUserId = userId.trim();

      if (cleanUserId.isNotEmpty) {
        recipients.add(cleanUserId);
      }
    }

    if (includeCurrentUser && current != null && current.isNotEmpty) {
      recipients.add(current);
    }

    if (!includeCurrentUser && current != null && current.isNotEmpty) {
      recipients.remove(current);
    }

    return recipients.toList();
  }

  static String? resolveActorNameFromContract({
    required ProcessData contract,
    required String? uid,
  }) {
    final cleanUid = uid?.trim();

    if (cleanUid == null || cleanUid.isEmpty) return null;

    final meta = contract.participantsInfo[cleanUid];

    if (meta == null) return null;

    final fullName = (meta['fullName'] ??
        meta['displayName'] ??
        meta['nameComplete'] ??
        '')
        .toString()
        .trim();

    if (fullName.isNotEmpty) return fullName;

    final name = (meta['name'] ?? '').toString().trim();
    final surname = (meta['surname'] ?? '').toString().trim();

    final composed = <String>[
      name,
      surname,
    ].where((item) => item.trim().isNotEmpty).join(' ').trim();

    if (composed.isNotEmpty) return composed;

    final email = (meta['email'] ?? '').toString().trim();

    if (email.isNotEmpty) return email;

    return null;
  }

  static String fallbackContractSummary(ProcessData contract) {
    final contractNumber = clean(contract.contractNumber);

    if (contractNumber != null) {
      return 'Contrato $contractNumber';
    }

    final processNumber = clean(contract.processNumber);

    if (processNumber != null) {
      return 'Processo $processNumber';
    }

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