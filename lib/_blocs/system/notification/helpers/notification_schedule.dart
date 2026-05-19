// lib/_blocs/system/notification/helpers/notification_schedule.dart

import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/system/notification/helpers/notification_contract_base.dart';
import 'package:sipged/_blocs/system/notification/notification_channel.dart';
import 'package:sipged/_blocs/system/notification/notification_delivery.dart';
import 'package:sipged/_blocs/system/notification/helpers/notification_source.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';

class NotificationSchedule {
  const NotificationSchedule._();

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

    Map<String, dynamic> extra = const <String, dynamic>{},
  }) async {
    final resolvedActorName = actorName ??
        NotificationContractBase.resolveActorNameFromContract(
          contract: contract,
          uid: actorId,
        ) ??
        'Usuário';

    final normalizedText = _normalizeScheduleText(
      title: title,
      subtitle: subtitle,
      details: details,
      actorName: resolvedActorName,
      extra: extra,
    );

    await NotificationContractBase.show(
      context: context,
      contract: contract,
      title: normalizedText.title,
      subtitle: normalizedText.subtitle,
      details: normalizedText.details,
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
      source: 'schedule_notification',
      sourceKey: NotificationSubSource.scheduleGeneral.key,
      defaultModule: 'operation_schedule',
      defaultLeadingLabel: 'Cronograma',
      extra: extra,
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
    String? clean(String? value) {
      final cleanValue = value?.trim();

      if (cleanValue == null || cleanValue.isEmpty) return null;

      return cleanValue;
    }

    final action = clean(extra['action']?.toString()) ?? '';

    final isSingleStakeAction =
        action == 'schedule_stake_saved' || action == 'schedule_stake_deleted';

    final isBulkStakeAction = action == 'schedule_bulk_stakes_saved' ||
        action == 'schedule_bulk_stakes_saved_with_deletions';

    if (!isSingleStakeAction && !isBulkStakeAction) {
      return (
      title: title,
      subtitle: subtitle,
      details: details,
      );
    }

    final serviceLabel = clean(extra['serviceLabel']?.toString()) ??
        clean(extra['tipoLabel']?.toString()) ??
        clean(title);

    final resolvedTitle = (serviceLabel ?? title).toUpperCase();

    if (isSingleStakeAction) {
      final estaca = clean(extra['estaca']?.toString());

      if (estaca == null) {
        return (
        title: resolvedTitle,
        subtitle: subtitle,
        details: details,
        );
      }

      final isDeleted = action == 'schedule_stake_deleted';

      final text = isDeleted
          ? 'Estaca $estaca removida por $actorName.'
          : 'Estaca $estaca atualizada por $actorName.';

      return (
      title: resolvedTitle,
      subtitle: text,
      details: text,
      );
    }

    final targetsCount = clean(extra['targetsCount']?.toString()) ?? '0';
    final deletedCountText = clean(extra['deletedCount']?.toString());
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
}