// lib/_blocs/modules/operation/operation/road/physics_finance/physics_finance_repository.dart
import 'physics_finance_data.dart';

abstract class PhysicsFinanceRepository {
  Future<List<PhysicsFinanceData>> list({
    required String contractId,
    required String additiveId,
  });

  Future<PhysicsFinanceData?> get({
    required String contractId,
    required String additiveId,
    required int termOrder,
  });

  Future<void> upsert({
    required String contractId,
    required String additiveId,
    required PhysicsFinanceData schedule,
    String? updatedBy,
  });

  Future<void> delete({
    required String contractId,
    required String additiveId,
    required String scheduleId,
  });
}
