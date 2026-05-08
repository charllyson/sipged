// lib/_blocs/modules/contracts/_process/contract_data.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ContractData {
  final String? id;

  /// ACL por contrato
  final Map<String, Map<String, bool>> permissionContractId;

  /// Metadados por participante
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
    if (localId.isNotEmpty) return 'Contrato $localId';

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
        result[userId] = Map<String, bool>.from(
          value.map(
                (k, v) => MapEntry(
              k.toString(),
              v == true,
            ),
          ),
        );
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
      id: id ?? json['id']?.toString(),
      permissionContractId: _readPermissionContractId(
        json['permissionContractId'],
      ),
      participantsInfo: _readParticipantsInfo(
        json['participantsInfo'],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (id != null && id!.trim().isNotEmpty) 'id': id,
      'permissionContractId': permissionContractId,
      'participantsInfo': participantsInfo,
    };
  }

  ContractData copyWithUpdatedPermission({
    required String userId,
    required String permissionType,
    required bool value,
  }) {
    final updatedPerms = Map<String, Map<String, bool>>.from(
      permissionContractId,
    );

    final userPerms = Map<String, bool>.from(
      updatedPerms[userId] ?? {},
    );

    userPerms[permissionType] = value;
    updatedPerms[userId] = userPerms;

    return copyWith(
      permissionContractId: updatedPerms,
    );
  }

  ContractData copyWithParticipantPerms({
    required String userId,
    required Map<String, bool> perms,
  }) {
    final updatedPerms = Map<String, Map<String, bool>>.from(
      permissionContractId,
    );

    updatedPerms[userId] = Map<String, bool>.from(perms);

    return copyWith(
      permissionContractId: updatedPerms,
    );
  }

  ContractData copyWithParticipantMeta({
    required String userId,
    required Map<String, dynamic> meta,
  }) {
    final updatedMeta = Map<String, Map<String, dynamic>>.from(
      participantsInfo,
    );

    updatedMeta[userId] = Map<String, dynamic>.from(meta);

    return copyWith(
      participantsInfo: updatedMeta,
    );
  }

  ContractData copyWithParticipantRole({
    required String userId,
    required String role,
  }) {
    final updatedMeta = Map<String, Map<String, dynamic>>.from(
      participantsInfo,
    );

    final current = Map<String, dynamic>.from(
      updatedMeta[userId] ?? {},
    );

    current['role'] = role;
    updatedMeta[userId] = current;

    return copyWith(
      participantsInfo: updatedMeta,
    );
  }

  ContractData copyWithAddedParticipant({
    required String userId,
    required Map<String, bool> perms,
    Map<String, dynamic> meta = const {},
  }) {
    final updatedPerms = Map<String, Map<String, bool>>.from(
      permissionContractId,
    );

    updatedPerms[userId] = Map<String, bool>.from(perms);

    final updatedMeta = Map<String, Map<String, dynamic>>.from(
      participantsInfo,
    );

    if (meta.isNotEmpty) {
      updatedMeta[userId] = Map<String, dynamic>.from(meta);
    }

    return copyWith(
      permissionContractId: updatedPerms,
      participantsInfo: updatedMeta,
    );
  }

  ContractData copyWithRemovedParticipant(String userId) {
    final updatedPerms = Map<String, Map<String, bool>>.from(
      permissionContractId,
    );

    final updatedMeta = Map<String, Map<String, dynamic>>.from(
      participantsInfo,
    );

    updatedPerms.remove(userId);
    updatedMeta.remove(userId);

    return copyWith(
      permissionContractId: updatedPerms,
      participantsInfo: updatedMeta,
    );
  }

  @override
  String toString() {
    return 'ProcessData('
        'id: $id, '
        'permissionContractId: ${permissionContractId.length}, '
        'participantsInfo: ${participantsInfo.length}'
        ')';
  }
}