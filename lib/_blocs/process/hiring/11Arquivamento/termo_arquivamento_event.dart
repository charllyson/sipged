// lib/_blocs/process/hiring/11Arquivamento/termo_arquivamento_event.dart
part of 'termo_arquivamento_bloc.dart';

sealed class TermoArquivamentoEvent {}

class TermoArquivamentoLoadRequested extends TermoArquivamentoEvent {
  final String contractId;
  TermoArquivamentoLoadRequested(this.contractId);
}

class TermoArquivamentoSaveRequested extends TermoArquivamentoEvent {
  final String contractId;
  final SectionsMap sectionsData;
  TermoArquivamentoSaveRequested({
    required this.contractId,
    required this.sectionsData,
  });
}

class TermoArquivamentoSaveOneSectionRequested extends TermoArquivamentoEvent {
  final String contractId;
  final String sectionKey;
  final Map<String, dynamic> data;
  TermoArquivamentoSaveOneSectionRequested({
    required this.contractId,
    required this.sectionKey,
    required this.data,
  });
}

/// Reseta o flag de sucesso após exibir Snackbar/Toast
class TermoArquivamentoClearSuccessRequested extends TermoArquivamentoEvent {}
