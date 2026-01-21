// lib/_blocs/modules/contracts/budget/budget_state.dart
import 'package:equatable/equatable.dart';
import 'budget_data.dart';

enum BudgetStatus { initial, loading, success, failure }

class BudgetState extends Equatable {
  const BudgetState({
    this.status = BudgetStatus.initial,
    this.byContract = const {},
    this.loading = const {},
    this.errorByContract = const {},
    this.lastContractId,
  });

  final BudgetStatus status;

  /// Cache: contractId -> BudgetData
  final Map<String, BudgetData> byContract;

  /// contractId -> loading
  final Map<String, bool> loading;

  /// contractId -> erro (string)
  final Map<String, String?> errorByContract;

  /// Último contrato operado (útil para UI)
  final String? lastContractId;

  BudgetData? dataFor(String contractId) => byContract[contractId];
  bool loadingFor(String contractId) => loading[contractId] == true;
  String? errorFor(String contractId) => errorByContract[contractId];

  BudgetState copyWith({
    BudgetStatus? status,
    Map<String, BudgetData>? byContract,
    Map<String, bool>? loading,
    Map<String, String?>? errorByContract,
    String? lastContractId,
  }) {
    return BudgetState(
      status: status ?? this.status,
      byContract: byContract ?? this.byContract,
      loading: loading ?? this.loading,
      errorByContract: errorByContract ?? this.errorByContract,
      lastContractId: lastContractId ?? this.lastContractId,
    );
  }

  @override
  List<Object?> get props => [status, byContract, loading, errorByContract, lastContractId];
}
