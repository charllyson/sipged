import 'contract_data.dart';

class ContractState {
  final bool loading;
  final bool initialized;
  final String? errorMessage;

  final List<ContractData> allProcesses;
  final ContractData? selectedProcess;

  /// Módulo usado no último carregamento/filtragem.
  ///
  /// Exemplo:
  /// - operation-hiring-records
  /// - operation-additive-records
  /// - operation-measurements-records
  /// - financial-payments-records
  final String? activePermissionModule;

  const ContractState({
    this.loading = false,
    this.initialized = false,
    this.errorMessage,
    this.allProcesses = const [],
    this.selectedProcess,
    this.activePermissionModule,
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
    String? activePermissionModule,
    bool clearActivePermissionModule = false,
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
      activePermissionModule: clearActivePermissionModule
          ? null
          : (activePermissionModule ?? this.activePermissionModule),
    );
  }
}