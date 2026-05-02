// lib/_blocs/system/notification/notification_dispatcher.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'local/notification_local_cubit.dart';
import 'notification_channel.dart';
import 'notification_data.dart';
import 'notification_delivery.dart';
import 'notification_source.dart';
import 'preferences/notification_preferences_repository.dart';
import 'remote/notification_remote_cubit.dart';

class NotificationDispatcher {
  const NotificationDispatcher._();

  static final NotificationPreferencesRepository _preferencesRepository =
  NotificationPreferencesRepository();

  static Future<void> dispatch({
    required BuildContext context,
    required NotificationData data,
    NotificationDelivery delivery = NotificationDelivery.localOnly,
    Iterable<String> targetUserIds = const <String>[],
    String? fallbackUserId,
    bool sendPush = false,
    bool global = false,
  }) async {
    if (!context.mounted) return;

    final sourceKey = _resolveSourceKey(data);

    final requestedChannels = <NotificationChannel>{
      ...delivery.channels,
      ...data.channels,
      if (sendPush || data.sendPush) NotificationChannel.push,
      if (data.persistInFirebase) NotificationChannel.bell,
    };

    if (requestedChannels.isEmpty) {
      requestedChannels.add(NotificationChannel.local);
    }

    final currentUserId =
        FirebaseAuth.instance.currentUser?.uid.trim() ?? fallbackUserId?.trim();

    if (currentUserId != null && currentUserId.isNotEmpty) {
      final localChannels = await _resolveEnabledChannelsForUser(
        userId: currentUserId,
        sourceKey: sourceKey,
        requestedChannels: requestedChannels,
      );

      if (localChannels.contains(NotificationChannel.local) && context.mounted) {
        context.read<NotificationLocalCubit>().show(
          data.copyWith(
            createdAt: data.createdAt ?? DateTime.now(),
            channels: const <NotificationChannel>{
              NotificationChannel.local,
            },
            persistInFirebase: false,
            sendPush: false,
            extra: NotificationData.sanitizeExtra(
              <String, dynamic>{
                ...data.extra,
                'source': sourceKey,
                'sourceKey': sourceKey,
                'subSource': sourceKey,
                'notificationSource': sourceKey,
                'channels': const <String>['local'],
                'sendPush': false,
                'sendEmail': false,
                'sendSms': false,
                'recipientUserId': currentUserId,
              },
            ),
          ),
        );
      }
    }

    final remoteRequestedChannels = requestedChannels.where((channel) {
      return channel != NotificationChannel.local;
    }).toSet();

    if (remoteRequestedChannels.isEmpty) return;

    if (!context.mounted) return;

    final remoteCubit = context.read<NotificationRemoteCubit>();

    if (global) {
      final globalChannels = remoteRequestedChannels;

      if (globalChannels.isEmpty) return;

      await remoteCubit.sendGlobal(
        data: _remoteData(
          data: data,
          sourceKey: sourceKey,
          channels: globalChannels,
        ),
        sendPush: globalChannels.contains(NotificationChannel.push),
      );

      return;
    }

    final recipients = targetUserIds
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();

    final fallback = fallbackUserId?.trim();

    if (recipients.isEmpty && fallback != null && fallback.isNotEmpty) {
      recipients.add(fallback);
    }

    if (recipients.isEmpty) return;

    final groupedByChannels = <String, _NotificationRecipientGroup>{};

    for (final userId in recipients) {
      final enabledChannels = await _resolveEnabledChannelsForUser(
        userId: userId,
        sourceKey: sourceKey,
        requestedChannels: remoteRequestedChannels,
      );

      final cleanChannels = enabledChannels.where((channel) {
        return channel != NotificationChannel.local;
      }).toSet();

      if (cleanChannels.isEmpty) continue;

      final groupKey = _channelsKey(cleanChannels);

      groupedByChannels.putIfAbsent(
        groupKey,
            () => _NotificationRecipientGroup(channels: cleanChannels),
      );

      groupedByChannels[groupKey]!.userIds.add(userId);
    }

    for (final group in groupedByChannels.values) {
      await remoteCubit.sendToUsers(
        userIds: group.userIds,
        data: _remoteData(
          data: data,
          sourceKey: sourceKey,
          channels: group.channels,
        ),
        sendPush: group.channels.contains(NotificationChannel.push),
      );
    }
  }

