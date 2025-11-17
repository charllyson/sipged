import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// usa o mesmo modelo já existente no projeto
import 'package:siged/_widgets/list/files/attachment.dart';

class ProcessData extends ChangeNotifier {
  /// Identificação e metadados
  String? id;

  double? initialValueContract;
  DateTime? publicationDate;
  int? initialValidityExecution;
  int? initialValidityContract;

  /// ACL por contrato
  Map<String, Map<String, bool>> permissionContractId = {};

  /// Metadados por participante
  Map<String, Map<String, dynamic>> participantsInfo = {};

  ProcessData({
    this.id,
    this.initialValidityExecution,
    this.initialValidityContract,
    this.publicationDate,
    this.initialValueContract,
    this.permissionContractId = const {},
    Map<String, Map<String, dynamic>>? participantsInfo,
  }) : participantsInfo = participantsInfo ?? {};

  factory ProcessData.empty() {
    return ProcessData(
      id: null,
      initialValueContract: 0.0,
      publicationDate: DateTime(2000),
      initialValidityContract: 0,
      initialValidityExecution: 0,
      permissionContractId: {},
      participantsInfo: {},
    );
  }

  /// Helper genérico para ler datas aceitando Timestamp / DateTime / String
  static DateTime? _readDate(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String && v.trim().isNotEmpty) {
      // tenta ISO ou dd/MM/yyyy
      try {
        return DateTime.parse(v);
      } catch (_) {
        // último chute: dd/MM/yyyy
        try {
          final parts = v.split('/');
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

  /// Recuperando informações no banco de dados
  factory ProcessData.fromDocument({required DocumentSnapshot snapshot}) {
    if (!snapshot.exists) {
      throw Exception("Contrato não encontrado");
    }
    final data = snapshot.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception("Os dados do contrato estão vazios");
    }

    final rawPerms = data['permissionContractId'];
    final rawParts = data['participantsInfo'];

    return ProcessData(
      id: snapshot.id,
      publicationDate: _readDate(data['datapublicacaodoe']),
      initialValueContract:
      (data['valorinicialdocontrato'] as num?)?.toDouble() ?? 0.0,
      initialValidityExecution:
      (data['initialvalidityexecutiondays'] as num?)?.toInt(),
      initialValidityContract:
      (data['initialvaliditycontractdays'] as num?)?.toInt(),
      permissionContractId:
      (rawPerms is Map<String, dynamic>)
          ? rawPerms.map(
            (userId, perm) =>
            MapEntry(userId, Map<String, bool>.from(perm as Map)),
      )
          : <String, Map<String, bool>>{},
      participantsInfo:
      (rawParts is Map<String, dynamic>)
          ? rawParts.map(
            (uid, meta) =>
            MapEntry(uid, Map<String, dynamic>.from(meta as Map)),
      )
          : <String, Map<String, dynamic>>{},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (initialValueContract != null)
        'valorinicialdocontrato': initialValueContract,
      if (publicationDate != null) 'datapublicacaodoe': publicationDate,
      if (initialValidityExecution != null)
        'initialvalidityexecutiondays': initialValidityExecution,
      if (initialValidityContract != null)
        'initialvaliditycontractdays': initialValidityContract,
      if (permissionContractId.isNotEmpty)
        'permissionContractId': permissionContractId,
      if (participantsInfo.isNotEmpty) 'participantsInfo': participantsInfo,
    };
  }

  factory ProcessData.fromJson(Map<String, dynamic> json, {String? id}) {
    return ProcessData(
      id: id,
      initialValueContract:
      (json['valorinicialdocontrato'] as num?)?.toDouble(),
      publicationDate: _readDate(json['datapublicacaodoe']),
      initialValidityExecution:
      (json['initialvalidityexecutiondays'] as num?)?.toInt(),
      initialValidityContract:
      (json['initialvaliditycontractdays'] as num?)?.toInt(),
      permissionContractId:
      (json['permissionContractId'] as Map<String, dynamic>?)
          ?.map(
            (key, value) =>
            MapEntry(key, Map<String, bool>.from(value)),
      ) ??
          {},
      participantsInfo:
      (json['participantsInfo'] as Map<String, dynamic>?)
          ?.map(
            (k, v) => MapEntry(k, Map<String, dynamic>.from(v)),
      ) ??
          {},
    );
  }

  // Atualiza as permissões do usuário para um contrato específico usando o ID do documento
  void updateContractPermissions(
      String contractDocId, String permissionType, bool value) {
    if (permissionContractId[contractDocId] == null) {
      permissionContractId[contractDocId] = {};
    }
    permissionContractId[contractDocId]![permissionType] = value;
  }

  // ---- Helpers locais de participantes (inalterados) ----
  void upsertParticipantLocal(
      String uid, {
        bool read = true,
        bool edit = false,
        bool delete = false,
        Map<String, dynamic>? meta,
      }) {
    permissionContractId[uid] = {'read': read, 'edit': edit, 'delete': delete};
    if (meta != null) {
      final m = Map<String, dynamic>.from(participantsInfo[uid] ?? {});
      m.addAll(meta);
      participantsInfo[uid] = m;
    }
    notifyListeners();
  }

  void removeParticipantLocal(String uid) {
    permissionContractId.remove(uid);
    participantsInfo.remove(uid);
    notifyListeners();
  }
}
