part of 'tr_bloc.dart';

abstract class TrEvent {}

class TrLoadRequested extends TrEvent {
  final String contractId;
  TrLoadRequested(this.contractId);
}

class TrSaveRequested extends TrEvent {
  final String contractId;
  final SectionsMap sectionsData;
  TrSaveRequested({
    required this.contractId,
    required this.sectionsData,
  });
}

class TrSaveOneSectionRequested extends TrEvent {
  final String contractId;
  final String sectionKey;
  final Map<String, dynamic> data;

  TrSaveOneSectionRequested({
    required this.contractId,
    required this.sectionKey,
    required this.data,
  });
}

/// Opcional: limpar o flag para evitar Snackbar repetido
class TrClearSuccessRequested extends TrEvent {}