  static Future<Set<NotificationChannel>> _resolveEnabledChannelsForUser({
    required String userId,
    required String sourceKey,
    required Set<NotificationChannel> requestedChannels,
  }) async {
    final cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) {
      return const <NotificationChannel>{};
    }

    final preference = await _preferencesRepository.getPreference(
      userId: cleanUserId,
      sourceKey: sourceKey,
    );

    return preference.filterChannels(requestedChannels);
  }

  static NotificationData _remoteData({
    required NotificationData data,
    required String sourceKey,
    required Set<NotificationChannel> channels,
  }) {
    return data.copyWith(
      createdAt: data.createdAt ?? DateTime.now(),
      channels: channels,
      persistInFirebase: channels.contains(NotificationChannel.bell),
      sendPush: channels.contains(NotificationChannel.push),
      extra: NotificationData.sanitizeExtra(
        <String, dynamic>{
          ...data.extra,
          'source': sourceKey,
          'sourceKey': sourceKey,
          'subSource': sourceKey,
          'notificationSource': sourceKey,
          'channels': channels.map((item) => item.key).toList(),
          'sendPush': channels.contains(NotificationChannel.push),
          'sendEmail': channels.contains(NotificationChannel.email),
          'sendSms': channels.contains(NotificationChannel.sms),
        },
      ),
    );
  }

  static String _resolveSourceKey(NotificationData data) {
    final fromNotificationSource = _clean(
      data.extra['notificationSource']?.toString(),
    );

    if (fromNotificationSource != null) {
      return _normalizeSubSourceKey(fromNotificationSource);
    }

    final fromSubSource = _clean(
      data.extra['subSource']?.toString(),
    );

    if (fromSubSource != null) {
      return _normalizeSubSourceKey(fromSubSource);
    }

    final fromSourceKey = _clean(
      data.extra['sourceKey']?.toString(),
    );

    if (fromSourceKey != null) {
      return _normalizeSubSourceKey(fromSourceKey);
    }

    final fromSource = _clean(
      data.extra['source']?.toString(),
    );

    if (fromSource != null) {
      return _normalizeSubSourceKey(fromSource);
    }

    final fromRoute = _clean(
      data.extra['route']?.toString(),
    );

    if (fromRoute != null) {
      return _normalizeSubSourceKey(fromRoute);
    }

    final fromModule = _clean(
      data.extra['module']?.toString(),
    );

    if (fromModule != null) {
      return _normalizeSubSourceKey(fromModule);
    }

    final fromAction = _clean(
      data.extra['action']?.toString(),
    );

    if (fromAction != null) {
      return _normalizeSubSourceKey(fromAction);
    }

    return NotificationSubSource.generalSystem.key;
  }

  static String _normalizeSubSourceKey(String value) {
    final clean = value.trim().toLowerCase();

    if (clean.isEmpty) {
      return NotificationSubSource.generalSystem.key;
    }

    final direct = NotificationSourceRegistry.tryResolveSubSource(clean);

    if (direct != null) {
      return direct.key;
    }

    final source = NotificationSourceRegistry.resolveSource(clean);

    if (source != NotificationSource.general || clean == NotificationSource.general.key) {
      final subSources = source.subSources;

      if (subSources.isNotEmpty) {
        return subSources.first.key;
      }
    }

    return _inferSubSourceFromText(clean);
  }

  static String _inferSubSourceFromText(String value) {
    final clean = value.trim().toLowerCase();

    if (clean.isEmpty) {
      return NotificationSubSource.generalSystem.key;
    }

    if (clean.contains('general_notices') ||
        clean.contains('notice') ||
        clean.contains('notices') ||
        clean.contains('aviso') ||
        clean.contains('avisos') ||
        clean.contains('comunicado')) {
      return NotificationSubSource.generalNotices.key;
    }

    if (clean.contains('general_ads') ||
        clean.contains('ads') ||
        clean.contains('publicidade') ||
        clean.contains('campanha')) {
      return NotificationSubSource.generalAds.key;
    }

    if (clean.contains('dfd')) {
      return NotificationSubSource.contractsHiringDfd.key;
    }

    if (clean.contains('etp')) {
      return NotificationSubSource.contractsHiringEtp.key;
    }

    if (clean.contains('contracts_hiring_tr') ||
        clean.contains('_tr') ||
        clean.contains('termo') ||
        clean.contains('referencia') ||
        clean.contains('referência')) {
      return NotificationSubSource.contractsHiringTr.key;
    }

    if (clean.contains('cotacao') || clean.contains('cotação')) {
      return NotificationSubSource.contractsHiringCotacao.key;
    }

    if (clean.contains('edital') ||
        clean.contains('julgamento') ||
        clean.contains('proposta') ||
        clean.contains('lance')) {
      return NotificationSubSource.contractsHiringEdital.key;
    }

    if (clean.contains('habilitacao') ||
        clean.contains('habilitação') ||
        clean.contains('regularidade')) {
      return NotificationSubSource.contractsHiringHabilitacao.key;
    }

    if (clean.contains('dotacao') ||
        clean.contains('dotação') ||
        clean.contains('orcamentaria') ||
        clean.contains('orçamentária') ||
        clean.contains('orcamento') ||
        clean.contains('orçamento')) {
      return NotificationSubSource.contractsHiringDotacao.key;
    }

    if (clean.contains('minuta')) {
      return NotificationSubSource.contractsHiringMinuta.key;
    }

    if (clean.contains('parecer') || clean.contains('juridico')) {
      return NotificationSubSource.contractsHiringParecer.key;
    }

    if (clean.contains('publicacao') ||
        clean.contains('publicação') ||
        clean.contains('extrato')) {
      return NotificationSubSource.contractsHiringPublicacao.key;
    }

    if (clean.contains('arquivamento') ||
        clean.contains('arquivar') ||
        clean.contains('arquivo')) {
      return NotificationSubSource.contractsHiringArquivamento.key;
    }

    if (clean.contains('measurement') ||
        clean.contains('measurements') ||
        clean.contains('medicao') ||
        clean.contains('medição') ||
        clean.contains('boletim')) {
      return NotificationSubSource.measurementsBulletin.key;
    }

    if (clean.contains('adjustment') ||
        clean.contains('adjustments') ||
        clean.contains('reajuste')) {
      return NotificationSubSource.measurementsAdjustments.key;
    }

    if (clean.contains('revision') ||
        clean.contains('revisao') ||
        clean.contains('revisão')) {
      return NotificationSubSource.measurementsRevision.key;
    }

    if (clean.contains('schedule') ||
        clean.contains('cronograma') ||
        clean.contains('estaca')) {
      return NotificationSubSource.scheduleGeneral.key;
    }

    if (clean.contains('additive') || clean.contains('aditivo')) {
      return NotificationSubSource.additivesGeneral.key;
    }

    if (clean.contains('apostille') ||
        clean.contains('apostila') ||
        clean.contains('apostilamento')) {
      return NotificationSubSource.apostillesGeneral.key;
    }

    if (clean.contains('validity') ||
        clean.contains('vigencia') ||
        clean.contains('vigência') ||
        clean.contains('validade') ||
        clean.contains('prazo')) {
      return NotificationSubSource.validityGeneral.key;
    }

    if (clean.contains('contract') ||
        clean.contains('contrato') ||
        clean.contains('process') ||
        clean.contains('processo') ||
        clean.contains('hiring') ||
        clean.contains('contratacao') ||
        clean.contains('contratação')) {
      return NotificationSubSource.contractsHiringDfd.key;
    }

    return NotificationSubSource.generalSystem.key;
  }

  static String _channelsKey(Set<NotificationChannel> channels) {
    final values = channels.map((item) => item.key).toList()..sort();

    return values.join('|');
  }

  static String? _clean(String? value) {
    final cleanValue = value?.trim().toLowerCase();

    if (cleanValue == null || cleanValue.isEmpty) {
      return null;
    }

    return cleanValue;
  }
}

class _NotificationRecipientGroup {
  _NotificationRecipientGroup({
    required this.channels,
  });

  final Set<NotificationChannel> channels;
  final List<String> userIds = <String>[];
}