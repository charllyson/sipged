import 'contract_data.dart';

class ContractState {
  final bool loading;
  final bool initialized;
  final String? errorMessage;

  final List<ContractData> allProcesses;
  final ContractData? selectedProcess;

  const ContractState({
    this.loading = false,
    this.initialized = false,
    this.errorMessage,
    this.allProcesses = const [],
    this.selectedProcess,
  });

  factory ContractState.initial() => const ContractState();

  ContractState copyWith({
    bool? loading,
    bool? initialized,
    String? errorMessage,
    bool clearErrorMessage = false,
    List<ContractData>? allProcesses,
    ContractData? selectedProcess,
    bool clearSelectedProcess = false,
  }) {
    return ContractState(
      loading: loading ?? this.loading,
      initialized: initialized ?? this.initialized,
      errorMessage:
      clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      allProcesses: allProcesses ?? this.allProcesses,
      selectedProcess: clearSelectedProcess
          ? null
          : (selectedProcess ?? this.selectedProcess),
    );
  }
}