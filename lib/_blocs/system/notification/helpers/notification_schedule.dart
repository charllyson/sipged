import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_blocs/system/notification/local/notification_cubit.dart';
import 'package:sipged/_blocs/system/notification/local/notification_data.dart';
import 'package:sipged/_blocs/system/notification/local/notification_type.dart';

class NotificationSchedule {
  const NotificationSchedule._();

  static Future<void> show({
    required BuildContext context,

    /// Contrato completo.
    ///
    /// Use quando a tela possuir `ProcessData`.
    ProcessData? contract,

    /// Id do contrato.
    ///
    /// Use quando a tela possuir apenas o id.
    String? contractId,

    /// Resumo/título do contrato.
    ///
    /// Use quando a tela possuir apenas o título ou nome da obra.
    String? contractSummary,

    required String title,
    String? subtitle,
    String? details,
    String? leadingLabel,
    String? module,

    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 5),

    /// false: apenas toast local.
    ///
    /// true: salva no sino/notificações.
    bool saveInBell = false,

    /// true: tenta enviar remote para os destinatários.
    ///
    /// Normalmente use junto com `saveInBell: true`.
    bool sendPush = false,

    String? actorId,
    String? actorName,

    /// Destinatários explícitos.
    ///
    /// Se vazio, tenta resolver pelos usuários vinculados ao contrato.
    Iterable<String> targetUserIds = const <String>[],

    /// Se true, inclui o usuário atual também como destinatário.
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

    final resolvedContractId = _clean(contractId) ?? _clean(contract?.id);

    final resolvedContractSummary = _clean(contractSummary) ??
        _clean(contract?.displaySummary) ??
        _clean(contract?.summarySubjectContract) ??
        _fallbackContractSummary(
          contract: contract,
          contractId: resolvedContractId,
        );

    final resolvedContractNumber = _clean(contract?.contractNumber) ??
        _clean(contract?.processNumber) ??
        resolvedContractId;

    final cleanModule = _clean(module) ?? 'operation_schedule';

    final recipients = _resolveRecipients(
      contract: contract,
      targetUserIds: targetUserIds,
      currentUserId: resolvedActorId,
      includeCurrentUser: includeCurrentUser,
    );

    final normalizedText = _normalizeScheduleText(
      title: title,
      subtitle: subtitle,
      details: details,
      actorName: resolvedActorName,
      extra: extra,
    );

    final resolvedExtra = _cleanExtra(<String, dynamic>{
      ...extra,
      'contractId': resolvedContractId,
      'contractNumber': resolvedContractNumber,
      'contractSummary': resolvedContractSummary,
      'contractTitle': resolvedContractSummary,
      'module': cleanModule,
      'route': cleanModule,
      'actorId': resolvedActorId,
      'actorName': resolvedActorName,
      'source': extra['source'] ?? 'schedule_bell_notifier',
      'sendPush': sendPush,
      if (recipients.isNotEmpty) 'targetUserIds': recipients,
    });

    final notification = NotificationData(
      title: normalizedText.title,
      subtitle: normalizedText.subtitle,
      details: normalizedText.details ?? resolvedContractSummary,
      leadingLabel: leadingLabel ?? 'Cronograma',
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
        debugPrint(
          '[ScheduleBellNotifier] Nenhum destinatário encontrado. '
              'Salvando apenas no fluxo local.',
        );
      }

      await cubit.show(
        notification,
        saveInFirebase: true,
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

  static ({
  String title,
  String? subtitle,
  String? details,
  }) _normalizeScheduleText({
    required String title,
    required String? subtitle,
    required String? details,
    required String actorName,
    required Map<String, dynamic> extra,
  }) {
    final action = _clean(extra['action']?.toString()) ?? '';

    final isSingleStakeAction = action == 'schedule_stake_saved' ||
        action == 'schedule_stake_deleted';

    final isBulkStakeAction = action == 'schedule_bulk_stakes_saved' ||
        action == 'schedule_bulk_stakes_saved_with_deletions';

    if (!isSingleStakeAction && !isBulkStakeAction) {
      return (
      title: title,
      subtitle: subtitle,
      details: details,
      );
    }

    final serviceLabel = _clean(extra['serviceLabel']?.toString()) ??
        _clean(extra['tipoLabel']?.toString()) ??
        _clean(title);

    final resolvedTitle = (serviceLabel ?? title).toUpperCase();

    if (isSingleStakeAction) {
      final estaca = _clean(extra['estaca']?.toString());

      if (estaca == null) {
        return (
        title: resolvedTitle,
        subtitle: subtitle,
        details: details,
        );
      }

      final isDeleted = action == 'schedule_stake_deleted';

      final text = isDeleted
          ? 'Estaca $estaca, removida por $actorName.'
          : 'Estaca $estaca, atualizada por $actorName.';

      return (
      title: resolvedTitle,
      subtitle: text,
      details: text,
      );
    }

    final targetsCount = _clean(extra['targetsCount']?.toString()) ?? '0';
    final deletedCountText = _clean(extra['deletedCount']?.toString());
    final deletedCount = int.tryParse(deletedCountText ?? '0') ?? 0;

    final text = deletedCount > 0
        ? '$targetsCount estaca(s) atualizada(s), com $deletedCount remoção(ões), por $actorName.'
        : '$targetsCount estaca(s) atualizada(s) por $actorName.';

    return (
    title: resolvedTitle,
    subtitle: text,
    details: text,
    );
  }

  static List<String> _resolveRecipients({
    required ProcessData? contract,
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

    if (contract != null) {
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

        recipients.add(userId);
      }

      for (final userId in contract.participantsInfo.keys) {
        final cleanUserId = userId.trim();

        if (cleanUserId.isEmpty) continue;

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

  static String? _resolveActorNameFromContract({
    required ProcessData? contract,
    required String? uid,
  }) {
    if (contract == null) return null;

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

    final composed = <String>[
      name,
      surname,
    ].where((item) => item.trim().isNotEmpty).join(' ').trim();

    if (composed.isNotEmpty) return composed;

    final email = (meta['email'] ?? '').toString().trim();

    if (email.isNotEmpty) return email;

    return null;
  }

  static String? _fallbackContractSummary({
    required ProcessData? contract,
    required String? contractId,
  }) {
    if (contract != null) {
      final number = _clean(contract.contractNumber);

      if (number != null) {
        return 'Contrato $number';
      }

      final process = _clean(contract.processNumber);

      if (process != null) {
        return 'Processo $process';
      }

      final id = _clean(contract.id);

      if (id != null) {
        return 'Contrato $id';
      }
    }

    final id = _clean(contractId);

    if (id != null) {
      return 'Contrato $id';
    }

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
            return;
          }

          if (nestedValue is DateTime) {
            nested[cleanNestedKey] = nestedValue.toIso8601String();
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