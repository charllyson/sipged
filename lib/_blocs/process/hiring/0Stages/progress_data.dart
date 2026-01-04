// lib/_blocs/process/hiring/0Stages/progress_data.dart

import 'package:meta/meta.dart';

@immutable
class ProgressData {
  final bool approved;
  final String? approverUid;
  final String? approverName;
  final DateTime? approvalCreatedAt;
  final DateTime? approvalUpdatedAt;

  final bool completed;
  final String? responsibleUserId;
  final String? approverUserId;
  final String? responsibleName;
  final String? stageApproverName;
  final DateTime? stageUpdatedAt;

  const ProgressData({
    required this.approved,
    this.approverUid,
    this.approverName,
    this.approvalCreatedAt,
    this.approvalUpdatedAt,
    required this.completed,
    this.responsibleUserId,
    this.approverUserId,
    this.responsibleName,
    this.stageApproverName,
    this.stageUpdatedAt,
  });

  static DateTime? _ts(dynamic v) {
    if (v == null) return null;
    try {
      if (v is DateTime) return v;
      // Compat Firestore Timestamp
      final toDate = (v as dynamic).toDate;
      if (toDate is Function) return toDate();
    } catch (_) {}
    return null;
  }

  static Map<String, dynamic> _map(Object? x) =>
      (x is Map<String, dynamic>) ? x : <String, dynamic>{};

  factory ProgressData.fromMap(Map<String, dynamic>? m) {
    final a = _map(m?['approval']);
    final byA = _map(a['approvedBy']);
    final s = _map(m?['stage']);

    // leitura nested
    final resp = _map(s['responsible']);
    final appr = _map(s['approver']);

    return ProgressData(
      approved: (a['approved'] == true),
      approverUid: byA['uid'] as String?,
      approverName: byA['name'] as String?,
      approvalCreatedAt: _ts(a['createdAt']),
      approvalUpdatedAt: _ts(a['updatedAt']),

      completed: (s['completed'] == true),

      // lidos do formato nested gravado no Firestore
      responsibleUserId: resp['uid'] as String?,
      responsibleName: resp['name'] as String?,

      approverUserId: appr['uid'] as String?,
      stageApproverName: appr['name'] as String?,

      stageUpdatedAt: _ts(s['updatedAt']),
    );
  }
}
