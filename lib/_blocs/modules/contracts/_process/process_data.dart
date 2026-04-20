import 'package:cloud_firestore/cloud_firestore.dart';

class ProcessData {
  final String? id;

  /// Identificação e metadados principais
  final DateTime? publicationDate;
  final int? initialValidityExecution;
  final int? initialValidityContract;

  /// ACL por contrato
  final Map<String, Map<String, bool>> permissionContractId;

  /// Metadados por participante
  final Map<String, Map<String, dynamic>> participantsInfo;

  const ProcessData({
    this.id,
    this.publicationDate,
    this.initialValidityExecution,
    this.initialValidityContract,
    this.permissionContractId = const {},
    this.participantsInfo = const {},
  });

  factory ProcessData.empty() {
    return const ProcessData(
      id: null,
      publicationDate: null,
      initialValidityExecution: 0,
      initialValidityContract: 0,
      permissionContractId: {},
      participantsInfo: {},
    );
  }

  ProcessData copyWith({
    String? id,
    DateTime? publicationDate,
    int? initialValidityExecution,
    int? initialValidityContract,
    Map<String, Map<String, bool>>? permissionContractId,
    Map<String, Map<String, dynamic>>? participantsInfo,
  }) {
    return ProcessData(
      id: id ?? this.id,
      publicationDate: publicationDate ?? this.publicationDate,
      initialValidityExecution:
      initialValidityExecution ?? this.initialValidityExecution,
      initialValidityContract:
      initialValidityContract ?? this.initialValidityContract,
      permissionContractId:
      permissionContractId ?? this.permissionContractId,
      participantsInfo: participantsInfo ?? this.participantsInfo,
    );
  }

  static DateTime? _readDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;

    if (value is String && value.trim().isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        try {
          final parts = value.split('/');
          if (parts.length == 3) {
            final d = int.parse(parts[0]);
            final m = int.parse(parts[1]);
            final y = int.parse(parts[2]);
            return DateTime(y, m, d);
          }
        } catch (_) {}
      }
    }

    return null;
  }

  factory ProcessData.fromDocument({required DocumentSnapshot snapshot}) {
    if (!snapshot.exists) {
      throw Exception('Contrato não encontrado');
    }

    final data = snapshot.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Os dados do contrato estão vazios');
    }

    return ProcessData.fromJson(data, id: snapshot.id);
  }

  factory ProcessData.fromJson(Map<String, dynamic> json, {String? id}) {
    final rawPerms = json['permissionContractId'];
    final rawParts = json['participantsInfo'];

    return ProcessData(
      id: id,
      publicationDate: _readDate(json['datapublicacaodoe']),
      initialValidityExecution:
      (json['initialvalidityexecutiondays'] as num?)?.toInt(),
      initialValidityContract:
      (json['initialvaliditycontractdays'] as num?)?.toInt(),
      permissionContractId: (rawPerms is Map<String, dynamic>)
          ? rawPerms.map(
            (userId, perm) => MapEntry(
          userId,
          Map<String, bool>.from((perm as Map).map(
                (k, v) => MapEntry(k.toString(), v == true),
          )),
        ),
      )
          : <String, Map<String, bool>>{},
      participantsInfo: (rawParts is Map<String, dynamic>)
          ? rawParts.map(
            (uid, meta) => MapEntry(
          uid,
          Map<String, dynamic>.from(meta as Map),
        ),
      )
          : <String, Map<String, dynamic>>{},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (publicationDate != null) 'datapublicacaodoe': publicationDate,
      if (initialValidityExecution != null)
        'initialvalidityexecutiondays': initialValidityExecution,
      if (initialValidityContract != null)
        'initialvaliditycontractdays': initialValidityContract,
      'permissionContractId': permissionContractId,
      'participantsInfo': participantsInfo,
    };
  }

  ProcessData copyWithUpdatedPermission({
    required String userId,
    required String permissionType,
    required bool value,
  }) {
    final updatedPerms =
    Map<String, Map<String, bool>>.from(permissionContractId);

    final userPerms = Map<String, bool>.from(updatedPerms[userId] ?? {});
    userPerms[permissionType] = value;
    updatedPerms[userId] = userPerms;

    return copyWith(permissionContractId: updatedPerms);
  }

  ProcessData copyWithParticipantPerms({
    required String userId,
    required Map<String, bool> perms,
  }) {
    final updatedPerms =
    Map<String, Map<String, bool>>.from(permissionContractId);
    updatedPerms[userId] = Map<String, bool>.from(perms);

    return copyWith(permissionContractId: updatedPerms);
  }

  ProcessData copyWithParticipantMeta({
    required String userId,
    required Map<String, dynamic> meta,
  }) {
    final updatedMeta =
    Map<String, Map<String, dynamic>>.from(participantsInfo);
    updatedMeta[userId] = Map<String, dynamic>.from(meta);

    return copyWith(participantsInfo: updatedMeta);
  }

  ProcessData copyWithParticipantRole({
    required String userId,
    required String role,
  }) {
    final updatedMeta =
    Map<String, Map<String, dynamic>>.from(participantsInfo);

    final current = Map<String, dynamic>.from(updatedMeta[userId] ?? {});
    current['role'] = role;
    updatedMeta[userId] = current;

    return copyWith(participantsInfo: updatedMeta);
  }

  ProcessData copyWithAddedParticipant({
    required String userId,
    required Map<String, bool> perms,
    Map<String, dynamic> meta = const {},
  }) {
    final updatedPerms =
    Map<String, Map<String, bool>>.from(permissionContractId);
    updatedPerms[userId] = Map<String, bool>.from(perms);

    final updatedMeta =
    Map<String, Map<String, dynamic>>.from(participantsInfo);
    if (meta.isNotEmpty) {
      updatedMeta[userId] = Map<String, dynamic>.from(meta);
    }

    return copyWith(
      permissionContractId: updatedPerms,
      participantsInfo: updatedMeta,
    );
  }

  ProcessData copyWithRemovedParticipant(String userId) {
    final updatedPerms =
    Map<String, Map<String, bool>>.from(permissionContractId);
    final updatedMeta =
    Map<String, Map<String, dynamic>>.from(participantsInfo);

    updatedPerms.remove(userId);
    updatedMeta.remove(userId);

    return copyWith(
      permissionContractId: updatedPerms,
      participantsInfo: updatedMeta,
    );
  }
}