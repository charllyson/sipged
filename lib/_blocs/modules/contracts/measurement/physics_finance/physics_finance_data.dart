// lib/_blocs/modules/contracts/measurement/physics_finance/physics_finance_data.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PhysicsFinanceData {
  final String id;
  final String contractId;
  final String additiveId;
  final int termOrder;
  final List<int> periods;
  final Map<String, List<double>> grid;
  final DateTime? createdAt;
  final String? createdBy;
  final DateTime? updatedAt;
  final String? updatedBy;

  const PhysicsFinanceData({
    required this.id,
    required this.contractId,
    required this.additiveId,
    required this.termOrder,
    required this.periods,
    required this.grid,
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
  });

  static String docIdForTerm(int termOrder) {
    return 'term-${termOrder.toString().padLeft(3, '0')}';
  }

  factory PhysicsFinanceData.empty({
    required String contractId,
    required String additiveId,
    required int termOrder,
    required List<int> periods,
  }) {
    return PhysicsFinanceData(
      id: docIdForTerm(termOrder),
      contractId: contractId.trim(),
      additiveId: additiveId.trim(),
      termOrder: termOrder,
      periods: List<int>.from(periods),
      grid: const <String, List<double>>{},
    );
  }

  factory PhysicsFinanceData.fromSnapshot({
    required String contractId,
    required String additiveId,
    required DocumentSnapshot<Map<String, dynamic>> snap,
  }) {
    final Map<String, dynamic> data = snap.data() ?? const <String, dynamic>{};

    final dynamic rawPeriods = data['periods'];
    final dynamic rawGrid = data['grid'];

    return PhysicsFinanceData(
      id: snap.id,
      contractId: (data['contractId'] as String?)?.trim().isNotEmpty == true
          ? (data['contractId'] as String).trim()
          : contractId.trim(),
      additiveId: (data['additiveId'] as String?)?.trim().isNotEmpty == true
          ? (data['additiveId'] as String).trim()
          : additiveId.trim(),
      termOrder: (data['termOrder'] as num?)?.toInt() ??
          int.tryParse(
            snap.id.replaceAll(RegExp(r'[^0-9]'), ''),
          ) ??
          1,
      periods: rawPeriods is List
          ? rawPeriods
          .whereType<num>()
          .map((value) => value.toInt())
          .toList()
          : const <int>[],
      grid: rawGrid is Map
          ? rawGrid.map<String, List<double>>(
            (key, value) {
          final String cleanKey = key.toString().trim();

          final List<double> values = value is List
              ? value
              .whereType<num>()
              .map((item) => item.toDouble())
              .toList()
              : <double>[];

          return MapEntry(cleanKey, values);
        },
      )
          : const <String, List<double>>{},
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      createdBy: data['createdBy'] as String?,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      updatedBy: data['updatedBy'] as String?,
    );
  }

  Map<String, dynamic> toMap({
    String? tenantId,
    String? recordPath,
    String? updatedByOverride,
    bool includeCreatedFields = false,
    String? createdByOverride,
  }) {
    final String cleanTenantId = tenantId?.trim() ?? '';
    final String cleanRecordPath = recordPath?.trim() ?? '';
    final String cleanUpdatedBy = updatedByOverride?.trim() ?? '';
    final String cleanCreatedBy = createdByOverride?.trim() ?? '';

    final Map<String, dynamic> payload = <String, dynamic>{
      'id': id.trim(),
      'contractId': contractId.trim(),
      'additiveId': additiveId.trim(),
      'termOrder': termOrder,
      'periods': List<int>.from(periods),
      'grid': grid.map(
            (key, value) {
          return MapEntry(
            key.trim(),
            List<double>.from(value),
          );
        },
      ),
      'updatedAt': FieldValue.serverTimestamp(),
      if (cleanUpdatedBy.isNotEmpty) 'updatedBy': cleanUpdatedBy,
      if (cleanTenantId.isNotEmpty) ...<String, dynamic>{
        'tenantId': cleanTenantId,
        'companyId': cleanTenantId,
      },
      if (cleanRecordPath.isNotEmpty) 'recordPath': cleanRecordPath,
      'sourceCollectionModel': 'tenant_contract_additive_schedules',
    };

    if (includeCreatedFields) {
      payload['createdAt'] = FieldValue.serverTimestamp();

      if (cleanCreatedBy.isNotEmpty) {
        payload['createdBy'] = cleanCreatedBy;
      }
    }

    return payload;
  }

  PhysicsFinanceData copyWith({
    String? id,
    String? contractId,
    String? additiveId,
    int? termOrder,
    List<int>? periods,
    Map<String, List<double>>? grid,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return PhysicsFinanceData(
      id: id ?? this.id,
      contractId: contractId ?? this.contractId,
      additiveId: additiveId ?? this.additiveId,
      termOrder: termOrder ?? this.termOrder,
      periods: periods != null ? List<int>.from(periods) : this.periods,
      grid: grid != null
          ? grid.map(
            (key, value) {
          return MapEntry(
            key,
            List<double>.from(value),
          );
        },
      )
          : this.grid,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}

class PhysFinRow {
  final String key;
  final int item;
  final String descricao;
  final double valor;
  final List<double> percent;

  const PhysFinRow({
    required this.key,
    required this.item,
    required this.descricao,
    required this.valor,
    required this.percent,
  });
}

class PhysFinTotals {
  final List<double> parciais;
  final List<double> acumulados;
  final double totalGeral;

  const PhysFinTotals({
    required this.parciais,
    required this.acumulados,
    required this.totalGeral,
  });
}

class PhysFinWidths {
  final double itemCol;
  final double descCol;
  final double? extraCol;
  final double percentCol;
  final double valueCol;
  final double barVisual;

  const PhysFinWidths({
    required this.itemCol,
    required this.descCol,
    this.extraCol,
    required this.percentCol,
    required this.valueCol,
    required this.barVisual,
  });
}

class PhysFinMeasured {
  final double descColWidth;
  final double valueColWidth;

  const PhysFinMeasured({
    required this.descColWidth,
    required this.valueColWidth,
  });
}

class PhysFinExtraColumn {
  final String header;
  final double width;
  final Widget Function(BuildContext context, PhysFinRow row) cellBuilder;

  const PhysFinExtraColumn({
    required this.header,
    required this.width,
    required this.cellBuilder,
  });
}