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

    final resolvedDisplay = await resolveContractDisplay(
      contract: contract,
    );

    if (!context.mounted) return;

    final contractSummary =
        clean(resolvedDisplay.summary) ?? fallbackContractSummary(contract);

    final contractNumber = clean(resolvedDisplay.number) ?? contractId;

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
    NotificationDelivery? delivery,
    Set<NotificationChannel>? channels,
  }) {
    final resolvedChannels = <NotificationChannel>{
      if (channels != null) ...channels,
      if (delivery != null) ...delivery.channels,
      if (channels == null && delivery == null) NotificationChannel.local,
      if (saveInBell) NotificationChannel.bell,
      if (sendPush) NotificationChannel.push,
    };

    if (resolvedChannels.isEmpty) {
      resolvedChannels.add(NotificationChannel.local);
    }

    return resolvedChannels;
  }

  /// Resolve os dados corretos de exibição do contrato:
  ///
  /// - número: PublicacaoExtratoData.numeroContrato
  /// - resumo: DfdData.descricaoObjeto
  static Future<({String? number, String? summary})> resolveContractDisplay({
    required ContractData contract,
  }) async {
    final contractId = clean(contract.id);

    if (contractId == null) {
      return (
      number: clean(contract.displayNumber),
      summary: clean(contract.displaySummary),
      );
    }

    final publicacao = await _loadPublicacaoExtrato(contractId);
    final dfd = await _loadDfd(contractId);

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

  static Future<PublicacaoExtratoData?> _loadPublicacaoExtrato(
      String contractId,
      ) async {
    final candidatePaths = <String>[
      'contracts/$contractId/hiring/10Publicacao',
      'contracts/$contractId/hiring/publicacaoExtrato',
      'contracts/$contractId/hiring/publicacao_extrato',
      'contracts/$contractId/publicacaoExtrato/main',
      'contracts/$contractId/publicacoes/extrato',
    ];

    for (final path in candidatePaths) {
      final data = await _tryReadDocument(path);

      if (data == null) continue;

      final parsed = _parsePublicacaoExtrato(data);

      if (parsed != null) return parsed;
    }

    return null;
  }

  static PublicacaoExtratoData? _parsePublicacaoExtrato(
      Map<String, dynamic> data,
      ) {
    final sectionsData = data['sectionsData'];
    final sections = data['sections'];

    if (sectionsData is Map) {
      return PublicacaoExtratoData.fromSectionsMap(
        _toSectionsMap(sectionsData),
      );
    }

    if (sections is Map) {
      return PublicacaoExtratoData.fromSectionsMap(
        _toSectionsMap(sections),
      );
    }

    return PublicacaoExtratoData.fromFlatMap(data);
  }

  static Future<DfdData?> _loadDfd(String contractId) async {
    final candidatePaths = <String>[
      'contracts/$contractId/hiring/00Dfd',
      'contracts/$contractId/hiring/01Dfd',
      'contracts/$contractId/hiring/dfd',
      'contracts/$contractId/dfd/main',
      'contracts/$contractId/demand/dfd',
    ];

    for (final path in candidatePaths) {
      final data = await _tryReadDocument(path);

      if (data == null) continue;

      final parsed = _parseDfd(
        data,
        contractId: contractId,
      );

      if (parsed != null) return parsed;
    }

    return null;
  }

  static DfdData? _parseDfd(
      Map<String, dynamic> data, {
        required String contractId,
      }) {
    final sectionsData = data['sectionsData'];
    final sections = data['sections'];

    if (sectionsData is Map) {
      return DfdData.fromSectionsMap(
        _toDynamicMap(sectionsData),
        contractId: contractId,
      );
    }

    if (sections is Map) {
      return DfdData.fromSectionsMap(
        _toDynamicMap(sections),
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

  /// Retorna todos os usuários que devem receber a notificação do contrato.
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

    final recipients = <String>{};

    recipients.addAll(
      _recipientsFromPermissionContractId(contract.permissionContractId),
    );

    recipients.addAll(
      _recipientsFromParticipantsInfo(contract.participantsInfo),
    );

    if (includeCurrentUser && current != null) {
      recipients.add(current);
    }

    if (!includeCurrentUser && current != null) {
      recipients.remove(current);
    }

    return _sortedUserIds(recipients);
  }

  static Set<String> _recipientsFromPermissionContractId(
      Map<String, Map<String, bool>> permissionContractId,
      ) {
    final recipients = <String>{};

    for (final entry in permissionContractId.entries) {
      final userId = clean(entry.key);

      if (userId == null) continue;

      final permissions = entry.value;

      if (_hasAnyContractPermission(permissions)) {
        recipients.add(userId);
      }
    }

    return recipients;
  }

  static Set<String> _recipientsFromParticipantsInfo(
      Map<String, dynamic> participantsInfo,
      ) {
    final recipients = <String>{};

    for (final entry in participantsInfo.entries) {
      final userId = clean(entry.key);

      if (userId == null) continue;

      final value = entry.value;

      if (_participantLooksActive(value)) {
        recipients.add(userId);
      }
    }

    return recipients;
  }

  static bool _participantLooksActive(dynamic value) {
    if (value == null) return true;

    if (value is bool) return value;

    if (value is Map) {
      final active = _boolFromDynamic(
        value['active'] ??
            value['enabled'] ??
            value['isActive'] ??
            value['ativo'] ??
            value['habilitado'],
      );

      final removed = _boolFromDynamic(
        value['removed'] ??
            value['deleted'] ??
            value['isDeleted'] ??
            value['removido'] ??
            value['excluido'] ??
            value['excluído'],
      );

      if (removed == true) return false;
      if (active == false) return false;

      return true;
    }

    return true;
  }

  static bool _hasAnyContractPermission(Map<String, bool> permissions) {
    if (permissions.isEmpty) return false;

    const acceptedKeys = <String>{
      'read',
      'view',
      'viewer',
      'visualizar',
      'visao',
      'visão',
      'ler',
      'leitura',
      'create',
      'creator',
      'criar',
      'criacao',
      'criação',
      'edit',
      'update',
      'write',
      'writer',
      'editar',
      'atualizar',
      'alterar',
      'escrever',
      'gravacao',
      'gravação',
      'delete',
      'remove',
      'deletar',
      'excluir',
      'remover',
      'admin',
      'administrator',
      'owner',
      'manager',
      'gestor',
      'fiscal',
      'administrador',
      'proprietario',
      'proprietário',
      'responsavel',
      'responsável',
      'canread',
      'canview',
      'cancreate',
      'canedit',
      'canupdate',
      'candelete',
      'canmanage',
    };

    for (final entry in permissions.entries) {
      final key = _normalizePermissionKey(entry.key);

      if (acceptedKeys.contains(key) && entry.value == true) {
        return true;
      }
    }

    return false;
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

  static bool? _boolFromDynamic(dynamic value) {
    if (value == null) return null;

    if (value is bool) return value;

    if (value is num) {
      if (value == 1) return true;
      if (value == 0) return false;
    }

    final text = value.toString().trim().toLowerCase();

    if (text.isEmpty) return null;

    if (<String>{
      'true',
      '1',
      'yes',
      'sim',
      's',
      'ativo',
      'active',
      'enabled',
      'habilitado',
    }.contains(text)) {
      return true;
    }

    if (<String>{
      'false',
      '0',
      'no',
      'nao',
      'não',
      'n',
      'inativo',
      'inactive',
      'disabled',
      'desabilitado',
    }.contains(text)) {
      return false;
    }

    return null;
  }

  static String _normalizePermissionKey(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('_', '')
        .replaceAll('-', '');
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
      (meta['fullName'] ??
          meta['displayName'] ??
          meta['nameComplete'] ??
          meta['nomeCompleto'] ??
          meta['nome'] ??
          '')
          .toString(),
    );

    if (fullName != null) return fullName;

    final name = clean(
      (meta['name'] ?? meta['nome'] ?? '').toString(),
    );

    final surname = clean(
      (meta['surname'] ?? meta['sobrenome'] ?? '').toString(),
    );

    final composed = <String>[
      ?name,
      ?surname,
    ].join(' ').trim();

    if (composed.isNotEmpty) return composed;

    final email = clean(
      (meta['email'] ?? '').toString(),
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