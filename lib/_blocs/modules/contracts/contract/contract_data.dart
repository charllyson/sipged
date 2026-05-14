import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:sipged/_blocs/system/permission/permission_cubit.dart';

class ContractData {
  final String? id;

  /// ACL por contrato.
  ///
  /// Estrutura oficial:
  /// permissionContractId: {
  ///   uid: {
  ///     read: true,
  ///     create: false,
  ///     edit: false,
  ///     delete: false,
  ///     approve: false,
  ///   }
  /// }
  final Map<String, Map<String, bool>> permissionContractId;

  /// Metadados por participante.
  ///
  /// Estrutura oficial:
  /// participantsInfo: {
  ///   uid: {
  ///     role: 'FISCAL',
  ///     ...
  ///   }
  /// }
  final Map<String, Map<String, dynamic>> participantsInfo;

  const ContractData({
    this.id,
    this.permissionContractId = const {},
    this.participantsInfo = const {},
  });

  factory ContractData.empty() {
    return const ContractData(
      id: null,
      permissionContractId: {},
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
    Map<String, Map<String, bool>>? permissionContractId,
    Map<String, Map<String, dynamic>>? participantsInfo,
  }) {
    return ContractData(
      id: id ?? this.id,
      permissionContractId: permissionContractId ?? this.permissionContractId,
      participantsInfo: participantsInfo ?? this.participantsInfo,
    );
  }

  static Map<String, Map<String, bool>> _readPermissionContractId(
      dynamic raw,
      ) {
    if (raw is! Map) return <String, Map<String, bool>>{};

    final result = <String, Map<String, bool>>{};

    for (final entry in raw.entries) {
      final userId = entry.key.toString().trim();

      if (userId.isEmpty) continue;

      final value = entry.value;

      if (value is Map) {
        result[userId] = SystemPermission.normalizeDocPerms(value);
      }
    }

    return result;
  }

  static Map<String, Map<String, dynamic>> _readParticipantsInfo(
      dynamic raw,
      ) {
    if (raw is! Map) return <String, Map<String, dynamic>>{};

    final result = <String, Map<String, dynamic>>{};

    for (final entry in raw.entries) {
      final userId = entry.key.toString().trim();

      if (userId.isEmpty) continue;

      final value = entry.value;

      if (value is Map) {
        result[userId] = Map<String, dynamic>.from(value);
      }
    }

    return result;
  }

  static dynamic _firstExistingValue(
      Map<String, dynamic> json,
      List<String> keys,
      ) {
    for (final key in keys) {
      if (json.containsKey(key)) {
        return json[key];
      }
    }

    return null;
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
    final rawPermissions = _firstExistingValue(
      json,
      const <String>[
        'permissionContractId',
        'permissionsContractId',
        'permissionContracts',
        'permissions',
        'participantsPermissions',
      ],
    );

    final rawParticipantsInfo = _firstExistingValue(
      json,
      const <String>[
        'participantsInfo',
        'participants',
        'participantsMeta',
        'participantsData',
      ],
    );

    return ContractData(
      id: _readIdFromJson(json, id),
      permissionContractId: _readPermissionContractId(rawPermissions),
      participantsInfo: _readParticipantsInfo(rawParticipantsInfo),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (id != null && id!.trim().isNotEmpty) 'id': id!.trim(),
      'permissionContractId': permissionContractId.map(
            (uid, perms) {
          return MapEntry(
            uid.trim(),
            SystemPermission.normalizeDocPerms(perms),
          );
        },
      )..removeWhere((uid, _) => uid.isEmpty),
      'participantsInfo': participantsInfo.map(
            (uid, meta) {
          return MapEntry(
            uid.trim(),
            Map<String, dynamic>.from(meta),
          );
        },
      )..removeWhere((uid, _) => uid.isEmpty),
    };
  }

  Map<String, bool> permissionForUser(String userId) {
    final uid = userId.trim();

    if (uid.isEmpty) {
      return SystemPermission.initialDocPerms();
    }

    return SystemPermission.normalizeDocPerms(
      permissionContractId[uid],
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

  bool hasParticipant(String userId) {
    final uid = userId.trim();

    if (uid.isEmpty) return false;

    return permissionContractId.containsKey(uid);
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

    final updatedPerms = Map<String, Map<String, bool>>.from(
      permissionContractId,
    );

    final userPerms = SystemPermission.normalizeDocPerms(
      updatedPerms[cleanUserId],
    );

    userPerms[cleanPermissionType] = value;
    updatedPerms[cleanUserId] = SystemPermission.normalizeDocPerms(userPerms);

    return copyWith(
      permissionContractId: updatedPerms,
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

    final updatedPerms = Map<String, Map<String, bool>>.from(
      permissionContractId,
    );

    updatedPerms[cleanUserId] = SystemPermission.normalizeDocPerms(perms);

    return copyWith(
      permissionContractId: updatedPerms,
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

    final updatedMeta = Map<String, Map<String, dynamic>>.from(
      participantsInfo,
    );

    updatedMeta[cleanUserId] = Map<String, dynamic>.from(meta);

    return copyWith(
      participantsInfo: updatedMeta,
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

    final updatedMeta = Map<String, Map<String, dynamic>>.from(
      participantsInfo,
    );

    final current = Map<String, dynamic>.from(
      updatedMeta[cleanUserId] ?? const <String, dynamic>{},
    );

    current['role'] = cleanRole;
    updatedMeta[cleanUserId] = current;

    return copyWith(
      participantsInfo: updatedMeta,
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

    final updatedPerms = Map<String, Map<String, bool>>.from(
      permissionContractId,
    );

    updatedPerms[cleanUserId] = SystemPermission.normalizeDocPerms(perms);

    final updatedMeta = Map<String, Map<String, dynamic>>.from(
      participantsInfo,
    );

    final normalizedMeta = <String, dynamic>{
      if (meta.isNotEmpty) ...Map<String, dynamic>.from(meta),
      if ((meta['role']?.toString().trim() ?? '').isEmpty)
        'role': 'COLABORADOR',
    };

    updatedMeta[cleanUserId] = normalizedMeta;

    return copyWith(
      permissionContractId: updatedPerms,
      participantsInfo: updatedMeta,
    );
  }

  ContractData copyWithRemovedParticipant(String userId) {
    final cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) {
      return this;
    }

    final updatedPerms = Map<String, Map<String, bool>>.from(
      permissionContractId,
    );

    final updatedMeta = Map<String, Map<String, dynamic>>.from(
      participantsInfo,
    );

    updatedPerms.remove(cleanUserId);
    updatedMeta.remove(cleanUserId);

    return copyWith(
      permissionContractId: updatedPerms,
      participantsInfo: updatedMeta,
    );
  }

  @override
  String toString() {
    return 'ContractData('
        'id: $id, '
        'permissionContractId: ${permissionContractId.length}, '
        'participantsInfo: ${participantsInfo.length}'
        ')';
  }
}