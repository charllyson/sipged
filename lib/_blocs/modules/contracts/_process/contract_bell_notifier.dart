// lib/_widgets/notification/contract_bell_notifier.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_blocs/system/module/module_permission.dart';
import 'package:sipged/_blocs/system/notification/notification_cubit.dart';
import 'package:sipged/_blocs/system/notification/notification_data.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';

class ContractBellNotifier {
  const ContractBellNotifier._();

  static Future<void> show({
    required BuildContext context,
    required ProcessData contract,
    required String title,
    String? subtitle,
    String? details,
    required String leadingLabel,
    required String module,
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 4),
    bool saveInBell = false,
    String? actorId,
    String? actorName,
    bool includeCurrentUser = false,
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) async {
    if (!context.mounted) return;

    final firebaseUser = FirebaseAuth.instance.currentUser;

    final resolvedActorId = (actorId ?? firebaseUser?.uid ?? '').trim();
    final resolvedActorName = _resolveActorName(
      actorName: actorName,
      firebaseUser: firebaseUser,
    );

    final notification = NotificationData(
      title: title,
      subtitle: subtitle,
      details: details ?? contract.displaySummary,
      leadingLabel: leadingLabel,
      type: type,
      duration: duration,
      persistInFirebase: saveInBell,
      createdBy: resolvedActorId.isEmpty ? null : resolvedActorId,
      extra: <String, dynamic>{
        'module': module,
        'contractId': contract.id,
        'contractNumber': contract.displayNumber,
        'contractSummary': contract.displaySummary,
        'actorId': resolvedActorId,
        'actorName': resolvedActorName,
        ...extra,
      },
    );

    if (!saveInBell) {
      await context.read<NotificationCubit>().show(notification);
      return;
    }

    final recipients = _recipientsFromContractAcl(
      contract: contract,
      currentUserId: resolvedActorId,
      includeCurrentUser: includeCurrentUser,
    );

    if (recipients.isEmpty) {
      await context.read<NotificationCubit>().show(notification);
      return;
    }

    await context.read<NotificationCubit>().showToUsers(
      notification,
      userIds: recipients,
      alsoShowLocalToast: true,
    );
  }

  static String _resolveActorName({
    required String? actorName,
    required User? firebaseUser,
  }) {
    final explicit = (actorName ?? '').trim();
    if (explicit.isNotEmpty) return explicit;

    final displayName = firebaseUser?.displayName?.trim() ?? '';
    if (displayName.isNotEmpty) return displayName;

    final email = firebaseUser?.email?.trim() ?? '';
    if (email.isNotEmpty) return email;

    return 'Usuário';
  }

  static List<String> _recipientsFromContractAcl({
    required ProcessData contract,
    required String currentUserId,
    required bool includeCurrentUser,
  }) {
    final ids = <String>{};
    final current = currentUserId.trim();

    for (final entry in contract.permissionContractId.entries) {
      final userId = entry.key.trim();
      if (userId.isEmpty) continue;

      if (!includeCurrentUser && current.isNotEmpty && userId == current) {
        continue;
      }

      final perms = ModulePermissions.fromMap(entry.value);

      final canRead = perms.read ||
          perms.create ||
          perms.edit ||
          perms.delete ||
          perms.approve;

      if (!canRead) continue;

      ids.add(userId);
    }

    return ids.toList(growable: false);
  }
}