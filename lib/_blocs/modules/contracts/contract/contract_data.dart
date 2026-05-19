// lib/_blocs/modules/contracts/contract/contract_data.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sipged/_blocs/system/permission/permission_data.dart';

class ContractData {
  final String? id;
  final Map<String, Map<String, dynamic>> participantsInfo;

  const ContractData({
    this.id,
    this.participantsInfo = const {},
  });

  factory ContractData.empty() {
    return const ContractData(
      id: null,
      participantsInfo: {},
    );
  }

  String get displaySummary {
    final localId = (id ?? '').trim();

    if (localId.isNotEmpty) {
      return 'Contrato $localId';
    }

    return 'Contrato sem identificação';
  }

  String get displayNumber {
    return id ?? '';
  }

  ContractData copyWith({
    String? id,
    Map<String, Map<String, dynamic>>? participantsInfo,
  }) {
    return ContractData(
      id: id ?? this.id,
      participantsInfo: participantsInfo ?? this.participantsInfo,
    );
  }

  static String? _readIdFromJson(
      Map<String, dynamic> json,
      String? id,
      ) {
    final explicitId = id?.trim();

    if (explicitId != null && explicitId.isNotEmpty) {
      return explicitId;
    }

    final fromId = json['id']?.toString().trim();

    if (fromId != null && fromId.isNotEmpty) {
      return fromId;
    }

    final contractId = json['contractId']?.toString().trim();

    if (contractId != null && contractId.isNotEmpty) {
      return contractId;
    }

    final uidContract = json['uidContract']?.toString().trim();

    if (uidContract != null && uidContract.isNotEmpty) {
      return uidContract;
    }

    final uidcontract = json['uidcontract']?.toString().trim();

    if (uidcontract != null && uidcontract.isNotEmpty) {
      return uidcontract;
    }

    return id;
  }

  static Map<String, Map<String, dynamic>> _readParticipantsInfo(
      dynamic raw,
      ) {
    if (raw is! Map) {
      return <String, Map<String, dynamic>>{};
    }

    final result = <String, Map<String, dynamic>>{};

    for (final entry in raw.entries) {
      final uid = entry.key.toString().trim();

      if (uid.isEmpty) continue;

      final value = entry.value;

      if (value is! Map) continue;

      final meta = Map<String, dynamic>.from(
        value.map(
              (key, item) {
            return MapEntry(
              key.toString(),
              item,
            );
          },
        ),
      );

      result[uid] = _normalizeParticipantMeta(meta);
    }

    return result;
  }

  static Map<String, dynamic> _normalizeParticipantMeta(
      Map<String, dynamic> raw,
      ) {
    final meta = Map<String, dynamic>.from(raw);

    final role = meta['role']?.toString().trim();

    meta['role'] = role == null || role.isEmpty ? 'COLABORADOR' : role;

    final active = meta['active'];

    meta['active'] = active is bool ? active : true;

    final permissions = meta['permissions'];

    meta['permissions'] = SystemPermission.normalizeDocPerms(
      permissions is Map ? permissions : const <String, bool>{},
    );

    return meta;
  }

  factory ContractData.fromDocument({
    required DocumentSnapshot snapshot,
  }) {
    if (!snapshot.exists) {
      throw Exception('Contrato não encontrado');
    }

    final data = snapshot.data() as Map<String, dynamic>?;

    if (data == null) {
      throw Exception('Os dados do contrato estão vazios');
    }

    return ContractData.fromJson(
      data,
      id: snapshot.id,
    );
  }

