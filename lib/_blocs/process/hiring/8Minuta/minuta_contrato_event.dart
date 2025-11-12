part of 'minuta_contrato_bloc.dart';

abstract class MinutaEvent {}

class MinutaLoadRequested extends MinutaEvent {
  final String contractId;
  MinutaLoadRequested(this.contractId);
}

class MinutaSaveRequested extends MinutaEvent {
  final String contractId;
  final SectionsMap sectionsData;
  MinutaSaveRequested({required this.contractId, required this.sectionsData});
}

class MinutaSaveOneSectionRequested extends MinutaEvent {
  final String contractId;
  final String sectionKey;
  final Map<String, dynamic> data;
  MinutaSaveOneSectionRequested({
    required this.contractId,
    required this.sectionKey,
    required this.data,
  });
}

/// limpar o flag de sucesso após mostrar Snackbar/toast
class MinutaClearSuccessRequested extends MinutaEvent {}
