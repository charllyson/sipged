// lib/_blocs/modules/operation/operation/road/physics_finance/physics_finance_store.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'physics_finance_bloc.dart';
import 'physics_finance_data.dart';

class PhysicsFinanceStore extends ChangeNotifier {
  PhysicsFinanceStore({PhysicsFinanceBloc? bloc})
      : _bloc = bloc ?? PhysicsFinanceBloc();

  final PhysicsFinanceBloc _bloc;

  // cache: "$cid::$aid" -> {termOrder: PhysicsFinanceData}
  final Map<String, Map<int, PhysicsFinanceData>> _byPair = {};
  final Map<String, bool> _loading = {};

  String _key(String contractId, String additiveId) => '$contractId::$additiveId';

  bool isLoading(String contractId, String additiveId) =>
      _loading[_key(contractId, additiveId)] == true;

  Future<void> ensure(String contractId, String additiveId) async {
    final k = _key(contractId, additiveId);
    if (_byPair.containsKey(k) || _loading[k] == true) return;
    _loading[k] = true; _notifyAfterBuild();
    try {
      final list = await _bloc.list(contractId: contractId, additiveId: additiveId);
      final map = <int, PhysicsFinanceData>{};
      for (final s in list) { map[s.termOrder] = s; }
      _byPair[k] = map;
    } finally {
      _loading[k] = false; _notifyAfterBuild();
    }
  }

  Future<PhysicsFinanceData?> getForTerm({
    required String contractId,
    required String additiveId,
    required int termOrder,
  }) async {
    final k = _key(contractId, additiveId);
    await ensure(contractId, additiveId);
    final cached = _byPair[k]?[termOrder];
    if (cached != null) return cached;

    final s = await _bloc.get(
      contractId: contractId,
      additiveId: additiveId,
      termOrder: termOrder,
    );
    if (s != null) {
      _byPair.putIfAbsent(k, () => <int, PhysicsFinanceData>{})[termOrder] = s;
      _notifyAfterBuild();
    }
    return s;
  }

  Future<void> upsert({
    required String contractId,
    required String additiveId,
    required PhysicsFinanceData schedule,
    String? updatedBy,
  }) async {
    await _bloc.upsert(
      contractId: contractId,
      additiveId: additiveId,
      schedule: schedule,
      updatedBy: updatedBy,
    );
    final k = _key(contractId, additiveId);
    _byPair.putIfAbsent(k, () => <int, PhysicsFinanceData>{})[schedule.termOrder] = schedule;
    _notifyAfterBuild();
  }

  Future<void> delete({
    required String contractId,
    required String additiveId,
    required String scheduleId,
  }) async {
    await _bloc.delete(
      contractId: contractId,
      additiveId: additiveId,
      scheduleId: scheduleId,
    );
    final k = _key(contractId, additiveId);
    _byPair[k]?.removeWhere((_, v) => v.id == scheduleId);
    _notifyAfterBuild();
  }

  void clearPair(String contractId, String additiveId) {
    final k = _key(contractId, additiveId);
    _byPair.remove(k); _loading.remove(k); _notifyAfterBuild();
  }

  void clearAll() {
    _byPair.clear(); _loading.clear(); _notifyAfterBuild();
  }

  void _notifyAfterBuild() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle || phase == SchedulerPhase.postFrameCallbacks) {
      if (hasListeners) notifyListeners();
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (hasListeners) notifyListeners();
      });
    }
  }
}
