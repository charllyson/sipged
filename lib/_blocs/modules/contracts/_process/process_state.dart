import 'process_data.dart';

class ProcessState {
  final bool loading;
  final bool initialized;
  final String? errorMessage;

  final List<ProcessData> allProcesses;
  final ProcessData? selectedProcess;

  const ProcessState({
    this.loading = false,
    this.initialized = false,
    this.errorMessage,
    this.allProcesses = const [],
    this.selectedProcess,
  });

  factory ProcessState.initial() => const ProcessState();

  ProcessState copyWith({
    bool? loading,
    bool? initialized,
    String? errorMessage,
    bool clearErrorMessage = false,
    List<ProcessData>? allProcesses,
    ProcessData? selectedProcess,
    bool clearSelectedProcess = false,
  }) {
    return ProcessState(
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