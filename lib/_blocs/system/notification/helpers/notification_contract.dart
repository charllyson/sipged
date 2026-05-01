import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_blocs/system/notification/local/notification_cubit.dart';
import 'package:sipged/_blocs/system/notification/local/notification_data.dart';
import 'package:sipged/_blocs/system/notification/local/notification_type.dart';

class NotificationContract {
  const NotificationContract._();

  static Future<void> show({
    required BuildContext context,
    required ProcessData contract,
    required String title,
    String? subtitle,
    String? details,
    String? leadingLabel,
    String? module,
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 5),
    bool saveInBell = false,
    bool sendPush = false,
    String? actorId,
    String? actorName,
    Iterable<String> targetUserIds = const <String>[],
    bool includeCurrentUser = true,
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) async {
    if (!context.mounted) return;

    final cubit = context.read<NotificationCubit>();
    final currentUser = FirebaseAuth.instance.currentUser;

    final resolvedActorId = _clean(actorId) ?? _clean(currentUser?.uid);

    final resolvedActorName = _clean(actorName) ??
        _resolveActorNameFromContract(
          contract: contract,
          uid: resolvedActorId,
        ) ??
        _clean(currentUser?.displayName) ??
        _clean(currentUser?.email) ??
        'Usuário';

    final contractId = _clean(contract.id);
    final contractSummary = _clean(contract.displaySummary) ??
        _clean(contract.summarySubjectContract) ??
        _fallbackContractSummary(contract);

    final contractNumber = _clean(contract.contractNumber) ??
        _clean(contract.processNumber) ??
        contractId;

    final cleanModule = _clean(module);

    final recipients = _resolveRecipients(
      contract: contract,
      targetUserIds: targetUserIds,
      currentUserId: resolvedActorId,
      includeCurrentUser: includeCurrentUser,
    );

    final resolvedExtra = _cleanExtra(<String, dynamic>{
      ...extra,
      'contractId': ?contractId,
      'contractNumber': ?contractNumber,
      'contractSummary': ?contractSummary,
      'contractTitle': ?contractSummary,
      'module': ?cleanModule,
      'route': ?cleanModule,
      'actorId': ?resolvedActorId,
      'actorName': resolvedActorName,
      'source': 'contract_bell_notifier',
      'sendPush': sendPush,
      if (recipients.isNotEmpty) 'targetUserIds': recipients,
    });

    final notification = NotificationData(
      title: title,
      subtitle: subtitle,
      details: details ?? contractSummary,
      leadingLabel: leadingLabel,
      type: type,
      duration: duration,
      createdBy: resolvedActorId,
      persistInFirebase: saveInBell,
      sendPush: sendPush,
      extra: resolvedExtra,
    );

    if (!saveInBell) {
      await cubit.show(
        notification,
        saveInFirebase: false,
        sendPush: false,
      );
      return;
    }

    if (recipients.isEmpty) {
      if (kDebugMode) {
        debugPrint('[ContractBellNotifier] Nenhum destinatário encontrado.');
      }

      await cubit.show(
        notification,
        saveInFirebase: false,
        sendPush: false,
      );
      return;
    }

    await cubit.showToUsers(
      notification,
      userIds: recipients,
      alsoShowLocalToast: true,
      sendPush: sendPush,
    );
  }

  static List<String> _resolveRecipients({
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

      if (!canRead) continue;

      if (!includeCurrentUser &&
          current != null &&
          current.isNotEmpty &&
          userId == current) {
        continue;
      }

      recipients.add(userId);
    }

    for (final userId in contract.participantsInfo.keys) {
      final cleanUserId = userId.trim();
      if (cleanUserId.isEmpty) continue;

      if (!includeCurrentUser &&
          current != null &&
          current.isNotEmpty &&
          cleanUserId == current) {
        continue;
      }

      recipients.add(cleanUserId);
    }

    return recipients.toList();
  }

  static String? _resolveActorNameFromContract({
    required ProcessData contract,
    required String? uid,
  }) {
    final cleanUid = uid?.trim();

    if (cleanUid == null || cleanUid.isEmpty) {
      return null;
    }

    final meta = contract.participantsInfo[cleanUid];

    if (meta == null) {
      return null;
    }

    final fullName = (meta['fullName'] ??
        meta['displayName'] ??
        meta['nameComplete'] ??
        '')
        .toString()
        .trim();

    if (fullName.isNotEmpty) return fullName;

    final name = (meta['name'] ?? '').toString().trim();
    final surname = (meta['surname'] ?? '').toString().trim();

    final composed = [name, surname]
        .where((item) => item.trim().isNotEmpty)
        .join(' ')
        .trim();

    if (composed.isNotEmpty) return composed;

    final email = (meta['email'] ?? '').toString().trim();

    if (email.isNotEmpty) return email;

    return null;
  }

  static String? _fallbackContractSummary(ProcessData contract) {
    final number = _clean(contract.contractNumber);
    if (number != null) return 'Contrato $number';

    final process = _clean(contract.processNumber);
    if (process != null) return 'Processo $process';

    final id = _clean(contract.id);
    if (id != null) return 'Contrato $id';

    return 'Contrato sem identificação';
  }

  static Map<String, dynamic> _cleanExtra(Map<String, dynamic> value) {
    final result = <String, dynamic>{};

    value.forEach((key, item) {
      final cleanKey = key.trim();

      if (cleanKey.isEmpty || item == null) return;

      if (item is String) {
        final cleanValue = item.trim();

        if (cleanValue.isNotEmpty) {
          result[cleanKey] = cleanValue;
        }

        return;
      }

      if (item is num || item is bool) {
        result[cleanKey] = item;
        return;
      }

      if (item is DateTime) {
        result[cleanKey] = item.toIso8601String();
        return;
      }

      if (item is Iterable) {
        final list = item
            .map((e) => e?.toString().trim() ?? '')
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList();

        if (list.isNotEmpty) {
          result[cleanKey] = list;
        }

        return;
      }

      if (item is Map) {
        final nested = <String, dynamic>{};

        item.forEach((nestedKey, nestedValue) {
          final cleanNestedKey = nestedKey.toString().trim();

          if (cleanNestedKey.isEmpty || nestedValue == null) return;

          if (nestedValue is String) {
            final cleanNestedValue = nestedValue.trim();

            if (cleanNestedValue.isNotEmpty) {
              nested[cleanNestedKey] = cleanNestedValue;
            }

            return;
          }

          if (nestedValue is num || nestedValue is bool) {
            nested[cleanNestedKey] = nestedValue;
          }
        });

        if (nested.isNotEmpty) {
          result[cleanKey] = nested;
        }
      }
    });

    return result;
  }

  static String? _clean(String? value) {
    final cleanValue = value?.trim();

    if (cleanValue == null || cleanValue.isEmpty) {
      return null;
    }

    return cleanValue;
  }
}