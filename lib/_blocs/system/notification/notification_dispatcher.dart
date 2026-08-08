import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'local/notification_local_cubit.dart';
import 'notification_channel.dart';
import 'notification_data.dart';
import 'notification_delivery.dart';
import 'helpers/notification_source.dart';
import 'preferences/notification_preference_data.dart';
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

    final requestedChannels = _resolveRequestedChannels(
      data: data,
      delivery: delivery,
      sendPush: sendPush,
    );

    if (requestedChannels.isEmpty) return;

    final currentUserId = _resolveCurrentUserId(fallbackUserId);

    final preferenceCache = <String, Future<NotificationPreferenceData>>{};

    Future<Set<NotificationChannel>> resolveEnabledChannels({
      required String userId,
      required Set<NotificationChannel> channels,
    }) {
      return _resolveEnabledChannelsForUser(
        cache: preferenceCache,
        userId: userId,
        sourceKey: sourceKey,
        requestedChannels: channels,
      );
    }

    await _dispatchLocalIfAllowed(
      context: context,
      data: data,
      sourceKey: sourceKey,
      currentUserId: currentUserId,
      requestedChannels: requestedChannels,
      resolveEnabledChannels: resolveEnabledChannels,
    );

    final remoteRequestedChannels = _remoteChannelsOnly(requestedChannels);

    if (remoteRequestedChannels.isEmpty) return;
    if (!context.mounted) return;

    final remoteCubit = context.read<NotificationRemoteCubit>();

    if (global) {
      await _dispatchGlobal(
        remoteCubit: remoteCubit,
        data: data,
        sourceKey: sourceKey,
        channels: remoteRequestedChannels,
      );

      return;
    }

    await _dispatchToUsers(
      remoteCubit: remoteCubit,
      data: data,
      sourceKey: sourceKey,
      targetUserIds: targetUserIds,
      fallbackUserId: fallbackUserId,
      requestedChannels: remoteRequestedChannels,
      resolveEnabledChannels: resolveEnabledChannels,
    );
  }

  static Set<NotificationChannel> _resolveRequestedChannels({
    required NotificationData data,
    required NotificationDelivery delivery,
    required bool sendPush,
  }) {
    final channels = <NotificationChannel>{
      ...delivery.channels,
      ...data.channels,
      if (data.persistInFirebase) NotificationChannel.bell,
      if (sendPush || data.sendPush) NotificationChannel.push,
      if (data.sendEmail) NotificationChannel.email,
      if (data.sendSms) NotificationChannel.sms,
    };

    if (channels.isEmpty) {
      channels.add(NotificationChannel.local);
    }

    return channels;
  }

  static String? _resolveCurrentUserId(String? fallbackUserId) {
    final authUserId = FirebaseAuth.instance.currentUser?.uid.trim();

    if (authUserId != null && authUserId.isNotEmpty) {
      return authUserId;
    }

    final fallback = fallbackUserId?.trim();

    if (fallback != null && fallback.isNotEmpty) {
      return fallback;
    }

    return null;
  }

  static Future<void> _dispatchLocalIfAllowed({
    required BuildContext context,
    required NotificationData data,
    required String sourceKey,
    required String? currentUserId,
    required Set<NotificationChannel> requestedChannels,
    required Future<Set<NotificationChannel>> Function({
    required String userId,
    required Set<NotificationChannel> channels,
    }) resolveEnabledChannels,
  }) async {
    if (!requestedChannels.contains(NotificationChannel.local)) return;

    final userId = currentUserId?.trim();

    if (userId == null || userId.isEmpty) return;

    final enabledChannels = await resolveEnabledChannels(
      userId: userId,
      channels: const <NotificationChannel>{
        NotificationChannel.local,
      },
    );

    if (!enabledChannels.contains(NotificationChannel.local)) return;
    if (!context.mounted) return;

    context.read<NotificationLocalCubit>().show(
      data.copyWith(
        createdAt: data.createdAt ?? DateTime.now(),
        channels: const <NotificationChannel>{
          NotificationChannel.local,
        },
        persistInFirebase: false,
        sendPush: false,
        sendEmail: false,
        sendSms: false,
        recipientUserId: userId,
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
            'recipientUserId': userId,
          },
        ),
      ),
    );
  }

  static Future<void> _dispatchGlobal({
    required NotificationRemoteCubit remoteCubit,
    required NotificationData data,
    required String sourceKey,
    required Set<NotificationChannel> channels,
  }) async {
    if (channels.isEmpty) return;

    await remoteCubit.sendGlobal(
      data: _remoteData(
        data: data,
        sourceKey: sourceKey,
        channels: channels,
      ),
      sendPush: channels.contains(NotificationChannel.push),
    );
  }

  static Future<void> _dispatchToUsers({
    required NotificationRemoteCubit remoteCubit,
    required NotificationData data,
    required String sourceKey,
    required Iterable<String> targetUserIds,
    required String? fallbackUserId,
    required Set<NotificationChannel> requestedChannels,
    required Future<Set<NotificationChannel>> Function({
    required String userId,
    required Set<NotificationChannel> channels,
    }) resolveEnabledChannels,
  }) async {
    final recipients = _resolveRecipients(
      targetUserIds: targetUserIds,
      fallbackUserId: fallbackUserId,
    );

    if (recipients.isEmpty) return;

    // Resolve as preferências de canal de todos os destinatários em paralelo
    // (antes era um `await` por usuário, em série). `resolveEnabledChannels`
    // já cacheia por `userId::sourceKey` (ver `_resolveEnabledChannelsForUser`),
    // então chamadas concorrentes para o mesmo usuário/fonte reaproveitam a
    // mesma leitura em vez de duplicá-la. `Future.wait` preserva a ordem da
    // lista de entrada, então o agrupamento abaixo fica idêntico ao da versão
    // sequencial — só mais rápido para notificações com muitos destinatários.
    final resolvedChannelsByUser = await Future.wait(
      recipients.map((userId) async {
        final enabledChannels = await resolveEnabledChannels(
          userId: userId,
          channels: requestedChannels,
        );

        return MapEntry(userId, _remoteChannelsOnly(enabledChannels));
      }),
    );

    final groupedByChannels = <String, _NotificationRecipientGroup>{};

    for (final entry in resolvedChannelsByUser) {
      final userId = entry.key;
      final cleanChannels = entry.value;

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

  static List<String> _resolveRecipients({
    required Iterable<String> targetUserIds,
    required String? fallbackUserId,
  }) {
    final recipients = targetUserIds
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet();

    final fallback = fallbackUserId?.trim();

    if (recipients.isEmpty && fallback != null && fallback.isNotEmpty) {
      recipients.add(fallback);
    }

    final list = recipients.toList()..sort();

    return list;
  }

  static Set<NotificationChannel> _remoteChannelsOnly(
      Iterable<NotificationChannel> channels,
      ) {
    return channels.where((channel) {
      return channel != NotificationChannel.local;
    }).toSet();
  }

  static Future<Set<NotificationChannel>> _resolveEnabledChannelsForUser({
    required Map<String, Future<NotificationPreferenceData>> cache,
    required String userId,
    required String sourceKey,
    required Set<NotificationChannel> requestedChannels,
  }) async {
    final cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) {
      return const <NotificationChannel>{};
    }

    final cacheKey = '$cleanUserId::$sourceKey';

    final preferenceFuture = cache.putIfAbsent(
      cacheKey,
          () {
        return _preferencesRepository.getPreference(
          userId: cleanUserId,
          sourceKey: sourceKey,
        );
      },
    );

    final preference = await preferenceFuture;

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
      sendEmail: channels.contains(NotificationChannel.email),
      sendSms: channels.contains(NotificationChannel.sms),
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
    final candidates = <String?>[
      data.extra['notificationSource']?.toString(),
      data.extra['subSource']?.toString(),
      data.extra['sourceKey']?.toString(),
      data.extra['source']?.toString(),
      data.extra['route']?.toString(),
      data.extra['module']?.toString(),
      data.extra['action']?.toString(),
    ];

    for (final candidate in candidates) {
      final cleanValue = _clean(candidate);

      if (cleanValue == null) continue;

      return _normalizeSubSourceKey(cleanValue);
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

    if (source != NotificationSource.general ||
        clean == NotificationSource.general.key) {
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

    if (_containsAny(clean, const [
      'general_notices',
      'notice',
      'notices',
      'aviso',
      'avisos',
      'comunicado',
    ])) {
      return NotificationSubSource.generalNotices.key;
    }

    if (_containsAny(clean, const [
      'general_ads',
      'ads',
      'publicidade',
      'campanha',
    ])) {
      return NotificationSubSource.generalAds.key;
    }

    if (clean.contains('dfd')) {
      return NotificationSubSource.contractsHiringDfd.key;
    }

    if (clean.contains('etp')) {
      return NotificationSubSource.contractsHiringEtp.key;
    }

    if (_containsAny(clean, const [
      'contracts_hiring_tr',
      '_tr',
      'termo',
      'referencia',
      'referência',
    ])) {
      return NotificationSubSource.contractsHiringTr.key;
    }

    if (_containsAny(clean, const [
      'cotacao',
      'cotação',
    ])) {
      return NotificationSubSource.contractsHiringCotacao.key;
    }

    if (_containsAny(clean, const [
      'edital',
      'julgamento',
      'proposta',
      'lance',
    ])) {
      return NotificationSubSource.contractsHiringEdital.key;
    }

    if (_containsAny(clean, const [
      'habilitacao',
      'habilitação',
      'regularidade',
    ])) {
      return NotificationSubSource.contractsHiringHabilitacao.key;
    }

    if (_containsAny(clean, const [
      'dotacao',
      'dotação',
      'orcamentaria',
      'orçamentária',
    ])) {
      return NotificationSubSource.contractsHiringDotacao.key;
    }

    if (_containsAny(clean, const [
      'budget',
      'orcamento',
      'orçamento',
      'planilha',
      'budget_general',
    ])) {
      return NotificationSubSource.budgetGeneral.key;
    }

    if (clean.contains('minuta')) {
      return NotificationSubSource.contractsHiringMinuta.key;
    }

    if (_containsAny(clean, const [
      'parecer',
      'juridico',
      'jurídico',
    ])) {
      return NotificationSubSource.contractsHiringParecer.key;
    }

    if (_containsAny(clean, const [
      'publicacao',
      'publicação',
      'extrato',
    ])) {
      return NotificationSubSource.contractsHiringPublicacao.key;
    }

    if (_containsAny(clean, const [
      'arquivamento',
      'arquivar',
      'arquivo',
    ])) {
      return NotificationSubSource.contractsHiringArquivamento.key;
    }

    // -------------------------------------------------------------------------
    // PAGAMENTOS
    // Importante: pagamentos vêm antes de "medição", porque alguns textos podem
    // conter "pagamento de medição". Nesse caso, a origem correta é pagamentos.
    // -------------------------------------------------------------------------

    if (_containsAny(clean, const [
      'payments_bulletin',
      'payment_bulletin',
      'financial_payments',
      'payment_notification',
      'pagamento_boletim',
      'pagamento de boletim',
      'pagamento medicao',
      'pagamento medição',
      'pagamento de medicao',
      'pagamento de medição',
      'pagamentos medicao',
      'pagamentos medição',
    ])) {
      return NotificationSubSource.paymentsBulletin.key;
    }

    if (_containsAny(clean, const [
      'payments_adjustments',
      'payment_adjustment',
      'financial_payments_adjustments',
      'adjustment_payment_notification',
      'pagamento_reajuste',
      'pagamento de reajuste',
      'pagamentos_reajuste',
      'pagamentos de reajuste',
    ])) {
      return NotificationSubSource.paymentsAdjustments.key;
    }

    if (_containsAny(clean, const [
      'payments_revision',
      'payments_revisions',
      'payment_revision',
      'financial_payments_revisions',
      'revision_payment_notification',
      'pagamento_revisao',
      'pagamento_revisão',
      'pagamento de revisao',
      'pagamento de revisão',
      'pagamentos_revisao',
      'pagamentos_revisão',
      'pagamentos de revisao',
      'pagamentos de revisão',
    ])) {
      return NotificationSubSource.paymentsRevision.key;
    }

    if (_containsAny(clean, const [
      'payment',
      'payments',
      'pagamento',
      'pagamentos',
      'pago',
      'paga',
      'liquidacao',
      'liquidação',
      'financeiro',
      'financial',
    ])) {
      return NotificationSubSource.paymentsBulletin.key;
    }

    // -------------------------------------------------------------------------
    // MEDIÇÕES
    // -------------------------------------------------------------------------

    if (_containsAny(clean, const [
      'measurements_bulletin',
      'measurement_bulletin',
      'operation_measurements',
      'measurement_notification',
      'measurement',
      'measurements',
      'medicao',
      'medição',
      'medicoes',
      'medições',
      'boletim',
    ])) {
      return NotificationSubSource.measurementsBulletin.key;
    }

    if (_containsAny(clean, const [
      'measurements_adjustments',
      'measurement_adjustment',
      'operation_measurements_adjustments',
      'adjustment_measurement_notification',
      'adjustment',
      'adjustments',
      'reajuste',
      'reajustes',
    ])) {
      return NotificationSubSource.measurementsAdjustments.key;
    }

    if (_containsAny(clean, const [
      'measurements_revision',
      'measurements_revisions',
      'measurement_revision',
      'operation_measurements_revisions',
      'revision_measurement_notification',
      'revision',
      'revisao',
      'revisão',
      'revisoes',
      'revisões',
    ])) {
      return NotificationSubSource.measurementsRevision.key;
    }

    if (_containsAny(clean, const [
      'schedule',
      'gallery',
      'estaca',
    ])) {
      return NotificationSubSource.scheduleGeneral.key;
    }

    if (_containsAny(clean, const [
      'additive',
      'aditivo',
      'aditivos',
    ])) {
      return NotificationSubSource.additivesGeneral.key;
    }

    if (_containsAny(clean, const [
      'apostille',
      'apostila',
      'apostilamento',
      'apostilamentos',
    ])) {
      return NotificationSubSource.apostillesGeneral.key;
    }

    if (_containsAny(clean, const [
      'validity',
      'vigencia',
      'vigência',
      'validade',
      'prazo',
    ])) {
      return NotificationSubSource.validityGeneral.key;
    }

    if (_containsAny(clean, const [
      'contract',
      'contrato',
      'process',
      'processo',
      'hiring',
      'contratacao',
      'contratação',
    ])) {
      return NotificationSubSource.contractsHiringDfd.key;
    }

    return NotificationSubSource.generalSystem.key;
  }

  static bool _containsAny(String value, Iterable<String> terms) {
    for (final term in terms) {
      if (value.contains(term)) return true;
    }

    return false;
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