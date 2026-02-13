
import 'package:cloud_firestore/cloud_firestore.dart';

class PhysicsFinanceData {
  final String id;                 // ex.: "term-001"
  final String contractId;
  final String additiveId;
  final int termOrder;             // 1, 2, 3...
  final List<int> periods;         // [30, 60, 90, ...]
  final Map<String, List<double>> grid; // itemId/serviceKey -> [%, %, ...]
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

  static String docIdForTerm(int termOrder) =>
      'term-${termOrder.toString().padLeft(3, '0')}';

  factory PhysicsFinanceData.fromSnapshot({
    required String contractId,
    required String additiveId,
    required DocumentSnapshot<Map<String, dynamic>> snap,
  }) {
    final data = snap.data() ?? const <String, dynamic>{};
    return PhysicsFinanceData(
      id: snap.id,
      contractId: contractId,
      additiveId: additiveId,
      termOrder: (data['termOrder'] as num?)?.toInt() ??
          int.tryParse(snap.id.replaceAll(RegExp(r'[^0-9]'), '')) ??
          1,
      periods: (data['periods'] as List<dynamic>? ?? const [])
          .map((e) => (e as num).toInt())
          .toList(),
      grid: (data['grid'] as Map<String, dynamic>? ?? const {})
          .map((k, v) => MapEntry(
        k,
        (v as List<dynamic>? ?? const [])
            .map((e) => (e as num).toDouble())
            .toList(),
      )),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      updatedBy: data['updatedBy'] as String?,
    );
  }

  Map<String, dynamic> toMap({String? updatedByOverride}) {
    return {
      'termOrder': termOrder,
      'periods': periods,
      'grid': grid,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': ?updatedByOverride,
    };
  }
}