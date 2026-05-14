// lib/_blocs/modules/operation/phys_fin/physics_finance_data.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class PhysicsFinanceData {
  final String id;
  final String contractId;
  final String additiveId;
  final int termOrder;
  final List<int> periods;
  final Map<String, List<double>> grid;
  final DateTime? updatedAt;
  final String? updatedBy;

  const PhysicsFinanceData({
    required this.id,
    required this.contractId,
    required this.additiveId,
    required this.termOrder,
    required this.periods,
    required this.grid,
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
      contractId: contractId,
      additiveId: additiveId,
      termOrder: termOrder,
      periods: periods,
      grid: const <String, List<double>>{},
    );
  }

  factory PhysicsFinanceData.fromSnapshot({
    required String contractId,
    required String additiveId,
    required DocumentSnapshot<Map<String, dynamic>> snap,
  }) {
    final Map<String, dynamic> data = snap.data() ?? const <String, dynamic>{};

    return PhysicsFinanceData(
      id: snap.id,
      contractId: contractId,
      additiveId: additiveId,
      termOrder: (data['termOrder'] as num?)?.toInt() ??
          int.tryParse(snap.id.replaceAll(RegExp(r'[^0-9]'), '')) ??
          1,
      periods: (data['periods'] as List<dynamic>? ?? const <dynamic>[])
          .map((e) => (e as num).toInt())
          .toList(),
      grid: (data['grid'] as Map<String, dynamic>? ?? const <String, dynamic>{})
          .map(
            (key, value) {
          final List<double> values =
          (value as List<dynamic>? ?? const <dynamic>[])
              .map((e) => (e as num).toDouble())
              .toList();

          return MapEntry(key, values);
        },
      ),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      updatedBy: data['updatedBy'] as String?,
    );
  }

  Map<String, dynamic> toMap({
    String? updatedByOverride,
  }) {
    return {
      'id': id,
      'contractId': contractId,
      'additiveId': additiveId,
      'termOrder': termOrder,
      'periods': periods,
      'grid': grid,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': ?updatedByOverride,
    };
  }

  PhysicsFinanceData copyWith({
    String? id,
    String? contractId,
    String? additiveId,
    int? termOrder,
    List<int>? periods,
    Map<String, List<double>>? grid,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return PhysicsFinanceData(
      id: id ?? this.id,
      contractId: contractId ?? this.contractId,
      additiveId: additiveId ?? this.additiveId,
      termOrder: termOrder ?? this.termOrder,
      periods: periods ?? this.periods,
      grid: grid ?? this.grid,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}