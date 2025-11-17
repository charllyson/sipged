// lib/_blocs/process/hiring/1Dfd/dfd_event.dart

part of 'dfd_bloc.dart';

sealed class DfdEvent {}

class DfdLoadRequested extends DfdEvent {
  final String contractId;
  DfdLoadRequested(this.contractId);
}

class DfdSaveRequested extends DfdEvent {
  final String contractId;
  final SectionsMap sectionsData; // {secao: map}

  DfdSaveRequested({
    required this.contractId,
    required this.sectionsData,
  });
}

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

/// limpar o flag de sucesso após mostrar Snackbar/toast
class DfdClearSuccessRequested extends DfdEvent {}