  factory ContractData.fromJson(
      Map<String, dynamic> json, {
        String? id,
      }) {
    return ContractData(
      id: _readIdFromJson(json, id),
      participantsInfo: _readParticipantsInfo(
        json['participantsInfo'],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    final normalizedParticipants = participantsInfo.map(
          (uid, meta) {
        return MapEntry(
          uid.trim(),
          _normalizeParticipantMeta(
            Map<String, dynamic>.from(meta),
          ),
        );
      },
    )..removeWhere((uid, _) => uid.isEmpty);

    return <String, dynamic>{
      if (id != null && id!.trim().isNotEmpty) 'id': id!.trim(),
      'participantsInfo': normalizedParticipants,
    };
  }

  List<String> get participantIds {
    final ids = participantsInfo.keys
        .map((uid) => uid.trim())
        .where((uid) => uid.isNotEmpty)
        .toSet()
        .toList();

    ids.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return ids;
  }

  Map<String, bool> permissionForUser(String userId) {
    final uid = userId.trim();

    if (uid.isEmpty) {
      return SystemPermission.initialDocPerms();
    }

    final info = participantsInfo[uid];

    if (info == null) {
      return SystemPermission.initialDocPerms();
    }

    return SystemPermission.normalizeDocPerms(
      info['permissions'],
    );
  }

  Map<String, dynamic> participantInfoForUser(String userId) {
    final uid = userId.trim();

    if (uid.isEmpty) {
      return const <String, dynamic>{};
    }

    return Map<String, dynamic>.from(
      participantsInfo[uid] ?? const <String, dynamic>{},
    );
  }

  String participantRoleForUser(String userId) {
    final info = participantInfoForUser(userId);
    final role = info['role']?.toString().trim();

    if (role == null || role.isEmpty) {
      return 'COLABORADOR';
    }

    return role;
  }

  bool participantIsActive(String userId) {
    final info = participantInfoForUser(userId);

    if (info.isEmpty) return false;

    final active = info['active'];

    if (active is bool) {
      return active;
    }

    return true;
  }

  bool hasParticipant(String userId) {
    final uid = userId.trim();

    if (uid.isEmpty) return false;

    return participantsInfo.containsKey(uid);
  }

  bool canUser(String userId, String permissionType) {
    final cleanPermission = permissionType.trim();

    if (cleanPermission.isEmpty) return false;

    final perms = permissionForUser(userId);

    return perms[cleanPermission] == true;
  }

  ContractData copyWithUpdatedPermission({
    required String userId,
    required String permissionType,
    required bool value,
  }) {
    final cleanUserId = userId.trim();
    final cleanPermissionType = permissionType.trim();

    if (cleanUserId.isEmpty || cleanPermissionType.isEmpty) {
      return this;
    }

    final updatedParticipants = Map<String, Map<String, dynamic>>.from(
      participantsInfo,
    );

    final currentMeta = Map<String, dynamic>.from(
      updatedParticipants[cleanUserId] ?? const <String, dynamic>{},
    );

    final currentPerms = SystemPermission.normalizeDocPerms(
      currentMeta['permissions'],
    );

    currentPerms[cleanPermissionType] = value;

    currentMeta['permissions'] = SystemPermission.normalizeDocPerms(
      currentPerms,
    );

    updatedParticipants[cleanUserId] = _normalizeParticipantMeta(currentMeta);

    return copyWith(
      participantsInfo: updatedParticipants,
    );
  }

  ContractData copyWithParticipantPerms({
    required String userId,
    required Map<String, bool> perms,
  }) {
    final cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) {
      return this;
    }

    final updatedParticipants = Map<String, Map<String, dynamic>>.from(
      participantsInfo,
    );

    final currentMeta = Map<String, dynamic>.from(
      updatedParticipants[cleanUserId] ?? const <String, dynamic>{},
    );

    currentMeta['permissions'] = SystemPermission.normalizeDocPerms(perms);

    updatedParticipants[cleanUserId] = _normalizeParticipantMeta(currentMeta);

    return copyWith(
      participantsInfo: updatedParticipants,
    );
  }

  ContractData copyWithParticipantMeta({
    required String userId,
    required Map<String, dynamic> meta,
  }) {
    final cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) {
      return this;
    }

    final updatedParticipants = Map<String, Map<String, dynamic>>.from(
      participantsInfo,
    );

    updatedParticipants[cleanUserId] = _normalizeParticipantMeta(
      Map<String, dynamic>.from(meta),
    );

    return copyWith(
      participantsInfo: updatedParticipants,
    );
  }

  ContractData copyWithParticipantRole({
    required String userId,
    required String role,
  }) {
    final cleanUserId = userId.trim();
    final cleanRole = role.trim();

    if (cleanUserId.isEmpty || cleanRole.isEmpty) {
      return this;
    }

    final updatedParticipants = Map<String, Map<String, dynamic>>.from(
      participantsInfo,
    );

    final currentMeta = Map<String, dynamic>.from(
      updatedParticipants[cleanUserId] ?? const <String, dynamic>{},
    );

    currentMeta['role'] = cleanRole;

    updatedParticipants[cleanUserId] = _normalizeParticipantMeta(currentMeta);

    return copyWith(
      participantsInfo: updatedParticipants,
    );
  }

  ContractData copyWithAddedParticipant({
    required String userId,
    required Map<String, bool> perms,
    Map<String, dynamic> meta = const {},
  }) {
    final cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) {
      return this;
    }

    final updatedParticipants = Map<String, Map<String, dynamic>>.from(
      participantsInfo,
    );

    final nextMeta = <String, dynamic>{
      ...Map<String, dynamic>.from(meta),
      'permissions': SystemPermission.normalizeDocPerms(perms),
      'active': true,
    };

    final role = nextMeta['role']?.toString().trim();

    if (role == null || role.isEmpty) {
      nextMeta['role'] = 'COLABORADOR';
    }

    updatedParticipants[cleanUserId] = _normalizeParticipantMeta(nextMeta);

    return copyWith(
      participantsInfo: updatedParticipants,
    );
  }

  ContractData copyWithRemovedParticipant(String userId) {
    final cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) {
      return this;
    }

    final updatedParticipants = Map<String, Map<String, dynamic>>.from(
      participantsInfo,
    );

    updatedParticipants.remove(cleanUserId);

    return copyWith(
      participantsInfo: updatedParticipants,
    );
  }

  @override
  String toString() {
    return 'ContractData('
        'id: $id, '
        'participantsInfo: ${participantsInfo.length}'
        ')';
  }
}