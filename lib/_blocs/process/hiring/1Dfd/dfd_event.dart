// lib/_blocs/process/hiring/1Dfd/dfd_event.dart
part of 'dfd_bloc.dart';

sealed class DfdEvent {}

class DfdLoadRequested extends DfdEvent {
  final String contractId;
  DfdLoadRequested(this.contractId);
}

/// Salvar TODAS as seções de uma vez
class DfdSaveRequested extends DfdEvent {
  final String contractId;
  final SectionsMap sectionsData; // {secao: map}
  DfdSaveRequested({
    required this.contractId,
    required this.sectionsData,
  });
}

/// Salvar APENAS uma seção
class DfdSaveOneSectionRequested extends DfdEvent {
  final String contractId;
  final String sectionKey;
  final Map<String, dynamic> data;
  DfdSaveOneSectionRequested({
    required this.contractId,
    required this.sectionKey,
    required this.data,
  });
}

/// Reseta o flag de sucesso (Snackbar/Toast já exibido)
class DfdClearSuccessRequested extends DfdEvent {}
