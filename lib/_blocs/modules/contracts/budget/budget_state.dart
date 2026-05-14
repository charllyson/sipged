// lib/_blocs/modules/contracts/budget/budget_state.dart

import 'package:equatable/equatable.dart';

import 'budget_data.dart';

enum BudgetStatus {
  initial,
  loading,
  success,
  failure,
}

class BudgetState extends Equatable {
  const BudgetState({
    this.status = BudgetStatus.initial,
    this.byContract = const <String, BudgetData>{},
    this.loading = const <String, bool>{},
    this.errorByContract = const <String, String?>{},
    this.lastContractId,
  });

  final BudgetStatus status;
  final Map<String, BudgetData> byContract;
  final Map<String, bool> loading;
  final Map<String, String?> errorByContract;
  final String? lastContractId;

  BudgetData? dataFor(String contractId) {
    return byContract[contractId.trim()];
  }

  bool loadingFor(String contractId) {
    return loading[contractId.trim()] == true;
  }

  String? errorFor(String contractId) {
    return errorByContract[contractId.trim()];
  }

  BudgetState copyWith({
    BudgetStatus? status,
    Map<String, BudgetData>? byContract,
    Map<String, bool>? loading,
    Map<String, String?>? errorByContract,
    String? lastContractId,
    bool clearLastContractId = false,
  }) {
    return BudgetState(
      status: status ?? this.status,
      byContract: byContract ?? this.byContract,
      loading: loading ?? this.loading,
      errorByContract: errorByContract ?? this.errorByContract,
      lastContractId:
      clearLastContractId ? null : lastContractId ?? this.lastContractId,
    );
  }

  @override
  List<Object?> get props {
    return <Object?>[
      status,
      byContract,
      loading,
      errorByContract,
      lastContractId,
    ];
  }
}