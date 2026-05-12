import 'contract_data.dart';

class ContractState {
  final bool loading;
  final bool initialized;
  final String? errorMessage;

  final List<ContractData> allProcesses;
  final ContractData? selectedProcess;

  /// Tenant usado no último carregamento.
  ///
  /// Caminho oficial:
  /// /tenants/{tenantId}/contracts/{contractId}
  final String? activeTenantId;

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
    this.allProcesses = const <ContractData>[],
    this.selectedProcess,
    this.activeTenantId,
    this.activePermissionModule,
  });

  factory ContractState.initial() {
    return const ContractState();
  }

  bool get hasActiveTenant {
    return activeTenantId != null && activeTenantId!.trim().isNotEmpty;
  }

  ContractState copyWith({
    bool? loading,
    bool? initialized,
    String? errorMessage,
    bool clearErrorMessage = false,
    List<ContractData>? allProcesses,
    ContractData? selectedProcess,
    bool clearSelectedProcess = false,
    String? activeTenantId,
    bool clearActiveTenantId = false,
    String? activePermissionModule,
    bool clearActivePermissionModule = false,
  }) {
    return ContractState(
      loading: loading ?? this.loading,
      initialized: initialized ?? this.initialized,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      allProcesses: allProcesses ?? this.allProcesses,
      selectedProcess:
      clearSelectedProcess ? null : selectedProcess ?? this.selectedProcess,
      activeTenantId:
      clearActiveTenantId ? null : activeTenantId ?? this.activeTenantId,
      activePermissionModule: clearActivePermissionModule
          ? null
          : activePermissionModule ?? this.activePermissionModule,
    );
  }
}